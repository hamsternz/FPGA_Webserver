----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.06.2016 06:25:44
-- Design Name: 
-- Module Name: tcp_engine_tx_fifo - Behavioral
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

entity tcp_engine_tx_fifo is
    Port ( clk : in STD_LOGIC;
        write_en         : in  std_logic := '0';
        full             : out std_logic := '0';
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
        
        read_en           : in  std_logic := '0';
        empty             : out std_logic := '0';
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
        out_data_addr     : out  std_logic_vector(15 downto 0) := (others => '0');
        out_data_len      : out  std_logic_vector(10 downto 0) := (others => '0'));
end tcp_engine_tx_fifo;

architecture Behavioral of tcp_engine_tx_fifo is
    component fifo_32 is
    port (
        clk      : in  std_logic;
        
        full     : out std_logic;
        write_en : in  std_logic;
        data_in  : in  std_logic_vector;
        
        empty    : out std_logic;
        read_en  : in  std_logic; 
        data_out : out  std_logic_vector);
    end component;

    signal data_in  : std_logic_vector(192 downto 0) := (others => '0');
    signal data_out : std_logic_vector(192 downto 0) := (others => '0');
begin
    out_data_addr     <= data_out(192 downto 177);
    out_data_len      <= data_out(176 downto 166);
    out_src_port      <= data_out(165 downto 150);
    out_dst_ip        <= data_out(149 downto 118);
    out_dst_port      <= data_out(117 downto 102);    
    out_seq_num       <= data_out(101 downto 70);
    out_ack_num       <= data_out(69 downto 38);
    out_window        <= data_out(37 downto 22);
    out_flag_urg      <= data_out(21);
    out_flag_ack      <= data_out(20);
    out_flag_psh      <= data_out(19);
    out_flag_rst      <= data_out(18);
    out_flag_syn      <= data_out(17);
    out_flag_fin      <= data_out(16);
    out_urgent_ptr    <= data_out(15 downto 0);    

    data_in <=  in_data_addr
             &  in_data_len
             &  in_src_port
             &  in_dst_ip
             &  in_dst_port    
             &  in_seq_num
             &  in_ack_num
             &  in_window 
             &  in_flag_urg
             &  in_flag_ack 
             &  in_flag_psh
             &  in_flag_rst
             &  in_flag_syn 
             &  in_flag_fin
             &  in_urgent_ptr;    

i_generic_fifo: fifo_32
    port map (
        clk      => clk,
        full     => full,
        write_en => write_en,
        data_in  => data_in,
        empty    => empty,
        read_en  => read_en, 
        data_out => data_out);
end Behavioral;
