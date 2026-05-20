-- Written by Enrico Picco, 2022 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
    use work.types_pkg.all;
    use work.const_pkg.all;

entity xillydemo is
  port (
    PCIE_PERST_B_LS : IN std_logic;
    PCIE_REFCLK_N : IN std_logic;
    PCIE_REFCLK_P : IN std_logic;
    PCIE_RX_N : IN std_logic_vector(7 DOWNTO 0);
    PCIE_RX_P : IN std_logic_vector(7 DOWNTO 0);
    --GPIO_LED : OUT std_logic_vector(3 DOWNTO 0);
	GPIO_LED : OUT std_logic_vector(7 DOWNTO 0);
    PCIE_TX_N : OUT std_logic_vector(7 DOWNTO 0);
    PCIE_TX_P : OUT std_logic_vector(7 DOWNTO 0);
	
	--VC707 Resources
        CPU_RESET        : in    std_logic; -- CPU RST button, SW10
        SYSCLK_P         : in    std_logic;
        SYSCLK_N         : in    std_logic;
	
	--FMC151 i/o pins 
		--Clock/Data connection to ADC on FMC150 (ADS62P49)
        clk_ab_p         : in    std_logic;
        clk_ab_n         : in    std_logic;
        cha_p            : in    std_logic_vector(6 downto 0);
        cha_n            : in    std_logic_vector(6 downto 0);
        chb_p            : in    std_logic_vector(6 downto 0);
        chb_n            : in    std_logic_vector(6 downto 0);

        --Clock/Data connection to DAC on FMC150 (DAC3283)
        dac_dclk_p       : out   std_logic;
        dac_dclk_n       : out   std_logic;
        dac_data_p       : out   std_logic_vector(7 downto 0);
        dac_data_n       : out   std_logic_vector(7 downto 0);
        dac_frame_p      : out   std_logic;
        dac_frame_n      : out   std_logic;
        txenable         : out   std_logic;

        --Clock/Trigger connection to FMC150
        clk_to_fpga_p    : in    std_logic;
        clk_to_fpga_n    : in    std_logic;
        ext_trigger_p    : in    std_logic;
        ext_trigger_n    : in    std_logic;

        --Serial Peripheral Interface (SPI)
        spi_sclk         : out   std_logic; -- Shared SPI clock line
        spi_sdata        : out   std_logic; -- Shared SPI sata line

        -- ADC specific signals
        adc_n_en         : out   std_logic; -- SPI chip select
        adc_sdo          : in    std_logic; -- SPI data out
        adc_reset        : out   std_logic; -- SPI reset

        -- CDCE specific signals
        cdce_n_en        : out   std_logic; -- SPI chip select
        cdce_sdo         : in    std_logic; -- SPI data out
        cdce_n_reset     : out   std_logic;
        cdce_n_pd        : out   std_logic;
        ref_en           : out   std_logic;
        pll_status       : in    std_logic;

        -- DAC specific signals
        dac_n_en         : out   std_logic; -- SPI chip select
        dac_sdo          : in    std_logic; -- SPI data out

        -- Monitoring specific signals
        mon_n_en         : out   std_logic; -- SPI chip select
        mon_sdo          : in    std_logic; -- SPI data out
        mon_n_reset      : out   std_logic;
        mon_n_int        : in    std_logic;

        --FMC Present status
        prsnt_m2c_l      : in    std_logic;
	
	GPIO_DIP_SW      : in    std_logic_vector(7 downto 0)
	
     );
end xillydemo;

architecture sample_arch of xillydemo is
    
  component xillybus
    port (
      PCIE_PERST_B_LS : IN std_logic;
      PCIE_REFCLK_N : IN std_logic;
      PCIE_REFCLK_P : IN std_logic;
      PCIE_RX_N : IN std_logic_vector(7 DOWNTO 0);
      PCIE_RX_P : IN std_logic_vector(7 DOWNTO 0);
      GPIO_LED : OUT std_logic_vector(3 DOWNTO 0);
      PCIE_TX_N : OUT std_logic_vector(7 DOWNTO 0);
      PCIE_TX_P : OUT std_logic_vector(7 DOWNTO 0);
      bus_clk : OUT std_logic;
      quiesce : OUT std_logic;
      user_r_mem_8_rden : OUT std_logic;
      user_r_mem_8_empty : IN std_logic;
      user_r_mem_8_data : IN std_logic_vector(7 DOWNTO 0);
      user_r_mem_8_eof : IN std_logic;
      user_r_mem_8_open : OUT std_logic;
      user_w_mem_8_wren : OUT std_logic;
      user_w_mem_8_full : IN std_logic;
      user_w_mem_8_data : OUT std_logic_vector(7 DOWNTO 0);
      user_w_mem_8_open : OUT std_logic;
      user_mem_8_addr : OUT std_logic_vector(4 DOWNTO 0);
      user_mem_8_addr_update : OUT std_logic;
      user_r_read_32_rden : OUT std_logic;
      user_r_read_32_empty : IN std_logic;
      user_r_read_32_data : IN std_logic_vector(31 DOWNTO 0);
      user_r_read_32_eof : IN std_logic;
      user_r_read_32_open : OUT std_logic;
      user_r_read_8_rden : OUT std_logic;
      user_r_read_8_empty : IN std_logic;
      user_r_read_8_data : IN std_logic_vector(7 DOWNTO 0);
      user_r_read_8_eof : IN std_logic;
      user_r_read_8_open : OUT std_logic;
      user_w_write_32_wren : OUT std_logic;
      user_w_write_32_full : IN std_logic;
      user_w_write_32_data : OUT std_logic_vector(31 DOWNTO 0);
      user_w_write_32_open : OUT std_logic;
      user_w_write_8_wren : OUT std_logic;
      user_w_write_8_full : IN std_logic;
      user_w_write_8_data : OUT std_logic_vector(7 DOWNTO 0);
      user_w_write_8_open : OUT std_logic);
  end component;

  component fifo_8x2048
    port (
      clk: IN std_logic;
      srst: IN std_logic;
      din: IN std_logic_VECTOR(7 downto 0);
      wr_en: IN std_logic;
      rd_en: IN std_logic;
      dout: OUT std_logic_VECTOR(7 downto 0);
      full: OUT std_logic;
      empty: OUT std_logic);
  end component;

--  component fifo_32x512
--    port (
--      clk: IN std_logic;
--      srst: IN std_logic;
--      din: IN std_logic_VECTOR(31 downto 0);
--      wr_en: IN std_logic;
--      rd_en: IN std_logic;
--      dout: OUT std_logic_VECTOR(31 downto 0);
--      full: OUT std_logic;
--      empty: OUT std_logic);
--  end component;

  component PCIctrl
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
  end component;
  
  
  component sysclkwiz
  port(
        clk_in1_p  : in  std_logic;
        clk_in1_n  : in  std_logic;
        clk_100Mhz : out  std_logic;   -- BUFG
        clk_200Mhz : out  std_logic;   -- BUFG
        --clk_out3  => ethtxclk,      -- BUFG: 125 MHz
        clk_10MHz  : out  std_logic;     -- BUFG: 10 MHz for I2C
        reset      : in  std_logic;
        locked     : out  std_logic
   );
   end component;  
   
   component fmc151
   port (
        -- Clock from ML605 (sysclk)
        clk_100MHz      : in  std_logic;
        clk_200MHz      : in  std_logic;
        mmcm_locked     : in  std_logic;

        -- CPU Reset
        cpu_reset       : in  std_logic;
        
        --Clock/Data connection to ADC on FMC150 (ADS62P49)
        clk_ab_p         : in    std_logic;
        clk_ab_n         : in    std_logic;
        cha_p            : in    std_logic_vector(6 downto 0);
        cha_n            : in    std_logic_vector(6 downto 0);
        chb_p            : in    std_logic_vector(6 downto 0);
        chb_n            : in    std_logic_vector(6 downto 0);

        --Clock/Data connection to DAC on FMC150 (DAC3283)
        dac_dclk_p       : out   std_logic;
        dac_dclk_n       : out   std_logic;
        dac_data_p       : out   std_logic_vector(7 downto 0);
        dac_data_n       : out   std_logic_vector(7 downto 0);
        dac_frame_p      : out   std_logic;
        dac_frame_n      : out   std_logic;
        txenable         : out   std_logic;

        --Clock/Trigger connection to FMC150
        clk_to_fpga_p    : in    std_logic;
        clk_to_fpga_n    : in    std_logic;
        ext_trigger_p    : in    std_logic;
        ext_trigger_n    : in    std_logic;

        --Serial Peripheral Interface (SPI)
        spi_sclk         : out   std_logic; -- Shared SPI clock line
        spi_sdata        : out   std_logic; -- Shared SPI sata line

        -- ADC specific signals
        adc_n_en         : out   std_logic; -- SPI chip select
        adc_sdo          : in    std_logic; -- SPI data out
        adc_reset        : out   std_logic; -- SPI reset
        clk_adc          : out   std_logic;

        -- CDCE specific signals
        cdce_n_en        : out   std_logic; -- SPI chip select
        cdce_sdo         : in    std_logic; -- SPI data out
        cdce_n_reset     : out   std_logic;
        cdce_n_pd        : out   std_logic;
        ref_en           : out   std_logic;
        pll_status       : in    std_logic;

        -- DAC specific signals
        dac_n_en         : out   std_logic; -- SPI chip select
        dac_sdo          : in    std_logic; -- SPI data out

        -- Monitoring specific signals
        mon_n_en         : out   std_logic; -- SPI chip select
        mon_sdo          : in    std_logic; -- SPI data out
        mon_n_reset      : out   std_logic;
        mon_n_int        : in    std_logic;

        --FMC Present status
        prsnt_m2c_l      : in    std_logic;

        -- Actual data
        dac_din_i       : in  std_logic_vector(15 downto 0);
        dac_din_q       : in  std_logic_vector(15 downto 0);
        adc_dout_i      : out std_logic_vector(13 downto 0);
        adc_dout_q      : out std_logic_vector(13 downto 0);

        -- iDelay setup
        state           : in  stateType;
        setTarget       : in  targetType;
        inWord          : in  std_logic_vector(15 downto 0);
        inWordTrig      : in  std_logic;
        d_idelay        : out std_logic_vector(14 downto 0)
);
   end component;
   
   component synctrig
       port (
        clk1        : in  std_logic;
        clk2        : in  std_logic;
        trigInClk1  : in  std_logic;
        trigOutClk2 : out std_logic := '0';
        d_tog_clk1  : out std_logic;
        d_reg_clk2  : out std_logic_vector(2 downto 0)
    );
	end component;
	
   component statexdom 
    port (
        clk1            : in  std_logic;
        clk2            : in  std_logic;
        stateInClk1     : in  stateType;
        stateOutClk2    : out stateType
    );
  end component;
  
  --double clock fifo , IP core generated 
  component fifo32_doubleclock IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC
  );
  END component;
  
-- Synplicity black box declaration
  attribute syn_black_box : boolean;
  --attribute syn_black_box of fifo_32x512: component is true;
  attribute syn_black_box of fifo_8x2048: component is true;

  type demo_mem is array(0 TO 31) of std_logic_vector(7 DOWNTO 0);
  signal demoarray : demo_mem;
  
  signal bus_clk :  std_logic;
  signal quiesce : std_logic;

  signal reset_8 : std_logic;
  signal reset_32 : std_logic;

  signal ram_addr : integer range 0 to 31;
  
  signal user_r_mem_8_rden :  std_logic;
  signal user_r_mem_8_empty :  std_logic;
  signal user_r_mem_8_data :  std_logic_vector(7 DOWNTO 0);
  signal user_r_mem_8_eof :  std_logic;
  signal user_r_mem_8_open :  std_logic;
  signal user_w_mem_8_wren :  std_logic;
  signal user_w_mem_8_full :  std_logic;
  signal user_w_mem_8_data :  std_logic_vector(7 DOWNTO 0);
  signal user_w_mem_8_open :  std_logic;
  signal user_mem_8_addr :  std_logic_vector(4 DOWNTO 0);
  signal user_mem_8_addr_update :  std_logic;
  signal user_r_read_32_rden :  std_logic;
  signal user_r_read_32_empty :  std_logic;
  signal user_r_read_32_data :  std_logic_vector(31 DOWNTO 0);
  signal user_r_read_32_eof :  std_logic;
  signal user_r_read_32_open :  std_logic;
  signal user_r_read_8_rden :  std_logic;
  signal user_r_read_8_empty :  std_logic;
  signal user_r_read_8_data :  std_logic_vector(7 DOWNTO 0);
  signal user_r_read_8_eof :  std_logic;
  signal user_r_read_8_open :  std_logic;
  signal user_w_write_32_wren :  std_logic;
  signal user_w_write_32_full :  std_logic;
  signal user_w_write_32_data :  std_logic_vector(31 DOWNTO 0);
  signal user_w_write_32_open :  std_logic;
  signal user_w_write_8_wren :  std_logic;
  signal user_w_write_8_full :  std_logic;
  signal user_w_write_8_data :  std_logic_vector(7 DOWNTO 0);
  signal user_w_write_8_open :  std_logic;
  
  signal full_always_0 : std_logic;
  
  --sysclkwiz
  signal clk_200MHz            : std_logic;
  signal clk_100MHz            : std_logic;
  signal clk_10MHz             : std_logic;
  signal mmcm_locked           : std_logic;
  
  --fmc151
  signal clk_adc               : std_logic;
  signal expclk                : std_logic;
  signal adc_i, adc_q          : std_logic_vector(13 downto 0);
  signal dac_i, dac_q          : std_logic_vector(15 downto 0);
  signal dac_i_preinv          : std_logic_vector(15 downto 0);
  signal d_idelay              : std_logic_vector(14 downto 0);
  --fmc debug:
  --signal count: integer:=1;
  --signal tmp  : std_logic := '0';
  signal PCITrigOut_clk200MHz     : std_logic;

  --PCIctrl
  signal state_PCIclk          : stateType  := idle;
  signal setTarget             : targetType := none;
  signal PCIWordOut            : signed(15 downto 0);
  signal PCITrigOut_PCIclk     : std_logic;
  signal d_dvalid              : std_logic;
  
  --fpga2exp
  signal state_expclk          : stateType  := idle;
  signal PCITrigOut_expclk     : std_logic;
  signal addrPattern           : unsigned(12 downto 0);
  signal addrMask              : unsigned(9 downto 0);
  signal addrWeights           : unsigned(9 downto 0);
  signal d_wtsdly              : unsigned(6 downto 0);
  signal d_f2e_ndacamp         : unsigned(2 downto 0);
  signal d_linputs             : unsigned(12 downto 0);
  
  --bramS
  signal dbMsk                 : signed(15 downto 0);
  signal d_addrMsk             : unsigned(9 downto 0);
  signal dataMask              : signed(15 downto 0);
  --bramL
  signal dbPat                 : signed(15 downto 0);
  signal d_addrPat             : unsigned(12 downto 0);
  signal dataInputs            : signed(15 downto 0);
  
  
  --exp2fpga
  signal nrnavg1               : signed(15 downto 0);
  signal nrnavg2               : signed(15 downto 0);
  signal nrntrig1              : std_logic;
  signal nrntrig2              : std_logic;
    signal d_e2f_beat1           : std_logic;
    signal d_e2f_beat2           : std_logic;
    signal d_e2f_smpdly1         : signed(13 downto 0);
    signal d_e2f_smpdly2         : signed(13 downto 0);
	signal d_e2f_triglevel       : signed(13 downto 0);
    signal d_e2f_enbpacer        : std_logic;
    signal d_e2f_enbsmp1         : std_logic;
    signal d_e2f_enbsmp2         : std_logic;
	signal d_nrn1amplif          : unsigned(2 downto 0);
    signal d_nrn2amplif          : unsigned(2 downto 0);
    signal d_e2f_ndiscrbits      : unsigned(4 downto 0);
    signal d_e2f_sum1            : signed(19 downto 0);
    signal d_e2f_sum2            : signed(19 downto 0);
	
  signal rec_rcouts            : std_logic;
  signal rec_nrn1              : std_logic;
  signal rec_nrn2              : std_logic;
  signal recData               : signed(15 downto 0);
  signal recTrig               : std_logic;
  signal trig_rcout            : std_logic;
  signal trig_rcout_dly        : std_logic;
  signal trig_rcout_ddly       : std_logic;
  signal rcout                 : signed(15 downto 0);
  signal rcout_dly             : signed(15 downto 0);
  signal rcout_ddly            : signed(15 downto 0);
  signal fake_sw               : std_logic_vector(2 downto 0);
  signal d_rcout_sum           : signed(15 downto 0);

  --fpga2PCI
  signal from_fifo_full   : std_logic;
  signal to_fifo_data     : std_logic_vector(31 downto 0);
  signal to_fifo_wren     : std_logic;
  signal d_maxdata        : unsigned(25 downto 0);
  
     


    ATTRIBUTE MARK_DEBUG : STRING;
    -- ATTRIBUTE MARK_DEBUG OF state_PCIclk : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF setTarget : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF PCIWordOut : SIGNAL IS "true";
	-- ATTRIBUTE MARK_DEBUG OF PCITrigOut_PCIclk : SIGNAL IS "true";
    --ATTRIBUTE MARK_DEBUG OF PCITrigOut_clk200MHz : SIGNAL IS "true";
    --ATTRIBUTE MARK_DEBUG OF d_idelay : SIGNAL IS "true";
   -- ATTRIBUTE MARK_DEBUG OF user_w_write_32_data : SIGNAL IS "true";    
   -- ATTRIBUTE MARK_DEBUG OF user_w_write_32_wren : SIGNAL IS "true";
   --ATTRIBUTE MARK_DEBUG OF d_dvalid : SIGNAL IS "true";
	
	--ATTRIBUTE MARK_DEBUG OF state_expclk : SIGNAL IS "true";
    ATTRIBUTE MARK_DEBUG OF PCITrigOut_expclk : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF addrPattern : SIGNAL IS "true";
    --ATTRIBUTE MARK_DEBUG OF addrMask : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF addrWeights : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF d_f2e_ndacamp : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF d_linputs : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF d_wtsdly : SIGNAL IS "true";
	
	-- ATTRIBUTE MARK_DEBUG OF dbMsk : SIGNAL IS "true";
	-- ATTRIBUTE MARK_DEBUG OF d_addrMsk : SIGNAL IS "true";
	 --ATTRIBUTE MARK_DEBUG OF dataMask : SIGNAL IS "true";
	
    -- ATTRIBUTE MARK_DEBUG OF dbPat : SIGNAL IS "true";
	-- ATTRIBUTE MARK_DEBUG OF d_addrPat : SIGNAL IS "true";
	 --ATTRIBUTE MARK_DEBUG OF dataInputs : SIGNAL IS "true";
	
    -- ATTRIBUTE MARK_DEBUG OF dac_i : SIGNAL IS "true";
	 ATTRIBUTE MARK_DEBUG OF dac_i_preinv : SIGNAL IS "true";
    -- ATTRIBUTE MARK_DEBUG OF dac_data_p : SIGNAL IS "true";
    -- ATTRIBUTE MARK_DEBUG OF dac_data_n : SIGNAL IS "true";
	ATTRIBUTE MARK_DEBUG OF adc_i : SIGNAL IS "true";
	--ATTRIBUTE MARK_DEBUG OF adc_q : SIGNAL IS "true";
	
	--exp2fpga debug
      ATTRIBUTE MARK_DEBUG OF nrnavg1 : SIGNAL IS "true";
	  --ATTRIBUTE MARK_DEBUG OF nrnavg2 : SIGNAL IS "true";
      ATTRIBUTE MARK_DEBUG OF nrntrig1 : SIGNAL IS "true";
      --ATTRIBUTE MARK_DEBUG OF nrntrig2 : SIGNAL IS "true";
	 --ATTRIBUTE MARK_DEBUG OF d_e2f_smpdly1 : SIGNAL IS "true";
	 --ATTRIBUTE MARK_DEBUG OF d_e2f_smpdly2 : SIGNAL IS "true";
     --ATTRIBUTE MARK_DEBUG OF d_e2f_triglevel : SIGNAL IS "true";
     --ATTRIBUTE MARK_DEBUG OF d_e2f_enbpacer : SIGNAL IS "true";
	 --ATTRIBUTE MARK_DEBUG OF d_e2f_enbsmp1 : SIGNAL IS "true";
	 --ATTRIBUTE MARK_DEBUG OF d_e2f_enbsmp2 : SIGNAL IS "true";
     --ATTRIBUTE MARK_DEBUG OF d_nrn1amplif : SIGNAL IS "true";
     --ATTRIBUTE MARK_DEBUG OF d_nrn2amplif : SIGNAL IS "true";
	  --ATTRIBUTE MARK_DEBUG OF recData : SIGNAL IS "true";
      ATTRIBUTE MARK_DEBUG OF recTrig : SIGNAL IS "true";
	 --ATTRIBUTE MARK_DEBUG OF fake_sw : SIGNAL IS "true";
     -- ATTRIBUTE MARK_DEBUG OF rec_nrn1 : SIGNAL IS "true";
	 -- ATTRIBUTE MARK_DEBUG OF rec_nrn2 : SIGNAL IS "true";
     -- ATTRIBUTE MARK_DEBUG OF rec_rcouts : SIGNAL IS "true";
	  -- ATTRIBUTE MARK_DEBUG OF rcout_ddly : SIGNAL IS "true";
	  
	  --fpgatoPCI debug
	  -- ATTRIBUTE MARK_DEBUG OF from_fifo_full : SIGNAL IS "true";
	  -- ATTRIBUTE MARK_DEBUG OF reset_32 : SIGNAL IS "true";
      -- ATTRIBUTE MARK_DEBUG OF to_fifo_data : SIGNAL IS "true";
	  -- ATTRIBUTE MARK_DEBUG OF to_fifo_wren : SIGNAL IS "true";
       --ATTRIBUTE MARK_DEBUG OF d_maxdata : SIGNAL IS "true";
	  -- ATTRIBUTE MARK_DEBUG OF user_r_read_32_rden : SIGNAL IS "true";
	  -- ATTRIBUTE MARK_DEBUG OF user_r_read_32_data : SIGNAL IS "true";
	  -- ATTRIBUTE MARK_DEBUG OF user_r_read_32_empty : SIGNAL IS "true";
	  -- ATTRIBUTE MARK_DEBUG OF user_r_read_32_open : SIGNAL IS "true";

	  
begin
  xillybus_ins : xillybus
    port map (
      -- Ports related to /dev/xillybus_mem_8
      -- FPGA to CPU signals:
      user_r_mem_8_rden => user_r_mem_8_rden,
      user_r_mem_8_empty => user_r_mem_8_empty,
      user_r_mem_8_data => user_r_mem_8_data,
      user_r_mem_8_eof => user_r_mem_8_eof,
      user_r_mem_8_open => user_r_mem_8_open,
      -- CPU to FPGA signals:
      user_w_mem_8_wren => user_w_mem_8_wren,
      user_w_mem_8_full => user_w_mem_8_full,
      user_w_mem_8_data => user_w_mem_8_data,
      user_w_mem_8_open => user_w_mem_8_open,
      -- Address signals:
      user_mem_8_addr => user_mem_8_addr,
      user_mem_8_addr_update => user_mem_8_addr_update,

      -- Ports related to /dev/xillybus_read_32
      -- FPGA to CPU signals:
      user_r_read_32_rden => user_r_read_32_rden,
      user_r_read_32_empty => user_r_read_32_empty,
      user_r_read_32_data => user_r_read_32_data,
      user_r_read_32_eof => user_r_read_32_eof,
      user_r_read_32_open => user_r_read_32_open,

      -- Ports related to /dev/xillybus_read_8
      -- FPGA to CPU signals:
      user_r_read_8_rden => user_r_read_8_rden,
      user_r_read_8_empty => user_r_read_8_empty,
      user_r_read_8_data => user_r_read_8_data,
      user_r_read_8_eof => user_r_read_8_eof,
      user_r_read_8_open => user_r_read_8_open,

      -- Ports related to /dev/xillybus_write_32
      -- CPU to FPGA signals:
      user_w_write_32_wren => user_w_write_32_wren,
      user_w_write_32_full => full_always_0,
      user_w_write_32_data => user_w_write_32_data,
      user_w_write_32_open => open,

      -- Ports related to /dev/xillybus_write_8
      -- CPU to FPGA signals:
      user_w_write_8_wren => user_w_write_8_wren,
      user_w_write_8_full => user_w_write_8_full,
      user_w_write_8_data => user_w_write_8_data,
      user_w_write_8_open => user_w_write_8_open,

      -- General signals
      PCIE_PERST_B_LS => PCIE_PERST_B_LS,
      PCIE_REFCLK_N => PCIE_REFCLK_N,
      PCIE_REFCLK_P => PCIE_REFCLK_P,
      PCIE_RX_N => PCIE_RX_N,
      PCIE_RX_P => PCIE_RX_P,
	  --GPIO_LED => GPIO_LED,
      GPIO_LED => GPIO_LED(3 downto 0),
      PCIE_TX_N => PCIE_TX_N,
      PCIE_TX_P => PCIE_TX_P,
      bus_clk => bus_clk,
      quiesce => quiesce
      );

--  A simple inferred RAM

  ram_addr <= conv_integer(user_mem_8_addr);
  
  process (bus_clk)
  begin
    if (bus_clk'event and bus_clk = '1') then
      if (user_w_mem_8_wren = '1') then 
        demoarray(ram_addr) <= user_w_mem_8_data;
      end if;
      if (user_r_mem_8_rden = '1') then
        user_r_mem_8_data <= demoarray(ram_addr);
      end if;
    end if;
  end process;

  user_r_mem_8_empty <= '0';
  user_r_mem_8_eof <= '0';
  user_w_mem_8_full <= '0';

-- PCIctrl
  my_PCIcontroller : PCIctrl
    port map(
        clk         => bus_clk, -- PCI clock
        PCI_data    => user_w_write_32_data(15 downto 0),
        PCI_wren    => user_w_write_32_wren,
        state       => state_PCIclk,
        setTarget   => setTarget,
        wordOut     => PCIWordOut,
        trigOut     => PCITrigOut_PCIclk,
        --d_rxword    => open,
	    d_dvalid    => d_dvalid,
        full        => full_always_0
    );

 
  my_sysclkwiz : sysclkwiz
    port map(
        clk_in1_p  => sysclk_p,
        clk_in1_n   => sysclk_n,
        clk_100Mhz  => clk_100Mhz,    -- BUFG
        clk_200Mhz  => clk_200Mhz,    -- BUFG
        --clk_out3  => ethtxclk,      -- BUFG: 125 MHz
        clk_10MHz   => clk_10MHz,     -- BUFG: 10 MHz for I2C
        reset       => cpu_reset,
        locked      => mmcm_locked
    );
	
   my_fmc151 : fmc151
    port map (
        clk_100MHz      => clk_100MHz,
        clk_200MHz      => clk_200MHz,
        mmcm_locked     => mmcm_locked,
        cpu_reset       => cpu_reset,
        clk_ab_p        => clk_ab_p,
        clk_ab_n        => clk_ab_n,     
        cha_p           => cha_p,        
        cha_n           => cha_n,        
        chb_p           => chb_p,        
        chb_n           => chb_n,        
        dac_dclk_p      => dac_dclk_p,   
        dac_dclk_n      => dac_dclk_n,   
        dac_data_p      => dac_data_p,   
        dac_data_n      => dac_data_n,   
        dac_frame_p     => dac_frame_p,  
        dac_frame_n     => dac_frame_n,  
        txenable        => txenable,     
        clk_to_fpga_p   => clk_to_fpga_p,
        clk_to_fpga_n   => clk_to_fpga_n,
        ext_trigger_p   => ext_trigger_p,
        ext_trigger_n   => ext_trigger_n,
        spi_sclk        => spi_sclk,     
        spi_sdata       => spi_sdata,    
        adc_n_en        => adc_n_en,     
        adc_sdo         => adc_sdo,      
        adc_reset       => adc_reset,    
        clk_adc         => clk_adc,
        cdce_n_en       => cdce_n_en,    
        cdce_sdo        => cdce_sdo,     
        cdce_n_reset    => cdce_n_reset,  
        cdce_n_pd       => cdce_n_pd,    
        ref_en          => ref_en,       
        pll_status      => pll_status,   
        dac_n_en        => dac_n_en,     
        dac_sdo         => dac_sdo,      
        mon_n_en        => mon_n_en,      
        mon_sdo         => mon_sdo,
        mon_n_reset     => mon_n_reset,
        mon_n_int       => mon_n_int,
        prsnt_m2c_l     => prsnt_m2c_l,
        dac_din_i       => dac_i, -- inverted in hardware
        dac_din_q       => dac_q,
        adc_dout_i      => adc_i,
        adc_dout_q      => adc_q,
        state           => state_PCIclk,
        setTarget       => setTarget,
        inWord          => std_logic_vector(PCIWordOut),
        inWordTrig      => PCITrigOut_clk200MHz,
        d_idelay        => d_idelay
    );
    expclk <= clk_adc;
	gpio_led(6) <= clk_adc;
	--clock divider to debug expclk and see it slower at LED(6)
	--process(clk_adc)
	--begin
	--if (clk_adc'event and clk_adc='1') then
	  --count <=count+1;
	  --if (count = 100000000) then
        --tmp <= NOT tmp;
        --count <= 1;
	  --end if;
	 --end if;
	--gpio_led(6) <= tmp;
	--end process;
	
	
	syncPCITrigOut2 : synctrig
    port map (
        clk1        => bus_clk,
        clk2        => clk_200MHz,
        trigInClk1  => PCITrigOut_PCIclk,
        trigOutClk2 => PCITrigOut_clk200MHz
    );
	
	
	fpga2exp : entity work.fpga2exp
    port map (
	    clk         => expclk,
        state       => state_expclk,
        setTarget   => setTarget,
        mode_cont   => GPIO_DIP_SW(4),
        inWord      => PCIWordOut,
        inWordTrig  => PCITrigOut_expclk,
        dataInputs  => dataInputs, --dataInputs,
        dataMask    => dataMask,        --dataMask,
        dataWeights => (others => '0'), --dataWeights,
        addrPattern => addrPattern,
        addrMask    => addrMask,
        addrWeights => addrWeights,
        toDAC1      => dac_i_preinv,
        toDAC2      => open,
        d_linputs   => d_linputs,
        d_beatInp   => open, --d_f2e_beatInp,
        d_ndacamp   => d_f2e_ndacamp,
        d_wtsdly    => d_wtsdly
	 );
	 
	 dac_i <= not dac_i_preinv;


    syncPCITrigOut : synctrig
    port map (
        clk1        => bus_clk,
        clk2        => expclk,
        trigInClk1  => PCITrigOut_PCIclk,
        trigOutClk2 => PCITrigOut_expclk
    );

	statexdom1 : statexdom
    port map (
        clk1                    => bus_clk,
        clk2                    => expclk,
        stateInClk1             => state_PCIclk,
        stateOutClk2            => state_expclk
    );
        
		
		
    bramMsk : entity work.bramS -- 16b x 1k
    generic map (
        wrState     => setup,
        target      => mask
    )
    port map (
        clkwr       => bus_clk,
        clkrd       => expclk,
        state       => state_PCIclk,
        setTarget   => setTarget,
        wrTrig      => PCITrigOut_PCIclk,
        wrData      => PCIWordOut,
        rdAddr      => addrMask,
        --
        dbData      => dbMsk,       -- @ clkwr
        rdData      => dataMask,    -- @ clkrd
        d_addr      => d_addrMsk    -- @ clkwr
    );
	
	
	--bramPat : entity work.bramS -- 16b x 1k
    bramInp : entity work.bramL -- 16b x 8k
    generic map (
        wrState     => setup,
        target      => inputs 
    )
    port map (
        clkwr       => bus_clk,
        clkrd       => expclk,
        state       => state_PCIclk,
        setTarget   => setTarget,
        wrTrig      => PCITrigOut_PCIclk,
        wrData      => PCIWordOut,
        rdAddr      => addrPattern,
        --
        dbData      => dbPat,       -- @ clkwr
        rdData      => dataInputs,  -- @ clkrd
        d_addr      => d_addrPat    -- @ clkwr
    );
	
	exp2fpga : entity work.exp2fpga
    port map (
        clk             => expclk,
        state           => state_expclk,
        setTarget       => setTarget,
        inWord          => PCIWordOut,
        inWordTrig      => PCITrigOut_expclk,
        --fromADC1        => signed(adc_i(15 downto 2)),
        --fromADC2        => signed(adc_q(15 downto 2)),
        fromADC1        => signed(adc_i),
        fromADC2        => signed(adc_q),
        avgout1         => nrnavg1,
        avgout2         => nrnavg2,
        trigout1        => nrntrig1, -- @ expclk
        trigout2        => nrntrig2, -- @ expclk
        d_beat1         => d_e2f_beat1,
        d_beat2         => d_e2f_beat2,
        d_smpdly1       => d_e2f_smpdly1,
        d_smpdly2       => d_e2f_smpdly2,
        d_triglevel     => d_e2f_triglevel,
        d_enbpacer      => d_e2f_enbpacer,
        d_enbsmp1       => d_e2f_enbsmp1,
        d_enbsmp2       => d_e2f_enbsmp2,
        --d_adcofst       => open,
        d_nrn1amplif    => d_nrn1amplif,
        d_nrn2amplif    => d_nrn2amplif,
        d_ndiscrbits    => d_e2f_ndiscrbits,
        d_sum1          => d_e2f_sum1,
        d_sum2          => d_e2f_sum2
    );
	
	fpga2PCI : entity work.fpga2PCI
    port map(
	    clk              => expclk,
		state            => state_expclk,
        setTarget        => setTarget,
        inWord           => PCIWordOut,
        inWordTrig       => PCITrigOut_expclk,
		recData          => recData,
		recTrig          => recTrig,
		from_fifo_full   => from_fifo_full,
		to_fifo_data     => to_fifo_data,
		to_fifo_wren     => to_fifo_wren,
		d_maxdata        => d_maxdata
    );

	
	myfifo32 : fifo32_doubleclock
    port map(
    rst       => reset_32,
    wr_clk    => expclk,
    rd_clk    => bus_clk,
    din       => to_fifo_data,
    wr_en     => to_fifo_wren,
    rd_en     => user_r_read_32_rden,
    dout      => user_r_read_32_data,
    full      => from_fifo_full,
    empty     => user_r_read_32_empty
    --wr_rst_busy : OUT STD_LOGIC;
    --rd_rst_busy : OUT STD_LOGIC
    );
	
	reset_32 <= not user_r_read_32_open;
  
	rec_signals : process (expclk)
    begin
        if rising_edge(expclk) then
            --if nrntrig1='1' AND (gpio_dip_sw(2)='0' OR gpio_dip_sw(3)='1') then
            if nrntrig1='1' AND rec_nrn1='1' then
                recData <= nrnavg1;
                recTrig <= '1';
            --elsif nrntrig2='1' AND (gpio_dip_sw(2)='1' OR gpio_dip_sw(3)='1') then
            elsif nrntrig2='1' AND rec_nrn2='1' then
                recData <= nrnavg2;
                recTrig <= '1';
            --elsif trig_rcout='1' AND gpio_dip_sw(1)='1' then
            elsif trig_rcout_ddly='1' AND rec_rcouts='1' then
                --recData <= (others => '0'); --rcout;
                recData <= rcout_ddly;
                recTrig <= '1';
            else
                recData <= (others => '0');
                recTrig <= '0';
            end if;
        end if;
    end process;

    -- IMPLEMENTING "SWITCHES" ON MATLAB
	set_rec : process (expclk)
    begin
        if rising_edge(expclk) then
            if state_expclk=setup AND setTarget=rec_select AND PCITrigOut_expclk='1' then
                fake_sw <= std_logic_vector(PCIWordOut(2 downto 0));
            end if;
        end if;
    end process;


    --- Selector for recorded data (clocked hardware switches) ---
    switch_records : process(expclk) 
    begin
        if rising_edge(expclk) then
            rec_rcouts <= fake_sw(0);
            rec_nrn1   <= not fake_sw(1) OR fake_sw(2);
            rec_nrn2   <= fake_sw(1) OR fake_sw(2);
        end if;
    end process;
    
    --- Sum modulated neurons (RC out) ---
    comp_rcout : process (expclk)
        variable cnt : integer range 0 to nNeurons-1;
        variable sum : signed(15 downto 0);
    begin
        if rising_edge(expclk) then
            if state_expclk=train OR state_expclk=test then
                if nrntrig2='1' then
                    if cnt=nNeurons-1 then
                        rcout       <= sum + nrnavg2;
                        trig_rcout  <= '1';
                        sum         := (others => '0');
                        cnt         := 0;
                    else
                        rcout       <= (others => '0');
                        trig_rcout  <= '0';
                        sum         := sum + nrnavg2;
                        cnt         := cnt + 1;
                    end if;
                else
                    rcout       <= (others => '0');
                    trig_rcout  <= '0';
                end if;
            else
                rcout       <= (others => '0');
                trig_rcout  <= '0';
                cnt         := 0;
                sum         := (others => '0');
            end if;
            d_rcout_sum     <= sum;
        end if;
    end process;
    --- --- ---


    --- Delay RC out by 2 expclk cycles ---
    delay_rcout : process (expclk)
    begin
        if rising_edge(expclk) then
            trig_rcout_ddly <= trig_rcout_dly;
            trig_rcout_dly  <= trig_rcout;
            rcout_ddly      <= rcout_dly;
            rcout_dly       <= rcout;
        end if;
    end process;
    --- --- ---
	
	
----  32-bit loopback

--  fifo_32 : fifo_32x512
--    port map(
--      clk        => bus_clk,
--      srst       => reset_32,
--      din        => user_w_write_32_data,
--      wr_en      => user_w_write_32_wren,
--      rd_en      => user_r_read_32_rden,
--      dout       => user_r_read_32_data,
--      full       => user_w_write_32_full,
--      empty      => user_r_read_32_empty
--      );

--  reset_32 <= not (user_w_write_32_open or user_r_read_32_open);

  user_r_read_32_eof <= '0';
  
--  8-bit loopback

  fifo_8 : fifo_8x2048
    port map(
      clk        => bus_clk,
      srst       => reset_8,
      din        => user_w_write_8_data,
      wr_en      => user_w_write_8_wren,
      rd_en      => user_r_read_8_rden,
      dout       => user_r_read_8_data,
      full       => user_w_write_8_full,
      empty      => user_r_read_8_empty
      );

    reset_8 <= not (user_w_write_8_open or user_r_read_8_open);

    user_r_read_8_eof <= '0';
  
end sample_arch;
