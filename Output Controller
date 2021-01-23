-----------------------------------------------------------------------------
-- Company:     Cosc 56 20X
-- Engineer:    Joseph Notis
-- 
-- Create Date: 08/22/2020 07:21:23 PM
-- Design Name: OutputSetup
-- Module Name: OutputSetup - Behavioral
-- Project Name: Morse Code Sender
-- Target Devices: Basys3/Artix7
-- Tool Versions: Vivado 2018.3
-- Description: 
-- Converts the 8-bit representation of morse code into the dots/dash --output 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Redesigned to include an FSM
-- Revision 0.03 - Resolved terminal count issue with Parser
-- Revision 0.04 - Added post_out to handle with the space between --morse signals
-- Revision 0.05 - Added timing for end of character and spaces using --states and counters
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OutputSetup is
	port(clk:		in	std_logic;     -- 10Hz morse clock
	     out_start:   in  std_logic;
    	 morse8:		in	std_logic_vector(7 downto 0);
    	 out_en:		in	std_logic;
-- signal_done in controller
         take_morse:	in	std_logic;            
 morse_out:		out	std_logic;
         signal_en:     out std_logic;
         out_done:	out	std_logic);
end OutputSetup;



architecture Behavioral of OutputSetup is
type state_type is (idle, shift1, get_morse, wait_out, send_out, post_out, last_bit1, last_bit2, space);
signal curr_state, next_state: state_type;
-- Parser signals
-- One higher than the bit position (makes tc easier)
signal bit_pos: integer range 0 to 5 := 5; 
signal bit_tc: std_logic := '0';
signal mbit: std_logic := '0';
signal shift_en: std_logic := '0';  -- Shift to next bit
signal bit_reset: std_logic := '0'; 

-- Timing for space between wordss
signal space_en: std_logic := '0'; -- enables space counter
signal space_count: integer range 0 to 2 := 0;
signal space_tc: std_logic := '0';

begin
-- Serially parses the morse code from the MSB to LSB
Parser: process(clk, bit_pos, morse8, out_en, shift_en, bit_reset)
begin

if rising_edge(clk) then
    if bit_reset = '1' then
        bit_pos <= 5;
    elsif out_en = '1' and shift_en = '1' then
        if bit_pos = 0 then
            bit_pos <= 5;
        else
            bit_pos <= bit_pos - 1;
        end if;
    else
        bit_pos <= bit_pos;
    end if;
end if;

    if bit_pos = 0 and out_en = '1' then
        bit_tc <= '1';
    else
        bit_tc <= '0';
    end if;
    mbit <= morse8(bit_pos);

end process Parser;

SpaceCounter: process(clk, space_count)
begin
    if rising_edge(clk) then
        if space_en = '1' and space_count = 2 then
            space_count <= 0;
        elsif space_en = '1' then
            space_count <= space_count + 1;
        else
            space_count <= space_count;
        end if;
    end if;
    
    if space_count = 2 then
        space_tc <= '1';
    else
        space_tc <= '0';
    end if;
end process SpaceCounter;
----------------
-- Controller --
----------------
FSMupdate: process(clk)
begin
	if rising_edge(clk) then
		curr_state <= next_state;
	end if;
end process FSMupdate;

FSMcomb: process(curr_state, morse8, out_start, take_morse, mbit, bit_pos, bit_tc, space_tc)
begin
	next_state <= curr_state;
    shift_en <= '0';
    signal_en <= '0';
    bit_reset <= '0';
    out_done <= '0';
    morse_out <= '0';
    space_en <= '0';

	case curr_state is
	   
	   -- Wait until a new bit is read
		when idle =>
		  if out_start = '1' then
		      next_state <= shift1;
		  end if;
		  
-- Use the parser to find the leading 1 or recognize a dud/space
		when shift1 =>
		  if morse8(7) = '1' then
		      next_state <= space;
		  elsif bit_tc = '1' then
		      out_done <= '1';
		      bit_reset <= '1';
		      next_state <= idle;
		  elsif mbit = '1' then
		      next_state <= get_morse;
		  else
		      shift_en <= '1';
		  end if;
		  
		-- Shift to the next morse signal
        when get_morse =>
            shift_en <= '1';
            next_state <= wait_out;
        
        -- Wait until ready to send a new dot/dash
        when wait_out =>
            if take_morse = '1' then
                next_state <= send_out;
            end if;
        
        -- Send the dot/dash as an output signal
        when send_out =>      
            signal_en <= '1';
            morse_out <= mbit;
            if take_morse = '0' then
                next_state <= post_out;
            end if;
        
        -- Wait for 1 unit and either get next morse bit
        --   or handle end of word    
        when post_out =>     
            if take_morse = '1' then
                if bit_tc = '1' then
                    next_state <= last_bit1;
                else
                    next_state <= get_morse;
                end if; 
            end if;
        
        -- Wait the 1st of 2 extra end of word units
        when last_bit1 =>    
            if take_morse = '0' then 
                next_state <= last_bit2;
            end if;
        
        
        -- Wait for the 2nd of 2 extra end-of-word units
        when last_bit2 =>
            if take_morse = '1' then
                out_done <= '1';
                next_state <= idle;
                bit_reset <= '1';
            end if;
        -- Handle space between words (3 extra units)
        when space =>
            if take_morse = '1' then
                space_en <= '1';
                if space_tc = '1' then
                    next_state <= last_bit1;
                 end if;
            end if;
	end case;
end process FSMcomb;
end Behavioral;
