-- BRAM Module
-- todo: overview
-- Written by P. Antonik, 2015
-- For Michiel's BPT project
-- Modified by Enrico Picco, 2022

-- NOTES: --todo

-- the bram block has two port A and B. port A address is controlled within the module and cannot be accessed from outside, only input and output buses are available. port B address is accessed from outside. port A is used to write data into memory (a out is used to check that data is written) in a sequential way, and port B is used to read data from memory

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library work;
    use work.types_pkg.all;
    use work.const_pkg.nBRAMs;
    use work.const_pkg.lAddr;


entity braml is
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
        rdAddr      : in  unsigned(lAddr-1 downto 0);
        dbData      : out signed(15 downto 0);
        rdData      : out signed(15 downto 0);
        d_addr      : out unsigned(lAddr-1 downto 0)
    );
end entity;

architecture Behavioral of braml is

    --constant nBRAMs : integer := 8;
    --constant lAddr  : integer := 13; -- 10 + log2(nBRAMs)

    type array_addr is array (0 to nBRAMs-1) of unsigned(9 downto 0);
    type array_data is array (0 to nBRAMs-1) of signed(15 downto 0);

    signal wrEn     : std_logic_vector(0 to nBRAMs);
    signal aAddr    : array_addr;
    signal bAddr    : array_addr;
    signal aIn      : array_data;
    signal aOut     : array_data;
    signal bOut     : array_data;
    signal addr     : unsigned(lAddr-1 downto 0);

begin

    d_addr <= addr;

    controller : process (clkwr)
    begin
        if rising_edge(clkwr) then
            if state=wrState AND setTarget=target then
                if wrTrig='1' then
                    if addr/=to_unsigned(2**lAddr-1, lAddr) then
                        addr <= addr + 1;
                    end if;
                end if;
            elsif state=bramcheck then
                if addr/=to_unsigned(2**lAddr-1, lAddr) then
                    addr <= addr + 1;
                end if;
            else
                addr <= (others => '0');
            end if;
        end if;
    end process;

    brams : for i in 0 to nBRAMs-1 generate
        i_bramdio18x1k : entity work.bramdio18x1k
        port map (
            clka  => clkwr,
            clkb  => clkrd,
            aWrEn => wrEn(i),
            bWrEn => '0',
            aAddr => aAddr(i),
            bAddr => bAddr(i),
            aIn   => aIn(i),
            bIn   => (others => '0'),
            aOut  => aOut(i),
            bOut  => bOut(i)
        );
    end generate;

    wrEn <= (0 => wrTrig, others => '0') when addr(addr'left downto 10)="000" AND
            state=wrState AND setTarget=target else
            (1 => wrTrig, others => '0') when addr(addr'left downto 10)="001" AND
            state=wrState AND setTarget=target else
            (2 => wrTrig, others => '0') when addr(addr'left downto 10)="010" AND
            state=wrState AND setTarget=target else
            (3 => wrTrig, others => '0') when addr(addr'left downto 10)="011" AND
            state=wrState AND setTarget=target else
            (4 => wrTrig, others => '0') when addr(addr'left downto 10)="100" AND
            state=wrState AND setTarget=target else
            (5 => wrTrig, others => '0') when addr(addr'left downto 10)="101" AND
            state=wrState AND setTarget=target else
            (6 => wrTrig, others => '0') when addr(addr'left downto 10)="110" AND
            state=wrState AND setTarget=target else
            (7 => wrTrig, others => '0') when addr(addr'left downto 10)="111" AND
            state=wrState AND setTarget=target else
            (others => '0');

    aAddr <= (0 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="000" else
             (1 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="001" else
             (2 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="010" else
             (3 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="011" else
             (4 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="100" else
             (5 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="101" else
             (6 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="110" else
             (7 => addr(9 downto 0), others => (others => '0')) 
              when addr(addr'left downto 10)="111" else
             (others => (others => '0'));
 
    bAddr <= (0 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="000" else
             (1 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="001" else
             (2 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="010" else
             (3 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="011" else
             (4 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="100" else
             (5 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="101" else
             (6 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="110" else
             (7 => rdAddr(9 downto 0), others => (others => '0')) 
              when rdAddr(rdAddr'left downto 10)="111" else
             (others => (others => '0'));
                            
    aIn <= (0 => wrData, others => (others => '0')) when addr(addr'left downto 10)="000" else
           (1 => wrData, others => (others => '0')) when addr(addr'left downto 10)="001" else
           (2 => wrData, others => (others => '0')) when addr(addr'left downto 10)="010" else
           (3 => wrData, others => (others => '0')) when addr(addr'left downto 10)="011" else
           (4 => wrData, others => (others => '0')) when addr(addr'left downto 10)="100" else
           (5 => wrData, others => (others => '0')) when addr(addr'left downto 10)="101" else
           (6 => wrData, others => (others => '0')) when addr(addr'left downto 10)="110" else
           (7 => wrData, others => (others => '0')) when addr(addr'left downto 10)="111" else
           (others => (others => '0'));
    
    rdData <= bOut(0) when rdAddr(rdAddr'left downto 10)="000" else
              bOut(1) when rdAddr(rdAddr'left downto 10)="001" else
              bOut(2) when rdAddr(rdAddr'left downto 10)="010" else
              bOut(3) when rdAddr(rdAddr'left downto 10)="011" else
              bOut(4) when rdAddr(rdAddr'left downto 10)="100" else
              bOut(5) when rdAddr(rdAddr'left downto 10)="101" else
              bOut(6) when rdAddr(rdAddr'left downto 10)="110" else
              bOut(7) when rdAddr(rdAddr'left downto 10)="111" else
              (others => '0');

    dbData <= aOut(0) when addr(addr'left downto 10)="000" else
              aOut(1) when addr(addr'left downto 10)="001" else
              aOut(2) when addr(addr'left downto 10)="010" else
              aOut(3) when addr(addr'left downto 10)="011" else
              aOut(4) when addr(addr'left downto 10)="100" else
              aOut(5) when addr(addr'left downto 10)="101" else
              aOut(6) when addr(addr'left downto 10)="110" else
              aOut(7) when addr(addr'left downto 10)="111" else
              (others => '0');

end;
