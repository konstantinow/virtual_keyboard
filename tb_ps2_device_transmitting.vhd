--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:04:16 04/29/2017
-- Design Name:   
-- Module Name:   C:/Users/Witaliy/Desktop/ISE/project/keyboard/tb_ps2_device_transmitting.vhd
-- Project Name:  keyboard
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: PS2_DEVICE
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_ps2_device_transmitting IS
END tb_ps2_device_transmitting;
 
ARCHITECTURE behavior OF tb_ps2_device_transmitting IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT PS2_DEVICE
    PORT(
         ps2_clk : INOUT  std_logic;
         ps2_data : INOUT  std_logic;
         clk_main_in : IN  std_logic;
         ps2_clk_in : IN  std_logic;
         byte_in : IN  std_logic_vector(7 downto 0);
         new_byte_in : IN  std_logic;
         byte_o : OUT  std_logic_vector(7 downto 0);
         new_byte_o : OUT  std_logic;
         busy_o : OUT  std_logic
        );
    END COMPONENT;

   --Inputs
   signal clk_main_in   : std_logic;
   signal ps2_clk_in    : std_logic;
   signal byte_in       : std_logic_vector(7 downto 0);
   signal new_byte_in   : std_logic := '0';

	--BiDirs
   signal ps2_clk       : std_logic;
   signal ps2_data      : std_logic;

 	--Outputs
   signal byte_o        : std_logic_vector(7 downto 0);
   signal new_byte_o    : std_logic;
   signal busy_o        : std_logic;

   -- Clock period definitions
   constant ps2_clk_in_period   : time := 100 ns;
   constant clk_main_in_period  : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: PS2_DEVICE PORT MAP (
          ps2_clk => ps2_clk,
          ps2_data => ps2_data,
          clk_main_in => clk_main_in,
          ps2_clk_in => ps2_clk_in,
          byte_in => byte_in,
          new_byte_in => new_byte_in,
          byte_o => byte_o,
          new_byte_o => new_byte_o,
          busy_o => busy_o
        );

   -- Clock process definitions
   ps2_clk_in_process :process
   begin
		ps2_clk_in <= '0';
		wait for ps2_clk_in_period;
		ps2_clk_in <= '1';
		wait for ps2_clk_in_period;
   end process;
 
   clk_main_in_process :process
   begin
		clk_main_in <= '0';
		wait for clk_main_in_period;
		clk_main_in <= '1';
		wait for clk_main_in_period;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for ps2_clk_in_period*10;

      byte_in <= "10000111";
      new_byte_in <= '1';
      wait for 10 ns;	
      new_byte_in <= '0';

      --wait for 40 ns;	
      --byte_in <= "11110000";
      --new_byte_in <= '1';
      --wait for 10 ns;	
      --new_byte_in <= '0';

      wait;
   end process;

END;
