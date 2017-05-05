----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:32:07 05/04/2017 
-- Design Name: 
-- Module Name:    top - Behavioral 
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

entity top is
    port(
            CLK_MAIN    : in std_logic;
            CLK_MAIN_O  : out std_logic;
            LED         : out std_logic_vector(7 downto 0)
        );
end top;

architecture Behavioral of top is

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
                busy_o : OUT  std_logic
            );
    END COMPONENT;
-- [--/--]

-- [C][frequency_divider]
    component frequency_divider
        generic (div : natural range 0 to 10000);
        port (
                clk     : in std_logic;
                clk_o   : out std_logic
             );
    end component;
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
    signal h_byte_o        : std_logic_vector(7 downto 0);
    signal h_new_byte_o    : std_logic;
    signal h_busy_o        : std_logic;
-- [--/--]

-- [S][Device Inputs]
    signal d_byte_in       : std_logic_vector(7 downto 0);
    signal d_new_byte_in   : std_logic := '0';
-- [--/--]

-- [S][Device Outputs]
    signal d_byte_o        : std_logic_vector(7 downto 0);
    signal d_new_byte_o    : std_logic;
    signal d_busy_o        : std_logic;
-- [--/--]

-- [T][state]
    type t_state is (
        idle,
        h_strobe_1,
        h_strobe_11,
        h_strobe_0,
        d_waiting_new_byte
    );
-- [--/--]

-- [S][Internal signals]
    signal s_count              : natural range 0 to 1          := 0;
    signal s_internal_state     : t_state                       := idle;
    signal s_leds               : std_logic_vector(7 downto 0)  := "10101010";
    signal s_ps2_clk_in         : std_logic                     := '0';
-- [S][Internal signals]

begin

-- [I][freq_divider 25MHz]
    inst_freq_divider_0_04MHz: frequency_divider 
    generic map(div => 2)
    port map (
                 clk => CLK_MAIN,
                 clk_o => s_ps2_clk_in
             );
-- [--/--]

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
                                busy_o => h_busy_o
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
                                    busy_o => d_busy_o
                                );
-- [--/--]

-- [P][General]
    process(CLK_MAIN)
    begin
        if rising_edge(CLK_MAIN)
        then
            case s_internal_state is
                when idle =>
                    if s_count < 1
                    then
                        s_count <= s_count + 1;
                        s_internal_state <= h_strobe_1;
                    end if;
                when h_strobe_1 =>
                    h_byte_in <= "01110110";
                    --h_byte_in <= "00000000";
                    h_new_byte_in <= '1';
                    s_internal_state <= h_strobe_11;
                when h_strobe_11 =>
                    s_internal_state <= h_strobe_0;
                when h_strobe_0 =>
                    h_new_byte_in <= '0';
                    s_internal_state <= d_waiting_new_byte;
                when d_waiting_new_byte =>
                    if (d_new_byte_o = '1')
                    then
                        s_leds <= d_byte_o;
                        s_internal_state <= idle;
                    end if;
            end case;
        end if;
        -- LED <= s_leds;
        LED <= x"A1";
    end process;
-- [--/--]

    CLK_MAIN_O <= CLK_MAIN;

end Behavioral;
