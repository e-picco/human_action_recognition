-- Constants package (v1.0)
-- Written by P. Antonik, 2015
-- For Michiel's BPT project
-- Modified by Enrico Picco, 2022

library IEEE;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package const_pkg is

    constant nNeurons   : integer := 200; --120; --600; --100; --50;
    constant nSamples   : integer := 8; --80; --16; --32;
    constant eAvg       : integer := 4; --4; --3;
    constant nLSkip     : integer := 2; --32; --4;
    constant nRSkip     : integer := 2; --32; --4;
    constant eAvgOfst   : integer := 8; --compute mean dc offset over 2^# samples

    constant nBRAMs     : integer := 8;
    constant lAddr      : integer := 13;

end const_pkg;
