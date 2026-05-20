-- Instantiation of RAMB18E1 primitive (18K-bit Configurable Synchronous Block RAM)
-- Dual Input/Output
-- 18-bit wide, 1k deep
-- Written by Enrico Picco, 2022

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library unisim;
    use unisim.vcomponents.all;


entity bramdio18x1k is
    port (
        clka        : in  std_logic;
        clkb        : in  std_logic;
        aWrEn       : in  std_logic;
        bWrEn       : in  std_logic;
        aAddr       : in  unsigned( 9 downto 0);
        bAddr       : in  unsigned( 9 downto 0);
        aIn         : in  signed(15 downto 0);
        bIn         : in  signed(15 downto 0);
        aOut        : out signed(15 downto 0);
        bOut        : out signed(15 downto 0)
    );
end entity;


architecture Behavioral of bramdio18x1k is
    signal aOut_slv : std_logic_vector(15 downto 0);
    signal bOut_slv : std_logic_vector(15 downto 0);
begin
    aOut <= signed(aOut_slv);
    bOut <= signed(bOut_slv);

    i_RAMB18E1 : RAMB18E1
    generic map (
        --INIT_00 => X"0f01_0f00_0e00_0d00_0c00_0b00_0a00_0900_0800_0700_0600_0500_0400_0300_3200_3100",
        -- all unspecified parameters are left with default values
        RAM_MODE        => "TDP",
        READ_WIDTH_A    => 18, -- resulting bus address is [13:4]
        READ_WIDTH_B    => 18,
        WRITE_WIDTH_A   => 18,
        WRITE_WIDTH_B   => 18
    )
    port map (
        DOADO           => aOut_slv, -- 18-bit A port data/LSB data output
        DOBDO           => bOut_slv, -- 18-bit B port data/MSB data output
        DOPADOP         => open, -- 2-bit A port parity/LSB parity output
        DOPBDOP         => open, -- 2-bit B port parity/MSB parity output
        ADDRARDADDR     => std_logic_vector(aAddr) & "0000", -- 14-bit A port address/Read address input
        ADDRBWRADDR     => std_logic_vector(bAddr) & "0000", -- 14-bit B port address/Write address input
        CLKARDCLK       => clka, -- 1-bit A port clock/Read clock input
        CLKBWRCLK       => clkb, -- 1-bit B port clock/Write clock input
        DIADI           => std_logic_vector(aIn), -- 32-bit A port data/LSB data input
        DIBDI           => std_logic_vector(bIn), -- 32-bit B port data/MSB data input
        DIPADIP         => "00", -- 2-bit A port parity/LSB parity input
        DIPBDIP         => "00", -- 2-bit B port parity/MSB parity input
        ENARDEN         => '1', -- 1-bit A port enable/Read enable input
        ENBWREN         => '1', -- 1-bit B port enable/Write enable input
        REGCEAREGCE     => '0', -- 1-bit A port register enable/Register enable input
        REGCEB          => '0', -- 1-bit B port register enable input
        RSTRAMARSTRAM   => '0', -- 1-bit A port set/reset input
        RSTRAMB         => '0', -- 1-bit B port set/reset input
        RSTREGARSTREG   => '0', -- 1-bit A port register set/reset input
        RSTREGB         => '0', -- 1-bit B port register set/reset input
        WEA             => aWrEn & aWrEn, -- 4-bit A port write enable input
        WEBWE           => bWrEn & bWrEn & "00" -- 8-bit B port write enable/Write enable input
    );

end architecture;
