----------------------------------------------------------------------------------
-- Engineer: Mike Field <haster@snap.net.nz> 
-- 
-- Module Name: detect_speed_and_reassemble_bytes - Behavioral
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

entity detect_speed_and_reassemble_bytes is
    Port ( clk125Mhz      : in  STD_LOGIC;
        -- Interface to input FIFO
        input_empty         : in  STD_LOGIC;           
        input_read          : out STD_LOGIC := '0';           
        input_data          : in  STD_LOGIC_VECTOR (7 downto 0);
        input_data_present  : in  STD_LOGIC;
        input_data_error    : in  STD_LOGIC;
        
        link_10mb           : out STD_LOGIC := '0'; 
        link_100mb          : out STD_LOGIC := '0';
        link_1000mb         : out STD_LOGIC := '0';
        link_full_duplex    : out STD_LOGIC := '0';
        
        output_data_enable  : out STD_LOGIC := '0';
        output_data         : out STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
        output_data_present : out STD_LOGIC := '0';
        output_data_error   : out STD_LOGIC := '0');
end detect_speed_and_reassemble_bytes;

architecture Behavioral of detect_speed_and_reassemble_bytes is
    signal preamble_count        : unsigned(4 downto 0) := (others => '0');
    signal i_link_10mb           : STD_LOGIC := '0';
    signal i_link_100mb          : STD_LOGIC := '0';
    signal i_link_1000mb         : STD_LOGIC := '0';
    signal i_link_full_duplex    : STD_LOGIC := '0';
    signal fresh_data            : STD_LOGIC := '0';
    signal active_data           : STD_LOGIC := '0';

    signal phase                    : STD_LOGIC                    := '0';
    signal last_nibble_data         : std_logic_vector(3 downto 0) := "0000";
    signal last_nibble_data_error   : std_logic := '0';
    signal last_nibble_data_present : std_logic := '0';

    signal i_output_data_enable  : STD_LOGIC := '0';
    signal i_output_data         : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal i_output_data_present : STD_LOGIC := '0';
    signal i_output_data_error   : STD_LOGIC := '0';

begin
    link_10mb        <= i_link_10mb;
    link_100mb       <= i_link_100mb;
    link_1000mb      <= i_link_1000mb;
    link_full_duplex <= i_link_full_duplex;

    output_data_enable  <= i_output_data_enable; 
    output_data         <= i_output_data;
    output_data_present <= i_output_data_present;
    output_data_error   <= i_output_data_error;


    input_read <= not input_empty;
detect_link_status: process(clk125Mhz)
    begin
        if rising_edge(clk125Mhz) then
            if fresh_data = '1'  and (input_data_present = '0') and (input_data_error = '0') and 
               input_data(3 downto 0) = input_data(7 downto 4) then
               ----------------------------------------------------
               -- The idle sumbols have link status incoded in them
               ----------------------------------------------------
               i_link_10mb        <= '0';
               i_link_100mb       <= '0';
               i_link_1000mb      <= '0';
               i_link_full_duplex <= '0';
               case input_data(2 downto 0) is
                   when "001" => i_link_10mb   <= '1'; i_link_full_duplex <= input_data(3);
                   when "011" => i_link_100mb  <= '1'; i_link_full_duplex <= input_data(3);
                   when "101" => i_link_1000mb <= '1'; i_link_full_duplex <= input_data(3);
                   when others => NULL;
               end case;
            end if;
            fresh_data <= not input_empty;    
        end if;
    end process;
    
reassemble_data:process(clk125Mhz)
    begin
        if rising_edge(clk125Mhz) then
            i_output_data_present <= '0';
            i_output_data_enable  <= '0';
            i_output_data         <= (others => '0');
            if i_link_1000mb = '1' then
                -- this is designs such that one idle symbol will be
                -- emitted after the end of the contents of the packet
                if fresh_data = '1' then
                    if active_data = '1' then                        
                        i_output_data_enable  <= '1';
                        i_output_data         <= input_data;
                        i_output_data_present <= input_data_present;
                        i_output_data_error   <= input_data_error;
                        active_data           <= input_data_present;
                     else
                        -- Check we see a valid preamble sequence
                        -- We see two nibbles of the preamble every
                        -- time we see a byte
                        if input_data_present = '1' then
                            if input_data = x"55" then
                                if preamble_count (4) = '0' then
                                    preamble_count <= preamble_count+2;
                                end if;
                            elsif input_data = x"D5" and preamble_count(4) = '0' then
                                active_data <= '1';
                            end if;
                        else
                            preamble_count <= (others => '0');
                        end if;
                     end if;
                 end if;
            else
                ----------------------------------------------
                -- For 100Mb/s and 10Mb/s the data is received
                -- as nibbles (4 bits) per transfer
                -----------------------------------------------
                if fresh_data = '1' then
                    if active_data = '1' then
                        -- Set the output but only assert output_data_enable every other cycle
                        i_output_data         <= input_data(3 downto 0) & last_nibble_data;
                        i_output_data_present <= input_data_present and last_nibble_data_present;
                        i_output_data_error   <= input_data_error   or  last_nibble_data_error;
                        i_output_data_enable  <= phase;
                        phase               <= not phase;
                        -- Only allow 'active data' to drop during second half of byte
                        if phase = '1' then
                            active_data         <= input_data_present and last_nibble_data_present;
                        end if;
                     else
                        -- Check we see a valid preamble sequence
                        if input_data_present = '1' then
                            if input_data = x"55" then
                                if preamble_count (4) = '0' then
                                    preamble_count <= preamble_count+1;
                                end if;
                            elsif input_data = x"DD" and preamble_count(4) = '0' then
                                active_data <= '1';
                                phase       <= '0';
                            end if;
                        else
                            preamble_count <= (others => '0');
                        end if;
                     end if;
                 end if;
            end if;

            if fresh_data = '1' then
                -- Remember the data in case we are running at 
                -- a slow data rate (where nibbles are transferred)
                last_nibble_data         <= input_data(3 downto 0);                        
                last_nibble_data_present <= input_data_present;
                last_nibble_data_error   <= input_data_error;
                last_nibble_data_present <= input_data_present;
            end if;
        end if;
    end process;
end Behavioral;
