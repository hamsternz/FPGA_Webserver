----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.06.2016 06:22:11
-- Design Name: 
-- Module Name: tb_tcp_engine_add_data - Behavioral
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

entity tb_tcp_engine_add_data is
end tb_tcp_engine_add_data;

architecture Behavioral of tb_tcp_engine_add_data is
    component tcp_engine_add_data is
    Port ( clk : in STD_LOGIC;
        read_en          : out std_logic := '0';
        empty            : in  std_logic := '0';
        
        in_src_port      : in  std_logic_vector(15 downto 0) := (others => '0');
        in_dst_ip        : in  std_logic_vector(31 downto 0) := (others => '0');
        in_dst_port      : in  std_logic_vector(15 downto 0) := (others => '0');    
        in_seq_num       : in  std_logic_vector(31 downto 0) := (others => '0');
        in_ack_num       : in  std_logic_vector(31 downto 0) := (others => '0');
        in_window        : in  std_logic_vector(15 downto 0) := (others => '0');
        in_flag_urg      : in  std_logic := '0';
        in_flag_ack      : in  std_logic := '0';
        in_flag_psh      : in  std_logic := '0';
        in_flag_rst      : in  std_logic := '0';
        in_flag_syn      : in  std_logic := '0';
        in_flag_fin      : in  std_logic := '0';
        in_urgent_ptr    : in  std_logic_vector(15 downto 0) := (others => '0');    
        in_data_addr     : in  std_logic_vector(15 downto 0) := (others => '0');
        in_data_len      : in  std_logic_vector(10 downto 0) := (others => '0');
        
        out_hdr_valid     : out  std_logic := '0';
        out_src_port      : out std_logic_vector(15 downto 0) := (others => '0');
        out_dst_ip        : out std_logic_vector(31 downto 0) := (others => '0');
        out_dst_port      : out std_logic_vector(15 downto 0) := (others => '0');    
        out_seq_num       : out std_logic_vector(31 downto 0) := (others => '0');
        out_ack_num       : out std_logic_vector(31 downto 0) := (others => '0');
        out_window        : out std_logic_vector(15 downto 0) := (others => '0');
        out_flag_urg      : out std_logic := '0';
        out_flag_ack      : out std_logic := '0';
        out_flag_psh      : out std_logic := '0';
        out_flag_rst      : out std_logic := '0';
        out_flag_syn      : out std_logic := '0';
        out_flag_fin      : out std_logic := '0';
        out_urgent_ptr    : out std_logic_vector(15 downto 0) := (others => '0');    
        out_data_valid    : out std_logic := '0';
        out_data          : out std_logic_vector(7 downto 0) := (others => '0'));
    end component;

    signal clk              : STD_LOGIC;
    signal read_en          : std_logic := '0';
    signal empty            : std_logic := '1';
    signal count            : integer := 0;
        
    signal in_src_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal in_dst_ip        : std_logic_vector(31 downto 0) := (others => '0');
    signal in_dst_port      : std_logic_vector(15 downto 0) := (others => '0');    
    signal in_seq_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal in_ack_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal in_window        : std_logic_vector(15 downto 0) := (others => '0');
    signal in_flag_urg      : std_logic := '0';
    signal in_flag_ack      : std_logic := '0';
    signal in_flag_psh      : std_logic := '0';
    signal in_flag_rst      : std_logic := '0';
    signal in_flag_syn      : std_logic := '0';
    signal in_flag_fin      : std_logic := '0';
    signal in_urgent_ptr    : std_logic_vector(15 downto 0) := (others => '0');    
    signal in_data_addr     : std_logic_vector(15 downto 0) := (others => '0');
    signal in_data_len      : std_logic_vector(10 downto 0) := (others => '0');
        
    signal out_hdr_valid     : std_logic := '0';
    signal out_src_port      : std_logic_vector(15 downto 0) := (others => '0');
    signal out_dst_ip        : std_logic_vector(31 downto 0) := (others => '0');
    signal out_dst_port      : std_logic_vector(15 downto 0) := (others => '0');    
    signal out_seq_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal out_ack_num       : std_logic_vector(31 downto 0) := (others => '0');
    signal out_window        : std_logic_vector(15 downto 0) := (others => '0');
    signal out_flag_urg      : std_logic := '0';
    signal out_flag_ack      : std_logic := '0';
    signal out_flag_psh      : std_logic := '0';
    signal out_flag_rst      : std_logic := '0';
    signal out_flag_syn      : std_logic := '0';
    signal out_flag_fin      : std_logic := '0';
    signal out_urgent_ptr    : std_logic_vector(15 downto 0) := (others => '0');    
    signal out_data_valid    : std_logic := '0';
    signal out_data          : std_logic_vector(7 downto 0) := (others => '0');
begin

process
    begin
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
    end process;

clk_proc: process(clk)
    begin
        if rising_edge(clk) then
            if count = 49 then
                empty <= '0';
                count <= 0;
            else
                count <= count + 1;
            end if;
            
            if read_en = '1' and empty = '0' then              
                in_src_port <= std_logic_vector(unsigned(in_src_port)+1);
                in_dst_port <= std_logic_vector(unsigned(in_dst_port)+1);
                in_data_len <= "00000010000";
                empty <= '1';
            end if; 
        end if;
    end process;

uut: tcp_engine_add_data port map (
        clk            => clk,

        read_en        => read_en,
        empty          => empty,

        in_src_port    => in_dst_port,
        in_dst_ip      => in_dst_ip,
        in_dst_port    => in_dst_port,    
        in_seq_num     => in_seq_num,
        in_ack_num     => in_ack_num,
        in_window      => in_window,
        in_flag_urg    => in_flag_urg,
        in_flag_ack    => in_flag_ack,
        in_flag_psh    => in_flag_psh,
        in_flag_rst    => in_flag_rst,
        in_flag_syn    => in_flag_syn,
        in_flag_fin    => in_flag_fin,
        in_urgent_ptr  => in_urgent_ptr,    
        in_data_addr   => in_data_addr,
        in_data_len    => in_data_len,
        
        out_hdr_valid  => out_hdr_valid, 
        out_src_port   => out_src_port,
        out_dst_ip     => out_dst_ip,
        out_dst_port   => out_dst_port,    
        out_seq_num    => out_seq_num,
        out_ack_num    => out_ack_num,
        out_window     => out_window,
        out_flag_urg   => out_flag_urg,
        out_flag_ack   => out_flag_ack,
        out_flag_psh   => out_flag_psh,
        out_flag_rst   => out_flag_rst,
        out_flag_syn   => out_flag_syn,
        out_flag_fin   => out_flag_fin,
        out_urgent_ptr => out_urgent_ptr,    
        out_data       => out_data,
        out_data_valid => out_data_valid);

end Behavioral;
