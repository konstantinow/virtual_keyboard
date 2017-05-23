library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity KEYBOARD_HOST is
    port(
        clk_main            : in std_logic;

        ps2_clk             : inout std_logic;
        ps2_data            : inout std_logic;

        data_in             : in std_logic_vector(63 downto 0);
        data_length_in      : in std_logic_vector(2 downto 0);
        new_data_in         : in std_logic; -- rising_edge

        run_init_in         : in std_logic; -- rising_edge

        host_busy_o         : out std_logic := '0'
        );
end KEYBOARD_HOST;

architecture Behavioral of KEYBOARD_HOST is

-- [C][PS2]
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

-- [T][host_state]
    type type_host_state is (
        idle,
        transmitting,
        receiving
    );
-- [--/--]

-- [S][PS2]
    signal s_ps2_byte_in        : std_logic_vector(7 downto 0);
    signal s_ps2_new_byte_in    : std_logic;

    signal s_ps2_byte_o             : std_logic_vector(7 downto 0);
    signal s_ps2_new_byte_o         : std_logic;
    signal s_ps2_busy_o             : std_logic;
    signal s_ps2_prev_busy_o        : std_logic;
    signal s_ps2_clk_in_0_0125MHz   : std_logic;
-- [--/--]

-- [S][TRANSMITTING]
    signal s_host_state         : type_host_state := idle;
-- [--/--]

-- [S][TRANSMITTING]
    signal s_t_prev_new_data_in : std_logic;
    signal s_t_data_in          : std_logic_vector(63 downto 0);
    signal s_t_data_length_in   : natural range 0 to 8;
    signal s_t_index_data       : natural range 0 to 8          :=  0;
    signal s_t_run_transmitting : std_logic                     := '0';
    signal s_t_end_transmitting : std_logic                     := '0';
    signal s_t_ps2_readed_byte  : std_logic                     := '1';
-- [--/--]

-- [S][Internal signals]
    signal s_divider_count      : natural range 0 to 4000       := 0;
-- [--/--]

    constant DIVIDER_DIV        : natural range 0 to 4000       := 4000;

begin

-- [I][host]
    host: PS2_HOST PORT MAP (
                                ps2_clk => ps2_clk,
                                ps2_data => ps2_data,
                                clk_main_in => clk_main,
                                ps2_clk_in => s_ps2_clk_in_0_0125MHz,
                                byte_in => s_ps2_byte_in,
                                new_byte_in => s_ps2_new_byte_in,
                                byte_o => s_ps2_byte_o,
                                new_byte_o => s_ps2_new_byte_o,
                                busy_o => s_ps2_busy_o
                            );
-- [--/--]

-- [P][clk_main][Detect transmitting HOST -> KEYBOARD]
    process(clk_main)
    begin
        if rising_edge(clk_main)
        then
            s_t_run_transmitting <= '0'; --Default value.
            if new_data_in /= s_t_prev_new_data_in and new_data_in = '1'
            then
                s_t_data_in <= data_in;
                s_t_data_length_in <= to_integer(unsigned(data_length_in));
                s_t_run_transmitting <= '1';
            end if;
        s_t_prev_new_data_in <= new_data_in;
        end if;
    end process;
-- [--/--]

-- [P][clk_main][Set host state]
    process(clk_main)
    begin
        if rising_edge(clk_main)
        then
            if s_t_run_transmitting = '1' and s_host_state = idle
            then
                s_host_state <= transmitting;
            elsif s_t_end_transmitting = '1'
            then
                s_host_state <= idle;
            end if;
        end if;
    end process;
-- [--/--]

-- [P][clk_main][Transmitting HOST -> KEYBOARD]
    process(clk_main)
    begin
        if rising_edge(clk_main)
        then
            s_t_end_transmitting <= '0'; -- Default value
            s_ps2_new_byte_in <= '0'; -- Default value
            s_t_ps2_readed_byte <= '1'; -- Default value

            if s_host_state = transmitting and s_ps2_busy_o = '0' and s_t_ps2_readed_byte = '1' and s_t_end_transmitting = '0'
            then
                if s_t_index_data < s_t_data_length_in
                then
                    s_ps2_byte_in <= s_t_data_in(s_t_index_data*8 + 7 downto s_t_index_data*8);
                    s_ps2_new_byte_in <= '1';
                    s_t_index_data <= s_t_index_data + 1;
                    s_t_ps2_readed_byte <= '0';
                else
                    s_t_index_data <= 0;
                    s_t_end_transmitting <= '1';
                end if;
            end if;
        end if;
        s_ps2_prev_busy_o <= s_ps2_busy_o;
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

    s_ps2_clk_in_0_0125MHz <= '1' when s_divider_count < DIVIDER_DIV/2 else '0';

    host_busy_o <= '0' when (s_host_state = idle) else '1';

end Behavioral;
