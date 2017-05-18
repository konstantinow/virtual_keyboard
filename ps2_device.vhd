library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PS2_DEVICE is
    port(
            ps2_clk     : inout std_logic   := 'Z';
            ps2_data    : inout std_logic   := 'Z';

            clk_main_in : in std_logic; -- =50MHz
            ps2_clk_in  : in std_logic; -- ~=10-16KHz

            byte_in     : in std_logic_vector(7 downto 0);
            new_byte_in : in std_logic      := '0'; --По фронту необходимо забрать данные с data_in.

            byte_o      : out std_logic_vector(7 downto 0);
            new_byte_o  : out std_logic     := '0'; --По фронту необходимо в модуле выше забрать данные с byte_o.

            busy_o      : out std_logic     := '0';
            test1       : out std_logic     := '0';
            test2       : out std_logic     := '0';
            test3       : out std_logic     := '0';
            test4       : out std_logic     := '0'
        );
end PS2_DEVICE;

architecture Behavioral of PS2_DEVICE is

-- [T][transmitting_state]
    type type_transmitting_state is (
        idle,
        t_start_bit,
        t_send_bits,
        t_stop_bit,
        t_send_ended
    );
-- [--/--]

-- [T][ps2_state]
    type type_ps2_state is (
        idle,
        transmitting,
        receiving
    );
-- [--/--]

-- [T][receiving_state]
    type type_receiving_state is (
        idle,
        r_receive_bits,
        r_receive_ended
    );
-- [--/--]

-- [S][Internal signals]
    signal s_prev_ps2_clk_in            : std_logic                 := '0';
    signal s_need_generate_ps2_clk      : std_logic                 := '0';
    signal s_ps2_state                  : type_ps2_state            := idle;
    signal s_transmitting_state         : type_transmitting_state   := idle;
    signal s_receiving_state            : type_receiving_state      := idle;
    signal s_divider_count              : natural range 0 to 1250   := 0;
-- [--/--]

-- [S][TRANSMITTER]
    signal s_t_prev_ps2_clk             : std_logic                 := 'Z';
    signal s_t_prev_new_byte_in         : std_logic                 := '0';
    signal s_t_run_transmitting         : std_logic                 := '0';
    signal s_t_end_transmitting         : std_logic                 := '0';
    signal s_t_current_bit              : std_logic;
    signal s_t_need_generate_ps2_clk    : std_logic                 := '0';
    signal s_t_byte                     : std_logic_vector(7 downto 0);
    signal s_t_count_transmitted_bit    : natural range 0 to 7      := 0;
-- [--/--]

-- [S][RECEIVER]
    signal s_r_prev_ps2_clk             : std_logic := 'Z';
    signal s_r_clk_0_04MHz              : std_logic := '0';
    signal s_r_prev_clk_0_04MHz         : std_logic := '0';
    signal s_r_run_receiving            : std_logic := '0';
    signal s_r_end_receiving            : std_logic := '0';
    signal s_r_current_bit              : std_logic := 'Z';
    signal s_r_need_generate_ps2_clk    : std_logic := '0';
    signal s_r_data                     : std_logic_vector(10 downto 0); -- |{0}Start|{1-8}data|{9}P|{10}Stop|
    signal s_r_count_tick               : natural range 0 to 4  := 0; -- Нужен, чтобы проверить наличие '0' на ps2_clk не менее 100мксек
    signal s_r_count_received_bit       : natural range 0 to 11 := 0; -- Вместе с старт_бит, бит_паритета и стоп_битом.
-- [--/--]

    constant DIVIDER_DIV    : natural range 0 to 1250   := 1250;

begin

-- [P][clk_main_in][Detect transmitting "Device -> Host"]
    process(clk_main_in)
    begin
        if rising_edge(clk_main_in)
        then
            s_t_run_transmitting <= '0'; -- default value.

            if s_t_prev_new_byte_in /= new_byte_in and new_byte_in = '1'
            then
                if s_ps2_state = idle
                then
                    s_t_byte <= byte_in;
                    s_t_run_transmitting <= '1';
                end if;
            end if;
            s_t_prev_new_byte_in <= new_byte_in;
        end if;
    end process;
-- [--/--]

-- [P][clk_main_in][Detect receiving "Device <- Host"]
    process(clk_main_in)
    begin
        if rising_edge(clk_main_in)
        then
            if s_r_clk_0_04MHz /= s_r_prev_clk_0_04MHz and s_r_clk_0_04MHz = '1'
            then
                if ps2_clk = '0'
                then
                    if s_r_count_tick = 4 and s_ps2_state = idle
                    then
                        s_r_run_receiving <= '1';
                        s_r_count_tick <= 0;
                    elsif s_r_count_tick < 4 and s_ps2_state = idle
                    then
                        s_r_count_tick <= s_r_count_tick + 1;
                    end if;

                    if s_ps2_state /= idle
                    then
                        s_r_count_tick <= 0;
                    end if;

                end if;
            end if;

            if s_ps2_state = receiving
            then
                s_r_run_receiving <= '0'; --reset
            end if;

            s_r_prev_clk_0_04MHz <= s_r_clk_0_04MHz;
        end if;
    end process;
-- [--/--]

-- [P][clk_main_in][Set ps2 state and ps2_data]
    process(clk_main_in, s_ps2_state)
    begin
        if rising_edge(clk_main_in)
        then
            if s_t_run_transmitting = '1' and s_ps2_state = idle
            then
                s_ps2_state <= transmitting;
            elsif s_r_run_receiving = '1' and s_r_end_receiving /= '1' and s_ps2_state = idle
            then
                if (ps2_clk /= '0') -- waiting for ps2_clk release by host
                then
                    s_ps2_state <= receiving;
                end if;
            elsif s_t_end_transmitting = '1' or s_r_end_receiving = '1'
            then
                s_ps2_state <= idle;
            end if;

        end if;

        case s_ps2_state is
            when receiving =>
                ps2_data <= s_r_current_bit;
            when transmitting =>
                if s_t_current_bit = '0'
                then
                    test3 <= '1';
                end if;
                if ps2_data = '0'
                then
                    test4 <= '1';
                end if;

                if s_t_current_bit = '1'
                then
                    ps2_data <= 'Z';
                else
                    ps2_data <= '0';
                end if;
            when idle =>
                ps2_data <= 'Z';
        end case;

    end process;
-- [--/--]

-- [P][clk_main_in][Transmitting]
    process(clk_main_in)
    begin
        if rising_edge(clk_main_in)
        then
            if (s_prev_ps2_clk_in /= ps2_clk_in and ps2_clk_in = '1') and s_ps2_state = transmitting
            then
                s_t_end_transmitting <= '0'; -- Default value

                case s_transmitting_state is
                    when idle =>
                        s_transmitting_state <= t_start_bit;
                        s_t_need_generate_ps2_clk <= '1';
                        s_t_current_bit <= '1';
                    when t_start_bit =>
                        test1 <= '1';
                        s_t_current_bit <= '0';
                        s_transmitting_state <= t_send_bits;
                    when t_send_bits =>
                        if (s_t_count_transmitted_bit < 8)
                        then
                            s_t_current_bit <= s_t_byte(s_t_count_transmitted_bit);
                            s_t_count_transmitted_bit <= s_t_count_transmitted_bit + 1;
                            test2 <= '1';
                        else
                            s_t_count_transmitted_bit <= 0;
                            s_t_current_bit <= not(s_t_byte(0) xor s_t_byte(1) xor s_t_byte(2) xor s_t_byte(3) xor s_t_byte(4) xor s_t_byte(5) xor s_t_byte(6) xor s_t_byte(7));
                            s_transmitting_state <= t_stop_bit;
                        end if;
                    when t_stop_bit =>
                        s_t_current_bit <= '1';
                        s_transmitting_state <= t_send_ended;
                        s_t_need_generate_ps2_clk <= '0';
                    when t_send_ended =>
                        s_t_current_bit <= '1';
                        s_transmitting_state <= idle;
                        s_t_end_transmitting <= '1';
                end case;
            end if;
        end if;
    end process;
-- [--/--]

-- [P][clk_main_in][Receiving. Set s_r_data]
    process(clk_main_in)
    begin
        if rising_edge(clk_main_in)
        then
            new_byte_o <= '0'; -- Default value

            if s_ps2_state = receiving
            then
                case s_receiving_state is
                    when idle =>
                        s_r_end_receiving <= '0';
                        if s_r_end_receiving = '0'
                        then
                            s_receiving_state <= r_receive_bits;
                        end if;
                    when r_receive_bits =>
                        s_r_need_generate_ps2_clk <= '1';
                        if ps2_clk /= s_r_prev_ps2_clk and ps2_clk = '0' -- falling_edge
                        then
                            if s_r_count_received_bit < 11
                            then
                                s_r_data(s_r_count_received_bit) <= ps2_data;
                                s_r_count_received_bit <= s_r_count_received_bit + 1;
                            end if;
                        elsif (ps2_clk /= s_r_prev_ps2_clk and ps2_clk = '1') and s_r_count_received_bit = 11
                        then
                            if (s_r_data(0) = '0' and
                                s_r_data(10) = '1' and
                                s_r_data(9) = not(s_r_data(1) xor s_r_data(2) xor s_r_data(3) xor s_r_data(4) xor s_r_data(5) xor s_r_data(6) xor s_r_data(7) xor s_r_data(8)))
                            then
                                s_r_current_bit <= '0';
                            end if;
                            s_r_count_received_bit <= 0;
                            s_r_need_generate_ps2_clk <= '0';
                            s_receiving_state <= r_receive_ended;
                        end if;
                    when r_receive_ended =>
                        if ps2_clk /= s_prev_ps2_clk_in and ps2_clk /= '0' --(not falling_edge) Set data in state 'Z' when clk will be 'Z'.
                        then
                            new_byte_o <= '1';
                            byte_o <= s_r_data(8 downto 1);
                            s_r_current_bit <= 'Z';
                            s_receiving_state <= idle;
                            s_r_end_receiving <= '1';
                        end if;
                end case;
            end if;
            s_r_prev_ps2_clk <= ps2_clk;
        end if;
    end process;
-- [--/--]

-- [P][clk_main_in][Receiving. Generate ps2_clk]
    process(clk_main_in)
    begin
        if rising_edge(clk_main_in)
        then
            if ps2_clk_in /= s_prev_ps2_clk_in and ps2_clk_in = '1'
            then
                if (s_r_need_generate_ps2_clk = '1' or s_t_need_generate_ps2_clk = '1')
                then
                    s_need_generate_ps2_clk <= '1';
                else
                    s_need_generate_ps2_clk <= '0';
                end if;
            end if;

            if s_need_generate_ps2_clk = '1'
            then
                ps2_clk <= ps2_clk_in;
            else
                ps2_clk <= 'Z';
            end if;

            s_prev_ps2_clk_in <= ps2_clk_in;
        end if;
    end process;
-- [--/--]

-- [P][clk_main_in][GENERATOR - 0.04MHz]
    process(clk_main_in)
    begin -- Нужная частота - каждые 25мкс устанавливать фронт. Тогда frequency = 0.04MHz. Тогда clk_main(50MHz) нужно поделить на 0.04 = 1250.
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

    s_r_clk_0_04MHz <= '1' when s_divider_count < DIVIDER_DIV/2 else '0';

    busy_o <= '0' when (s_ps2_state = idle) else '1';
    
end architecture Behavioral;
