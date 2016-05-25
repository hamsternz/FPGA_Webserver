----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: tx_add_preamble - Behavioral
--
-- Description: Add the required 16 nibbles of preamble to the data packet. 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tx_add_preamble is
    Port ( clk             : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC;
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC                     := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0'));
end tx_add_preamble;

architecture Behavioral of tx_add_preamble is
    signal delay_data        : std_logic_vector(8*8-1 downto 0) := (others => '0');
    signal delay_data_valid  : std_logic_vector(8-1 downto 0) := (others => '0');
begin

process(clk)
    begin
        if rising_edge(clk) then
            if delay_data_valid(delay_data_valid'high)= '1' then
                -- Passing through data
                data_out        <= delay_data(delay_data'high downto delay_data'high-7);
                data_valid_out <= '1';        
            elsif delay_data_valid(delay_data_valid'high-1)= '1' then
                -- Start Frame Delimiter
                data_out        <= "11010101"; 
                data_valid_out <= '1';
            elsif data_valid_in = '1' then
                -- Preamble nibbles
                data_out        <= "01010101"; 
                data_valid_out <= '1';        
            else
                -- Link idle
                data_out        <= "00000000"; 
                data_valid_out <= '0';                
            end if;
            -- Move the data through the delay line
            delay_data       <= delay_data(delay_data'high-8 downto 0) & data_in;  
            delay_data_valid <= delay_data_valid(delay_data_valid'high-1 downto 0) & data_valid_in;
        end if;
    end process;

end Behavioral;