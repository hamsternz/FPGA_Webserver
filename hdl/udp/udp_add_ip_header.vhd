----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: udp_add_ip_header - Behavioral
--
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

entity udp_add_ip_header is
    Port ( clk                : in  STD_LOGIC;

           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC := '0';
           data_out           : out STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
           
           udp_data_length    : in  STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_checksum        : in  STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_src_ip          : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dest_ip         : in  STD_LOGIC_VECTOR (31 downto 0)  := (others => '0'));           
end udp_add_ip_header;

architecture Behavioral of udp_add_ip_header is
    type a_data_delay is array(0 to 20) of std_logic_vector(8 downto 0);
    signal data_delay      : a_data_delay := (others => (others => '0'));
    -------------------------------------------------------
    -- Note: Set the initial state to pass the data through
    -------------------------------------------------------
    signal count              : unsigned(4 downto 0) := (others => '1');
    signal data_valid_in_last : std_logic            := '0';
    
    constant ip_version         : STD_LOGIC_VECTOR ( 3 downto 0)  := x"4";
    constant ip_header_len      : STD_LOGIC_VECTOR ( 3 downto 0)  := x"5";
    constant ip_type_of_service : STD_LOGIC_VECTOR ( 7 downto 0)  := x"00";           --zzz
    constant ip_identification  : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0'); --zzz
    constant ip_flags           : STD_LOGIC_VECTOR ( 2 downto 0)  := (others => '0'); --zzz
    constant ip_fragment_offset : STD_LOGIC_VECTOR (12 downto 0)  := (others => '0'); --zzz
    constant ip_ttl             : STD_LOGIC_VECTOR ( 7 downto 0)  := x"FF";
    constant ip_protocol        : STD_LOGIC_VECTOR ( 7 downto 0)  := x"11";
    signal   ip_length          : STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
               
begin
    ip_length <= std_logic_vector(unsigned(udp_data_length)+28);
process(clk)
    begin
        if rising_edge(clk) then
            case count is
                when "00000" => data_out <= ip_version & ip_header_len;                 data_valid_out <= '1';
                when "00001" => data_out <= ip_type_of_service;                         data_valid_out <= '1';
                when "00010" => data_out <= ip_length(15 downto 8);                     data_valid_out <= '1';
                when "00011" => data_out <= ip_length( 7 downto 0);                     data_valid_out <= '1';
                when "00100" => data_out <= ip_identification(15 downto 8);             data_valid_out <= '1';
                when "00101" => data_out <= ip_identification( 7 downto 0);             data_valid_out <= '1';
                when "00110" => data_out <= ip_flags & ip_fragment_offset(12 downto 8); data_valid_out <= '1';
                when "00111" => data_out <= ip_fragment_offset( 7 downto 0);            data_valid_out <= '1';
                when "01000" => data_out <= ip_ttl;                                     data_valid_out <= '1';
                when "01001" => data_out <= ip_protocol;                                data_valid_out <= '1';
                when "01010" => data_out <= ip_checksum(15 downto 8);                   data_valid_out <= '1';
                when "01011" => data_out <= ip_checksum( 7 downto 0);                   data_valid_out <= '1';
                when "01100" => data_out <= ip_src_ip( 7 downto 0);                     data_valid_out <= '1';
                when "01101" => data_out <= ip_src_ip(15 downto 8);                     data_valid_out <= '1';
                when "01110" => data_out <= ip_src_ip(23 downto 16);                    data_valid_out <= '1';
                when "01111" => data_out <= ip_src_ip(31 downto 24);                    data_valid_out <= '1';
                when "10000" => data_out <= ip_dest_ip( 7 downto 0);                    data_valid_out <= '1';
                when "10001" => data_out <= ip_dest_ip(15 downto 8);                    data_valid_out <= '1';
                when "10010" => data_out <= ip_dest_ip(23 downto 16);                   data_valid_out <= '1';
                when "10011" => data_out <= ip_dest_ip(31 downto 24);                   data_valid_out <= '1';                         
                when others  => data_out <= data_delay(0)(7 downto 0);                  data_valid_out <= data_delay(0)(8);
            end case;

            data_delay(0 to data_delay'high-1) <= data_delay(1 to data_delay'high);
            if data_valid_in = '1' then
                data_delay(data_delay'high) <= '1' & data_in;
                if data_valid_in_last = '0' then
                    count <= (others => '0');
                elsif count /= "11111" then
                    count <= count + 1;
                end if;
            else
                data_delay(data_delay'high) <= (others => '0');
                if count /= "11111" then
                    count <= count + 1;
                end if;
            end if;     
            data_valid_in_last <= data_valid_in;

        end if;
    end process;
end Behavioral;
