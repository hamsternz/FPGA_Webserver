----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.05.2016 15:23:02
-- Design Name: 
-- Module Name: clocking - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity clocking is
    Port ( clk100MHz : in STD_LOGIC;
           clk125MHz : out STD_LOGIC;
           clk125MHz90 : out STD_LOGIC);
end clocking;

architecture Behavioral of clocking is
    signal clk100MHz_buffered : std_logic := '0';
    signal clkfb              : std_logic := '0';
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
clocking : PLLE2_BASE
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
      CLKOUT0 => CLK125MHz,   CLKOUT1 => open,  CLKOUT2 => open,  
      CLKOUT3 => CLK125MHz90, CLKOUT4 => open,  CLKOUT5 => open,
      LOCKED   => open,
      PWRDWN   => '0', 
      RST      => '0',
      CLKFBOUT => clkfb,
      CLKFBIN  => clkfb
   );


end Behavioral;
