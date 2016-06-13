----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net> 
-- 
-- Module Name: clocking - Behavioral
--
-- Description: Generate a 125MHz clock and 125MHz a clock with 90 degrees of 
--              phase shift.  
-- 
------------------------------------------------------------------------------------
-- FPGA_Webserver from https://github.com/hamsternz/FPGA_Webserver
------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field <hamster@snap.net.nz>
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity clocking is
    Port ( clk100MHz : in STD_LOGIC;
           clk125MHz : out STD_LOGIC;
           clk125MHz90 : out STD_LOGIC);
end clocking;

architecture Behavioral of clocking is
    signal clk100MHz_buffered     : std_logic := '0';
    signal clkfb                  : std_logic := '0';
    signal clk125MHz_unbuffered   : STD_LOGIC;
    signal clk125MHz90_unbuffered : STD_LOGIC;
begin
bufg_100: BUFG 
    port map (
        i => clk100MHz,
        o => clk100MHz_buffered
    );
   -------------------------------------------------------
   -- Generate a 125MHz clock from the 100MHz 
   -- system clock 
   ------------------------------------------------------- 
pll_clocking : PLLE2_BASE
   generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLKFBOUT_MULT      => 10,
      CLKFBOUT_PHASE     => 0.0,
      CLKIN1_PERIOD      => 10.0,

      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT0_DIVIDE     => 8,  CLKOUT1_DIVIDE     => 20, CLKOUT2_DIVIDE      => 40, 
      CLKOUT3_DIVIDE     => 8,  CLKOUT4_DIVIDE     => 16, CLKOUT5_DIVIDE      => 16,

      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      CLKOUT0_DUTY_CYCLE => 0.5, CLKOUT1_DUTY_CYCLE => 0.5, CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5, CLKOUT4_DUTY_CYCLE => 0.5, CLKOUT5_DUTY_CYCLE => 0.5,

      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE      =>    0.0, CLKOUT1_PHASE      => 0.0, CLKOUT2_PHASE      => 0.0,
      CLKOUT3_PHASE      => -270.0, CLKOUT4_PHASE      => 0.0, CLKOUT5_PHASE      => 0.0,

      DIVCLK_DIVIDE      => 1,
      REF_JITTER1        => 0.0,
      STARTUP_WAIT       => "FALSE"
   )
   port map (
      CLKIN1   => CLK100MHz_buffered,
      CLKOUT0  => CLK125MHz_unbuffered,   CLKOUT1 => open,  CLKOUT2 => open,  
      CLKOUT3  => CLK125MHz90_unbuffered, CLKOUT4 => open,  CLKOUT5 => open,
      LOCKED   => open,
      PWRDWN   => '0', 
      RST      => '0',
      CLKFBOUT => clkfb,
      CLKFBIN  => clkfb
   );

bufg_125Mhz: BUFG 
    port map (
        i => clk125MHz_unbuffered,
        o => clk125MHz
    );

bufg_125Mhz90: BUFG 
    port map (
        i => clk125MHz90_unbuffered,
        o => clk125MHz90
    );


end Behavioral;
