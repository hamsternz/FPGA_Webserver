----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.05.2016 15:45:24
-- Design Name: 
-- Module Name: fifo_rxclk_to_clk125MHz - Behavioral
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

entity fifo_rxclk_to_clk125MHz is
    Port ( rx_clk          : in  STD_LOGIC;
           rx_write        : in  STD_LOGIC                     := '1';           
           rx_data         : in  STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           rx_data_present : in  STD_LOGIC                     := '0';
           rx_data_error   : in  STD_LOGIC                     := '0';
           
           clk125Mhz       : in  STD_LOGIC;
           empty           : out STD_LOGIC                     := '1';           
           read            : in  STD_LOGIC                     := '1';           
           data            : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           data_present    : out STD_LOGIC                     := '0';
           data_error      : out STD_LOGIC                     := '0');
end fifo_rxclk_to_clk125MHz;

architecture Behavioral of fifo_rxclk_to_clk125MHz is
    COMPONENT fifo_dual_clock_10_bits_16_deep
    PORT (
        wr_clk : IN STD_LOGIC;
        full   : OUT STD_LOGIC;
        wr_en  : IN STD_LOGIC;
        din    : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        
        rd_clk : IN STD_LOGIC;
        rd_en  : IN STD_LOGIC;
        dout   : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        empty  : OUT STD_LOGIC);
    END COMPONENT;
begin

i_fifo_dual_clock_10_bits_16_deep : fifo_dual_clock_10_bits_16_deep PORT MAP (
        wr_clk          => rx_clk,
        wr_en           => rx_write,
        din(9)          => rx_data_present,
        din(8)          => rx_data_error,
        din(7 downto 0) => rx_data,
        full            => open,

        rd_clk           => clk125Mhz,
        empty            => empty,
        rd_en            => read,
        dout(9)          => data_present,
        dout(8)          => data_error,
        dout(7 downto 0) => data);

end Behavioral;
