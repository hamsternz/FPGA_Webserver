----------------------------------------------------------------------------------
-- Engineer: Mike Field<hamster@snap.net.nz> 
-- 
-- Module Name: rgmii_tx - Behavioral
--
-- Description: Low level interface to a RGMII Ethernet PHY 
-- 
------------------------------------------------------------------------------------
-- FPGA_Webserver from https://github.com/hamsternz/FPGA_Webserver
------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field <hamster@snap.net.nz>
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity tx_rgmii is
    Port ( clk         : in STD_LOGIC;
           clk90       : in STD_LOGIC;
           phy_ready   : in STD_LOGIC;

           data        : in STD_LOGIC_VECTOR (7 downto 0);
           data_valid  : in STD_LOGIC;
           data_enable : in STD_LOGIC := '1';
           data_error  : in STD_LOGIC;
           
           eth_txck    : out STD_LOGIC := '0';
           eth_txctl   : out STD_LOGIC := '0';
           eth_txd     : out STD_LOGIC_VECTOR (3 downto 0) := (others => '0'));
end tx_rgmii;

architecture Behavioral of tx_rgmii is
    signal enable_count        : unsigned(6 downto 0) := (others => '0');

    signal enable_frequency    : unsigned(6 downto 0) := (others => '1');
    signal times_3             : unsigned(8 downto 0) := (others => '0');
    signal first_quarter       : unsigned(6 downto 0) := (others => '0');
    signal second_quarter      : unsigned(6 downto 0) := (others => '0');
    signal third_quarter       : unsigned(6 downto 0) := (others => '0');

    signal dout1               : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal doutctl1            : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
    signal doutclk1            : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
    signal dout0               : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal doutctl0            : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
    signal doutclk0            : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
    signal hold_data           : STD_LOGIC_VECTOR (7 downto 0);
    signal hold_valid          : STD_LOGIC;
    signal hold_error          : STD_LOGIC;
    signal ok_to_send          : STD_LOGIC := '0';
    signal tx_ready            : STD_LOGIC;
    signal tx_ready_meta       : STD_LOGIC;

--    ATTRIBUTE IOB : STRING ;
--    ATTRIBUTE IOB OF dout    : signal IS "TRUE";
--    ATTRIBUTE IOB OF doutctl : signal IS "TRUE";
begin

    times_3 <= ("0" & enable_frequency & "0") + ("00" & enable_frequency);  
    -------------------------------------------------
    -- Map the data and control signals so that they
    -- can be sent via the DDR registers
    -------------------------------------------------
process(clk90)
    begin
        if rising_edge(clk90) then
            doutclk0 <= doutclk1;
        end if;
    end process;

process(clk)
    begin
        if rising_edge(clk) then
            -- one cycle delay to improve timing 
            dout0    <= dout1;
            doutctl0 <= doutctl1;

            first_quarter  <= "00" & enable_frequency(enable_frequency'high downto 2);
            second_quarter <= "0"  & enable_frequency(enable_frequency'high downto 1);
            third_quarter  <= times_3(times_3'high downto 2);
            if data_enable = '1' then
                enable_frequency <= enable_count+1;
                enable_count <= (others => '0');                
            elsif  enable_count /= "1111111" then
                enable_count <= enable_count + 1;
            end if;

            if data_enable = '1' then
                hold_data <= data;
                hold_valid <= data_valid;
                hold_error <= data_error;
                if enable_frequency = 1 then
                    -- Double data rate transfer at full frequency
                    dout1(3 downto 0) <= data(3 downto 0); 
                    dout1(7 downto 4) <= data(7 downto 4); 
                    doutctl1(0) <= ok_to_send and data_valid;
                    doutctl1(1) <= ok_to_send and (data_valid XOR data_error);
                    doutclk1(0) <= '1';
                    doutclk1(1) <= '0';
                else
                    -- Send the low nibble
                    dout1(3 downto 0) <= data(3 downto 0); 
                    dout1(7 downto 4) <= data(3 downto 0); 
                    doutctl1(0) <= ok_to_send and data_valid;
                    doutctl1(1) <= ok_to_send and data_valid;
                    doutclk1(0) <= '1';
                    doutclk1(1) <= '1';
                end if;
            elsif enable_count = first_quarter-1  then
                if enable_frequency(1) = '1' then
                    -- Send the high nibble and valid signal for the last half of this cycle
                    doutctl1(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk1(1) <= '0';
                else        
                    doutctl1(0) <= ok_to_send and (hold_valid XOR hold_error);
                    doutctl1(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk1(0) <= '0';
                    doutclk1(1) <= '0';
                end if;
            elsif enable_count = first_quarter  then
                doutctl1(0) <= ok_to_send and (hold_valid XOR hold_error);
                doutctl1(1) <= ok_to_send and (hold_valid XOR hold_error);
                doutclk1(0) <= '0';
                doutclk1(1) <= '0';
            elsif enable_count = second_quarter-1  then
                dout1(3 downto 0) <= hold_data(7 downto 4); 
                dout1(7 downto 4) <= hold_data(7 downto 4); 
               -- Send the high nibble and valid signal for the last half of this cycle
                doutclk1(0) <= '1';        
                doutclk1(1) <= '1';        
                doutctl1(0) <= ok_to_send and hold_valid;
                doutctl1(1) <= ok_to_send and hold_valid;
            elsif enable_count = third_quarter-1  then
                if enable_frequency(1) = '1' then
                    doutctl1(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk1(1) <= '0';
                else        
                    doutctl1(0) <= ok_to_send and (hold_valid XOR hold_error);
                    doutctl1(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk1(0) <= '0';
                    doutclk1(1) <= '0';
                end if;
            elsif enable_count = third_quarter  then
                doutclk1(0) <= '0';        
                doutclk1(1) <= '0';        
                doutctl1(0) <= ok_to_send and (hold_valid XOR hold_error);
                doutctl1(1) <= ok_to_send and (hold_valid XOR hold_error);
            end if;
        end if; 
    end process;

   ----------------------------------------------------
   -- DDR output registers 
   ----------------------------------------------------
tx_d0  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(0), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout0(0), D2 => dout0(4));
tx_d1  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(1), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout0(1), D2 => dout0(5));
tx_d2  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(2), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout0(2), D2 => dout0(6));
tx_d3  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(3), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout0(3), D2 => dout0(7));
tx_ctl : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txctl,   C  => clk, CE => '1', R  => '0', S  => '0', D1 => doutctl0(0), D2 => doutctl0(1));

tx_c   : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txck,  C  => clk90, CE => '1', R  => '0', S  => '0', D1 => doutclk0(0), D2 => doutclk0(1));
    
monitor_reset_state: process(clk)
    begin
       if rising_edge(clk) then
          tx_ready      <= tx_ready_meta;
          tx_ready_meta <= phy_ready;
          if tx_ready = '1' and data_valid = '0' and data_enable = '1' then
             ok_to_send    <= '1';
          end if;
       end if;
    end process;

end Behavioral;
