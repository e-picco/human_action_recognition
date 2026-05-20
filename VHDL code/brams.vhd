-- BRAM Short Module
-- todo: overview
-- Written by P. Antonik, 2015
-- PatGen Project
-- Modified by Enrico Picco, 2022

-- NOTES: --todo

-- the bram block has two port A and B. port A address is controlled within the module and cannot be accessed from outside, only input and output buses are available. port B address is accessed from outside. port A is used to write data into memory (a out is used to check that data is written) in a sequential way, and port B is used to read data from memory

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library work;
    use work.types_pkg.all;


entity brams is
    generic (
        wrState     : stateType;
        target      : targetType
    );
    port (
        clkwr       : in  std_logic := '0';
        clkrd       : in  std_logic := '0';
        state       : in  stateType := idle;
        setTarget   : in  targetType;
        wrTrig      : in  std_logic;
        wrData      : in  signed(15 downto 0);
        rdAddr      : in  unsigned(9 downto 0);
        dbData      : out signed(15 downto 0);
        rdData      : out signed(15 downto 0);
        d_addr      : out unsigned(9 downto 0)
    );
end entity;

architecture Behavioral of brams is

    signal addr     : unsigned(9 downto 0);
    signal aWrEn    : std_logic;

begin

    d_addr <= addr;

    controller : process (clkwr)
    begin
        if rising_edge(clkwr) then
            if state=wrState AND setTarget=target then
                if wrTrig='1' then
                    if addr/=to_unsigned(1023, 10) then
                        addr <= addr + 1;
                    end if;
                end if;
            elsif state=bramcheck then
                if addr/=to_unsigned(1023, 10) then
                    addr <= addr + 1;
                end if;
            else
                addr <= (others => '0');
            end if;
        end if;
    end process;

    aWrEn <= '1' when wrTrig='1' AND state=wrState AND setTarget=target else '0';

    i_bramdio18x1k : entity work.bramdio18x1k
    port map (
        clka   => clkwr,
        clkb   => clkrd,
        aWrEn => aWrEn,
        bWrEn => '0',
        aAddr => addr,
        bAddr => rdAddr,
        aIn   => wrData,
        bIn   => (others => '0'),
        aOut  => dbData,
        bOut  => rdData
    );

end;
