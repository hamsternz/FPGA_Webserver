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
    generic (
        our_mac     : std_logic_vector(47 downto 0) := (others => '0'));
    Port ( clk            : in  STD_LOGIC;
           data_valid_in  : in  STD_LOGIC;
           data_in        : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out : out STD_LOGIC := '0';
           data_out       : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
         
           ether_type     : out STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 
           ether_dst_mac  : out STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
           ether_src_mac  : out STD_LOGIC_VECTOR (47 downto 0) := (others => '0'));
end icmp_extract_ethernet_header;

architecture Behavioral of icmp_extract_ethernet_header is
    signal count           : unsigned(3 downto 0)         := (others => '0');
    signal i_ether_type    : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 
    signal i_ether_dst_mac : STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
    signal i_ether_src_mac : STD_LOGIC_VECTOR (47 downto 0) := (others => '0');
    signal valid_mac       : STD_LOGIC := '1';
begin
    ether_dst_mac <= i_ether_dst_mac;
    ether_src_mac <= i_ether_src_mac;
    ether_type    <= i_ether_type;
    
process(clk)
    begin
        if rising_edge(clk) then
            data_out       <= data_in;
            if data_valid_in = '1' then
                -- Note, at count of zero,  
                case count is
                    when "0000" => i_ether_dst_mac( 7 downto  0) <= data_in;
                    when "0001" => i_ether_dst_mac(15 downto  8) <= data_in;
                    when "0010" => i_ether_dst_mac(23 downto 16) <= data_in;
                    when "0011" => i_ether_dst_mac(31 downto 24) <= data_in;
                    when "0100" => i_ether_dst_mac(39 downto 32) <= data_in;
                    when "0101" => i_ether_dst_mac(47 downto 40) <= data_in;
                    
                    when "0110" => i_ether_src_mac( 7 downto  0) <= data_in;
                    when "0111" => i_ether_src_mac(15 downto  8) <= data_in;
                    when "1000" => i_ether_src_mac(23 downto 16) <= data_in;
                    when "1001" => i_ether_src_mac(31 downto 24) <= data_in;
                    when "1010" => i_ether_src_mac(39 downto 32) <= data_in;
                    when "1011" => i_ether_src_mac(47 downto 40) <= data_in;
                                   if i_ether_dst_mac = x"FFFFFFFFFFFF" or i_ether_dst_mac = our_mac then
                                       valid_mac <= '1';
                                   else
                                       valid_mac <= '0';
                                   end if;
                    when "1100" => i_ether_type(7 downto 0)      <= data_in;
                    when "1101" => i_ether_type(15 downto 8)     <= data_in;
                    when others => if  valid_mac = '1' and i_ether_type = x"0008" then
                                       data_valid_out <= data_valid_in;
                                       data_out       <= data_in;
                                   else
                                       data_valid_out <= '0';
                                       data_out       <= (others => '0');
                                   end if;
                end case;
                if count /= "1111" then
                    count <= count+1;
                end if;
            else
               data_valid_out <= '0';
               data_out       <= data_in;
               count <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
