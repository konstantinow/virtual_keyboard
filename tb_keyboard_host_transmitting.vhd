--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   06:28:17 05/22/2017
-- Design Name:   
-- Module Name:   C:/Users/Witaliy/Desktop/ISE/project/keyboard/tb_keyboard_host_transmitting.vhd
-- Project Name:  keyboard
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: KEYBOARD_HOST
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
 
ENTITY tb_keyboard_host_transmitting IS
END tb_keyboard_host_transmitting;
 
ARCHITECTURE behavior OF tb_keyboard_host_transmitting IS 
 
    COMPONENT KEYBOARD_HOST
    PORT(
         clk_main : IN  std_logic;
         ps2_clk : INOUT  std_logic;
         ps2_data : INOUT  std_logic;
         data_in : IN  std_logic_vector(63 downto 0);
         data_length_in : IN  std_logic_vector(2 downto 0);
         new_data_in : IN  std_logic;
         run_init_in : IN  std_logic;
         host_busy_o : OUT  std_logic
        );
    END COMPONENT;

-- [C][PS2_DEVICE]
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
-- [--/--]

   --Inputs
   signal clk_main : std_logic := '0';
   signal s_ps2_clk_in : std_logic := '0';
   signal data_in : std_logic_vector(63 downto 0) := (others => '0');
   signal data_length_in : std_logic_vector(2 downto 0) := (others => '0');
   signal new_data_in : std_logic := '0';
   signal run_init_in : std_logic := '0';

	--BiDirs
   signal ps2_clk : std_logic;
   signal ps2_data : std_logic;

 	--Outputs
   signal host_busy_o : std_logic;

   -- Clock period definitions
   constant clk_main_period : time := 10 ns;
 
    signal s_divider_count      : natural range 0 to 4000       := 0;

    constant DIVIDER_DIV        : natural range 0 to 4000       := 4000;

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: KEYBOARD_HOST PORT MAP (
          clk_main => clk_main,
          ps2_clk => ps2_clk,
          ps2_data => ps2_data,
          data_in => data_in,
          data_length_in => data_length_in,
          new_data_in => new_data_in,
          run_init_in => run_init_in,
          host_busy_o => host_busy_o
        );

-- [I][device]
    device: PS2_DEVICE PORT MAP (
                                    ps2_clk => ps2_clk,
                                    ps2_data => ps2_data,
                                    clk_main_in => CLK_MAIN,
                                    ps2_clk_in => s_ps2_clk_in,
                                    byte_in => x"00",
                                    new_byte_in => '0',
                                    byte_o => open,
                                    new_byte_o => open,
                                    busy_o => open
                                );
-- [--/--]

   -- Clock process definitions
   clk_main_process :process
   begin
		clk_main <= '0';
		wait for clk_main_period/2;
		clk_main <= '1';
		wait for clk_main_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
      data_in(23 downto 0) <= "10101011" & "00000001" & "11110000";
      data_length_in <= "011";
      new_data_in <= '1';
      wait for clk_main_period * 2;
      new_data_in <= '0';

      wait for 3000 us;

      data_in(15 downto 0) <= "11110000" & "00001111";
      data_length_in <= "010";
      new_data_in <= '1';
      wait for clk_main_period * 2;
      new_data_in <= '0';

      wait;
   end process;

-- [P][clk_main_in][GENERATOR - 0.0125MHz]
    process(CLK_MAIN)
    begin
        if rising_edge(CLK_MAIN)
        then
            if s_divider_count = DIVIDER_DIV - 1
            then
                s_divider_count <= 0;
            else
                s_divider_count <= s_divider_count + 1;
            end if;
        end if;
    end process;
-- [--/--]

    s_ps2_clk_in <= '1' when s_divider_count < DIVIDER_DIV/2 else '0';

END;
