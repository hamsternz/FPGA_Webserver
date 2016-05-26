----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.05.2016 22:29:27
-- Design Name: 
-- Module Name: icmp_handler - Behavioral
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

entity icmp_handler is 
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0');
        our_ip      : std_logic_vector(31 downto 0) := (others => '0'));
    port (  clk                : in  STD_LOGIC;
            packet_in_valid    : in  STD_LOGIC;
            packet_in_data     : in  STD_LOGIC_VECTOR (7 downto 0);
            -- For receiving data from the PHY        
            packet_out_request : out std_logic := '0';
            packet_out_granted : in  std_logic := '0';
            packet_out_valid   : out std_logic;         
            packet_out_data    : out std_logic_vector(7 downto 0));
end icmp_handler;

architecture Behavioral of icmp_handler is

    component icmp_extract_ethernet_header
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC;
           data_out       : out STD_LOGIC_VECTOR (7 downto 0);
           
           ether_is_ipv4  : out STD_LOGIC; 
           ether_src_mac  : out STD_LOGIC_VECTOR (47 downto 0));
    end component;
    signal ether_extracted_data_valid : STD_LOGIC := '0';
    signal ether_extracted_data       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal ether_is_ipv4             : STD_LOGIC := '0'; 
    signal ether_src_mac             : STD_LOGIC_VECTOR (47 downto 0) := (others => '0');

    component icmp_extract_ip_header 
    Port ( clk                : in  STD_LOGIC;
           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC;
           data_out           : out STD_LOGIC_VECTOR (7 downto 0);
           
           ip_version         : out STD_LOGIC_VECTOR (3 downto 0);
           ip_type_of_service : out STD_LOGIC_VECTOR (7 downto 0);
           ip_length          : out STD_LOGIC_VECTOR (15 downto 0);
           ip_identification  : out STD_LOGIC_VECTOR (15 downto 0);
           ip_flags           : out STD_LOGIC_VECTOR (2 downto 0);
           ip_fragment_offset : out STD_LOGIC_VECTOR (12 downto 0);
           ip_ttl             : out STD_LOGIC_VECTOR (7 downto 0);
           ip_protocol        : out STD_LOGIC_VECTOR (7 downto 0);
           ip_checksum        : out STD_LOGIC_VECTOR (15 downto 0);
           ip_src_ip          : out STD_LOGIC_VECTOR (31 downto 0);
           ip_dest_ip         : out STD_LOGIC_VECTOR (31 downto 0));           
    end component;
    signal ip_extracted_data_valid : STD_LOGIC := '0';
    signal ip_extracted_data       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    signal ip_version         : STD_LOGIC_VECTOR (3 downto 0)  := (others => '0');
    signal ip_type_of_service : STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
    signal ip_length          : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal ip_identification  : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal ip_flags           : STD_LOGIC_VECTOR (2 downto 0)  := (others => '0');
    signal ip_fragment_offset : STD_LOGIC_VECTOR (12 downto 0) := (others => '0');
    signal ip_ttl             : STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
    signal ip_protocol        : STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
    signal ip_checksum        : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal ip_src_ip          : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    signal ip_dest_ip         : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');           

    component icmp_extract_icmp_header 
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC;
           data_out       : out STD_LOGIC_VECTOR (7 downto 0);
           
           icmp_type       : out STD_LOGIC_VECTOR (7 downto 0);
           icmp_code       : out STD_LOGIC_VECTOR (7 downto 0);
           icmp_checksum   : out STD_LOGIC_VECTOR (15 downto 0);
           icmp_identifier : out STD_LOGIC_VECTOR (15 downto 0);
           icmp_sequence   : out STD_LOGIC_VECTOR (15 downto 0));           
    end component;
    signal icmp_extracted_data_valid : STD_LOGIC := '0';
    signal icmp_extracted_data       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    signal icmp_type       : STD_LOGIC_VECTOR (7 downto 0);
    signal icmp_code       : STD_LOGIC_VECTOR (7 downto 0);
    signal icmp_checksum   : STD_LOGIC_VECTOR (15 downto 0);
    signal icmp_identifier : STD_LOGIC_VECTOR (15 downto 0);           
    signal icmp_sequence   : STD_LOGIC_VECTOR (15 downto 0);           

begin
i_icmp_extracted_ethernet_header: icmp_extract_ethernet_header port map (
    clk            => clk,
    data_valid_in  => packet_in_valid,
    data_in        => packet_in_data,
    data_valid_out => ether_extracted_data_valid,
    data_out       => ether_extracted_data,
       
    ether_is_ipv4  => ether_is_ipv4, 
    ether_src_mac  => ether_src_mac);

i_icmp_extract_ip_header: icmp_extract_ip_header port map ( 
    clk            => clk,
    data_valid_in  => ether_extracted_data_valid,
    data_in        => ether_extracted_data,
    data_valid_out => ip_extracted_data_valid,
    data_out       => ip_extracted_data,
    
    ip_version         => ip_version,
    ip_type_of_service => ip_type_of_service,
    ip_length          => ip_length,
    ip_identification  => ip_identification,
    ip_flags           => ip_flags,
    ip_fragment_offset => ip_fragment_offset,
    ip_ttl             => ip_ttl,
    ip_protocol        => ip_protocol,
    ip_checksum        => ip_checksum,
    ip_src_ip          => ip_src_ip,
    ip_dest_ip         => ip_dest_ip);           

i_icmp_extract_icmp_header : icmp_extract_icmp_header port map ( 
    clk            => clk,
 
    data_valid_in  => ip_extracted_data_valid,
    data_in        => ip_extracted_data,
    data_valid_out => icmp_extracted_data_valid,
    data_out       => icmp_extracted_data,
           
    icmp_type       => icmp_type,
    icmp_code       => icmp_code,
    icmp_checksum   => icmp_checksum,
    icmp_identifier => icmp_identifier,
    icmp_sequence   => icmp_sequence);           


end Behavioral;
