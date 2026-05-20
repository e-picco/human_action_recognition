-- PCICTRL Module
-- Overview: receive & interpret commands & data from PCIe
-- Written by Enrico Picco, Dec 2021
-- Based on "etherctrl.vhd", written by P.Antonik, 2015

--blalba
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library work;
    use work.types_pkg.stateType;
    use work.types_pkg.targetType;


entity PCIctrl is
    port(
        clk         : in  std_logic; -- PCI clock
        --PCI_data    : in  std_logic_vector(31 downto 0);
		PCI_data    : in  std_logic_vector(15 downto 0);
        PCI_wren    : in  std_logic;
        state       : out stateType;
        --trigState   : out std_logic := '0';
        setTarget   : out targetType;
        wordOut     : out signed(15 downto 0) := (others => '0');
        trigOut     : out std_logic := '0';
        --d_rxword    : out std_logic_vector(15 downto 0);
        --d_rxtrig    : out std_logic
	    d_dvalid    : out std_logic := '0';
        full        : out std_logic
    );
end entity;


architecture Behavioral of PCIctrl is
   
   
    --signal rxword  : std_logic_vector(15 downto 0);
    signal rxtrig   : std_logic;
    --signal discard  : std_logic; -- used to discard packet footer
    --signal debug_others : std_logic;
    
--    ATTRIBUTE MARK_DEBUG : STRING;
--    ATTRIBUTE MARK_DEBUG OF debug_others : SIGNAL IS "true";
--    ATTRIBUTE MARK_DEBUG OF PCI_wren : SIGNAL IS "true";
--    ATTRIBUTE MARK_DEBUG OF PCI_data : SIGNAL IS "true";
--    ATTRIBUTE MARK_DEBUG OF state : SIGNAL IS "true";
--    ATTRIBUTE MARK_DEBUG OF setTarget : SIGNAL IS "true";
--    ATTRIBUTE MARK_DEBUG OF wordOut : SIGNAL IS "true";
--    ATTRIBUTE MARK_DEBUG OF trigOut : SIGNAL IS "true";
--    --ATTRIBUTE MARK_DEBUG OF d_rxword : SIGNAL IS "true";
--    ATTRIBUTE MARK_DEBUG OF full : SIGNAL IS "true";
    
    
begin

    --d_rxtrig <= rxtrig;
	
	
    
	--rxword <= PCI_data(15 downto 0);
	
	--d_rxword <= rxword;
	
	full <= '0';
	--full <= PCI_data(15);

--    detector : process (clk)
--        constant lheader : integer := 50;
--        variable cnt     : integer range 0 to lheader;
--        variable hclk    : std_logic;
--        variable msbyte  : std_logic_vector(7 downto 0);
--        variable word    : std_logic_vector(15 downto 0);
--    begin
--        if rising_edge(clk) then
--            if rx_dv='0' then
--                cnt         := 0;   -- used to discard packet header
--                hclk        := '1'; -- used to compose 2-byte words
--                word        := (others => '0');
--                msbyte      := (others => '0');
--                rxword      <= (others => '0');
--                rxtrig      <= '0';
--            elsif cnt=lheader then
--                hclk    := not hclk;
--                word    := msbyte & rxd;
--                msbyte  := rxd;
--                if hclk='1' AND discard='0' then
--                    d_rxword    <= word;
--                    rxword      <= word;
--                    rxtrig      <= '1';
--                else
--                    rxtrig      <= '0';
--                end if;
--            else
--                cnt := cnt + 1;
--            end if;
--        end if;
--    end process;

    interpreter : process (clk)
        variable dvalid : std_logic := '0';
    begin
        if rising_edge(clk) then
		    case PCI_wren is 
			    when '0' =>
				    --discard     <= '0';
                    wordOut     <= (others => '0');
                    trigOut     <= '0';
                    --trigState   <= '0';
                    --dvalid      := '0'; d_dvalid <= '0'; --THIS IS THE ONLY LINE MODIFIED 
                    --elsif rxtrig='1' then
				when '1' =>
				    case PCI_data is
                    -- states
                    when X"7000" => 
                        state     <= idle;
                        setTarget <= none;
                        --trigState <= '1';
                    when X"7001" => 
                        state     <= setup;
                        setTarget <= none;
                        --trigState <= '1';
                    when X"7002" => 
                        state     <= train;
                        setTarget <= none;
                        --trigState <= '1';
                    when X"7003" => 
                        state     <= test;
                        setTarget <= none;
                        --trigState <= '1';
                    when X"7009" => 
                        state     <= bramcheck;
                        setTarget <= none;
                        --trigState <= '1';
                    -- targets
                    when X"7010" => setTarget <= none;
                    when X"7011" => setTarget <= inputs;   --112 17
                    when X"7012" => setTarget <= mask;     --112 18
                    when X"7013" => setTarget <= weights;  --112 19
                    when X"7014" => setTarget <= idelay;   --112 20
                    when X"7015" => setTarget <= smpdelay1;--112 21
                    when X"7016" => setTarget <= linp;     --112 22
                    when X"7017" => setTarget <= nsmp;     --to be implemented 
                    when X"7018" => setTarget <= maxfrm;   --to be deleted 
                    when X"7019" => setTarget <= adc2ofst; --to be implemented 
                    when X"701a" => setTarget <= nrn1ampf; --112 26
                    when X"701b" => setTarget <= trglvl;   --112 27
                    when X"701c" => setTarget <= nrn2ampf; --112 28
                    when X"701d" => setTarget <= dacamp;   --112 29
                    when X"701e" => setTarget <= adc1ofst; --to be implemented 
                    when X"701f" => setTarget <= dacofst;  --to be deleted
                    when X"7020" => setTarget <= smpdelay2;--112 32
                    when X"7021" => setTarget <= wtsdelay; --112 33
                    when X"7022" => setTarget <= n_warmup; --to be deleted (it was used in bramda)
					when X"7023" => setTarget <= rec_select; --112 35
					when X"7024" => setTarget <= max_sampled_data;  --112 36
                    -- distinguish data frames from other frames on the line
                    when X"7654" => dvalid := '1';  d_dvalid <= '1';                   --118 84
					when X"7655" => trigOut <= '0'; dvalid := '0';  d_dvalid <= '0';   --118 85
                    -- discard footer
                    --when X"7FFF" => discard <= '1';      --127 255
					when others => --debug_others <= '1';
                            wordOut     <= signed(PCI_data);
                            trigOut     <= dvalid;
                            --trigState   <= '0';					
					end case;
                            
            --else
                --trigOut     <= '0';
                --trigState   <= '0';
            end case;
        end if;
    end process;
    

end architecture;
