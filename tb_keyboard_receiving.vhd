--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   08:50:36 05/06/2017
-- Design Name:   
-- Module Name:   C:/Users/Witaliy/Desktop/ISE/project/keyboard/tb_keyboard_receiving.vhd
-- Project Name:  keyboard
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: KEYBOARD
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

ENTITY tb_keyboard_receiving IS
    END tb_keyboard_receiving;

ARCHITECTURE behavior OF tb_keyboard_receiving IS 


-- [C][Keyboard]
    COMPONENT KEYBOARD
        PORT(
                clk_main : IN  std_logic;
                ps2_clk : INOUT  std_logic;
                ps2_data : INOUT  std_logic;
                data_in : IN  std_logic_vector(63 downto 0);
                data_length_in : IN  std_logic_vector(2 downto 0);
                new_data_in : IN  std_logic;
                is_init : OUT  std_logic;
                caps_lock : OUT  std_logic;
                num_lock : OUT  std_logic;
                keyboard_busy_o : OUT  std_logic
            );
    END COMPONENT;
-- [--/--]

-- [C][Host]
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
-- [--/--]

-- [T][state]
    type type_state is (
        t_0_set_new_byte_in,
        done
    );
-- [--/--]

-- [S][Internal signals]
    signal clk_main : std_logic := '0';
    signal s_state  :   type_state  := t_0_set_new_byte_in;
-- [--/--]

-- [S][BiDirs]
    signal ps2_clk : std_logic;
    signal ps2_data : std_logic;
-- [--/--]

-- [S][Keyboard]
    signal k_data_in : std_logic_vector(63 downto 0) := (others => '0');
    signal k_data_length_in : std_logic_vector(2 downto 0) := (others => '0');
    signal k_new_data_in : std_logic := '0';

    signal k_is_init : std_logic;
    signal k_caps_lock : std_logic;
    signal k_num_lock : std_logic;
    signal k_keyboard_busy_o : std_logic;
-- [--/--]

-- [S][Host]
    signal h_data_in : std_logic_vector(63 downto 0) := (others => '0');
    signal h_data_length_in : std_logic_vector(2 downto 0) := (others => '0');
    signal h_new_data_in : std_logic := '0';

    signal h_run_init_in : std_logic;
    signal h_host_busy_o : std_logic;
-- [--/--]

   -- Clock period definitions
    constant clk_main_period : time := 10 ns;
    constant ps2_clk_period : time := 10 ns;

BEGIN

-- [I][Keyboard]
    i_keyboard: KEYBOARD PORT MAP (
                                    clk_main => clk_main,
                                    ps2_clk => ps2_clk,
                                    ps2_data => ps2_data,
                                    data_in => k_data_in,
                                    data_length_in => k_data_length_in,
                                    new_data_in => k_new_data_in,
                                    is_init => k_is_init,
                                    caps_lock => k_caps_lock,
                                    num_lock => k_num_lock,
                                    keyboard_busy_o => k_keyboard_busy_o
                                );
-- [--/--]

-- [I][Host]
    i_host: KEYBOARD_HOST PORT MAP (
                                clk_main => clk_main,
                                ps2_clk => ps2_clk,
                                ps2_data => ps2_data,
                                data_in => h_data_in,
                                data_length_in => h_data_length_in,
                                new_data_in => h_new_data_in,
                                run_init_in => h_run_init_in,
                                host_busy_o => h_host_busy_o
                            );
-- [--/--]

    clk_main_process :process
    begin
        clk_main <= '0';
        wait for clk_main_period/2;
        clk_main <= '1';
        wait for clk_main_period/2;
    end process;

    stim_proc: process
    begin		
        wait for 100 ns;	

        case s_state is
            when t_0_set_new_byte_in =>
                h_new_data_in <= '0';
                h_data_in <= x"0000000000" & "000011110101010110101010";
                h_data_length_in <= "011";
                h_new_data_in <= '1';
                wait for 100 ns;
                h_new_data_in <= '0';
                s_state <= done;
            when done =>
                null;
        end case;

        wait;
    end process;

END;
