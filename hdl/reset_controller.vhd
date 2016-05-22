----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Description: Control the timing of reset signals 
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
use IEEE.NUMERIC_STD.ALL;

entity reset_controller is
    Port ( clk125mhz : in STD_LOGIC;
           phy_ready : out STD_LOGIC;
           eth_rst_b : out STD_LOGIC);
end reset_controller;

architecture Behavioral of reset_controller is
    signal reset_counter : unsigned(24 downto 0)     := (others => '0');
begin

control_reset: process(clk125MHz)
     begin
        if rising_edge(clk125MHz) then           
           if reset_counter(reset_counter'high) = '0' then
               reset_counter <= reset_counter + 1;
           end if; 
           eth_rst_b <= reset_counter(reset_counter'high) or reset_counter(reset_counter'high-1);
           phy_ready  <= reset_counter(reset_counter'high);
        end if;
     end process;

end Behavioral;
