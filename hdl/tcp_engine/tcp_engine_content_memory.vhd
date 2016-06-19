----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.06.2016 23:01:07
-- Design Name: 
-- Module Name: tcp_engine_content_memory - Behavioral
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

entity tcp_engine_content_memory is
    Port ( clk : in STD_LOGIC;
           address : in STD_LOGIC_VECTOR (15 downto 0);
           data : out STD_LOGIC_VECTOR (7 downto 0));
end tcp_engine_content_memory;

architecture Behavioral of tcp_engine_content_memory is
    type a_mem is array(0 to 15) of std_logic_vector(7 downto 0);
    -- For now, just the characters '0' to '9' and 'A' to 'F'
    signal mem : a_mem := (x"30", x"31", x"32", x"33",
                           x"34", x"35", x"36", x"37",
                           x"38", x"39", x"41", x"42",
                           x"43", x"44", x"45", x"46");
begin
    process(clk)
        begin
            if rising_edge(clk) then
                data <= mem(to_integer(unsigned(address(3 downto 0))));
            end if;
        end process;

end Behavioral;
