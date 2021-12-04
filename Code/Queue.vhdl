-----------------------------------------------------------------------------
-- Company: ENGS 31
-- Engineer: Ariel Attias
-- 
-- Create Date: 08/22/2020 06:23:13 PM
-- Design Name: Queue with ring buffer
-- Module Name: queue - Behavioral
-- Project Name: Keyboard-Morse Code Project
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: This queue is a FIFO implementation which regulates the rate 
--    at which the morse code information passes on to the output.
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - w_confirm and r_confirm bits added
-- Revision 0.03 - added size signal
-- Revision 0.05 - qmax changed to 127 from 7 for more space
-- Additional Comments:
-- 
--------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity queue is
    port(clk: in STD_LOGIC;
         reset: in STD_LOGIC;
         wr_en: in STD_LOGIC;
         wdata: in STD_LOGIC_VECTOR(7 downto 0);
         rd_en: in STD_LOGIC;
         rdata: out STD_LOGIC_VECTOR(7 downto 0); 
         empty: out STD_LOGIC;
         full: out STD_LOGIC;     
         w_confirm: out STD_LOGIC;
         r_confirm: out STD_LOGIC);
end queue;

architecture Behavioral of queue is
-- depth of our queue- it can hold 255 characters
    constant qMax: integer := 255;    
  
--where we write or read in array
signal waddr, raddr: unsigned(7 downto 0):=(others => '0'); 
-- counter which keeps track of the number of characters in the queue
signal size: integer:=0;
signal i_w_confirm, i_r_confirm: STD_LOGIC := '0';
  --queue itself, stores the 8 bit characters
type arr is array (qMax downto 0) of STD_LOGIC_VECTOR(7 downto 0);   
signal fifo :arr := (others => (others => '0'));
  
begin
read_write: process(clk,rd_en, wr_en,reset, i_w_confirm, i_r_confirm, waddr, raddr,size)
begin
    if rising_edge(clk) then
        
        if reset='1' then    -- clicking reset sets
            waddr<="00000000";-- the write address to 0 and
            raddr<="00000000";-- the read address to 0.
        --  if only writing from the queue:
        elsif (wr_en='1' and rd_en='0') then 
-- the number of characters in the queue increases by one
           size<=size+1;  
--confirm we've successfully written the character in
            i_w_confirm <= '1';            i_r_confirm <= '0';
            raddr<=raddr; -- leave head
    

            if waddr=126 then 
			-- increment tail by two, thereby rolling over to 0
        		waddr<=waddr+2; 
            else
                waddr<=waddr+1;--increment the tail by one
            end if; 
--assign the character to its spot
            fifo(to_integer((waddr)))<=wdata; 
          -- if only reading from the queue:
       elsif (wr_en='0' and rd_en='1') then               size<=size-1;
            waddr<=waddr;--leave tail;
            i_r_confirm <= '1';
            i_w_confirm <= '0';
            if raddr=126 then 
                raddr<=raddr+2;--incrmement head;
            else
                raddr<=raddr+1;--incrmement head;
            end if;
            
           rdata<=fifo(to_integer((raddr)));  
     --  if only writing from the queue:
        elsif (wr_en='1' and rd_en='1') then                   fifo(to_integer((waddr)))<=wdata;
            rdata<=fifo(to_integer((raddr)));
            i_w_confirm <= '1';
            i_r_confirm <= '1';
            
            if waddr=126 then 
                waddr<=waddr+2; -- increment tail
            else
                waddr<=waddr+1;
            end if; 
          
            if raddr=126 then 
                raddr<=raddr+2;--incrmement head;
            else
                raddr<=raddr+1;--incrmement head;
            end if;
         elsif (wr_en='0' and rd_en='0') then
            raddr<=raddr;--leave head;
            waddr<=waddr;--leave tail;
            i_w_confirm <= '0';
            i_r_confirm <= '0';
        end if;
    end if;
--if the number of elements in the queue reaches the depth of the queue
    if size=qMax then         
  empty <= '0'; -- we know it is not empty
        full  <= '1'; -- we know it is full
    elsif size=0 then -- if there are no characters in the queue
        empty <= '1'; -- it is definitely empty
        full  <= '0'; -- which means it definitely is not full
    else  -- if the number of characters is not 0 or the maximum
        empty <= '0'; -- the queue is not empty
        full  <= '0'; -- nor is it full
    end if;
    w_confirm <= i_w_confirm;
    r_confirm <= i_r_confirm;
end process;
end Behavioral;
