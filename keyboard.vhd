library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity KEYBOARD is
    port(
        clk_main            : in std_logic;

        ps2_clk             : inout std_logic;
        ps2_data            : inout std_logic;

        --Сюда пишет клавиатура(настоящая, т.е. кто-то нажал на клавиатуру на клиенте). До 8 байт.
        data_in             : in std_logic_vector(63 downto 0);
        data_length_in      : in std_logic_vector(2 downto 0);
        new_data_in         : in std_logic; -- rising_edge
        ----------------------------------------------------
            
        --Флаги для отображения в вебе
        is_init             : out std_logic := '0';
        caps_lock           : out std_logic := '0';
        num_lock            : out std_logic := '0';
        ----------------------------------------------------

        keyboard_busy_o     : out std_logic := '0'

        );
end KEYBOARD;

architecture Behavioral of KEYBOARD is

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
    signal s_received_data          : std_logic_vector(63 downto 0); -- Data from host.
    signal s_received_data_length   : natural range 0 to 8          := 0;
    signal s_received_data_ended    : std_logic                     := '0';
-- [--/--]

-- [S][Internal signals]
    signal s_prev_new_data_in       : std_logic                     := '0';
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

-- [C][frequency_divider]
    component frequency_divider
        generic (div : natural range 0 to 10000);
        port (
                 clk    : in std_logic;
                 clk_o  : out std_logic
             );
    end component;
-- [--/--]

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

-- [I][frequency_divider 12.5KHz]
    inst_freq_divider_12_5KHz: frequency_divider 
    -- TODO: replace 1 to 4000.
    generic map(div => 2) -- Нужная частота - каждые 25мкс устанавливать фронт. Тогда frequency = 12.5KHz. Тогда clk_main(50MHz) нужно поделить на 0.0125MHz = 4000.
    port map (
                 clk => clk_main,
                 clk_o => s_ps2_clk_in_0_0125MHz
             );
-- [--/--]

-- [P][clk_main][RECEIVING KEYBOARD <- HOST]
    process(clk_main)
    begin
        if rising_edge(clk_main)
        then
            s_received_data_ended <= '0'; -- Default value.
            if(s_ps2_prev_new_byte_o /= s_ps2_new_byte_o and s_ps2_new_byte_o = '1') -- Значит нужно считать новый байт с PS2.
            then
                s_received_data(s_received_data_length*8 + 7 downto s_received_data_length*8) <= s_ps2_byte_o;
                s_received_data_length <= s_received_data_length + 1;

                --TODO: Выполнить после кучи проверок на то, что нужный пакет принят(Сверить длину и т.д.).
                if s_received_data_length = 1
                then
                    s_received_data_ended <= '1';
                end if;
            end if;
            s_ps2_prev_new_byte_o <= s_ps2_new_byte_o;
        end if;
    end process;
-- [--/--]

-- TODO: s_length_data_to_send <= to_integer(unsigned(data_length_in));

end Behavioral;
