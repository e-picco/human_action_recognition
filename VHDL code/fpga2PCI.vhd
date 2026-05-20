-- exp2fpga-->FIFO-->PCI-->PC data transfer
-- Written by Enrico Picco, Jan 2022 

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library work;
    use work.types_pkg.all;
    use work.const_pkg.all;

entity fpga2PCI is
    port (
	    clk               : in  std_logic;
		state             : in  stateType := idle;
        setTarget         : in  targetType;
        inWord            : in  signed(15 downto 0);
        inWordTrig        : in  std_logic;
		recData           : in  signed(15 downto 0); 
		recTrig           : in  std_logic;
		from_fifo_full    : in  std_logic;
		to_fifo_data : out std_logic_vector(31 downto 0);
		to_fifo_wren : out std_logic := '0';
		d_maxdata    : out unsigned(25 downto 0)
    );
end entity;

architecture Behavioral of fpga2PCI is

    signal maxdata : unsigned(25 downto 0);	
	
begin

    d_maxdata <= maxdata;
	
	

    datacounter : process (clk)
        variable cnt : unsigned(15 downto 0); 
    begin
        if rising_edge(clk) then
            if state=train OR state=test then
                if recTrig='1' AND cnt/=maxdata AND from_fifo_full='0' then
                    cnt         := cnt + 1;
                    to_fifo_wren <= '1';
					to_fifo_data(31 downto 16) <= (others => '0');
	                to_fifo_data(15 downto 0) <= std_logic_vector(recData);
                else
                    to_fifo_wren <= '0';
                end if;
            else
                cnt         := (others => '0');
                to_fifo_wren <= '0';
            end if;
            --d_cnt <= cnt;
        end if;
    end process;
	
    set_max_sampled_data : process (clk)
    begin
        if rising_edge(clk) then
            if state=setup AND setTarget=max_sampled_data AND inWordTrig='1' then
               maxdata  <= unsigned(inWord) & "0000000000"; --shift left 10-bits
            end if;
        end if;
    end process;

end;
