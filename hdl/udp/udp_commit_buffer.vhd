----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz> 
-- 
-- Module Name: udp_commit_buffer - Behavioral
--
-- Description: Somewhere to hold the data outbound UDP packet while waiting to
--              be granted access to the TX interface.
--              If the buffer gets over-run with data (e.g. if the TX interface is 
--              busy) then it drops the packet.  
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

entity udp_commit_buffer is
    Port ( clk                : in  STD_LOGIC;
       data_valid_in      : in  STD_LOGIC;
       data_in            : in  STD_LOGIC_VECTOR (7 downto 0);
       packet_out_request : out std_logic := '0';
       packet_out_granted : in  std_logic;
       packet_out_valid   : out std_logic := '0';         
       packet_out_data    : out std_logic_vector(7 downto 0) := (others => '0'));
end udp_commit_buffer;

architecture Behavioral of udp_commit_buffer is
    type a_data_buffer is array(0 to 2047) of std_logic_vector(8 downto 0);
    signal data_buffer : a_data_buffer := (others => (others => '0'));
    attribute ram_style : string;
    attribute ram_style of data_buffer : signal is "block";
        
    signal read_addr      : unsigned(10 downto 0) := (others => '0');
    signal write_addr     : unsigned(10 downto 0) := (others => '0');
    signal committed_addr : unsigned(10 downto 0) := (others => '0');
    
    type s_read_state is (read_idle, read_reading, read_waiting);
    signal read_state : s_read_state  := read_idle;
    
    type s_write_state is (write_idle, write_writing, write_aborted);
    signal write_state : s_write_state  := write_idle;
    
    signal i_packet_out_valid   : std_logic := '0';         
    signal i_packet_out_data    : std_logic_vector(7 downto 0) := (others => '0');

    constant fcs_length        : integer := 4;
    constant interpacket_gap   : integer := 12; 
    constant for_next_preamble : integer := 8; 

    -- counter for the delay between packets
    signal read_pause : unsigned(5 downto 0) := (others => '0');
begin
    packet_out_valid <= i_packet_out_valid;
    packet_out_data  <= i_packet_out_data;

process(clk) 
    variable write_data : std_logic_vector(8 downto 0);
    begin
        if rising_edge(clk) then
            -------------------------------------------------
            -- Writing the data into the buffer. If the buffer
            -- would overrun the then packet is dropped (i.e.
            -- committed_addr will not be updated).
            ------------------------------------------------
            if write_state = write_writing or data_valid_in = '1' then 
                write_data := (others => '0');
                if data_valid_in = '1' then
                    write_data := data_valid_in & data_in;
                end if;
                data_buffer(to_integer(write_addr)) <= write_data;
            end if;
            
            case write_state is
                when write_writing =>
                    
                    if write_addr+1 = read_addr then
                        -------------------------------------------------------
                        -- If we would wrap around? Is so then abort the packet
                        -------------------------------------------------------
                        write_addr  <= committed_addr; 
                        write_state <= write_aborted;                     
                    else
                        write_addr <= write_addr + 1;
                        if data_valid_in = '0' then
                            committed_addr <= write_addr + 1;
                            write_state    <= write_idle;
                        end if;
                    end if;
                when write_aborted =>
                    ---------------------------------------------------------
                    -- Wait until the data_valid_in drop at the end of packet
                    ---------------------------------------------------------
                    if data_valid_in = '0' then
                        write_state <= write_idle;
                    end if;

                when others => -- write_idle state 
                    if data_valid_in = '1' then   
                        write_addr <= write_addr + 1;
                        write_state <= write_writing;
                    end if;
            end case;
            
            -------------------------------------------
            -- If data is committed in the buffer, then
            -- request the TX interface, and then start
            -- reading the data out of the buffer 
            -------------------------------------------
            case read_state is
                when read_reading =>
                    if(i_packet_out_valid = '0') then
                        read_state <= read_waiting;                      
                    else
                        i_packet_out_valid <= data_buffer(to_integer(read_addr))(8);
                        i_packet_out_data  <= data_buffer(to_integer(read_addr))(7 downto 0);
                        read_addr <= read_addr + 1;
                    end if;
                    
                when read_waiting =>
                    ---------------------------------------------------------
                    -- Add some 'empy space' for the frame check sequence,
                    -- interpacket gap and the preamble that will be appended
                    ---------------------------------------------------------
                    i_packet_out_valid   <= '0';
                    i_packet_out_data    <= (others => '0');
                    if read_pause = to_unsigned(fcs_length + interpacket_gap + for_next_preamble-1,6) then
                        read_state <= read_idle;
                        -- Release the output stream
                        packet_out_request <= '0';                 
                    else
                        read_pause <= read_pause + 1;
                    end if;
                    
                when others => --- For the read_idle state
                    -- Start counting from 2, as this causes the 'request' line    
                    -- to drop early enough to release the TX interface the   
                    -- cycle that the last word of the interpacket gap is sent.
                    read_pause <= (1 => '1', others => '0');
                    if read_addr = committed_addr then
                        -- Nothing to do
                        packet_out_request <= '0';    
                        i_packet_out_valid <= '0';
                        i_packet_out_data  <= (others => '0');
                    else
                        -- Ask for the TX interfaces
                        packet_out_request <= '1';  
                        if packet_out_granted = '1' then
                            -- Granted, so start sending! 
                            i_packet_out_valid <= data_buffer(to_integer(read_addr))(8);
                            i_packet_out_data  <= data_buffer(to_integer(read_addr))(7 downto 0);
                            read_addr <= read_addr + 1;
                            read_state <= read_reading;
                        end if;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;