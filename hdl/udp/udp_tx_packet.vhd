----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Create Date: 05.06.2016 22:31:14
-- Module Name: udp_tx_packet - Behavioral
-- 
-- Dependencies: Contruct and send out UDP packets 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity udp_tx_packet is
    generic (
        our_ip      : std_logic_vector(31 downto 0) := (others => '0');
        our_mac     : std_logic_vector(47 downto 0) := (others => '0'));
    port(  clk               : in  STD_LOGIC;
        udp_tx_busy          : out std_logic := '0';
        udp_tx_valid         : in  std_logic;
        udp_tx_data          : in  std_logic_vector(7 downto 0);
        udp_tx_src_port      : in  std_logic_vector(15 downto 0);
        udp_tx_dst_mac       : in  std_logic_vector(47 downto 0);
        udp_tx_dst_ip        : in  std_logic_vector(31 downto 0);
        udp_tx_dst_port      : in  std_logic_vector(15 downto 0);

        packet_out_request : out std_logic := '0';
        packet_out_granted : in  std_logic := '0';
        packet_out_valid   : out std_logic := '0';         
        packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
end udp_tx_packet;

architecture Behavioral of udp_tx_packet is

    -- For holding the destination and port details on the first data transfer
    signal udp_tx_valid_last : STD_LOGIC := '0';
    signal tx_src_port       : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_dst_mac        : std_logic_vector(47 downto 0) := (others => '0');
    signal tx_dst_ip         : std_logic_vector(31 downto 0) := (others => '0');
    signal tx_dst_port       : std_logic_vector(15 downto 0) := (others => '0');

    signal udp_tx_length   : std_logic_vector(15 downto 0) := (others => '0');
    signal udp_tx_checksum : std_logic_vector(15 downto 0) := (others => '0');

    signal pre_udp_valid   : STD_LOGIC := '0';
    signal pre_udp_data    : STD_LOGIC_VECTOR (7 downto 0);

    component udp_tx_buffer_count_checksum_data is
    Port ( clk             : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC;
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
           data_length     : out std_logic_vector(15 downto 0);
           data_checksum   : out std_logic_vector(15 downto 0));           
    end component;
    signal data_length     : std_logic_vector(15 downto 0);
    signal data_checksum   : std_logic_vector(15 downto 0);           
    
    component udp_add_udp_header is
    Port ( clk             : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC;
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

           ip_src_ip       : in  STD_LOGIC_VECTOR (31 downto 0);
           ip_dst_ip       : in  STD_LOGIC_VECTOR (31 downto 0);           

           data_length     : in  std_logic_vector(15 downto 0);
           data_checksum   : in  std_logic_vector(15 downto 0);
           udp_src_port    : in  std_logic_vector(15 downto 0);
           udp_dst_port    : in  std_logic_vector(15 downto 0));
    end component;

    signal pre_ip_valid  : STD_LOGIC := '0';
    signal pre_ip_data   : STD_LOGIC_VECTOR (7 downto 0);
    signal ip_length     : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
    signal ip_checksum   : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');

    component udp_add_ip_header is
    Port ( clk                : in  STD_LOGIC;

           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC := '0';
           data_out           : out STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');

           udp_data_length    : in  STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_src_ip          : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dst_ip          : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0'));           
    end component;

    signal pre_header_valid  : STD_LOGIC := '0';
    signal pre_header_data   : STD_LOGIC_VECTOR (7 downto 0);

    component ethernet_add_header is
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC := '0';
           data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
         
           ether_type     : in STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 
           ether_dst_mac  : in STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
           ether_src_mac  : in STD_LOGIC_VECTOR (47 downto 0) := (others => '0'));
    end component;

    signal complete_valid    : STD_LOGIC  := '0';
    signal complete_data     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    
    component transport_commit_buffer
    Port ( clk                : in  STD_LOGIC;
           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           packet_out_request : out std_logic := '0';
           packet_out_granted : in  std_logic := '0';
           packet_out_valid   : out std_logic := '0';         
           packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
    end component;

begin

process(clk)
    begin
        if rising_edge(clk) then
            -- Capture the destination address data on the first cycle of the data packet 
            if udp_tx_valid = '1' and udp_tx_valid_last = '0' then 
                tx_src_port      <= udp_tx_src_port;
                tx_dst_mac       <= udp_tx_dst_mac;
                tx_dst_ip        <= udp_tx_dst_ip;
                tx_dst_port      <= udp_tx_dst_port;
            end if;
            udp_tx_valid_last <= udp_tx_valid;
        end if;
    end process;
i_udp_tx_buffer_count_checksum_data: udp_tx_buffer_count_checksum_data port map (
    clk            => clk,
    
    data_valid_in  => udp_tx_valid,
    data_in        => udp_tx_data,
    data_valid_out => pre_udp_valid,
    data_out       => pre_udp_data,
    
    data_length    => data_length,
    data_checksum  => data_checksum);    
    
i_udp_add_udp_header: udp_add_udp_header port map (
    clk             => clk,
    data_valid_in   => pre_udp_valid,
    data_in         => pre_udp_data,
    data_valid_out  => pre_ip_valid,
    data_out        => pre_ip_data,

    ip_src_ip       => our_ip,
    ip_dst_ip      => tx_dst_ip,           

    data_length     => data_length,
    data_checksum   => data_checksum,
    udp_src_port    => tx_src_port,
    udp_dst_port    => tx_dst_port);

i_udp_add_ip_header: udp_add_ip_header port map (
        clk             => clk,
        data_valid_in   => pre_ip_valid,
        data_in         => pre_ip_data,
        data_valid_out  => pre_header_valid,
        data_out        => pre_header_data,
    
        udp_data_length => data_length,
        ip_src_ip       => our_ip,
        ip_dst_ip      => tx_dst_ip);           

i_ethernet_add_header: ethernet_add_header port map (
        clk            => clk,
        data_valid_in  => pre_header_valid,
        data_in        => pre_header_data,
        data_valid_out => complete_valid,
        data_out       => complete_data,         
        ether_type     => x"0800",
        ether_dst_mac  => tx_dst_mac,
        ether_src_mac  => our_mac);

i_transport_commit_buffer: transport_commit_buffer port map (
        clk                => clk,
        data_valid_in      => complete_valid,
        data_in            => complete_data,
        packet_out_request => packet_out_request,
        packet_out_granted => packet_out_granted,
        packet_out_valid   => packet_out_valid,         
        packet_out_data    => packet_out_data);

end Behavioral;