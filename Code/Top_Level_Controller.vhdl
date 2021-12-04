----------------------------------------------------------------------------------
-- Company:     Cosc 56 20X
-- Engineers:    Ariel Attias and Joseph Notis
-- 
-- Create Date: 08/24/2020 01:24:29 PM
-- Design Name: Top Project Shell-- Module Name: MorseCode-shell - Behavioral
-- Project Name: Keyboard to Morse Code Project
-- Target Devices: Basys 3 with AD2 and WaveForms software
-- Tool Versions: 
-- Description: This project takes in a typed out phrase and converts it into morse code,
--with sound and light outputs.
-- 
--The components below take in ASCII codes from the UARTinterface, converts 
-- it using a dictionary into a8 bit morse code string (e.g. a- "00000101", --after the first 1, 0 represents dots and 1 represents dashes),and then 
-- converts these dots and dashes into sound and light output.
--
-- Dependencies: 
--              SerialRx.vhd
--              dictionary.vhd
--              queue.vhd
--              output_controller.vhd
--              output_datapath.vhd
--              
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Set clock timing for simulation and output at different --speeds
-- Revision 0.03 - Added output ports and process for logic analyzer (JA2, --JA3)
-- Revision 0.04 - Added mux7seg for debugging
-- Revision 0.05 - added process for sound output, as well as another clock divider and signal
-- Revision 0.06 - commented out testing ports and signals
-- Additional Comments:
-- 
-----------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity MorseCode_shell is
 Port (mclk:               in  std_logic;
 ranslate_sw:       in  std_logic;
 light_sw:           in  std_logic;
       audio_sw:           in  std_logic;
 rsrx:               in  std_logic;
 signal_LA:          out std_logic;
signal_out:         out std_logic;
sound_out:          out std_logic
-- 7 segment display (inclusion is optional)
--        seg: out STD_LOGIC_VECTOR (0 to 6);	
--        dp:                 out std_logic;
--        an:                 out STD_LOGIC_VECTOR (3 downto 0);
);
end MorseCode_shell;
architecture Behavioral of MorseCode_shell is
-------------
-- Component Declarations
-------------
component MorseCode_controller is
    port (clk: in std_logic;
          translate_sw:      in std_logic;
          prev_output_done:  in std_logic;     -- out_done in OutputSetup
          queue_empty:       in std_logic;
          translate_en:      out std_logic;
          output_circuit_en: out std_logic;    -- new_char in OutputSetup
          read_en:           out std_logic);
 end component;
 
 component SerialRx is
    port (clk :              in STD_LOGIC;             -- 10MHz master clock           RsRx :             in STD_LOGIC;                       -- received bit stream
rx_data :          out STD_LOGIC_VECTOR (7 downto 0);   -- data byte          rx_done_tick :     out STD_LOGIC);
end component;

component dictionary is 
    port (clk:               in STD_LOGIC;
          translate_en:      in STD_LOGIC;
--ascii value given by keyboard
          ascii_code:        in  STD_LOGIC_VECTOR(7 downto 0); 
--morse code ouput in dots and dashes    
          morse_code:        out STD_LOGIC_VECTOR(7 downto 0)); 
end component;
component queue is
    port(clk:                in STD_LOGIC;
         reset:              in STD_LOGIC;  
         wr_en:              in STD_LOGIC;
         wdata:              in STD_LOGIC_VECTOR(7 downto 0); 
         rd_en:              in STD_LOGIC;
         rdata:              out STD_LOGIC_VECTOR(7 downto 0);
         empty:              out STD_LOGIC;
         full:               out STD_LOGIC;
         w_confirm:          out STD_LOGIC;
         r_confirm:          out STD_LOGIC);
end component;



component OutputSetup is
 port(clk:			     in	std_logic;     -- 10Hz morse clock		     out_start:          in std_logic;
morse8:		     in	std_logic_vector(7 downto 0);         take_morse:	     in	std_logic;    -- signal_done in controller;
    out_en:		     in	std_logic;
 morse_out:		     out std_logic;
 signal_en:          out std_logic;         
out_done:		     out std_logic);
end component;

component OutputSender is
    port(clk:                in std_logic;
         out_en:             in std_logic;
         morse_out:          in std_logic;
         take_morse:         out std_logic;
         light_sound_output: out std_logic);
end component;

-- 7-segment display
--component mux7seg is
--    port(clk:                in STD_LOGIC;
--         y0, y1, y2, y3:     in STD_LOGIC_VECTOR (3 downto 0);	
--         dp_set:             in std_logic_vector(3 downto 0);			
--         seg:                out STD_LOGIC_VECTOR (0 to 6);	
--         dp:                 out std_logic;
--         an:                 out STD_LOGIC_VECTOR (3 downto 0) );		--end component;
---------------------
-- Clock Divider and Process Signals
---------------------
-- From Lab3_shell.vhd:
-- Signals for the clock divider, which divides the master clock down to --10000 Hz
-- Master clock frequency / CLOCK_DIVIDER_VALUE = 500 Hz
constant SOUND_CLOCK_DIVIDER_VALUE: integer := 2E6;  -- For Sound output
--constant SOUND_CLOCK_DIVIDER_VALUE: integer := 5E3;   -- For simulation
--sound output requires a 500 Hz clock
-- clock divider counter for sound 
signal soundclkdiv: unsigned(22 downto 0) := (others => '0');    signal soundclkdiv_tog: std_logic := '0';                        -- terminal count
signal soundclk: std_logic := '0';   
--signal required for sound
signal square_hold:std_logic:= '0';--our sound signal 
---------------------
-- Component Signals and Intermediaries
---------------------
-- 1-bit representation of morse (0 is dot, 1 is dash)
signal morse_bit: std_logic := '0';
-- Previous output is complete (need to fetch next from the queue)
signal prev_output_done: std_logic := '0'; -- out_done in OutputSetup
-- Rx input done
signal rx_done_tick: std_logic := '0';     -- from SerialRx
-- Queue is empty
signal queue_empty: std_logic := '0';
-- Enables dictionary
signal translate_en: std_logic := '0';
-- Enable parsing morse bitstring and output
signal output_circuit_en: std_logic := '0';
-- Write to queue
signal write_en: std_logic := '0';
-- Read to queue
signal read_en: std_logic := '0';
-- Confirm write to queue
signal w_confirm: std_logic := '0';
-- Confirm read to queue
signal r_confirm: std_logic := '0';
-- ASCII letter input
signal rx_data: std_logic_vector (7 downto 0) := (others => '0');
-- 8 bit morse representation of a character from dictionary
signal morse_code_dict: std_logic_vector (7 downto 0) := (others => '0');
-- Reset the queue
signal reset: std_logic := '0';
-- 8 bit morse representation of a character read from the queue
signal morse_code_out: std_logic_vector (7 downto 0) := (others => '0');
-- Queue is full
signal queue_full: std_logic := '0';
-- Take a new morse code bit to be output
signal take_morse: std_logic := '0';
-- Enable output (audio or light)
signal signal_en: std_logic := '0';
-- Output for the character is complete
signal out_done: std_logic := '0';
-- Enable output circuit
signal out_en: std_logic := '0';
--internal signal for morse code from UART/keyboard
signal i_signal: std_logic := '0';

begin
-------------
-- Processes
-------------
-- From Lab3_shell.vhd:
-- Clock buffer for the 20 kHz clock
-- The BUFG component puts the slow clock onto the FPGA clocking network
--slow clock buffer for sound clock     
sound_clock_buffer: BUFG
      port map (I => soundclkdiv_tog,
                O => soundclk );

-- From Lab3_shell.vhd
-- Divide the master clock down to 20 Hz, then toggling the
--clock divider for sound clock
sound_clock_divider: process(mclk)
begin
	if rising_edge(mclk) then
	   	if soundclkdiv = SOUND_CLOCK_DIVIDER_VALUE-1 then 
	   	    soundclkdiv_tog <= NOT(soundclkdiv_tog);        -- T flipflop
			soundclkdiv <= (others => '0')
		else
			soundclkdiv <= soundclkdiv + 1;                 -- Counter
		end if;
end if;
end process sound_clock_divider;
--sound is produced on rising and falling edges of square wave.
--This process converted the dots and dashes into edges
sound_output: process(mclk, translate_sw, audio_sw, i_signal)
begin
    if rising_edge(mclk) then--using our slow clock
        if translate_sw ='1' and audio_sw = '1' then --if switch is HIGH, we use our UART signals
            if i_signal='1' then --if we are one a rising edge of a dot or dash
                square_hold<= not(square_hold); --change the value of ourwave, producing an edge and therefore a sound
            else 
                square_hold<= square_hold; --the wave value doesn't change,and no sound is produced
            end if;
        else
             square_hold<= square_hold;
        end if;
    end if;
end process;

translate: process(mclk, rx_done_tick)
begin
    if rising_edge(mclk) then
        if rx_done_tick = '1' then
            write_en <= '1';
        else
            write_en <= '0';
        end if;
    end if;
end process translate;
-- wire up the outputs
linkouts: process(light_sw, i_signal, square_hold )
begin
    signal_LA <= i_signal;
    if light_sw = '1' then 
        signal_out <= i_signal;
    else 
        signal_out <= '0';
    end if;
    sound_out <= square_hold;
end process linkouts;

-------------
-- Port maps
-------------
controller: MorseCode_controller port map(
    clk => mclk,
    translate_sw      => translate_sw,
    prev_output_done  => prev_output_done,
    queue_empty       => queue_empty,
    translate_en      => translate_en,
    output_circuit_en => output_circuit_en,
    read_en           => read_en);
    
serial_Rx: SerialRx port map (
    clk          => mclk,
    rsrx         => rsrx,
    rx_data      => rx_data,
    rx_done_tick => rx_done_tick);
    
dict: dictionary port map(
    clk          => mclk,
    translate_en => translate_en,
    ascii_code   => rx_data,
    morse_code   => morse_code_dict);
 
morse_queue: queue port map (
    clk   => mclk,
    reset => reset,
    wr_en => write_en,
    wdata => morse_code_dict,
    rd_en => read_en,
    rdata => morse_code_out,
    empty => queue_empty,
    full  => queue_full,
    w_confirm => w_confirm,
    r_confirm => r_confirm);
    
out_controller: OutputSetup port map(
    clk        => mclk,
    out_start  => output_circuit_en,
    morse8     => morse_code_out,
    take_morse => take_morse,
    out_en     => output_circuit_en,
    morse_out  => morse_bit,
    signal_en  => out_en,
    out_done   => prev_output_done);

out_datapath: OutputSender port map(
    clk        => soundclk,
    out_en     => out_en,
    morse_out  => morse_bit,
    take_morse => take_morse,
    light_sound_output => i_signal);

-- Uncomment (along with component and display in constraints) to see ASCIIinput
--display: mux7seg port map( 
--            clk => mclk,				-- runs on the 100 MHz clock
--           	y3  => "0000", 		        
--           	y2  => "0000", 	
--           	y1  => rx_data(7 downto 4), 		
--           	y0  => rx_data(3 downto 0),		
--           	dp_set => "0000",           -- decimal points off
--          	seg => seg,
--          	dp  => dp,
--           	an  => an);
end Behavioral;
