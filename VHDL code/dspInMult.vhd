-- Project: PatGen
-- DSP module, computes the input signal to experiment (symbol * mask)
-- Written by P. Antonik, 2015
-- Modified by Enrico Picco, 2022


library IEEE;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library unisim;
    use unisim.vcomponents.all;


entity dspInMult is
    port (
        clk         : in  std_logic;
        input       : in  signed(15 downto 0);
        mask        : in  signed(15 downto 0);
        mskdInp     : out std_logic_vector(15 downto 0)
    );
end dspInMult;


architecture Behavioral of dspInMult is
    signal p : std_logic_vector(47 downto 0);
    signal a : std_logic_vector(29 downto 0);
    signal b : std_logic_vector(17 downto 0);
begin
 
    a <= (29 downto 16 => input(15)) & std_logic_vector(input);
    b <= (17 downto 16 => mask(15)) & std_logic_vector(mask);
    mskdInp <= p(30 downto 15);

    -- Stage 1/1 ---------------------------------------------------------------
    i1_dsp48e1 : DSP48E1 -- input * mask -> mskdInp : A * B = P
    generic map (
        -- Feature Control Attributes: Data Path Selection
        A_INPUT => "DIRECT", -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
        B_INPUT => "DIRECT", -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
        USE_DPORT => FALSE, -- Select D port usage (TRUE or FALSE)
        USE_MULT => "MULTIPLY", -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")

        -- Pattern Detector Attributes: Pattern Detection Configuration
        AUTORESET_PATDET => "NO_RESET", -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
        MASK => X"3fffffffffff", -- 48-bit mask value for pattern detect (1=ignore)
        PATTERN => X"000000000000", -- 48-bit pattern match for pattern detect
        SEL_MASK => "MASK", -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
        SEL_PATTERN => "PATTERN", -- Select pattern value ("PATTERN" or "C")
        USE_PATTERN_DETECT => "NO_PATDET", -- Enable pattern detect ("PATDET" or "NO_PATDET")

        -- Register Control Attributes: Pipeline Register Configuration
        ACASCREG => 0, -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
        ADREG => 0, -- Number of pipeline stages for pre-adder (0 or 1)
        ALUMODEREG => 0, -- Number of pipeline stages for ALUMODE (0 or 1)
        AREG => 0, -- Number of pipeline stages for A (0, 1 or 2)
        BCASCREG => 0, -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
        BREG => 0, -- Number of pipeline stages for B (0, 1 or 2)
        CARRYINREG => 0, -- Number of pipeline stages for CARRYIN (0 or 1)
        CARRYINSELREG => 0, -- Number of pipeline stages for CARRYINSEL (0 or 1)
        CREG => 0, -- Number of pipeline stages for C (0 or 1)
        DREG => 0, -- Number of pipeline stages for D (0 or 1)
        INMODEREG => 0, -- Number of pipeline stages for INMODE (0 or 1)
        MREG => 0, -- Number of multiplier pipeline stages (0 or 1)
        OPMODEREG => 0, -- Number of pipeline stages for OPMODE (0 or 1)
        PREG => 0, -- Number of pipeline stages for P (0 or 1)
        USE_SIMD => "ONE48" -- SIMD selection ("ONE48", "TWO24", "FOUR12")
        )
    port map (
        -- Cascade: 30-bit (each) Cascade Ports
        ACOUT =>        open, -- 30-bit A port cascade output
        BCOUT =>        open, -- 18-bit B port cascade output
        CARRYCASCOUT => open, -- 1-bit Cascade carry output
        MULTSIGNOUT =>  open, -- 1-bit Multiplier sign cascade output
        PCOUT =>        open, -- 48-bit Cascade output

        -- Control: 1-bit (each) Control Inputs/Status Bits
        OVERFLOW =>       open, -- 1-bit Overflow in add/acc output
        PATTERNBDETECT => open, -- 1-bit Pattern bar detect output
        PATTERNDETECT =>  open, -- 1-bit Pattern detect output
        UNDERFLOW =>      open, -- 1-bit Underflow in add/acc output

        -- Data: 4-bit (each) Data Ports
        CARRYOUT => open, -- 4-bit Carry output
        P => p, -- 48-bit Primary data output

        -- Cascade: 30-bit (each) Cascade Ports
        ACIN => "000000000000000000000000000000", -- 30-bit A cascade data input
        BCIN => "000000000000000000", -- 18-bit B cascade input
        CARRYCASCIN => '0', -- 1-bit Cascade carry input
        MULTSIGNIN => '0', -- 1-bit Multiplier sign input
        PCIN => "000000000000000000000000000000000000000000000000", -- 48-bit P cascade input
        
        -- Control: 4-bit (each) Control Inputs/Status Bits
        ALUMODE => "0000", -- 4-bit ALU control input: X + Y + Z + CIN
        CARRYINSEL => "000", -- 3-bit Carry select input
        CEINMODE => '1', -- 1-bit Clock enable input for INMODEREG
        CLK => clk, -- 1-bit Clock input
        INMODE => "00000", -- 5-bit INMODE control input: A2 * B2
        OPMODE => "0000101", -- 7-bit Operation mode input: M + M + 0
        RSTINMODE => '0', -- 1-bit Reset input for INMODEREG
        
        -- Data: 30-bit (each) Data Ports
        A => a, -- 30-bit A data input
        B => b, -- 18-bit B data input
        C => "000000000000000000000000000000000000000000000000", -- 48-bit C data input
        CARRYIN => '0', -- 1-bit Carry input signal
        D => "0000000000000000000000000", -- 25-bit D data input
        
        -- Reset/Clock Enable: 1-bit (each) Reset/Clock Enable Inputs
        CEA1 =>          '0', -- 1-bit Clock enable input for 1st stage AREG 
        CEA2 =>          '0', -- 1-bit Clock enable input for 2nd stage AREG 
        CEAD =>          '0', -- 1-bit Clock enable input for ADREG
        CEALUMODE =>     '1', -- 1-bit Clock enable input for ALUMODERE
        CEB1 =>          '0', -- 1-bit Clock enable input for 1st stage BREG
        CEB2 =>          '0', -- 1-bit Clock enable input for 2nd stage BREG
        CEC =>           '0',  --'1', -- 1-bit Clock enable input for CREG
        CECARRYIN =>     '1', -- 1-bit Clock enable input for CARRYINREG
        CECTRL =>        '1', -- 1-bit Clock enable input for OPMODEREG and CARRYINSELREG
        CED =>           '1', -- 1-bit Clock enable input for DREG
        CEM =>           '0',  --'1', -- 1-bit Clock enable input for MREG
        CEP =>           '0',  --'1', -- 1-bit Clock enable input for PREG
        RSTA =>          '0', -- 1-bit Reset input for AREG
        RSTALLCARRYIN => '0', -- 1-bit Reset input for CARRYINREG
        RSTALUMODE =>    '0', -- 1-bit Reset input for ALUMODEREG
        RSTB =>          '0', -- 1-bit Reset input for BREG
        RSTC =>          '0', -- 1-bit Reset input for CREG
        RSTCTRL =>       '0', -- 1-bit Reset input for OPMODEREG and CARRYINSELREG
        RSTD =>          '0', -- 1-bit Reset input for DREG and ADREG
        RSTM =>          '0', -- 1-bit Reset input for MREG
        RSTP =>          '0'  -- 1-bit Reset input for PREG
    );

end Behavioral;
