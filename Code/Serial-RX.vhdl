-----------------------------------------------------------------------------
-- Company: 		Cosc56 31 20X
-- Engineer/Name:   Joseph Notis
-- 
-- Create Date:    	12:55:02 08/16/2020 
-- Design Name: 	SerialRx
-- Module Name:     SerialRx - Behavioral 
-- Project Name:    Morse Code Sender
-- Target Devices:  Basys3/Artix7
-- Tool versions: 	Vivado 2018.3
-- Dependencies:    Optional: mux7seg.vhd (7-segment display)
-- Description: 	Serial asynchronous receiver for a UART protocol
--
-- Revisions: 
--  Revision 0.01 - File Created
--  Revision 0.02 - Updated controller to eliminate redundencies and combinedbit1 counter with baud couner
--  Revision 0.03 - Changed baud counter to do more checks with the first it --(N/2)
--  Revision 0.04 - Changed baud to 9,600 for morse code
--  Revision 0.05 - Chanced clock frequency from 10MHz to 100MHz
--  Revision 0.06 - Removed mux7seg for use with MorseCode-shell.vhd
-- Additional Comments: 
--    Based off the old lab 5 provided by Professor Hansen and Labs 4 (SPIBus) and 5 (Digital Filter) 20X
----------------------------------------------------------------------------------
library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity SerialRx is
Port (clk :           in STD_LOGIC;                     -- 10MHz masterclock
      RsRx :          in STD_LOGIC;                  -- received bitstream
     --  7-segment display outputs (for testing SerialRx in hardware)
--      seg	: out std_logic_vector(0 to 6);
--      dp    : out std_logic;
--      an 	: out std_logic_vector(3 downto 0);
-- SerialRx outputs
--      rx_shift :      out STD_LOGIC;       -- for testing only
  rx_data :       out STD_LOGIC_VECTOR (7 downto 0);   -- data byte
  rx_done_tick :  out STD_LOGIC);
end SerialRx;

architecture behavior of SerialRX is

-- 7-segment display
--component mux7seg is
--    Port ( 	clk : in  STD_LOGIC;
--           	y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);	
--           	dp_set : in std_logic_vector(3 downto 0);				
--           	seg : out  STD_LOGIC_VECTOR (0 to 6);
--          	dp : out std_logic;
--           	an : out  STD_LOGIC_VECTOR (3 downto 0) );			
--end component;

constant CLOCK_FREQUENCY : integer := 100000000;	-- 100 MHz Basys3 Clock	
-- Baud rate of UART protocon in WaveForms
constant BAUD_RATE : integer := 9600;constant BAUD_COUNT : integer := integer(CLOCK_FREQUENCY / BAUD_RATE);
constant BIT1_COUNT: integer := integer(BAUD_COUNT / 2);
constant NUM_BITS : integer := 10; -- 8-bit ASCII, 1 start bit, 1 stop bit
-- Synchronizer
signal rsrx_sync: std_logic := '1';
signal rsrx_flop1: std_logic := '1';
-- shift register
signal ser_data_reg: std_logic_vector(9 downto 0) := (others=>'0');   
-- output register
signal i_rx_data: std_logic_vector(7 downto 0) := (others=>'0');       
signal i_rx_done_tick: std_logic := '0';

-- controller outputs
signal clear_shiftreg: std_logic := '0';
signal shift_en: std_logic := '0';
signal load_en: std_logic := '0';

-- Baud counter
signal baud_ctr: integer range 0 to BAUD_COUNT := 0;
signal baud_en: std_logic := '0';
signal baud_tc: std_logic := '0';
signal bit1_en: std_logic := '0';
signal bit1_tc: std_logic := '0';

-- Shift counter
signal shift_tc: std_logic := '0';
signal n_shifts: integer range 0 to NUM_BITS := 0;

-- Controller FSM
type state_type is (idle, waitbit1, waitshift, shift, dataready);	
signal curr_state, next_state: state_type;

begin

---------------------------
-- Component declaration --
---------------------------

-- 7-segment display - shows received data in hex form (use in hardware testsonly)
--display: mux7seg port map( 
--            clk => clk,				-- runs on the 1 MHz clock
--           	y3 => "0000", 		        
--           	y2 => "0000", 	
--           	y1 => i_rx_data(7 downto 4), 		
--           	y0 => i_rx_data(3 downto 0),		
--           	dp_set => "0000",           -- decimal points off
--          	seg => seg,
--          	dp => dp,
--           	an => an );

--------------
-- Datapath --
--------------

-- Synchronizer
synchronizer: process(clk, rsrx, rsrx_flop1)
begin	
	if rising_edge(clk) then	
        rsrx_flop1 <= rsrx;	
        rsrx_sync <= rsrx_flop1;
	end if;
end process synchronizer;

-- Shift Register: right shift and update ser_data_reg when enabled(shift_en)
 ShiftRegister: process(clk, clear_shiftreg, shift_en
begin        
  if rising_edge(clk) then  
    if clear_shiftreg = '1' then
        ser_data_reg <= (others => '0');    
    else          
if shift_en='1' then
		  ser_data_reg <= rsr_sync & ser_data_reg(9 downto 1);
        else
            ser_data_reg <= ser_data_reg;
        end if;
    end if;
  end if;
end process ShiftRegister;

-- Parallel Load Register: receive ser_data_reg (shift reg) when enabled --(load_en)
OutputRegister: process (clk, load_en, i_rx_data, i_rx_done_tick)
begin
   if rising_edge(clk) then
       if load_en='1' then
            i_rx_data <= ser_data_reg(8 downto 1);
            i_rx_done_tick <= '1';
        else
            i_rx_data <= i_rx_data;
            i_rx_done_tick <= '0';
        end if;
    end if;
    rx_data <= i_rx_data;
    rx_done_tick <= i_rx_done_tick;
end process OutputRegister;
----------------
-- Controller --
----------------
--Count number of bits input to the serial data register
ShiftCounter: process(clk, n_shifts)
begin
	if rising_edge(clk) then
        if n_shifts = NUM_BITS then
            n_shifts <= 0;
        elsif shift_en = '1' then
            n_shifts <= n_shifts + 1;
        else
            n_shifts <= n_shifts;
        end if;
    end if;
    
  if n_shifts = NUM_BITS-1 then 
    shift_tc <= '1';
  else 
    shift_tc <= '0';
  end if; 
end process ShiftCounter;

-- Timing counter for when to read an input bit
BaudCounter: process(clk, baud_ctr, baud_en, bit1_en)
begin
	if rising_edge(clk) then
		if baud_en = '1' and baud_ctr < BAUD_COUNT - 1 then
   		 	baud_ctr <= baud_ctr + 1;
   		elsif bit1_en = '1' and baud_ctr < BIT1_COUNT - 1 then
   		    baud_ctr <= baud_ctr + 1; 
    	else
    	   baud_ctr <= 0;
    	end if;
end if;
    
  if baud_en = '1' and baud_ctr = BAUD_COUNT - 1 then
    baud_tc <= '1';
    bit1_tc <= '0';
  elsif bit1_en= '1' and baud_ctr = BIT1_COUNT - 1 then
    bit1_tc <= '1';
    baud_tc <= '0';
  else
    baud_tc <= '0';
    bit1_tc <= '0';
  end if;
end process BaudCounter;


-- Finite State Machine for Serial Receiver
FSMupdate: process(clk)
begin
	if rising_edge(clk) then
		curr_state <= next_state;	
end if;
end process FSMupdate

FSMcomb: process(curr_state, rsrx_sync, shift_tc, bit1_tc, baud_tc)
begin
	next_state <= curr_state;
  	load_en <= '0'; 
  	shift_en <= '0';
    bit1_en <= '0';
    baud_en <= '0';
--    rx_shift <= '0'; (uncomment in testing)

	case curr_state is
		when idle =>
			if rsrx_sync='0' then 
			     next_state <= waitbit1;
			else
			     next_state <= idle;
            end if;

		when waitbit1 =>
        	bit1_en <= '1';
			if bit1_tc='1' then next_state <= shift;
			else next_state <= waitbit1;
			end if;
    
    	when waitshift =>
    		baud_en <= '1';
        	if baud_tc = '1' then next_state <= shift;
        	else next_state <= waitshift;
	        end if;


	    when shift =>
--    	    rx_shift <= '1'; (uncomment in testing)
    	    shift_en <= '1';
        	if shift_tc = '1' then next_state <= dataready;
	        else next_state <= waitshift;
	        end if;
    
    	when dataready =>
			load_en <='1';
			next_state <= idle;         
	end case;
end process FSMcomb;

end behavior;
