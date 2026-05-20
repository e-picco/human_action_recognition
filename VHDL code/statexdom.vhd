library ieee;
    use ieee.std_logic_1164.all;
library work;
    use work.types_pkg.stateType;

entity statexdom is
    port (
        clk1            : in  std_logic;
        clk2            : in  std_logic;
        stateInClk1     : in  stateType;
        stateOutClk2    : out stateType
    );
end entity;

architecture Behavioral of statexdom is
    signal trigStateClk1    : std_logic := '0';
    signal trigStateClk2    : std_logic := '0';
    signal tog1             : std_logic := '0';
begin

    detector1 : process (clk1)
        variable prevstate : stateType := idle;
    begin
        if rising_edge(clk1) then
            if stateInClk1/=prevstate then
                trigStateClk1 <= '1';
            else
                trigStateClk1 <= '0';
            end if;
            prevstate := stateInClk1;
        end if;
    end process;


    process (clk1)
    begin
        if rising_edge(clk1) then
            tog1 <= tog1 XOR trigStateClk1;
        end if;
    end process;


    process (clk2)
        variable reg : std_logic_vector(2 downto 0) := "000";
    begin
        if rising_edge(clk2) then
            reg := reg(1 downto 0) & tog1;
            trigStateClk2 <= reg(2) XOR reg(1);
        end if;
    end process;


    detector2 : process (clk2)
    begin
        if rising_edge(clk2) then
            if trigStateClk2='1' then
                stateOutClk2 <= stateInClk1;
            end if;
        end if;
    end process;

end;
