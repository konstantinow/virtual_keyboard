----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    07:49:38 05/18/2017 
-- Design Name: 
-- Module Name:    top_host_receive - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_host_receive is
    port(
            CLK_MAIN    : in std_logic;
            CLK_MAIN_O  : out std_logic;
            LED         : out std_logic_vector(7 downto 0)
        );
end top_host_receive;

architecture Behavioral of top_host_receive is

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
                busy_o : OUT  std_logic;
                test1 : OUT std_logic;
                test2 : OUT std_logic;
                test3 : OUT std_logic;
                test4 : OUT std_logic
            );
    END COMPONENT;
-- [--/--]

-- [C][PS2_HOST]
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
                busy_o : OUT  std_logic;
                test1 : OUT std_logic;
                test2 : OUT std_logic;
                test3 : OUT std_logic;
                test4 : OUT std_logic
            );
    END COMPONENT;
-- [--/--]

-- [S][BiDirs]
    signal ps2_clk       : std_logic;
    signal ps2_data      : std_logic;
-- [--/--]

-- [S][HOST Inputs]
    signal h_byte_in       : std_logic_vector(7 downto 0);
    signal h_new_byte_in   : std_logic;
-- [--/--]

-- [S][HOST Outputs]
    signal h_byte_o         : std_logic_vector(7 downto 0);
    signal h_new_byte_o     : std_logic;
    signal h_busy_o         : std_logic;
    signal h_test1          : std_logic := '0';
    signal h_test2          : std_logic := '0';
    signal h_test3          : std_logic := '0';
    signal h_test4          : std_logic := '0';
-- [--/--]

-- [S][Device Inputs]
    signal d_byte_in       : std_logic_vector(7 downto 0);
    signal d_new_byte_in   : std_logic := '0';
-- [--/--]

-- [S][Device Outputs]
    signal d_byte_o         : std_logic_vector(7 downto 0);
    signal d_new_byte_o     : std_logic;
    signal d_busy_o         : std_logic;
    signal d_test1          : std_logic := '0';
    signal d_test2          : std_logic := '0';
    signal d_test3          : std_logic := '0';
    signal d_test4          : std_logic := '0';
-- [--/--]

    signal d_led7          : std_logic := '0'; --test1
    signal d_led6          : std_logic := '0'; --test2
    signal d_led5          : std_logic := '0'; --test3
    signal d_led4          : std_logic := '0'; --test4

    signal h_led3          : std_logic := '0'; --test1
    signal h_led2          : std_logic := '0'; --test2
    signal h_led1          : std_logic := '0'; --test3
    signal h_led0          : std_logic := '0'; --test4

-- [T][state]
    type t_state is (
        h_strobe_1,
        h_strobe_11,
        h_strobe_0,
        d_waiting_new_byte
    );
-- [--/--]

-- [S][Internal signals]
    signal s_count              : natural range 0 to 1          := 0;
    signal s_internal_state     : t_state                       := h_strobe_1;
    signal s_leds               : std_logic_vector(7 downto 0)  := "10101010";
    signal s_ps2_clk_in         : std_logic                     := '0';
    signal s_divider_count      : natural range 0 to 4000       := 0;
-- [S][Internal signals]

    constant DIVIDER_DIV    : natural range 0 to 4000   := 4000;

begin

-- [I][host]
    host: PS2_HOST PORT MAP (
                                ps2_clk => ps2_clk,
                                ps2_data => ps2_data,
                                clk_main_in => CLK_MAIN,
                                ps2_clk_in => s_ps2_clk_in,
                                byte_in => h_byte_in,
                                new_byte_in => h_new_byte_in,
                                byte_o => h_byte_o,
                                new_byte_o => h_new_byte_o,
                                busy_o => h_busy_o,
                                test1 => h_test1,
                                test2 => h_test2,
                                test3 => h_test3,
                                test4 => h_test4
                            );
-- [--/--]

-- [I][device]
    device: PS2_DEVICE PORT MAP (
                                    ps2_clk => ps2_clk,
                                    ps2_data => ps2_data,
                                    clk_main_in => CLK_MAIN,
                                    ps2_clk_in => s_ps2_clk_in,
                                    byte_in => d_byte_in,
                                    new_byte_in => d_new_byte_in,
                                    byte_o => d_byte_o,
                                    new_byte_o => d_new_byte_o,
                                    busy_o => d_busy_o,
                                    test1 => d_test1,
                                    test2 => d_test2,
                                    test3 => d_test3,
                                    test4 => d_test4
                                );
-- [--/--]

-- [P][General]
    process(CLK_MAIN)
    begin
        if rising_edge(CLK_MAIN)
        then
            case s_internal_state is
                when h_strobe_1 =>
                    d_byte_in <= "00010100";
                    d_new_byte_in <= '1';
                    s_internal_state <= h_strobe_11;
                when h_strobe_11 =>
                    s_internal_state <= h_strobe_0;
                when h_strobe_0 =>
                    d_new_byte_in <= '0';
                    s_internal_state <= d_waiting_new_byte;
                when d_waiting_new_byte =>
                    if (h_new_byte_o = '1')
                    then
                        s_leds <= h_byte_o;
                    end if;
            end case;

            --------------------------------
            d_led7 <= d_test1;

            if d_test2 = '1'
            then
                d_led6 <= '1';
            end if;


            if d_test3 = '1'
            then
                d_led5 <= '1';
            end if;


            if d_test4 = '1'
            then
                d_led4 <= '1';
            end if;
            --------------------------------

            --------------------------------
            if h_test1 = '1'
            then
                h_led3 <= '1';
            end if;

            if h_test2 = '1'
            then
                h_led2 <= '1';
            end if;

            if h_test3 = '1'
            then
                h_led1 <= '1';
            end if;

            if h_test4 = '1'
            then
                h_led0 <= '0';
            end if;
            --------------------------------

            -- LED <= h_led0 & h_led1 & h_led2 & h_led3 & d_led4 & d_led5 & d_led6 & d_led7;
            LED <= s_leds;
        end if;
    end process;
-- [--/--]

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

    CLK_MAIN_O <= CLK_MAIN;

end Behavioral;
