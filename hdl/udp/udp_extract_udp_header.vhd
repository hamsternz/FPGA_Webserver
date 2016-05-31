----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: udp_extract_udp_header.vhd - Behavioral
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
entity udp_extract_udp_header is
    Port ( clk            : in  STD_LOGIC;
       data_valid_in  : in  STD_LOGIC;
       data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
       data_valid_out : out STD_LOGIC := '0';
       data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
       
       udp_src_port   : out STD_LOGIC_VECTOR (15 downto 0);
       udp_dst_port   : out STD_LOGIC_VECTOR (15 downto 0);
       udp_length     : out STD_LOGIC_VECTOR (15 downto 0);
       udp_checksum   : out STD_LOGIC_VECTOR (15 downto 0));           
end udp_extract_udp_header;

architecture Behavioral of udp_extract_udp_header is
    signal count          : unsigned(3 downto 0)           := (others => '0');
    signal i_udp_src_port : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal i_udp_dst_port : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal i_udp_length   : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal i_udp_checksum : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    -- 'data_count' us used for trimming off padding on the end of the UDP packet 
    signal data_count     : unsigned(11 downto 0)          := (others => '0');
begin
    udp_length   <= i_udp_length;
    udp_checksum <= i_udp_checksum;
    udp_dst_port <= i_udp_dst_port;
    udp_src_port <= i_udp_src_port;

process(clk)
    begin
        if rising_edge(clk) then
            data_out       <= data_in;
            if data_valid_in = '1' then
                case count is
                    when "0000" => i_udp_src_port(15 downto 8) <= data_in;
                    when "0001" => i_udp_src_port( 7 downto 0) <= data_in;
                    when "0010" => i_udp_dst_port(15 downto 8) <= data_in;
                    when "0011" => i_udp_dst_port( 7 downto 0) <= data_in;
                    when "0100" => i_udp_length(15 downto 8)   <= data_in;
                    when "0101" => i_udp_length( 7 downto 0)   <= data_in;
                    when "0110" => i_udp_checksum(15 downto 8) <= data_in;
                    when "0111" => i_udp_checksum( 7 downto 0) <= data_in;
                    when others => if data_count < unsigned(i_udp_length) then
                                       data_valid_out <= data_valid_in;
                                       data_out       <= data_in;
                                   else
                                       data_valid_out <= '0';
                                       data_out       <= data_in;
                                   end if;
                                    
                end case;
                if count /= "1111" then
                    count <= count+1;
                end if;
                data_count <= data_count + 1;
            else
               data_valid_out <= '0';
               data_out       <= data_in;
               count <= (others => '0');
               data_count <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
