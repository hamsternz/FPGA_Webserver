----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.06.2016 18:44:26
-- Design Name: 
-- Module Name: udp_tx_buffer_count_checksum_data - Behavioral
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

entity udp_tx_buffer_count_checksum_data is
    Port ( clk             : in  STD_LOGIC;
       data_valid_in   : in  STD_LOGIC;
       data_in         : in  STD_LOGIC_VECTOR (7 downto 0);
       data_valid_out  : out STD_LOGIC                     := '0';
       data_out        : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
       data_length     : out std_logic_vector(15 downto 0) := (others => '0');
       data_checksum   : out std_logic_vector(15 downto 0) := (others => '0'));  
end udp_tx_buffer_count_checksum_data;

architecture Behavioral of udp_tx_buffer_count_checksum_data is
    type a_data_buffer is array (0 to 2047) of std_logic_vector(8 downto 0);

    signal write_ptr          : unsigned(10 downto 0) := (others => '0');
    signal read_ptr           : unsigned(10 downto 0) := (others => '1');
    signal checkpoint         : unsigned(10 downto 0) := (others => '1');
    signal data_buffer        : a_data_buffer := (others =>( others => '0'));
    attribute rom_style : string;
    attribute rom_style of data_buffer : signal is "block";

    signal data_count         : unsigned(10 downto 0) := (others => '0');
    signal data_valid_in_last : std_logic := '0';
    signal checksum           : unsigned(16 downto 0) := (others => '0');
begin

process(clk) 
    variable v_checksum : unsigned(16 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            data_out       <= data_in;
            data_valid_out <= data_valid_in; 

            if data_valid_in = '1' or data_valid_in_last = '1' then
                data_buffer(to_integer(write_ptr)) <= data_valid_in & data_in;
                write_ptr <= write_ptr + 1; 
            end if;

            if data_valid_in = '1' then
                data_count <= data_count + 1;
                --- Update the checksum here
                if data_count(0) = '0' then
                    checksum <= to_unsigned(0,17) + checksum(15 downto 0) + checksum(16 downto 16) + unsigned(data_in); 
                else
                    checksum <= to_unsigned(0,17) + checksum(15 downto 0) + checksum(16 downto 16) + (unsigned(data_in) & to_unsigned(0,8));
                end if;
            else
                if data_valid_in_last = '1' then
                    -- End of packet
                    v_checksum    := to_unsigned(0,17) + checksum(15 downto 0) + checksum(16 downto 16);
                    data_checksum <= std_logic_vector(v_checksum(15 downto 0) + v_checksum(16 downto 16));
                    data_length   <= "00000" & std_logic_vector(data_count);
                    checkpoint    <= write_ptr;
                end if;
                data_count <= (others => '0');
                checksum   <= (others => '1');
            end if;
            data_valid_in_last <= data_valid_in;
            
            data_valid_out <= data_buffer(to_integer(read_ptr))(8);
            data_out       <= data_buffer(to_integer(read_ptr))(7 downto 0);
            if read_ptr /= checkpoint then
                read_ptr <= read_ptr+1;
            else
                data_out       <= (others => '0');
                data_valid_out <= '0';
            end if;
        end if;
    end process;
end Behavioral;
