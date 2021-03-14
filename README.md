# Morse-Translator
VHDL project which converts a UART ASCII input into Morse Code output (LED and sound). Coded for a XILINX Basys 3 Artix-7 in COSC 56 at Dartmouth College with Joseph Notis

# Introduction

This project takes text and converts it into decipherable Morse Code. When the Translate switch is on, the user can input characters, words, or even sentences into the Waveforms UART window. If the Sound switch is on, the Waveforms scope connected to the designated PMOD port outputs Morse Code through sound. If the Light switch is on, the Basys-3 LED outputs Morse Code through light.
  
# Design Solution

Specification

Our system takes in 4 inputs, which includes the three switches, SerialRX input from Waveforms.

Translate Switch: this input notifies the system whether to use the SerialRX input.

Light Switch: this input notifies the system whether to output the Morse Code as Light or not.

Sound Switch: this input notifies the system whether to output the Morse Code as Sound through the PMOD port or not.

SerialRX Port: this PMOD port takes in the ASCII code from the Waveforms UART Protocol and relays it to the system.

Our system also has three outputs, an LED for light output and two PMOD ports, one for the sound output as well as one for the logic analyzer for testing and debugging. These inputs and outputs are displayed in Appendix A. Figure 1 concerns the PMOD connections and figure 2 concerns the on-board inputs and outputs.

Broadly speaking, the system takes in text and outputs Morse Code. For example, typing “a,” (or “A”) gives the signal “.-” in morse. An additional layer of complexity is added to create strings of letters. Typing “bat” should give “-... .- -” rather than “-....--”, as the spacing, either visual gaps in the light or silence in sound output, is necessary to decipher the letters. Another layer is added when typing “a bat,” as the space between words is different than the space between letters. Strictly speaking, the sound and LEDs turn on for 0.004 seconds for a dot and 0.024 seconds for a dash (three times longer than a dot), and spacing between characters is always 0.004 seconds, while spacing between words is 0.028 seconds (seven times a dot length). These layers of nuance necessitate additional processes and thought. In order to handle our inputs to give the user the related outputs, the project is broken down into several large blocks.

UART Protocol: the SerialRx process handles the typed input. All ASCII characters, including letters, numbers, and spaces are transmitted. 

Dictionary. The ASCII character is passed one at a time to the dictionary, which uses case statements to find the corresponding Morse signal. This Morse signal is 8 bits and has a leading “1” which is used by the state machine to recognize the true morse code. For example, “a” is then output as “00000101.”

For timing purposes, this Morse code signal is then placed in a queue, which has room for 256 characters. This queue is fully implemented and outputs pertinent information, such as if it is empty or full, as seen in the block diagram in Appendix B.
The Morse Code signal is taken out of the queue and manipulated using the Output controller and datapath. The datapath specifically converts the ones and zeros of a Morse code signal, where they represent dashes and dots respectively into a bitstring where the ones represent output on and the zeros represent output off. The controller then adds zeros for spacing.
Lastly, the top shell file combines all the processes, and divides the 10 MHz clock down to 500 Hz for the output. Here, the signal from the output datapath and controller is relayed to the relevant PMOD ports and LED outputs, as shown in Appendix A and detailed in the xdc constraints file in Appendix E.

# Operating Instructions

Set WaveForms with a UART Protocol, Logic Analyzer, and Oscilloscope with the same configuration as seen in Appendix J. Do this prior to turning on the Basys3.

Connect the Analog Discovery 2 (AD2) to the Basys3 with the following connections, as seen in Appendix A:

Connect the PMOD Test Pin Header (PTPH) to the top row of PMOD JA pins. Make sure that the GND and VCC pins are properly
aligned.

Connect DIO 0 to the PTPH port P1, which should be aligned with PMOD JA1.

If you would like to read the output of the Morse code signal using the Logic Analyzer, connect DIO 1 to the PTPH port P2, which should be connected to PMOD JA2. Connect a ground wire (black) to GND.

For sound output, connect the scope 1+ connector to the PTPH pin P4 and the scope 1- wire to the vertical GND pin.

Enable continuous scan on the oscilloscope for sound output.

With a connected flash drive containing only the Morse code .bit file, power on the Basys-3.

To enable translation, make sure that SW15 is high

To enable LED output, set SW14 to high

To enable audio, set SW13 to high

In the “TX” input field on the Protocol window of WaveForms, type the message. It is recommended that you use send word at a time, but a phrase will also work.

Once your message is ready to send, hit the “Send” button to the right of the TX input field.
