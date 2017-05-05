library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PS2_HOST is
    port(
            ps2_clk     : inout std_logic := 'Z';
            ps2_data    : inout std_logic := 'Z';

            clk_main_in : in std_logic; -- =50MHz
            ps2_clk_in  : in std_logic; -- ~=10-16KHz

            byte_in     : in std_logic_vector(7 downto 0);
            new_byte_in : in std_logic      := '0'; --По фронту необходимо забрать данные с data_in.

            byte_o      : out std_logic_vector(7 downto 0);
            new_byte_o  : out std_logic     := '0'; --По фронту необходимо в модуле выше забрать данные с data_o.

            busy_o      : out std_logic     := '0'
        );
end PS2_HOST;

architecture Behavioral of PS2_HOST is

-- [T][state_type]
    type state_type is (
        idle,
        t_pre_start_bit,
        t_send_bits,
        t_send_ended,
        t_waiting_ack
    );
-- [--/--]

-- [S][Internal signals]
    signal s_state                  : state_type := idle;
-- [--/--]

-- [S][TRANSMITTER]
    signal s_t_prev_new_byte_in         : std_logic := '0';
    signal s_t_prev_ps2_clk             : std_logic := '0';
    signal s_t_data                     : std_logic_vector(10 downto 0); -- |{0}Start|{1-8}data|{9}P|{10}Stop|
    signal s_t_run_transmitting         : std_logic := '0';
    signal s_t_index_bit                : natural range 0 to 11 := 0;
    signal s_t_current_bit              : std_logic := 'Z';
    signal s_t_counter_pre_start_bit    : natural range 0 to 10000 := 0; -- TODO: изменить 1000 на норм число.
-- [--/--]

begin

-- [P][ps2_clk][Transmitting "Host -> Device". Set ps2_data]
    process(ps2_clk, clk_main_in)
    begin
        if rising_edge(clk_main_in)
        then
            case s_state is
                when idle =>
                    if s_t_prev_new_byte_in /= new_byte_in and new_byte_in = '1'
                    then
                        s_t_data(0) <= '0';
                        s_t_data(8 downto 1) <= byte_in;
                        s_t_data(9) <= not(byte_in(0) xor byte_in(1) xor byte_in(2) xor byte_in(3) xor byte_in(4) xor byte_in(5) xor byte_in(6) xor byte_in(7));
                        s_t_data(10) <= '1';
                        s_state <= t_pre_start_bit;
                    end if;
                    s_t_prev_new_byte_in <= new_byte_in;
                when t_pre_start_bit =>
                    if s_t_counter_pre_start_bit < 10000
                    then
                        s_t_counter_pre_start_bit <= s_t_counter_pre_start_bit + 1;
                    else
                        s_t_counter_pre_start_bit <= 0;
                        s_state <= t_send_bits;
                    end if;
                when t_send_bits =>
                    if ps2_clk /= s_t_prev_ps2_clk and ps2_clk = '1'
                    then
                        if s_t_index_bit < 11
                        then
                            s_t_current_bit <= s_t_data(s_t_index_bit);
                            s_t_index_bit <= s_t_index_bit + 1;
                        end if;
                    end if;
                    if s_t_index_bit = 11
                    then
                        s_state <= t_send_ended;
                        s_t_index_bit <= 0;
                    end if;
                when t_send_ended =>
                    if ps2_clk /= s_t_prev_ps2_clk -- and ps2_clk /= '0' and ps2_clk /= '1' -- Detect 'Z'
                    then
                        s_state <= t_waiting_ack;
                        s_t_current_bit <= 'Z';
                    end if;
                when t_waiting_ack =>
                    s_state <= idle;
            end case;
            s_t_prev_ps2_clk <= ps2_clk;
        end if;
    end process;
-- [--/--]

    ps2_clk <= '0' when (s_state = t_pre_start_bit) else 'Z';
    busy_o <= '0' when (s_state = idle) else '1';
    ps2_data <= s_t_current_bit;
    
end architecture Behavioral;
