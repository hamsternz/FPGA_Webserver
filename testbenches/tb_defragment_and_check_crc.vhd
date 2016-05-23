----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.05.2016 06:48:08
-- Design Name: 
-- Module Name: tb_defragment_and_check_crc - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_defragment_and_check_crc is
    Port ( a : in STD_LOGIC);
end tb_defragment_and_check_crc;

architecture Behavioral of tb_defragment_and_check_crc is
    component defragment_and_check_crc is
    Port (  clk               : in  STD_LOGIC;
            input_data_enable  : in  STD_LOGIC;           
            input_data         : in  STD_LOGIC_VECTOR (7 downto 0);
            input_data_present : in  STD_LOGIC;
            input_data_error   : in  STD_LOGIC;
            packet_data_valid  : out STD_LOGIC;
            packet_data        : out STD_LOGIC_VECTOR (7 downto 0));
    end component;
    signal count : unsigned (7 downto 0) := "00000000";
    
    signal clk                     : std_logic := '0'; 
    signal spaced_out_data_enable  : std_logic := '0';  
    signal spaced_out_data         : std_logic_vector(7 downto 0);
    signal spaced_out_data_present : std_logic := '0';
    signal spaced_out_data_error   : std_logic := '0';
    
    signal packet_data_valid       : std_logic := '0';
    signal packet_data             : std_logic_vector(7 downto 0) := (others => '0');

begin

process
    begin
        wait for 5 ns;
        clk <= not clk;
    end process;
    
process(clk)
    begin
        if rising_edge(clk) then
--            if count(1 downto 0) = "000" then
                spaced_out_data <= "000" & std_logic_vector(count(4 downto 0));
                spaced_out_data_enable  <= '1';
                if count(4 downto 0) = "00000" then
                    spaced_out_data_enable  <= '0';
                    spaced_out_data_present <= '0';
                elsif count(4 downto 0) = "11111" then
                    spaced_out_data_enable  <= '1';
                    spaced_out_data_present <= '0';
                else
                    spaced_out_data_enable  <= '1';
                    spaced_out_data_present <= '1';
                end if;
--            else
--                spaced_out_data <= "00000000";
--                spaced_out_data_present <= '0';
--            end if;
            count <= count + 1;
        end if;
    end process;
    
uut: defragment_and_check_crc port map (
    clk                => clk,

    input_data_enable  => spaced_out_data_enable,     
    input_data         => spaced_out_data,
    input_data_present => spaced_out_data_present,
    input_data_error   => spaced_out_data_error,
    
    packet_data_valid  => packet_data_valid,
    packet_data        => packet_data);
end Behavioral;
