----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.05.2016 21:56:31
-- Design Name: 
-- Module Name: icmp_extract_ip_header - Behavioral
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

entity icmp_extract_ip_header is
    Port ( clk                : in  STD_LOGIC;

           data_valid_in      : in  STD_LOGIC;
           data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out     : out STD_LOGIC := '0';
           data_out           : out STD_LOGIC_VECTOR (7 downto 0)  := (others => '0');
           
           ip_version         : out STD_LOGIC_VECTOR ( 3 downto 0)  := (others => '0');
           ip_type_of_service : out STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           ip_length          : out STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_identification  : out STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_flags           : out STD_LOGIC_VECTOR ( 2 downto 0)  := (others => '0');
           ip_fragment_offset : out STD_LOGIC_VECTOR (12 downto 0)  := (others => '0');
           ip_ttl             : out STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           ip_protocol        : out STD_LOGIC_VECTOR ( 7 downto 0)  := (others => '0');
           ip_checksum        : out STD_LOGIC_VECTOR (15 downto 0)  := (others => '0');
           ip_src_ip          : out STD_LOGIC_VECTOR (31 downto 0)  := (others => '0');
           ip_dest_ip         : out STD_LOGIC_VECTOR (31 downto 0)  := (others => '0'));           
end icmp_extract_ip_header;

architecture Behavioral of icmp_extract_ip_header is
    signal count          : unsigned(4 downto 0)         := (others => '0');
begin
process(clk)
    begin
        if rising_edge(clk) then
            data_out       <= data_in;
            if data_valid_in = '1' then
                -- Note, at count of zero,  
                case count is
                    when "00000" => NULL;
                    when "00001" => NULL;
                    when "00010" => NULL;
                    when "00011" => NULL;
                    when "00100" => NULL;
                    when "00101" => NULL;
                    when "00110" => NULL;
                    when "00111" => NULL;
                    when "01000" => NULL;
                    when "01001" => NULL;
                    when "01010" => NULL;
                    when "01011" => NULL;
                    when "01100" => NULL;
                    when "01101" => NULL;
                    when "01110" => NULL;
                    when "01111" => NULL;
                    when "10000" => NULL;
                    when "10001" => NULL;
                    when "10010" => NULL;
                    when "10011" => NULL;
                    when "10100" => NULL;
                    when "10101" => NULL;
                    when "10110" => NULL;
                    when "10111" => NULL;
                    when "11000" => NULL;
                    when "11001" => NULL;
                    when "11010" => NULL;
                    when "11011" => NULL;
                    when "11100" => NULL;
                    when "11101" => NULL;
                    when "11110" => NULL;
                    when others => data_valid_out <= data_valid_in;
                                   data_out       <= data_in;
                end case;
                if count /= "11111" then
                    count <= count+1;
                end if;
            else
               data_valid_out <= '0';
               data_out       <= data_in;
               count          <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;
