-----------------------------------------------------------------------------
-- Company: ENGS 31
-- Engineer: Ariel Attias with partner Joseph Notis
-- 
-- Create Date: 08/19/2020 07:18:32 PM
-- Design Name: 
-- Module Name: dictionary - Behavioral
-- Project Name: Morse Code Project
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Uppercase ascii characters added
-- Additional Comments:
-- 
--------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dictionary is
 port (clk: in STD_LOGIC;
        translate_en: in  STD_LOGIC;
--ascii value given by keyboard
          ascii_code: in  STD_LOGIC_VECTOR(7 downto 0); 
--morse code output in dots and dashes          
morse_code: out STD_LOGIC_VECTOR(7 downto 0) );
end dictionary;

architecture Behavioral of dictionary is
signal morse_code_i: STD_LOGIC_VECTOR(7 downto 0):="00000000"; 
begin
--1 is for dashes, 0 is for dots, and a leading 1 is introduced for translation later
--this dictionary is for lowercase and uppercase characters and numerical digits only
morse_code_i<= "00000101" when ascii_code = ("01100001" or "01000001") else --a. for example, a is dot-dash. here we add our leading one
 	 "00011000" when ascii_code = ("01100010" or "01000010") else --b
 	 "00011010" when ascii_code = ("01100011" or "01000011") else --c
       "00001100" when ascii_code = ("01100100" or "01000100") else --d
       "00000010" when ascii_code = ("01100101" or "01000101") else --e
       "00010010" when ascii_code = ("01100110" or "01000110") else --f
       "00001110" when ascii_code = ("01100111" or "01000111") else --g
       "00010000" when ascii_code = ("01101000" or "01001000") else --h
       "00000100" when ascii_code = ("01101001" or "01001001") else --i
       "00010111" when ascii_code = ("01101010" or "01001010") else --j
       "00001101" when ascii_code = ("01101011" or "01001011")else --k
       "00010100" when ascii_code = ("01101100" or "01001100") else --l
       "00000111" when ascii_code = ("01101101" or "01001101") else --m
       "00000110" when ascii_code = ("01101110" or "01001110") else --n
       "00001111" when ascii_code = ("01101111" or "01001111") else --o
       "00010110" when ascii_code = ("01110000" or "01010000") else --p
       "00011101" when ascii_code = ("01110001" or "01010001") else --q
       "00001010" when ascii_code = ("01110010" or "01010010") else --r
       "00001000" when ascii_code = ("01110011" or "01010011") else --s
       "00000011" when ascii_code = ("01110100" or "01010100") else --t
       "00001001" when ascii_code = ("01110101" or "01010101") else --u  
       "00010001" when ascii_code = ("01110110" or "01010110") else --v
       "00001011" when ascii_code = ("01110111" or "01010111") else --w
       "00011001" when ascii_code = ("01111000" or "01011000")else --x
       "00011011" when ascii_code = ("01111001" or "01011001") else --y
       "00011100" when ascii_code = ("01111010" or "01011010") else --z
                        
      "00111111" when ascii_code = "00000000" else --0
      "00101111" when ascii_code = "00000001" else --1
      "00100111" when ascii_code = "00000010" else --2
       "00100011" when ascii_code = "00000011" else --3
       "00100001" when ascii_code = "00000100" else --4
        "00100000" when ascii_code = "00000101" else --5
        "00110000" when ascii_code = "00000110" else --6
        "00111000" when ascii_code = "00000111" else --7
        "00111100" when ascii_code = "00001000" else --8
        "00111110" when ascii_code = "00001001" else --9
          --spacebar, which will differentiate words for us              
       "10000000" when ascii_code = "00100000" else 
        "00000000";
--register which outputs value on rising edge as well as when translation is --enabled
translate: process(clk, translate_en)
begin
    if rising_edge(clk) then
        if translate_en='1' then
            morse_code<=morse_code_i;
        end if;
    end if;
end process;
end Behavioral
