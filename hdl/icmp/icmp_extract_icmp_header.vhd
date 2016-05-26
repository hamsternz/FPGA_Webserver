----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.05.2016 22:07:06
-- Design Name: 
-- Module Name: icmp_extract_icmp_header - Behavioral
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
entity icmp_extract_icmp_header is
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
end icmp_extract_icmp_header;

architecture Behavioral of icmp_extract_icmp_header is
    signal count          : unsigned(3 downto 0)         := (others => '0');
begin


process(clk)
    begin
        if rising_edge(clk) then
            data_out       <= data_in;
            if data_valid_in = '1' then
                -- Note, at count of zero,  
                case count is
                    when "0000" => icmp_type                    <= data_in;
                    when "0001" => icmp_code                    <= data_in;
                    when "0010" => icmp_checksum(7 downto 0)    <= data_in;
                    when "0011" => icmp_checksum(15 downto 8)   <= data_in;
                    when "0100" => icmp_identifier(7 downto 0)  <= data_in;
                    when "0101" => icmp_identifier(15 downto 8) <= data_in;
                    when "0110" => icmp_sequence(7 downto 0)    <= data_in;
                    when "0111" => icmp_sequence(15 downto 8)   <= data_in;
                    when others => data_valid_out <= data_valid_in;
                                   data_out       <= data_in;
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
