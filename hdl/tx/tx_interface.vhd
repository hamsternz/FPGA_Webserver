----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.05.2016 06:52:24
-- Design Name: 
-- Module Name: tx_interface - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity tx_interface is
    Port ( clk125MHz   : in  STD_LOGIC;
           clk125Mhz90 : in  STD_LOGIC;
           --
           phy_ready   : in  STD_LOGIC;
           link_10mb   : in  STD_LOGIC;
           link_100mb  : in  STD_LOGIC;
           link_1000mb : in  STD_LOGIC;
           ---
           arp_request : in  STD_LOGIC;
           arp_granted : out STD_LOGIC;
           arp_valid   : in  STD_LOGIC;
           arp_data    : in  STD_LOGIC_VECTOR (7 downto 0);
           ---
           icmp_request : in  STD_LOGIC;
           icmp_granted : out STD_LOGIC;
           icmp_valid   : in  STD_LOGIC;
           icmp_data    : in  STD_LOGIC_VECTOR (7 downto 0);
           ---
           udp_request : in  STD_LOGIC;
           udp_granted : out STD_LOGIC;
           udp_valid   : in  STD_LOGIC;
           udp_data    : in  STD_LOGIC_VECTOR (7 downto 0);
           ---
           eth_txck    : out STD_LOGIC;
           eth_txctl   : out STD_LOGIC;
           eth_txd     : out STD_LOGIC_VECTOR (3 downto 0));
end tx_interface;

architecture Behavioral of tx_interface is
    component tx_arbiter is
	generic (
		idle_time : std_logic_vector(5 downto 0));
    Port ( clk 	             : in  STD_LOGIC;
           ready             : in  STD_LOGIC;

           ch0_request       : in  STD_LOGIC;
		   ch0_granted       : out STD_LOGIC;
           ch0_valid         : in  STD_LOGIC;
           ch0_data          : in  STD_LOGIC_VECTOR (7 downto 0);

           ch1_request       : in  STD_LOGIC;
           ch1_granted       : out STD_LOGIC;
           ch1_valid         : in  STD_LOGIC;
           ch1_data          : in  STD_LOGIC_VECTOR (7 downto 0);

           ch2_request       : in  STD_LOGIC;
           ch2_granted       : out STD_LOGIC;
           ch2_valid         : in  STD_LOGIC;
           ch2_data          : in  STD_LOGIC_VECTOR (7 downto 0);

           merged_data_valid : out STD_LOGIC;
           merged_data       : out STD_LOGIC_VECTOR (7 downto 0));
    end component;
    
    component tx_add_crc32 is
    Port ( clk             : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC                     := '0';
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC                     := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0'));
    end component;

    component tx_add_preamble is
    Port ( clk             : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC;
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC                     := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0'));
    end component;

    signal merged_data_valid  : STD_LOGIC;
    signal merged_data        : STD_LOGIC_VECTOR (7 downto 0);

    signal with_crc_data_valid  : STD_LOGIC;
    signal with_crc_data        : STD_LOGIC_VECTOR (7 downto 0);
    
    signal framed_data_valid  : STD_LOGIC;
    signal framed_data        : STD_LOGIC_VECTOR (7 downto 0);

    signal data        : STD_LOGIC_VECTOR (7 downto 0);
    signal data_valid  : STD_LOGIC;
    signal data_enable : STD_LOGIC;
    signal data_error  : STD_LOGIC;

    -------------------------------------------
    -- Debugging
    -------------------------------------------    
    COMPONENT ila_0
    PORT (
        clk    : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
    END COMPONENT ;

    component tx_rgmii is
    Port ( clk         : in STD_LOGIC;
           clk90       : in STD_LOGIC;
           phy_ready   : in STD_LOGIC;

           data_valid  : in STD_LOGIC;
           data        : in STD_LOGIC_VECTOR (7 downto 0);
           data_error  : in STD_LOGIC;
           data_enable : in STD_LOGIC := '1';
           
           eth_txck    : out STD_LOGIC;
           eth_txctl   : out STD_LOGIC;
           eth_txd     : out STD_LOGIC_VECTOR (3 downto 0));
    end component ;
begin
i_tx_arbiter: tx_arbiter generic map(idle_time => "111111") Port map (
    clk => clk125MHz,
    ------------------------------
    ready             => phy_ready,
    
    ch0_request       => arp_request,
    ch0_granted       => arp_granted,
    ch0_data          => arp_data,
    ch0_valid         => arp_valid,
    
    ch1_request       => icmp_request,
    ch1_granted       => icmp_granted,
    ch1_data          => icmp_data,
    ch1_valid         => icmp_valid,
    
    ch2_request       => udp_request,
    ch2_granted       => udp_granted,
    ch2_data          => udp_data,
    ch2_valid         => udp_valid,
    
    merged_data_valid => merged_data_valid,
    merged_data       => merged_data);

--i_ila_0: ila_0 port map (
--    clk       => clk125Mhz,
--    probe0(0) => merged_data_valid, 
--    probe1(0) => merged_data_valid, 
--    probe2    => merged_data,
--    probe3(0) => merged_data_valid);

i_tx_add_crc32: tx_add_crc32 port map (
    clk              => clk125MHz,
    data_valid_in    => merged_data_valid,
    data_in          => merged_data,
    data_valid_out   => with_crc_data_valid,
    data_out         => with_crc_data);

i_tx_add_preamble: tx_add_preamble port map (
    clk             => clk125MHz,
    data_valid_in   => with_crc_data_valid,
    data_in         => with_crc_data,
    data_valid_out  => framed_data_valid,
    data_out        => framed_data);
----------------------------------------------------------------------
-- A FIFO needs to go here to slow down data for the 10/100 operation.
--
-- Plan is for a 4K FIFO, with an almost full at about 2500. That will
-- Allow space for a full packet and at least 50 cycles for latency 
-- within the feedback loop.
----------------------------------------------------------------------
-- A module need to go here to adapt the output of the FIFO to the
-- slowere speeds
--
-- link_10mb   : in  STD_LOGIC;
-- link_100mb  : in  STD_LOGIC;
-- link_1000mb : in  STD_LOGIC;
----------------------------------------------------------------------

i_tx_rgmii: tx_rgmii port map (
    clk         => clk125MHz,
    clk90       => clk125MHz90,
    phy_ready   => phy_ready,

    data_valid  => framed_data_valid,
    data        => framed_data,
    data_error  => '0',
    data_enable => '1',

    eth_txck  => eth_txck,
    eth_txctl => eth_txctl,
    eth_txd   => eth_txd);

end Behavioral;
