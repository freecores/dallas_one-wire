library ieee;
use ieee.std_logic_1164.all;

entity clk_divider is
  port
  (
	clk				: IN	std_logic;
	oneus_plus		: INOUT std_logic
  );
end entity;


architecture structural of clk_divider is

	signal counter		: integer range 0 to 16;

begin
	
	process ( clk )
	begin
		if rising_edge(clk) then
			counter <= counter + 1;
			if (counter mod 16) = 0 then
				oneus_plus <= not oneus_plus;
			end if;
		end if;
	end process;

end architecture;

PACKAGE TIMER_PKG IS
		COMPONENT clk_divider
		END COMPONENT;
END TIMER_PKG;