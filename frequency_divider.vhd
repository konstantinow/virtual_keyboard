library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity frequency_divider is
generic( div : natural range 0 to 10000);
	port ( clk   : in  std_logic;
			 clk_o : out std_logic);
end frequency_divider;

architecture Behavioral of frequency_divider is

	signal count : natural range 0 to 10000  := 0;
begin
	process(clk)
	begin
		if (rising_edge(clk))
		then
            if count = div - 1
            then
                count <= 0;
            else
                count <=  count + 1;
            end if; 
		end if;
	end process;
	
	clk_o <= '1' when count < div/2  else '0';

end Behavioral;

