--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:26:01 05/16/2017
-- Design Name:   
-- Module Name:   C:/Users/Witaliy/Desktop/ISE/project/keyboard/tb_top2.vhd
-- Project Name:  keyboard
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top
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
 
ENTITY tb_top2 IS
END tb_top2;
 
ARCHITECTURE behavior OF tb_top2 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top
    PORT(
         CLK_MAIN : IN  std_logic;
         CLK_MAIN_O : OUT  std_logic;
         LED : OUT  std_logic_vector(7 downto 0);
         d_ps2_clk : OUT std_logic;
         d_ps2_data : OUT std_logic;
         d_d_new_byte_in : out std_logic;
         d_h_busy_o      : out std_logic;
         BTN_SOUTH : in std_logic
        );
    END COMPONENT;

   --Inputs
   signal CLK_MAIN : std_logic := '0';

 	--Outputs
   signal CLK_MAIN_O : std_logic;
   signal LED : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant CLK_MAIN_period : time := 20 ns;
   constant CLK_MAIN_O_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          CLK_MAIN => CLK_MAIN,
          CLK_MAIN_O => CLK_MAIN_O,
          LED => LED,
          d_ps2_clk => open,
          d_ps2_data => open,
         d_d_new_byte_in => open,
         d_h_busy_o => open,
         BTN_SOUTH => '0'
        );

   -- Clock process definitions
   CLK_MAIN_process :process
   begin
		CLK_MAIN <= '0';
		wait for CLK_MAIN_period/2;
		CLK_MAIN <= '1';
		wait for CLK_MAIN_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_MAIN_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
