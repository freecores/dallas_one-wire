library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_unsigned.all;

entity one_wire is 
	port (
			clk, reset, read, write		: IN std_logic;
			DQ						: INOUT std_logic;
			rddata					: OUT std_logic_vector(7 downto 0);
			wrdata					: IN std_logic_vector(7 downto 0);
			ready					: INOUT std_logic
		);
end entity one_wire;

architecture structural of one_wire is
	signal iCount : integer range 0 to 500;
	signal iCntRst : bit;
	signal iD : std_logic;
begin
	
	--This counter is used in the state machine to count micro seconds
	--it is assumed that the clock edges are coming in at 1uS intervals
	counter: process
	begin
		wait until (clk'event and clk = '0');
			if(iCntRst = '1') then
				iCount <= 0;
			else
				iCount <= iCount + 1;
			end if;
	end process counter;	
	
	init_statemachine : block

	type states is (init1, init2, init3, rdy, begin_read, begin_write, rd_bit, finish_read, wr_bit);
	signal state : states;	
	begin
		nxt_state_decoder: process(state, clk)
			variable next_state : states;
			variable iBits : integer range 0 to 8;
		begin
		if clk 'event and clk = '1' then
			case (state) is
				when INIT1 => 
					iCntRst <= '0';
					iD <= '0';
					ready <= '0';
					if (iCount = 500) then
						next_state := INIT2;
						iCntRst <= '1';		--stop the timer
					else
						next_state := INIT1;
					end if;
				when INIT2 =>
					iCntRst <= '0';			--start the timer
					iD <= '1';
					ready <= '0';
					if (iCount = 15) then
						next_state := INIT3;
						iCntRst <= '1';		--stop the timer
					else
						next_state := INIT2;
					end if;
				when INIT3 =>
					iCntRst <= '0';			--start the timer (not needed)
					ready <= '0';
					if (DQ = '0') then
						next_state := RDY;
						iCntRst <= '1';		--stop the timer (not needed)
					else
						next_state := INIT3;
					end if;
				when RDY =>
					iCntRst <= '0';		--start the timer
					iBits := 0;
					iD <= '1';
					if(iCount >= 240 and ready = '0') then
						ready <= '1';
					end if;
					if(Read = '1' and iCount >= 240) then
						ready <= '0';
						iCntRst <= '1';			--stop timer
						next_state := BEGIN_READ;
					elsif(Write = '1' and iCount >= 240) then
						ready <= '0';
						iCntRst <= '1';			--stop timer
						next_state := BEGIN_WRITE;
					else
						next_state := RDY;
					end if;
				when BEGIN_READ =>
					iCntRst <= '0';		--start timer
					iD <= '0';
					if (iCount = 2) then							--this number used to be a 5
						iCntRst <= '1';		--stop timer
						next_state := RD_BIT;
					end if;
				when RD_BIT =>
					iD <= '1';
					iCntRst <= '0'; --start timer
					
					case ibits is
						when 0 =>
							rddata(0) <= DQ;
						when 1 =>
							rddata(1) <= DQ;
						when 2 =>
							rddata(2) <= DQ;
						when 3 =>
							rddata(3) <= DQ;
						when 4 =>
							rddata(4) <= DQ;
						when 5 =>
							rddata(5) <= DQ;
						when 6 =>
							rddata(6) <= DQ;
						when 7 =>
							rddata(7) <= DQ;
						when others =>
					end case;
						if(iCount >= 6) then
							next_state := FINISH_READ;
						end if;
				when FINISH_READ =>
					if(iBits <= 6 and iCount >= 55) then		--this second number used to be 55
						iD <= '1';
						iBits := iBits + 1;
						iCntRst <= '1'; --stop timer
						next_state := BEGIN_READ;
					elsif(iBits = 7) then
						iCntRst <= '1'; -- stop timer
						next_state := RDY;
					end if;
				when BEGIN_WRITE =>
					iCntRst <= '0'; 
					if(iBits <= 7) then
						iD <= '0';					--start timer
					end if;
					if (iCount = 1) then
						iCntRst <= '1';  --stop timer
						next_state := WR_BIT;
					end if;
				when WR_BIT =>
					iCntRst <= '0';
				
					--The below code is what is being accomplished by the huge if elseif structure 
					--if(data(iBits) = "001") then
					--	iD := '1';
					--end if;

					if(iBits = 0 and wrdata(0) = '1') then
						iD <= '1';
					elsif(iBIts = 0 and wrdata(0) = '0') then
						iD <= '0';
					elsif(iBits = 1 and wrdata(1) = '1') then
						iD <= '1';
					elsif(iBIts = 1 and wrdata(1) = '0') then
						iD <= '0';
					elsif(iBits = 2 and wrdata(2) = '1') then
						iD <= '1';
					elsif(iBIts = 2 and wrdata(2) = '0') then
						iD <= '0';
					elsif(iBits = 3 and wrdata(3) = '1') then
						iD <= '1';
					elsif(iBIts = 3 and wrdata(3) = '0') then
						iD <= '0';
					elsif(iBits = 4 and wrdata(4) = '1') then
						iD <= '1';
					elsif(iBIts = 4 and wrdata(4) = '0') then
						iD <= '0';
					elsif(iBits = 5 and wrdata(5) = '1') then
						iD <= '1';
					elsif(iBIts = 5 and wrdata(5) = '0') then
						iD <= '0';
					elsif(iBits = 6 and wrdata(6) = '1') then
						iD <= '1';
					elsif(iBIts = 6 and wrdata(6) = '0') then
						iD <= '0';
					elsif(iBits = 7 and wrdata(7) = '1') then
						iD <= '1';
					elsif(iBIts = 7 and wrdata(7) = '0') then
						iD <= '0';
					end if;
					if(iCount >= 60 and iBits <= 7) then
						iBits := iBits + 1;
						iD <= '1';
						iCntRst <= '1'; --stop timer
						next_state := BEGIN_WRITE;
					elsif(iBits = 8) then
						iD <= '1';
						iCntRst <= '1'; --stop timer
						next_state := RDY;
					end if;
			end case;

			state <= next_state;
			if(reset = '1') then
				state <= init1;
			end if;
		end if;
			
		end process nxt_state_decoder;
	end block init_statemachine;

	trictrl: process(iD)
	begin
		if( iD = '0' ) then
			DQ <= '0';
		else
			DQ <= 'Z';
		end if;
	end process trictrl;
	
end architecture structural;

PACKAGE PROTOCOL_PKG IS
		COMPONENT one_wire
		END COMPONENT;
END PROTOCOL_PKG;