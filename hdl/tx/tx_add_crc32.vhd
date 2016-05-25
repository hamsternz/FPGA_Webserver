----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: tx_add_crc32 - Behavioral
--
-- Description: Add the required 8 bytes of preamble to the data packet. 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tx_add_crc32 is
    Port ( clk             : in  STD_LOGIC;
           data_valid_in   : in  STD_LOGIC                     := '0';
           data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid_out  : out STD_LOGIC                     := '0';
           data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0'));
end tx_add_crc32;

architecture Behavioral of tx_add_crc32 is
    signal crc               : std_logic_vector(31 downto 0)   := (others => '1');
    signal trailer_left      : std_logic_vector(3 downto 0) := (others => '0');
begin

add_crc_proc: process(clk)
        variable v_crc : std_logic_vector(31 downto 0) := (others => '1');
    begin
        if rising_edge(clk) then
            if data_valid_in = '1' then
                -- Pass the data through
                data_out        <= data_in;
                data_valid_out <= '1';
                -- Flag that we need to output 8 bytes of CRC
                trailer_left    <= (others => '1');
                
                ----------------------------------------
                -- Update the CRC
                --
                -- This uses a variable to make the code 
                -- simple to follow and more compact
                ---------------------------------------- 
                v_crc := crc;
                for i in 0 to 7 loop
                    if data_in(i) = v_crc(31) then
                       v_crc := v_crc(30 downto 0) & '0';
                    else
                       v_crc := (v_crc(30 downto 0)& '0') xor x"04C11DB7";
                    end if;
                end loop;
                crc <= v_crc;                 
            elsif trailer_left(trailer_left'high)= '1' then
                -- append the CRC
                data_out        <= not (crc(24) & crc(25) & crc(26) & crc(27) & crc(28) & crc(29) & crc(30) & crc(31));
                crc             <= crc(23 downto 0) & "11111111";
                trailer_left    <= trailer_left(trailer_left'high-1 downto 0) & '0';
                data_valid_out <= '1';        
            else
                -- Idle
                data_out        <= "00000000"; 
                data_valid_out <= '0';                
            end if;
        end if;
    end process;
end Behavioral;