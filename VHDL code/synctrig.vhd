library ieee;
    use ieee.std_logic_1164.all;

entity synctrig is
    port (
        clk1        : in  std_logic;
        clk2        : in  std_logic;
        trigInClk1  : in  std_logic;
        trigOutClk2 : out std_logic := '0';
        d_tog_clk1  : out std_logic;
        d_reg_clk2  : out std_logic_vector(2 downto 0)
    );
end entity;

architecture Behavioral of synctrig is
    signal tog1  : std_logic := '0';
begin

    d_tog_clk1 <= tog1;


    process (clk1)
    begin
        if rising_edge(clk1) then
            tog1 <= tog1 XOR trigInClk1;
        end if;
    end process;


    process (clk2)
        variable reg : std_logic_vector(2 downto 0) := "000";
    begin
        if rising_edge(clk2) then
            reg := reg(1 downto 0) & tog1;
            trigOutClk2 <= reg(2) XOR reg(1);
            d_reg_clk2  <= reg;
        end if;
    end process;

end;
