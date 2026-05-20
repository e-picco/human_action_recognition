-- PatGen Project
-- Types package (v1.0)
-- todo ?? Custom bus types used to transfer wide data streams between different modules
-- Written by P. Antonik, 2015
-- Modified by Enrico Picco, 2022

library IEEE;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library work;
    use work.const_pkg.nSamples;

package types_pkg is

    type stateType      is (idle, setup, train, test, bramcheck);
    type targetType     is (none, inputs, mask, weights, idelay, smpdelay1, smpdelay2, linp, nsmp, maxfrm, nrn1ampf, nrn2ampf, trglvl, dacamp, adc1ofst, adc2ofst, dacofst, wtsdelay, n_warmup, rec_select, max_sampled_data);
    --type array_samples   is array (0 to nSamples-1) of signed(13 downto 0);
    
    --type array_mask      is array (0 to nNeurons-1) of signed(bShort-1 downto 0);
    --type array_neurons   is array (0 to nNeurons-1) of signed(bNeurons-1 downto 0);
    --type array_neuronspp is array (0 to nNeurons)   of signed(bNeurons-1 downto 0);
    --type array_weights   is array (0 to nNeurons)   of signed(nBits-1 downto 0);
    --type array_params    is array (0 to 8)          of signed(bShort-1 downto 0);

end package;
