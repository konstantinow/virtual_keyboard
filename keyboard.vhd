library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity KEYBOARD is
    port(
        clk_main            : in std_logic;

        ps2_clk             : inout std_logic;
        ps2_data            : inout std_logic;

        connect_keyboard_in : in std_logic; -- Эммуляция подключения к порту.(Нажатие на значок клавиатуры на сайте).
                                            -- rising_edge - подключили. falling_edge - отключили.

        --Сюда пишет клавиатура(настоящая, т.е. кто-то нажал на клавиатуру на клиенте). До 8 байт.
        data_in             : in std_logic_vector(63 downto 0);
        data_length_in      : in std_logic_vector(2 downto 0);
        new_data_in         : in std_logic; -- rising_edge
        ----------------------------------------------------
            
        is_init_o           : out std_logic := '0';
        led_mask_o          : out std_logic_vector(3 downto 0);
        ----------------------------------------------------

        keyboard_busy_o     : out std_logic := '0'

        );
end KEYBOARD;

architecture Behavioral of KEYBOARD is
          
-- [T][TRANSMITTING_STATE]
    type transmitting_state_type is (
            idle,
            t_connected_to_host,
            t_send_simple_keydown, -- example: '1' -> "0x16" + ACK + "0x16"
            t_disconnected
        );
-- [--/--]

-- [T][RECEIVING_STATE]
    type transmitting_state_type is (
            idle,
            r_wait_mask_inicators,
            r_read_id
        );
-- [--/--]

-- [S][PS/2]
    signal s_ps2_clk_in_0_0125MHz   : std_logic;
    signal s_ps2_byte_in            : std_logic_vector(7 downto 0);
    signal s_ps2_new_byte_in        : std_logic                     := '0';
    signal s_ps2_byte_o             : std_logic_vector(7 downto 0);
    signal s_ps2_new_byte_o         : std_logic;
    signal s_ps2_prev_new_byte_o    : std_logic                     := '0';
    signal s_ps2_busy_o             : std_logic;
-- [--/--]

-- [S][PS/2 RECEIVING]
    signal s_r_data         : std_logic_vector(63 downto 0); -- Data from host.
    signal s_r_data_length  : natural range 0 to 8          := 0;
    signal s_r_data_ended   : std_logic                     := '0';
    signal s_r_state        : std_logic                     := '0';
-- [--/--]

-- [S][PS/2 TRANSMITTING]
    signal s_t_run_init         : std_logic                     := '0';
    signal s_t_state            : std_logic                     := '0';
    signal s_t_index_data       : transmitting_state_type       := idle;
    signal s_t_need_send_byte   : std_logic                     := '0';
    signal s_t_byte             : std_logic_vector(7 downto 0);
-- [--/--]

-- [S][Internal signals]
    signal s_prev_new_data_in           : std_logic                     := '0';
    signal s_prev_connect_keyboard_in   : std_logic                     := '0';
    signal s_is_init                    : std_logic                     := '0';
    signal s_keyboard_disconnected      : std_logic                     := '0';
    signal s_led_mask                   : std_logic_vector(2 downto 0)  := "000";
    signal s_divider_count              : natural range 0 to 4000       := 0;
-- [--/--]

-- [Co][KEYBOARD TO HOST]
    constant K_COMPLETE_SUCCESS : std_logic_vector(7 downto 0)  := x"AA";
    constant K_ACKNOWLEDGE      : std_logic_vector(7 downto 0)  := x"FA";
    constant K_ID               : std_logic_vector(7 downto 0)  := x"AB"; -- TODO: need replace
    constant K_RESEND           : std_logic_vector(7 downto 0)  := x"FE";
-- [--/--]

-- [Co][HOST TO KEYBOARD]
    constant H_SET_KEYBOARD_INDICATORS  : std_logic_vector(7 downto 0)  := x"ED";
    constant H_READ_ID                  : std_logic_vector(7 downto 0)  := x"F2";
-- [--/--]

-- [C][PS2]
    component PS2_DEVICE is
    port(
            ps2_clk     : inout std_logic   := 'Z';
            ps2_data    : inout std_logic   := 'Z';
            clk_main_in : in std_logic;
            ps2_clk_in  : in std_logic;
            byte_in     : in std_logic_vector(7 downto 0);
            new_byte_in : in std_logic      := '0';
            byte_o      : out std_logic_vector(7 downto 0);
            new_byte_o  : out std_logic     := '0';
            busy_o      : out std_logic     := '0'
        );
    end component;
-- [--/--]

    constant DIVIDER_DIV    : natural range 0 to 1250   := 1250;

begin

-- [I][PS2]
    inst_ps2: PS2_DEVICE
    port map(
                ps2_clk     => ps2_clk,
                ps2_data    => ps2_data,
                clk_main_in => clk_main,
                ps2_clk_in  => s_ps2_clk_in_0_0125MHz,
                byte_in     => s_ps2_byte_in,
                new_byte_in => s_ps2_new_byte_in,
                byte_o      => s_ps2_byte_o ,
                new_byte_o  => s_ps2_new_byte_o,
                busy_o      => s_ps2_busy_o 
            );
-- [--/--]

-- [P][clk_main][DETECT CONNECTION TO HOST]
    process(clk_main)
    begin
        if rising_edge(clk_main)
        then
            s_t_run_init <= '0'; -- Default value
            s_keyboard_disconnected <= '0'; -- Default value

            if (s_prev_connect_keyboard_in /= connect_keyboard_in and connect_keyboard_in = '1') -- rising_edge
            then
                s_t_run_init <= '1';
            elsif(s_prev_connect_keyboard_in /= connect_keyboard_in and connect_keyboard_in = '0') -- falling_edge
            then
                s_keyboard_disconnected <= '1';
            end if;
        end if;
        s_prev_connect_keyboard_in <= connect_keyboard_in;
    end process;
-- [--/--]

-- [P][clk_main][COMMUNICATION KEYBOARD -> HOST]
    process(clk_main)
    begin
        if rising_edge(clk_main)
        then
            s_ps2_new_byte_in <= '0'; -- Default value

            case s_t_state is
                when idle =>
                    if s_t_run_init = '1'
                    then
                        s_t_state <= t_connected_to_host;
                    end if;

                    if s_keyboard_disconnected = '1'
                    then
                        s_t_state <= t_disconnected;
                    end if;

                    if s_prev_new_data_in /= new_data_in and new_data_in = '1'
                    then
                        s_t_index_data <= 0;
                        s_t_state <= t_send_simple_keydown;
                    end if;

                    if s_t_need_send_byte = '1'
                    then
                        s_t_state <= t_acknowledge;
                    end if;

                when t_connected_to_host =>
                    if s_ps2_busy_o = '0'
                    then
                        s_ps2_byte_in <= K_COMPLETE_SUCCESS;
                        s_ps2_new_byte_in <= '1';
                        is_init <= '1';
                        s_t_state <= idle;
                    end if;
                when t_send_simple_keydown =>
                    if is_init = '1' and s_ps2_busy_o = '0'
                    then
                        if s_t_index_data < to_integer(unsigned(data_length_in))
                        then
                            s_ps2_byte_in <= data_in(s_t_index_data*8 + 7 downto s_t_index_data*8);
                            s_ps2_new_byte_in <= '1';
                            s_t_index_data <= s_t_index_data + 1;
                        else
                            s_t_state <= idle;
                        end if;
                    end if;
                when t_acknowledge =>
                    if is_init = '1' and s_ps2_busy_o = '0'
                    then
                        s_ps2_byte_in <= K_ACKNOWLEDGE;
                        s_ps2_new_byte_in <= '1';
                        s_t_state <= idle;
                    end if;
                when t_disconnected =>
                    is_init <= '0';
                    s_t_state <= idle;
            end case;
            s_prev_new_data_in <= new_data_in;
        end if;
    end process;
-- [--/--]

-- [P][clk_main][RECEIVING KEYBOARD <- HOST]
    process(clk_main)
    begin
        if rising_edge(clk_main)
        then
            s_t_need_send_byte <= '0'; -- Default value

            case s_r_state is
                when idle =>
                    if (s_ps2_prev_new_byte_o /= s_ps2_new_byte_o and s_ps2_new_byte_o = '1')
                    then
                        case s_ps2_byte_o is 
                            when H_SET_KEYBOARD_INDICATORS =>
                                s_t_need_send_byte <= '1';
                                s_t_byte <= K_ACKNOWLEDGE;
                                s_r_state <= r_wait_mask_inicators;
                            when H_READ_ID =>
                                s_t_need_send_byte <= '1';
                                s_t_byte <= K_ACKNOWLEDGE;
                                s_r_state <= r_read_id;
                            when others =>
                                null;
                        end case;
                    end if;
                when r_read_id =>
                    s_t_need_send_byte <= '1';
                    s_t_byte <= K_ID;
                when r_wait_mask_inicators =>
                    if (s_ps2_prev_new_byte_o /= s_ps2_new_byte_o and s_ps2_new_byte_o = '1')
                    then
                        s_led_mask <= s_ps2_new_byte_o(2 downto 0);
                        s_t_need_send_byte <= '1';
                        s_t_byte <= K_ACKNOWLEDGE;
                    end if;
            end case;

            s_ps2_prev_new_byte_o <= s_ps2_new_byte_o;
        end if;
    end process;
-- [--/--]

-- [P][clk_main_in][GENERATOR - 0.0125MHz]
    process(clk_main_in)
    begin
        if rising_edge(clk_main_in)
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

    s_ps2_clk_in_0_0125MHz  <= '1' when s_divider_count < DIVIDER_DIV/2 else '0';

    is_init_o <= s_is_init;
    led_mask_o <= s_led_mask;

end Behavioral;
