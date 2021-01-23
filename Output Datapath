-----------------------------------------------------------------------------
-- Company: ENGS 31 20X
-- Engineer: Ariel Attias and Joseph Notis
-- 
-- Create Date: 08/24/2020 07:30:36 PM
-- Design Name: Sound and Light Morse Code Output
-- Module Name: OutputSender
-- Project Name: Keyboard to Morse Code project
-- Target Devices: Basys 3/Artix 7
-- Tool Versions: Vivado 2018.3.1
-- Description: Take a Bit representing a DOT (0) or DASH (1) 
--      and converts it to the necessary sound and light output
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Moved most timing related to spaces between signals --to controller
-- Revision 0.03 - Doubled length of dots and dashes to make outputs --easier to see
-- Additional Comments:
-- 
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OutputSender is
  Port ( clk:                   in  std_logic;
         out_en:                in  std_logic;
 --taking in the morse_out bit from the controller

         morse_out:             in  std_logic;  
--signal flagging if output can be retrieved        
        take_morse:            out std_logic;
        light_sound_output:    out std_logic); --output
end OutputSender;

architecture Behavioral of OutputSender is
-- a dot is flashing for one unit of time
constant DOTCOUNT:  integer := 2;
-- a dash is flashing for three units of time
constant DASHCOUNT: integer := 6;
signal count: integer range 0 to DASHCOUNT:=0;
signal out_bit: std_logic := '0';
signal i_out:   std_logic := '0';

begin

morse_bit_to_output: process(clk, morse_out, out_en, i_out)
begin
if out_en = '1' then --if output is enabled
    out_bit <= morse_out; --we process the bit we've received
else
    out_bit <= i_out;    --we process the same bit as before
end if;

if rising_edge(clk) then 
        take_morse <= '0';--process is busy
        if out_bit='1' then --if out_bit is a dash
--if our count is less than the necessary amount for dashes
            if count < (DASHCOUNT) then                 
count <= count + 1; --increment our count
-- remember we still need to output the dash
                i_out <= '1';                 
if out_en = '1' then --if we've enabled the output
--our output, the state of the LED or the sound, is on.
                   	 light_sound_output <= '1'; 
                end if;
            else --we've timed out of the DASH
                 take_morse<='1'; --process is free
			--we want our output to be off
                 light_sound_output <= '0';
                 count <= 0; --start our count over
            end if;
        else --if out_bit is a dot
-- if our count is less than the neccessary amount for dots            
		if count < (DOTCOUNT) then                
 		count <= count + 1; --increment our count
                	i_out <= '0'; -- our old bit, for the future, is 0
                	if out_en = '1' then --if we've enabled the output
                  	light_sound_output <= '1'; --turn the output on
                end if;
            else -- if we've timed out of the DOT state
                 take_morse<='1';--process is free
                 light_sound_output <= '0';-- turn the output off
                 count <= 0;--start the count over
            end if;
   end if;
end if;
end process;
end Behavioral;
