----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: receive_raw_data - Behavioral
-- Project Name: FPGA_Webserver
--
-- Description: The idea here is to receive the data from the PHY, then 
--              pass it out to an external dual-clocked FIFO.
--
--              This will minimise the size of the eth_rxck driven clocking domain
--
--              To allow for the rx and tx_clocks being asynchronous only the first
--              of the idle bytes will be written to the FIFO. Because the Ethernet
--              standard enforces 12 idle bytes following each 1512 bytes of data
--              the clock can be over 7200 parts per million (>900KHz) faster and we
--              still won't over-run the input FIFO running at the local 125MHz clock   
-- 
-- Dependencies: None 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity receive_raw_data is
    Port ( eth_rxck        : in  STD_LOGIC;
           eth_rxctl       : in  STD_LOGIC;
           eth_rxd         : in  STD_LOGIC_VECTOR (3 downto 0);
           rx_data_enable  : out STD_LOGIC                     := '1';
           rx_data         : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           rx_data_present : out STD_LOGIC                     := '0';
           rx_data_error   : out STD_LOGIC                     := '0');
end receive_raw_data;

architecture Behavioral of receive_raw_data is
    signal raw_ctl  : std_logic_vector(1 downto 0);
    signal raw_data : std_logic_vector(7 downto 0) := (others => '0');
    signal data_enable_last : std_logic := '0';
begin
ddr_rx_ctl : IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", INIT_Q1 => '0', INIT_Q2 => '0', SRTYPE => "SYNC")  
port map (Q1 => raw_ctl(0), Q2 => raw_ctl(1), C  => eth_rxck, CE => '1', D  => eth_rxctl, R  => '0', S  => '0');
ddr_rxd0 : IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", INIT_Q1 => '0', INIT_Q2 => '0', SRTYPE => "SYNC")  
port map (Q1 => raw_data(0), Q2 => raw_data(4), C  => eth_rxck, CE => '1', D  => eth_rxd(0), R  => '0', S  => '0');
ddr_rxd1 : IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", INIT_Q1 => '0', INIT_Q2 => '0', SRTYPE => "SYNC")  
port map (Q1 => raw_data(1), Q2 => raw_data(5), C  => eth_rxck, CE => '1', D  => eth_rxd(1), R  => '0', S  => '0');
ddr_rxd2 : IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", INIT_Q1 => '0', INIT_Q2 => '0', SRTYPE => "SYNC")  
port map (Q1 => raw_data(2), Q2 => raw_data(6), C  => eth_rxck, CE => '1', D  => eth_rxd(2), R  => '0', S  => '0');
ddr_rxd3 : IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", INIT_Q1 => '0', INIT_Q2 => '0', SRTYPE => "SYNC")  
port map (Q1 => raw_data(3), Q2 => raw_data(7), C  => eth_rxck, CE => '1', D  => eth_rxd(3), R  => '0', S  => '0');

process(eth_rxck) 
begin
    if rising_edge(eth_rxck) then        
        rx_data_enable   <= data_enable_last or raw_ctl(0);
        rx_data_present  <= raw_ctl(0);
        data_enable_last <= raw_ctl(0); 
        rx_data          <= raw_data;
        rx_data_error    <= raw_ctl(0) XOR raw_ctl(1);
    end if;
end process;

end Behavioral;
