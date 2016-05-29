----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.05.2016 22:14:27
-- Design Name: 
-- Module Name: rgmii_tx - Behavioral
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

    signal dout                : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal doutctl             : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
    signal doutclk             : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
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
process(clk)
    begin
        if rising_edge(clk) then
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
                    dout(3 downto 0) <= data(3 downto 0); 
                    dout(7 downto 4) <= data(7 downto 4); 
                    doutctl(0) <= ok_to_send and data_valid;
                    doutctl(1) <= ok_to_send and (data_valid XOR data_error);
                    doutclk(0) <= '1';
                    doutclk(1) <= '0';
                else
                    -- Send the low nibble
                    dout(3 downto 0) <= data(3 downto 0); 
                    dout(7 downto 4) <= data(3 downto 0); 
                    doutctl(0) <= ok_to_send and data_valid;
                    doutctl(1) <= ok_to_send and data_valid;
                    doutclk(0) <= '1';
                    doutclk(1) <= '1';
                end if;
            elsif enable_count = first_quarter-1  then
                if enable_frequency(1) = '1' then
                    -- Send the high nibble and valid signal for the last half of this cycle
                    doutctl(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk(1) <= '0';
                else        
                    doutctl(0) <= ok_to_send and (hold_valid XOR hold_error);
                    doutctl(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk(0) <= '0';
                    doutclk(1) <= '0';
                end if;
            elsif enable_count = first_quarter  then
                doutctl(0) <= ok_to_send and (hold_valid XOR hold_error);
                doutctl(1) <= ok_to_send and (hold_valid XOR hold_error);
                doutclk(0) <= '0';
                doutclk(1) <= '0';
            elsif enable_count = second_quarter-1  then
                dout(3 downto 0) <= hold_data(7 downto 4); 
                dout(7 downto 4) <= hold_data(7 downto 4); 
               -- Send the high nibble and valid signal for the last half of this cycle
                doutclk(0) <= '1';        
                doutclk(1) <= '1';        
                doutctl(0) <= ok_to_send and hold_valid;
                doutctl(1) <= ok_to_send and hold_valid;
            elsif enable_count = third_quarter-1  then
                if enable_frequency(1) = '1' then
                    doutctl(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk(1) <= '0';
                else        
                    doutctl(0) <= ok_to_send and (hold_valid XOR hold_error);
                    doutctl(1) <= ok_to_send and (hold_valid XOR hold_error);
                    doutclk(0) <= '0';
                    doutclk(1) <= '0';
                end if;
            elsif enable_count = third_quarter  then
                doutclk(0) <= '0';        
                doutclk(1) <= '0';        
                doutctl(0) <= ok_to_send and (hold_valid XOR hold_error);
                doutctl(1) <= ok_to_send and (hold_valid XOR hold_error);
            end if;
        end if; 
    end process;

   ----------------------------------------------------
   -- DDR output registers 
   ----------------------------------------------------
tx_d0  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(0), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout(0), D2 => dout(4));
tx_d1  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(1), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout(1), D2 => dout(5));
tx_d2  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(2), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout(2), D2 => dout(6));
tx_d3  : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txd(3), C  => clk, CE => '1', R  => '0', S  => '0', D1 => dout(3), D2 => dout(7));
tx_ctl : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txctl,   C  => clk, CE => '1', R  => '0', S  => '0', D1 => doutctl(0), D2 => doutctl(1));

tx_c   : ODDR generic map( DDR_CLK_EDGE => "SAME_EDGE", INIT         => '0', SRTYPE       => "SYNC")
              port map (Q  => eth_txck,  C  => clk90, CE => '1', R  => '0', S  => '0', D1 => doutclk(0), D2 => doutclk(1));
    
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
