----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.05.2016 16:14:51
-- Design Name: 
-- Module Name: main_design - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main_design is
    Port ( clk125Mhz          : in  STD_LOGIC;
       input_empty        : in  STD_LOGIC;           
       input_read         : out STD_LOGIC;           
       input_data         : in  STD_LOGIC_VECTOR (7 downto 0);
       input_data_present : in  STD_LOGIC;
       input_data_error   : in  STD_LOGIC;

       phy_ready          : in  STD_LOGIC;
       status             : out STD_LOGIC_VECTOR (3 downto 0);
       
       eth_txck           : out std_logic := '0';
       eth_txctl          : out std_logic := '0';
       eth_txd            : out std_logic_vector(3 downto 0) := (others => '0'));
end main_design;

architecture Behavioral of main_design is
    constant our_mac : std_logic_vector(47 downto 0) := x"01_23_45_67_89_AB";
    constant our_ip  : std_logic_vector(31 downto 0) := x"0B_00_00_0A";

    component detect_speed_and_reassemble_bytes is
    Port ( clk125Mhz      : in  STD_LOGIC;
        -- Interface to input FIFO
       input_empty         : in  STD_LOGIC;           
       input_read          : out STD_LOGIC;           
       input_data          : in  STD_LOGIC_VECTOR (7 downto 0);
       input_data_present  : in  STD_LOGIC;
       input_data_error    : in  STD_LOGIC;

       link_10mb           : out STD_LOGIC;
       link_100mb          : out STD_LOGIC;
       link_1000mb         : out STD_LOGIC;
       link_full_duplex    : out STD_LOGIC;

       output_data_enable  : out STD_LOGIC;
       output_data         : out STD_LOGIC_VECTOR (7 downto 0);
       output_data_present : out STD_LOGIC;
       output_data_error   : out STD_LOGIC);
    end component;
    signal spaced_out_data_enable  : STD_LOGIC;
    signal spaced_out_data         : STD_LOGIC_VECTOR (7 downto 0);
    signal spaced_out_data_present : STD_LOGIC;
    signal spaced_out_data_error   : STD_LOGIC;

    signal link_10mb           : STD_LOGIC;
    signal link_100mb          : STD_LOGIC;
    signal link_1000mb         : STD_LOGIC;
    signal link_full_duplex    : STD_LOGIC;

    component defragment_and_check_crc is
    Port ( 
        clk                : in  STD_LOGIC;
        input_data_enable  : in  STD_LOGIC;           
        input_data         : in  STD_LOGIC_VECTOR (7 downto 0);
        input_data_present : in  STD_LOGIC;
        input_data_error   : in  STD_LOGIC;
        packet_data_valid  : out STD_LOGIC;
        packet_data        : out STD_LOGIC_VECTOR (7 downto 0));
    end component;
    
    signal packet_data_valid  : STD_LOGIC;
    signal packet_data        : STD_LOGIC_VECTOR (7 downto 0);

    -------------------------------------------
    -- Protocol handlers
    -------------------------------------------
    component arp_handler is 
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0');
        our_ip      : std_logic_vector(31 downto 0) := (others => '0'));
    port (  clk              : in  STD_LOGIC;
            packet_in_valid  : in  STD_LOGIC;
            packet_in_data   : in  STD_LOGIC_VECTOR (7 downto 0);
            -- For receiving data from the PHY        
            packet_out_req   : out std_logic := '0';
            packet_out_grant : in  std_logic := '0';
            packet_out_valid : out std_logic;         
            packet_out_data  : out std_logic_vector(7 downto 0);         
             -- to enable IP->MAC lookup for outbound packets
            lookup_request   : in  std_logic;
            lookup_ip        : in  std_logic_vector(31 downto 0);
            lookup_mac       : out std_logic_vector(47 downto 0);
            lookup_found     : out std_logic;
            lookup_reply     : out std_logic);
    end component;

    signal packet_arp_req       : std_logic;
    signal packet_arp_grant     : std_logic;
    signal packet_arp_valid     : std_logic;         
    signal packet_arp_data      : std_logic_vector(7 downto 0);         

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
 
begin
   status  <= link_full_duplex & link_1000mb & link_100mb & link_10mb;

    ----------------------------------------------------------------------
    -- As well as converting nibbles to bytes (for the slowe speeds)
    -- this also strips out the preamble and start of frame symbols
    ----------------------------------------------------------------------
i_detect_speed_and_reassemble_bytes: detect_speed_and_reassemble_bytes port map (
    clk125Mhz          => clk125Mhz,
    -- Interface to input FIFO
   input_empty         => input_empty,           
   input_read          => input_read,           
   input_data          => input_data,
   input_data_present  => input_data_present,
   input_data_error    => input_data_error,

   link_10mb           => link_10mb,
   link_100mb          => link_100mb,
   link_1000mb         => link_1000mb,
   link_full_duplex    => link_full_duplex,

   output_data_enable  => spaced_out_data_enable,
   output_data         => spaced_out_data,
   output_data_present => spaced_out_data_present,
   output_data_error   => spaced_out_data_error);
    ----------------------------------------------------------------------
    -- Even at gigabit speeds the stream of bytes might include 
    -- gaps due to differences between the source and destination clocks.
    -- This module packs all the bytes in a packet close togeather, so
    -- they can be streamed though the rest of the design without using 
    -- a Data Enable line.
    --
    -- It also provides a handy place to check the FCS, allowing pacckets 
    -- with errors or corruption to be dropped early. 
    ----------------------------------------------------------------------
i_defragment_and_check_crc: defragment_and_check_crc port map (
    clk                => clk125Mhz,
    
    input_data_enable  => spaced_out_data_enable,     
    input_data         => spaced_out_data,
    input_data_present => spaced_out_data_present,
    input_data_error   => spaced_out_data_error,
    
    packet_data_valid  => packet_data_valid,
    packet_data        => packet_data);

i_ila_0: ila_0 port map (
    clk       => clk125Mhz,
    probe0(0) => packet_data_valid, 
    probe1(0) => packet_data_valid, 
    probe2    => packet_data,
    probe3(0) => packet_data_valid);

i_arp_handler:arp_handler  generic map (
        our_mac => our_mac,
        our_ip  => our_ip)
    port map (
        clk              => clk125MHz,
        packet_in_valid  => packet_data_valid,
        packet_in_data   => packet_data,
        -- For Sending data to the PHY        
        packet_out_req   => packet_arp_req,
        packet_out_grant => packet_arp_grant,
        packet_out_valid => packet_arp_valid,          
        packet_out_data  => packet_arp_data,         
         -- to enable IP->MAC lookup for outbound packets
        lookup_request   => '0',
        lookup_ip        => (others => '0'),
        lookup_mac       => open,
        lookup_found     => open,
        lookup_reply     => open);
end Behavioral;
