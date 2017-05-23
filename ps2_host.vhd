library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PS2_HOST is
    port(
            ps2_clk     : inout std_logic;
            ps2_data    : inout std_logic;

            clk_main_in : in std_logic; -- =50MHz
            ps2_clk_in  : in std_logic; -- ~=10-16KHz

            byte_in     : in std_logic_vector(7 downto 0);
            new_byte_in : in std_logic      := '0'; --По фронту необходимо забрать данные с data_in.

            byte_o      : out std_logic_vector(7 downto 0);
            new_byte_o  : out std_logic     := '0'; --По фронту необходимо в модуле выше забрать данные с data_o.

            busy_o      : out std_logic     := '0';

            test1       : out std_logic     := '0';
            test2       : out std_logic     := '0';
            test3       : out std_logic     := '0';
            test4       : out std_logic     := '0'
        );
end PS2_HOST;

architecture Behavioral of PS2_HOST is

-- [T][state_type]
    type state_type is (
        idle,
        t_waiting_free_line,
        t_pre_start_bit,
        t_send_bits,
        t_send_ended,
        t_waiting_ack,
        r_receive_bits,
        r_end_receive
    );
-- [--/--]

-- [S][Internal signals]
    signal s_state                  : state_type := idle;
-- [--/--]

-- [S][TRANSMITTER]
    signal s_t_prev_new_byte_in         : std_logic := '0';
    signal s_t_prev_ps2_clk             : std_logic := '1';
    signal s_t_data                     : std_logic_vector(10 downto 0); -- |{0}Start|{1-8}data|{9}P|{10}Stop|
    signal s_t_index_bit                : natural range 0 to 11 := 0;
    signal s_t_current_bit              : std_logic := '1';
    signal s_t_counter_pre_start_bit    : natural range 0 to 10000 := 0; -- TODO: изменить 1000 на норм число.
-- [--/--]

-- [S][RECEIVER]
    signal s_r_data                     : std_logic_vector(10 downto 0); -- |{0}Start|{1-8}data|{9}P|{10}Stop|
    signal s_r_index_bit                : natural range 0 to 11 := 0;
-- [--/--]

-- [S][RECEIVER]
    signal d_counter                    : natural range 0 to 12 := 0;
    signal d_data0                      : std_logic             := '0';
    signal d_data1                      : std_logic             := '0';
    signal d_data2                      : std_logic             := '0';
    signal d_data3                      : std_logic             := '0';
    signal d_data4                      : std_logic             := '0';
    signal d_data5                      : std_logic             := '0';
    signal d_data6                      : std_logic             := '0';
    signal d_data7                      : std_logic             := '0';
-- [--/--]

begin

-- [P][ps2_clk][Transmitting "Host -> Device". Set ps2_data]
    process(clk_main_in)
    begin
        if rising_edge(clk_main_in)
        then
            new_byte_o <= '0';
            case s_state is
                when idle =>
                    --s_r_index_bit <= 0; -- Default value
                    --s_r_data <= x"00" & "000"; -- Default value

                    s_t_current_bit <= 'Z';

                    busy_o <= '0';
                    if s_t_prev_new_byte_in /= new_byte_in and new_byte_in = '1'
                    then
                        busy_o <= '1';
                        s_t_data(0) <= '0';
                        s_t_data(8 downto 1) <= byte_in;
                        s_t_data(9) <= not(byte_in(0) xor byte_in(1) xor byte_in(2) xor byte_in(3) xor byte_in(4) xor byte_in(5) xor byte_in(6) xor byte_in(7));
                        s_t_data(10) <= '1';
                        s_state <= t_waiting_free_line;
                    elsif ps2_clk /= s_t_prev_ps2_clk and ps2_clk = '0' -- falling_edge
                    then
                        busy_o <= '1';

                        if d_counter < 11
                        then
                            s_r_data(d_counter) <= ps2_data;
                            d_counter <= d_counter + 1;
                        end if;
                        --s_r_data(s_r_index_bit) <= ps2_data;
                        --s_r_index_bit <= s_r_index_bit + 1;
                        --s_state <= r_receive_bits;
                    end if;

                    if d_counter = 11
                    then
                        busy_o <= '0';
                        new_byte_o <= '1';
                        byte_o <= s_r_data(8 downto 1);
                        d_counter <= 0;
                    end if;

                -- [TRANSMITTING]
                    when t_waiting_free_line =>
                        --TODO: need rewrite (Counter 50us).

                        if ps2_clk /= '0' and ps2_data /= '0'
                        then
                            s_state <= t_pre_start_bit;
                        end if;
                    when t_pre_start_bit =>
                        --TODO: counter.
                        if s_t_counter_pre_start_bit < 10000
                        then
                            s_t_counter_pre_start_bit <= s_t_counter_pre_start_bit + 1;
                        else
                            s_t_counter_pre_start_bit <= 0;
                            s_state <= t_send_bits;
                        end if;
                    when t_send_bits =>
                        if ps2_clk /= s_t_prev_ps2_clk and ps2_clk = '1' -- rising_edge
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
                        if ps2_clk /= s_t_prev_ps2_clk and ps2_clk = '1'
                        then
                            s_state <= t_waiting_ack;
                            s_t_current_bit <= 'Z';
                        end if;
                    when t_waiting_ack =>
                        if ps2_clk /= s_t_prev_ps2_clk
                        then
                            s_state <= idle;
                        end if;
                -- [--/--]

                -- [RECEIVING]
                    when r_receive_bits =>
                        if ps2_clk /= s_t_prev_ps2_clk and ps2_clk = '0' -- falling_edge
                        then
                            if s_r_index_bit < 11
                            then

                                if ps2_data = '0'
                                then
                                    s_r_data(s_r_index_bit) <= '0';
                                else
                                    s_r_data(s_r_index_bit) <= '1';
                                end if;

                                if d_counter = 0
                                then
                                    if ps2_data = '0'
                                    then
                                        test1 <= '1';
                                        d_data0 <= '0';
                                    else
                                        d_data0 <= '1';
                                    end if;
                                end if;


                                if d_counter = 1
                                then
                                    if ps2_data = '0'
                                    then
                                        test2 <= '1';
                                        d_data1 <= '0';
                                    else
                                        d_data1 <= '1';
                                    end if;
                                end if;


                                if d_counter = 2
                                then
                                    if ps2_data = '0'
                                    then
                                        test3 <= '1';
                                        d_data2 <= '0';
                                    else
                                        d_data2 <= '1';
                                    end if;
                                end if;


                                if d_counter = 3
                                then
                                    if ps2_data = '0'
                                    then
                                        test4 <= '1';
                                        d_data3 <= '0';
                                    else
                                        d_data3 <= '1';
                                    end if;
                                end if;


                                if d_counter = 4
                                then
                                    if ps2_data = '0'
                                    then
                                        d_data4 <= '0';
                                    else
                                        d_data4 <= '1';
                                    end if;
                                end if;


                                if d_counter = 5
                                then
                                    if ps2_data = '0'
                                    then
                                        d_data5 <= '0';
                                    else
                                        d_data5 <= '1';
                                    end if;
                                end if;


                                if d_counter = 6
                                then
                                    if ps2_data = '0'
                                    then
                                        d_data6 <= '0';
                                    else
                                        d_data6 <= '1';
                                    end if;
                                end if;


                                if d_counter = 7
                                then
                                    if ps2_data = '0'
                                    then
                                        d_data7 <= '0';
                                    else
                                        d_data7 <= '1';
                                    end if;
                                end if;

                                d_counter <= d_counter + 1;
                                s_r_index_bit <= s_r_index_bit + 1;
                            end if;
                        elsif s_r_index_bit = 11
                        then
                            s_r_index_bit <= 0;
                            s_state <= r_end_receive;
                        end if;
                    when r_end_receive =>
                        --TODO: need verification bits
                        -- new_byte_o <= '1';
                        -- byte_o <= d_data0 & d_data1 & d_data2 & d_data3 & d_data4 & d_data5 & d_data6 & d_data7;
                        s_state <= idle;
                -- [--/--]
            end case;
            s_t_prev_ps2_clk <= ps2_clk;
            s_t_prev_new_byte_in <= new_byte_in;
        end if;
    end process;
-- [--/--]

    ps2_clk <= '0' when (s_state = t_pre_start_bit) else 'Z';
    ps2_data <= s_t_current_bit;
    --ps2_data <= 'Z';
    
end architecture Behavioral;
