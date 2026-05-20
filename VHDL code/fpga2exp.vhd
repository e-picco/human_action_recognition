-- FGPA2EXP Module
-- Overview: read values from BRAM and sends to DAC
-- Written by Enrico Picco, 2021
-- Based on "fpga2exp" by P. Antonik, 2015
-- From PatGen Project

-- PIOTR NOTES: todo: rewrite
-- * main : process controlling data flow from BRAM to DSP and from DSP to DAC,
-- activated in fwpass state (in other states, signals are reset). At each beat,
-- a sequence of 3 operations is executed, separated by 4 cc:
--      1. set addresses to BRAM buses (masks & input)
--      2. register BRAM outputs to DFs that are read by DSP
--      3. register DSP output
-- The registered DSP output is sent to DAC at every beat.
-- * HW/SIM usage : DSP slices simulations take a lot of time, in iSim they
-- are replaced by a function.
-- * pacemaker : generates a beat for each (masked) RC input (each neuron), 
-- the counting is done by shifting a register, for faster operation


-- note: channel C of DAC is inverted

-- important note : change of design, no more flip-flips between bram and dsp, thus a long
-- multi-cycle path
-- only one register for toDac signal, that stores the final value


library IEEE;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library work;
    use work.types_pkg.stateType;
    use work.types_pkg.targetType;
    use work.const_pkg.nNeurons;
    use work.const_pkg.nSamples;


entity fpga2exp is
    port(
        clk         : in  std_logic;    -- expected expclk
        state       : in  stateType;    -- state @ clk
        setTarget   : in  targetType;
        mode_cont   : in  std_logic;
        inWord      : in  signed(15 downto 0);
        inWordTrig  : in  std_logic;
        dataInputs  : in  signed(15 downto 0);
        dataMask    : in  signed(15 downto 0);
        dataWeights : in  signed(15 downto 0);
        --enb_wts     : in  std_logic;
        --rcout       : in  signed(15 downto 0);
        --trig_rcout  : in  std_logic;
        --
        addrPattern : out unsigned(12 downto 0);
        addrMask    : out unsigned(9 downto 0);
        addrWeights : out unsigned(9 downto 0);
        toDAC1      : out std_logic_vector(15 downto 0);
        toDAC2      : out std_logic_vector(15 downto 0);
        d_lInputs   : out unsigned(12 downto 0);
        --d_nsamples  : out unsigned(6 downto 0);
        --d_dspinput  : out signed(15 downto 0);
        --d_warmup    : out std_logic;
        --d_preself   : out std_logic;
        d_beatInp   : out std_logic;
        --d_lwarmup   : out unsigned(6 downto 0);
        d_ndacamp   : out unsigned(2 downto 0);
        d_wtsdly    : out unsigned(6 downto 0)
    );
end entity;


architecture Behavioral of fpga2exp is

    component dspInMult
     port (
        clk         : in  std_logic;
        input       : in  signed(15 downto 0);
        mask        : in  signed(15 downto 0);
        mskdInp     : out std_logic_vector(15 downto 0)
    );
    end component;

    signal beatNrn  : std_logic;
    signal beatInp  : std_logic;
    --signal warmupcnt    : unsigned(6 downto 0);
    --signal dspinput : signed(15 downto 0);
    signal mskdInp  : std_logic_vector(15 downto 0);
    signal lInputs  : unsigned(12 downto 0);
    --signal nSamples : integer range 1 to 128;
    --signal dfRCOut  : signed(15 downto 0);
    --signal lWarmup  : unsigned(6 downto 0);
    signal ndacamp  : integer range 0 to 7;

    signal beat_wts         : std_logic;
    signal wtsdly           : unsigned(6 downto 0);
	
	signal init_debug        : std_logic;
	
	signal frame_cnt_debug   : unsigned(12 downto 0); 
	
	--ATTRIBUTE MARK_DEBUG : STRING;
    --ATTRIBUTE MARK_DEBUG OF setTarget : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF inWord : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF dataMask : SIGNAL IS "true";
	
	--ATTRIBUTE MARK_DEBUG OF toDAC1 : SIGNAL IS "true";
	
	--ATTRIBUTE MARK_DEBUG OF init_debug : SIGNAL IS "true";
    --ATTRIBUTE MARK_DEBUG OF beatNrn : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF beatInp : SIGNAL IS "true";
    --ATTRIBUTE MARK_DEBUG OF frame_cnt_debug : SIGNAL IS "true";




begin

    d_lInputs   <= lInputs;
    --d_nsamples  <= to_unsigned(nSamples, 7);
    d_beatInp   <= beatInp;
    --d_lwarmup   <= lWarmup;
    d_ndacamp   <= to_unsigned(ndacamp, 3);
    d_wtsdly    <= wtsdly;

    seq_inp_msk : process (clk)
        variable addrPat    : integer range 0 to (10*nNeurons) -1; -- -1;
        variable addrMsk    : integer range 0 to nNeurons-1;
        variable init       : std_logic;
		variable frame_cnt    : unsigned(12 downto 0); --for HAR

    begin
        if rising_edge(clk) then
		
            if state=train then
                
                if beatNrn='1' then
				
                    --if frame_cnt=lInputs-1 then --MAYBE IS THIS ONE!
					if (frame_cnt=lInputs-1) and ((addrPat rem nNeurons) =nNeurons-1)  then
                        if mode_cont='1' then
                            addrPat := 0;
							frame_cnt := (others => '0');
                        end if;
                    else
					    --if addrPat=nNeurons-1 then
						if (addrPat rem nNeurons) = nNeurons-1 then
						   --addrPat := 0;
						   frame_cnt := frame_cnt +1;
						--else 
                        end if;						
                    --if addrPat/=nNeurons-1 then
                        addrPat := addrPat + 1;
                        						
                    end if;
					
                    --addrPattern <= to_unsigned(addrPat,13);
					--frame_cnt_debug <= frame_cnt;
					
                --end if;

                --if beatNrn='1' then
                    if addrMsk=nNeurons-1 then
                        addrMsk := 0;
                    else
                        addrMsk := addrMsk + 1;
                    end if;
                    addrMask <= to_unsigned(addrMsk, 10);
                    --toDAC <= mskdInp;
                    toDAC1 <= std_logic_vector(shift_left(signed(mskdInp), ndacamp));
                elsif init='1' then
                    --toDAC1 <= (10 => '1', others => '0');
					--toDAC1 <= "1100000000000000"; -- ca2: -16384 , hex: c000
					toDAC1 <= "1110110010000000"; -- ca2: -4992  , hex: ec80
                    init  := '0';
                end if;

            else
                addrPat     := 0;
                addrMsk     := 0;
                init        := '1';
                --warmupcnt   <= (others => '0');
                toDAC1      <= (others => '0');
                addrPattern <= (others => '0');
                addrMask    <= (others => '0');
				frame_cnt   := (others => '0');
            end if;
			
			addrPattern <= to_unsigned(addrPat,13);
		    frame_cnt_debug <= frame_cnt;
			init_debug <= init;
			
        end if;
    end process;


    seq_wts : process (clk)
        variable addrWts    : integer range 0 to nNeurons-1;
    begin
        if rising_edge(clk) then
            if state=train then
                if beat_wts='1' then
                    if addrWts=nNeurons-1 then
                        addrWts := 0;
                    else
                        addrWts := addrWts + 1;
                    end if;
                    addrWeights <= to_unsigned(addrWts, 10);
                    toDAC2      <= std_logic_vector(dataWeights);
                end if;
            else
                addrWts     := 0;
                addrWeights <= (others => '0');
                toDAC2      <= (others => '0');
            end if;
        end if;
    end process;


    i_dspInMult : dspInMult
    port map(
        clk         => clk,
        input       => dataInputs,
        mask        => dataMask,
        mskdInp     => mskdInp
    );


    pacer : process(clk)
        variable iClk : std_logic_vector(127 downto 0);
        variable jClk : std_logic_vector(nNeurons-1 downto 0);
    begin
        if rising_edge(clk) then
            if state=train OR state=test then
                iClk := iClk(iClk'left-1 downto 0) & iClk(iClk'left);
                if iClk(nSamples)='1' then
                    iClk := (0 => '1', others => '0');
                    jClk := jClk(jClk'left-1 downto 0) & jClk(jClk'left);
                    if jClk(0)='1' then
                        beatInp <= '1';
                    else
                        beatInp <= '0';
                    end if;
                else
                    beatInp <= '0';
                end if;
                beatNrn <= iClk(0);
            else
                iClk := (0 => '1', others => '0');
                jClk := (0 => '1', others => '0');
                beatNrn <= '0';
                beatInp <= '0';
            end if;
        end if;
    end process;


    --enable_pacer_wts : process (clk)
    --begin
    --    if rising_edge(clk) then
    --        if state/=train AND state/=test then
    --            enb_pacer_wts <= '0';
    --        elsif trig_wts='1' then
    --            enb_pacer_wts <= '1';
    --        end if;
    --    end if;
    --end process;


    pacer_wts : process (clk)
        variable iClk : std_logic_vector(nSamples-1 downto 0);
        variable cnt  : integer range 0 to 2*nSamples-1;
    begin
        if rising_edge(clk) then
            if state/=train AND state/=test then
                iClk        := (iClk'left => '1', others => '0');
                beat_wts    <= '0';
                cnt         := 0;
            elsif cnt=to_integer(wtsdly) then
                iClk        := iClk(iClk'left-1 downto 0) & iClk(iClk'left);
                beat_wts    <= iClk(0);
            --elsif enb_wts='1' then
            else
                cnt         := cnt + 1;
            end if;
        end if;
    end process;


    setwtsdly : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=wtsdelay AND inWordTrig='1' then
                wtsdly <= unsigned(inWord(6 downto 0));
            end if;
        end if;
    end process;


    setlinputs : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=linp AND inWordTrig='1' then
                lInputs <= unsigned(inWord(12 downto 0));
            end if;
        end if;
    end process;

    
--    setnsamples : process (clk)
--    begin
--        if rising_edge(clk) then
--            if state=setup AND setTarget=nsmp AND inWordTrig='1' then
--                nSamples <= to_integer(unsigned(inWord));
--            end if;
--        end if;
--    end process;

    
--    setlwarmup : process (clk)
--    begin
--        if rising_edge(clk) then
--            if state=setup AND setTarget=lenwu AND inWordTrig='1' then
--                lWarmup <= unsigned(inWord(6 downto 0));
--            end if;
--        end if;
--    end process;


    setdacamp : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=dacamp AND inWordTrig='1' then
                ndacamp <= to_integer(unsigned(inWord(2 downto 0)));
            end if;
        end if;
    end process;

end Behavioral;
