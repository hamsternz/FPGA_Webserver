----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.05.2016 21:35:40
-- Design Name: 
-- Module Name: icmp_strip_ethernet_header - Behavioral
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

entity icmp_extract_ethernet_header is
    Port ( clk            : in  STD_LOGIC;
       data_valid_in  : in  STD_LOGIC;
       data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
       data_valid_out : out STD_LOGIC := '0';
       data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
       
       ether_is_ipv4  : out STD_LOGIC := '0'; 
       ether_src_mac  : out STD_LOGIC_VECTOR (47 downto 0) := (others => '0'));
end icmp_extract_ethernet_header;

architecture Behavioral of icmp_extract_ethernet_header is
    signal count          : unsigned(3 downto 0)         := (others => '0');
    signal ether_type_low : std_logic_vector(7 downto 0) := (others => '0');
begin

process(clk)
    begin
        if rising_edge(clk) then
            data_out       <= data_in;
            if data_valid_in = '1' then
                -- Note, at count of zero,  
                case count is
                    when "0000" => NULL;
                    when "0001" => NULL;
                    when "0010" => NULL;
                    when "0011" => NULL;
                    when "0100" => NULL;
                    when "0101" => NULL;
                    when "0110" => ether_src_mac( 7 downto  0) <= data_in;
                    when "0111" => ether_src_mac(15 downto  8) <= data_in;
                    when "1000" => ether_src_mac(23 downto 16) <= data_in;
                    when "1001" => ether_src_mac(31 downto 24) <= data_in;
                    when "1010" => ether_src_mac(39 downto 32) <= data_in;
                    when "1011" => ether_src_mac(47 downto 40) <= data_in;
                    when "1100" => ether_type_low <= data_in;
                    when "1101" => if data_in = x"00" and ether_type_low = x"08" then
                                       ether_is_ipv4 <= '1';
                                   end if;
                    when others => data_valid_out <= data_valid_in;
                                   data_out       <= data_in;
                end case;
                if count /= "1111" then
                    count <= count+1;
                end if;
            else
               data_valid_out <= '0';
               data_out       <= data_in;
               ether_is_ipv4  <= '0';
               count <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
