library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.protocol_pkg.all;
--use work.decode_pkg.all;
use work.timer_pkg.all;

entity DS1821 is
  port
  (
	master_clk, master_rst		: IN std_logic;
  	clk						: INOUT std_logic;
	tempValid					: OUT std_logic;
	reset, read1, write1 		: INOUT std_logic;
	DQ1						: INOUT std_logic;
	rddata1					: INOUT std_logic_vector(7 downto 0);
	wrdata1					: INOUT std_logic_vector(7 downto 0);
	ready1					: INOUT std_logic

	--useg						: OUT std_logic_vector( 0 to 6 );
	--lseg						: OUT std_logic_vector( 0 to 6 )
  );
end entity;

architecture DS1821Controller of DS1821 is

component one_wire is 
	port (
		clk, reset, read, write	: IN std_logic;
		DQ					: INOUT std_logic;
		rddata				: INOUT std_logic_vector(7 downto 0);
		wrdata				: IN std_logic_vector(7 downto 0);
		ready				: INOUT std_logic);
end component;

--component seg_decode is			--this component is only needed for debugging
--	port(
--		value				: IN std_logic_vector (3 downto 0);
--		output				: OUT std_logic_vector (0 to 6));
--end component;

component clk_divider is
	port(
	clk						: IN	std_logic;
	oneus_plus				: INOUT std_logic);
end component;

	type states is (init, sendCommStatProg, sendCommStatVal, init1, sendConvTempComm, init2, sendReadTempComm, readTemp);
	signal state				:states;
	signal next_state			:states;
	
begin
	temperaturemap1: one_wire port map(clk, reset, read1, write1, DQ1, rddata1, wrdata1, ready1);
	clkdivider: clk_divider port map(master_clk, clk);			--clock divider to make this work with 25.175Mhz
	--usegdecode: seg_decode port map(rddata1(7 downto 4), useg);		--seven seg decoder for debugging
	--lsegdecode: seg_decode port map(rddata1(3 downto 0), lseg);		--seven seg decoder for debugging
	
	process ( clk, master_rst )
	begin
		if master_rst = '0' then
			wrdata1 <= wrdata1;
			write1 <= write1;
			read1 <= read1;
			tempValid <= '0';
			reset <= '1';
			next_state <= init;
			state <= init;
		elsif rising_edge( clk ) then
			state <= next_state;	  
			case state is
				when init =>
					write1 <= '0';
					read1 <= '0';
					reset <= '1';
					tempValid <= '0';
					next_state <= sendCommStatProg;
				when sendCommStatProg =>
					reset <= '0';
					if ready1 = '1' then
						wrdata1 <= "00001100";			--send 0Ch = Configure the register command
						write1 <= '1';
						next_state <= sendCommStatVal;
					end if;
				when sendCommStatVal =>
					write1 <= '0';
					if ready1 = '1' then
						wrdata1 <= "01000010";			--send 42h = Write this value into the register
						write1 <= '1';
						next_state <= init1;
					end if;
				when init1 =>
					write1 <= '0';
					read1 <= '0';
					if ready1 = '1' then
						reset <= '1';
						next_state <= sendConvTempComm;
					end if;
				when sendConvTempComm =>	
					reset <= '0';
					--write1 <= '0';
					--tempValid <= '0';
					if ready1 = '1' AND reset <= '0' then
						wrdata1 <= "11101110";			--send EEh = Begin Conversions
						write1 <= '1';
						next_state <= init2;	  
					end if;
				when init2 =>
					if read1 = '1' then
						read1 <= '0';
						tempValid <= '0';
					end if;
					write1 <= '0';
					if ready1 = '1' then
						reset <= '1';
						tempValid <= '0';
						next_state <= sendReadTempComm;
					end if;
				when sendReadTempComm =>
					tempValid <= '1';
					reset <= '0';
					write1 <= '0';
					if ready1 = '1' AND reset <= '0' then
						tempValid <= '1';
						wrdata1 <= "10101010";			--send AAh = Read Temp Command
						write1 <= '1';
						next_state <= readTemp;
					end if;
				when readTemp =>						--starts reading the temperature
					write1 <= '0';
					tempValid <= '1';
					if ready1 = '1' then
						read1 <= '1';
						tempValid <= '0';
						next_state <= init2;
					end if;
				--when holdTemp =>						--For now I just hold the temp steady after one read
				--	read1 <= '0';
				--	if ready1 = '1' then
				--		tempValid <= '1';
				--		--ftemp <= rddata1 * "00001001";
				--	end if;
				--	next_state <= holdTemp;
				when OTHERS =>
			end case;
		end if;
	end process;
end architecture;

PACKAGE TEMPERATURE_PKG IS
		COMPONENT DS1821
		END COMPONENT;
END TEMPERATURE_PKG; 