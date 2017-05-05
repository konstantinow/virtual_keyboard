--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:07:24 04/29/2017
-- Design Name:   
-- Module Name:   C:/Users/Witaliy/Desktop/ISE/project/keyboard/tb_ps2_host_transmitting.vhd
-- Project Name:  keyboard
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: PS2_HOST
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
 
ENTITY tb_ps2_host_transmitting IS
END tb_ps2_host_transmitting;
 
ARCHITECTURE behavior OF tb_ps2_host_transmitting IS 
 
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
 
    COMPONENT PS2_HOST
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

   signal clk_main_in   : std_logic;
   signal ps2_clk_in    : std_logic;
	--BiDirs
   signal ps2_clk       : std_logic;
   signal ps2_data      : std_logic;
                       --Host
   --Inputs
   signal h_byte_in       : std_logic_vector(7 downto 0);
   signal h_new_byte_in   : std_logic;

 	--Outputs
   signal h_byte_o        : std_logic_vector(7 downto 0);
   signal h_new_byte_o    : std_logic;
   signal h_busy_o        : std_logic;

                       --Device
   --Inputs
   signal d_byte_in       : std_logic_vector(7 downto 0);
   signal d_new_byte_in   : std_logic := '0';

 	--Outputs
   signal d_byte_o        : std_logic_vector(7 downto 0);
   signal d_new_byte_o    : std_logic;
   signal d_busy_o        : std_logic;

   -- Clock period definitions
   constant clk_main_in_period  : time := 10 ns;
   constant ps2_clk_in_period   : time := 40 ns;
 
BEGIN
 
   host: PS2_HOST PORT MAP (
          ps2_clk => ps2_clk,
          ps2_data => ps2_data,
          clk_main_in => clk_main_in,
          ps2_clk_in => ps2_clk_in,
          byte_in => h_byte_in,
          new_byte_in => h_new_byte_in,
          byte_o => h_byte_o,
          new_byte_o => h_new_byte_o,
          busy_o => h_busy_o
        );

   device: PS2_DEVICE PORT MAP (
          ps2_clk => ps2_clk,
          ps2_data => ps2_data,
          clk_main_in => clk_main_in,
          ps2_clk_in => ps2_clk_in,
          byte_in => d_byte_in,
          new_byte_in => d_new_byte_in,
          byte_o => d_byte_o,
          new_byte_o => d_new_byte_o,
          busy_o => d_busy_o
        );


   -- Clock process definitions
   ps2_clk_in_process :process
   begin
		ps2_clk_in <= '0';
		wait for ps2_clk_in_period/2;
		ps2_clk_in <= '1';
		wait for ps2_clk_in_period/2;
   end process;
 

   clk_main_in_process :process
   begin
		clk_main_in <= '0';
		wait for clk_main_in_period/2;
		clk_main_in <= '1';
		wait for clk_main_in_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for ps2_clk_in_period*10;

      h_byte_in <= "11111110";
      h_new_byte_in <= '1';
      wait for 20 ns;	
      h_new_byte_in <= '0';

      wait;
   end process;

END;
