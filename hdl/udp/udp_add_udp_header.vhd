----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: udp_add_udp_header - Behavioral
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

entity udp_add_udp_header is
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC := '0';
           data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
         
           udp_src_port  : in  std_logic_vector(15 downto 0);
           udp_dst_port  : in  std_logic_vector(15 downto 0);
           data_length   : in  std_logic_vector(15 downto 0);
           data_checksum : in  std_logic_vector(15 downto 0));
end udp_add_udp_header;

architecture Behavioral of udp_add_udp_header is
    type a_data_delay is array(0 to 8) of std_logic_vector(8 downto 0);
    signal data_delay      : a_data_delay := (others => (others => '0'));
    
    ----------------------------------------------------------------
    -- Note: Set the initial state to pass the data striaght through
    ----------------------------------------------------------------
    signal count              : unsigned(3 downto 0) := (others => '1');
    signal data_valid_in_last : std_logic            := '0';

    signal udp_length         : std_logic_vector(15 downto 0);
    signal udp_checksum_u1    : unsigned(19 downto 0);
    signal udp_checksum_u2    : unsigned(16 downto 0);
    signal udp_checksum_u3    : unsigned(15 downto 0);
    signal udp_checksum       : std_logic_vector(15 downto 0);
begin
    -- NEED TO CORRECT THIS! ---
    udp_length      <= std_logic_vector(unsigned(data_length)+8);
    udp_checksum_u1 <= to_unsigned(0,20) + unsigned(data_checksum) + unsigned(udp_length) 
                                         + unsigned(udp_src_port)  + unsigned(udp_dst_port);
    udp_checksum_u2 <= to_unsigned(0,17) + udp_checksum_u1(15 downto 0) + udp_checksum_u1(19 downto 16);
    udp_checksum_u3 <= udp_checksum_u2(15 downto 0) + udp_checksum_u2(16 downto 16);
    udp_checksum    <= not std_logic_vector(udp_checksum_u3);
process(clk)
    begin
        if rising_edge(clk) then
            
            case count is
                when "0000" => data_out <= udp_src_port(15 downto 8);  data_valid_out <= '1';
                when "0001" => data_out <= udp_src_port( 7 downto 0);  data_valid_out <= '1';
                when "0010" => data_out <= udp_dst_port(15 downto 8);  data_valid_out <= '1';
                when "0011" => data_out <= udp_dst_port( 7 downto 0);  data_valid_out <= '1';
                when "0100" => data_out <= udp_length(15 downto 8);    data_valid_out <= '1';
                when "0101" => data_out <= udp_length( 7 downto 0);    data_valid_out <= '1';                    
                when "0110" => data_out <= udp_checksum(15 downto  8); data_valid_out <= '1';
                when "0111" => data_out <= udp_checksum( 7 downto  0); data_valid_out <= '1';
                when others => data_out <= data_delay(0)(7 downto 0);  data_valid_out <= data_delay(0)(8);
            end case;

            data_delay(0 to data_delay'high-1) <= data_delay(1 to data_delay'high);
            if data_valid_in = '1' then
                data_delay(data_delay'high) <= '1' & data_in;
                if data_valid_in_last = '0' then
                    count <= (others => '0');
                elsif count /= "1111" then
                    count <= count + 1;
                end if;
            else
                data_delay(data_delay'high) <= (others => '0');
                if count /= "1111" then
                    count <= count + 1;
                end if;
            end if;     
            data_valid_in_last <= data_valid_in;
        end if;
    end process;
end Behavioral;