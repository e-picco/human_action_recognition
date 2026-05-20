-- EXP2FPGA Module
-- Overview: todo
-- Written by P. Antonik, 2015-2016
-- PatGen Project
-- Modified by Enrico Picco, 2022

-- 0 DSP slice

-- Description: --todo
-- todo: comment offset computer
--      * detects the sync pulse and starts sampling at the right moment (after the pause)
--      * samples ADC signal and averages neurons values
--      * accumulates serial neurons into array (for parallel transfer)
--      * generates two beats: one fast for each neuron, one slow for each channel output
--      * acts as a pacemaker for olea, stepevo and check modules
--      * delays the target signal to be in sync with neurons

    -- pacemaker
    -- generates one fast beat for neurons and one slow for channel outputs
    -- the counting is done by shifting a register, for faster operation

    -- samples ADC signal into an array

    -- averages ADC samples and accumulates neurons values into array
    -- transforms a sequence of neurons (serial bus) into array (parallel bus)

library IEEE;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library work;
    use work.types_pkg.all;
    use work.const_pkg.nSamples;
    use work.const_pkg.eAvg;
    use work.const_pkg.eAvgOfst;
    use work.const_pkg.nLSkip;
    use work.const_pkg.nRSkip;

entity exp2fpga is
   port(
        clk             : in  std_logic;
        state           : in  stateType;
        setTarget       : in  targetType;
        inWord          : in  signed(15 downto 0);
        inWordTrig      : in  std_logic;
        fromADC1        : in  signed(13 downto 0);
        fromADC2        : in  signed(13 downto 0);
        avgout1         : out signed(15 downto 0);
        avgout2         : out signed(15 downto 0);
        trigout1        : out std_logic;
        trigout2        : out std_logic;
        d_beat1         : out std_logic;
        d_beat2         : out std_logic;
        d_smpdly1       : out signed(13 downto 0);
        d_smpdly2       : out signed(13 downto 0);
        d_triglevel     : out signed(13 downto 0);
        d_enbpacer      : out std_logic;
        d_enbsmp1       : out std_logic;
        d_enbsmp2       : out std_logic;
        --d_adcofst       : out signed(13 downto 0);
        d_nrn1amplif    : out unsigned(2 downto 0);
        d_nrn2amplif    : out unsigned(2 downto 0);
        d_ndiscrbits    : out unsigned(4 downto 0);
        d_sum1          : out signed(19 downto 0);
        d_sum2          : out signed(19 downto 0) 
    );
end entity;


architecture Behavioral of exp2fpga is

    signal beat1        : std_logic;
    signal beat2        : std_logic;
    signal enbsmp1      : std_logic;
    signal enbsmp2      : std_logic;
    signal enbpacer     : std_logic;
    --signal dcofst       : signed(15 downto 0);
    signal smpdly1      : signed(13 downto 0) := (others => '0');
    signal smpdly2      : signed(13 downto 0) := (others => '0');
    signal triglevel    : signed(13 downto 0) := (others => '0');
    signal nrn1amplif   : integer range 0 to 7;
    signal nrn2amplif   : integer range 0 to 7;
    signal ndiscrbits   : integer range 0 to 31 := 0;
	
	--ATTRIBUTE MARK_DEBUG : STRING;
    --ATTRIBUTE MARK_DEBUG OF fromADC1 : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF fromADC2 : SIGNAL IS "true";
	
	--ATTRIBUTE MARK_DEBUG OF beat1    : SIGNAL IS "true";	
	--ATTRIBUTE MARK_DEBUG OF enbsmp1  : SIGNAL IS "true";
    --ATTRIBUTE MARK_DEBUG OF enbpacer : SIGNAL IS "true";

	
begin

    d_smpdly1       <= smpdly1;
    d_smpdly2       <= smpdly2;
    d_triglevel     <= triglevel;
    d_enbpacer      <= enbpacer;
    d_enbsmp1       <= enbsmp1;
    d_enbsmp2       <= enbsmp2;
    d_beat1         <= beat1;
    d_beat2         <= beat2;
    d_nrn1amplif    <= to_unsigned(nrn1amplif, 3);
    d_nrn2amplif    <= to_unsigned(nrn2amplif, 3);
    d_ndiscrbits    <= to_unsigned(ndiscrbits, 5);


    sync : process (clk)
        variable adcofst : signed(13 downto 0);
    begin
        if rising_edge(clk) then
            if state/=train AND state/=test then
                enbpacer <= '0';
            else
                if fromADC1>triglevel then
                    enbpacer <= '1';
                end if;
            end if;
        end if;
    end process;

  
    smpavg1 : process (clk)
        variable skipbeat   : std_logic;
        variable sum        : signed(19 downto 0);
        variable smpExt     : signed(19 downto 0);
        variable cnt        : integer range 1 to nSamples;
        variable preavgout  : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            if state/=train AND state/=test then
                skipbeat    := '1';
                cnt         := 1;
                sum         := (others => '0');
                avgout1     <= (others => '0');
                trigout1    <= '0';
            elsif beat1='1' then
                --avgout      <= sum(15 downto 0);
                --avgout      <= shift_left(sum(15 downto 0), 2);
                -- amplification of neurons
                -- amplification by 8x
                -- discretisation of neurons by tuned amount of bits
                preavgout   := shift_left(sum(15 downto 0), nrn1amplif);
                preavgout   := shift_right(preavgout, ndiscrbits);
                preavgout   := shift_left(preavgout, ndiscrbits);
                avgout1     <= preavgout;
                trigout1    <= '1' AND not skipbeat;
                skipbeat    := '0';
                sum         := (others => '0');
                cnt         := 1;
            elsif enbsmp1='1' then
                trigout1 <= '0';
                case cnt is
                    when nLSkip to nSamples-nRSkip-1 =>
                        smpExt := (19 downto 14 => fromADC1(13)) & fromADC1;
                        sum := sum + smpExt;
                    when nSamples-1 =>
                        sum(15 downto 0) := shift_right(sum, eAvg)(15 downto 0);
                    when others => null;
                end case;
                cnt := cnt + 1;
            else
                trigout1 <= '0';
            end if;
        end if;
        d_sum1 <= sum;
    end process;

    
    smpavg2 : process (clk)
        variable skipbeat   : std_logic;
        variable sum        : signed(19 downto 0);
        variable smpExt     : signed(19 downto 0);
        variable cnt        : integer range 1 to nSamples;
        variable preavgout  : signed(15 downto 0);
    begin
        if rising_edge(clk) then
            if state/=train AND state/=test then
                skipbeat    := '1';
                cnt         := 1;
                sum         := (others => '0');
                avgout2     <= (others => '0');
                trigout2    <= '0';
            elsif beat2='1' then
                -- amplification of neurons
                -- amplification by 8x
                -- discretisation of neurons by tuned amount of bits
                preavgout   := shift_left(sum(15 downto 0), nrn2amplif);
                preavgout   := shift_right(preavgout, ndiscrbits);
                preavgout   := shift_left(preavgout, ndiscrbits);
                avgout2     <= preavgout;
                trigout2    <= '1' AND not skipbeat;
                skipbeat    := '0';
                sum         := (others => '0');
                cnt         := 1;
            elsif enbsmp2='1' then
                trigout2 <= '0';
                case cnt is
                    when nLSkip to nSamples-nRSkip-1 =>
                        smpExt := (19 downto 14 => fromADC2(13)) & fromADC2;
                        sum := sum + smpExt;
                    when nSamples-1 =>
                        sum(15 downto 0) := shift_right(sum, eAvg)(15 downto 0);
                    when others => null;
                end case;
                cnt := cnt + 1;
            else
                trigout2 <= '0';
            end if;
        end if;
        d_sum2 <= sum;
    end process;


            
    pacer1 : process (clk)
        variable iClk : std_logic_vector(nSamples-1 downto 0);
        --variable cnt  : integer range 0 to 2**14-1;
        variable cnt  : integer range 0 to 2*nSamples-1;
    begin
        if rising_edge(clk) then
            if state/=train AND state/=test then
                iClk    := (iClk'left => '1', others => '0');
                beat1   <= '0';
                cnt     := 0;
                enbsmp1 <= '0';
            elsif cnt=to_integer(smpdly1) then
            --elsif cnt=nSamples-1 then
                iClk    := iClk(iClk'left-1 downto 0) & iClk(iClk'left);
                beat1   <= iClk(0);
                enbsmp1 <= '1';
            elsif enbpacer='1' then
                cnt     := cnt + 1; -- skip initialisation "pulse"
                enbsmp1 <= '0';
            end if;
        end if;
    end process;

    
    pacer2 : process (clk)
        variable iClk : std_logic_vector(nSamples-1 downto 0);
        variable cnt  : integer range 0 to 2*nSamples-1;
    begin
        if rising_edge(clk) then
            if state/=train AND state/=test then
                iClk    := (iClk'left => '1', others => '0');
                beat2   <= '0';
                cnt     := 0;
                enbsmp2 <= '0';
            elsif cnt=to_integer(smpdly2) then
                iClk    := iClk(iClk'left-1 downto 0) & iClk(iClk'left);
                beat2   <= iClk(0);
                enbsmp2 <= '1';
            elsif enbpacer='1' then
                cnt     := cnt + 1; -- skip initialisation "pulse"
                enbsmp2 <= '0';
            end if;
        end if;
    end process;


    setsmpdly1 : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=smpdelay1 AND inWordTrig='1' then
                smpdly1 <= inWord(13 downto 0);
            end if;
        end if;
    end process;

    
    setsmpdly2 : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=smpdelay2 AND inWordTrig='1' then
                smpdly2 <= inWord(13 downto 0);
            end if;
        end if;
    end process;

    
    settriglevel : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=trglvl AND inWordTrig='1' then
                triglevel <= inWord(13 downto 0);
            end if;
        end if;
    end process;

    
    setnrn1amplif : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=nrn1ampf AND inWordTrig='1' then
                nrn1amplif <= to_integer(unsigned(inWord(2 downto 0)));
            end if;
        end if;
    end process;

    
    setnrn2amplif : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=nrn2ampf AND inWordTrig='1' then
                nrn2amplif <= to_integer(unsigned(inWord(2 downto 0)));
            end if;
        end if;
    end process;


    
end Behavioral;
