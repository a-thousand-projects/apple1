/*  SmartyKit 1 - 2.8" TFT 320x240 Display module driver with TV output support (TV terminal). v.1.2
 *  http://www.smartykit.io/ 
 *  Copyright (C) 2019, Sergey Panarin <contact@smartykit.io>
 *  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
#undef _SMARTY_DEBUG_

// Video controller pins connections:
// D0 & D1 – reserved for Serial connection
// D2 -> Beeper (beeps when Video controller has loaded and beeps when char 0x07 (BELL) is received)
// D3 –> 4-16 ports decoder Video (9) out pin (signal is active when CPU writes to Video port)
// D4 -> NC (not connected)
// D5 -> Video BIT7 pin output 
// D6-D13 -> Video port input (8 pins) to connect to Video port (char code is transfered here) 
// A0-A3 -> 2.8" TFT 320x240 Display module connection (SPI bus)
// A4-A5 -> TV terminal via I2C bus (TWI)
#define BEEPER_PIN 2
inline void beep() { tone(BEEPER_PIN, 880, 200); }

#define CPU_WRITESTOVIDEOPORT_PIN 3
#define VIDEO_BIT7_PIN 5

int VideoPort[8] = {6, 7, 8, 9, 10, 11, 12, 13};

// SPI bus connections to Display module
#define TFT_CS -1
#define TFT_RST A0
#define TFT_DC A1
#define TFT_MOSI A2
#define TFT_CLK A3 
#define TFT_MISO -1
//SPI bus: CS is hard-wired to Low (not connected here), RST = A0, DC = A1, MOSI = A2, SCK = A3, MISO = not connected (NC)


#define TEXT_COLOR ILI9341_CYAN // could be customized from Smarty_TFT.h Color definitions: e.g. ILI9341_NAVY
#define BG_COLOR ILI9341_BLACK   // could be customized from Smarty_TFT.h Color definitions: e.g. ILI9341_DARKGREY


// Woz OS console color scheme
#define CONSOLE_PROMPT_COLOR ILI9341_BLUE
#define CONSOLE_COLON_COLOR ILI9341_MAGENTA //ILI9341_PURPLE
#define CONSOLE_DOT_COLOR ILI9341_OLIVE

#include <Terminal.h>

  
  Terminal TV_terminal;   // creating instance of Terminal in I2C (TWI) mode, uses A4 (SDA) and A5 (SCL) as I2C bus
 

void setup() 
{
  Serial.begin(9600);
  Serial.println("setup()");
  pinMode(BEEPER_PIN, OUTPUT);
  pinMode(VIDEO_BIT7_PIN, OUTPUT); 

  DisplayBusy(); //wait until video setup is ready


  beep();

  for (int bit = 0; bit < 8; bit++) {
     pinMode(VideoPort[bit], INPUT); 
  };

  pinMode(CPU_WRITESTOVIDEOPORT_PIN, INPUT_PULLUP); 

  // Initialise the terminal
  TV_terminal.setFont(TERMINAL_FONT_40_NORMAL_SINGLE);
  TV_terminal.setCursor(0,0);
  TV_terminal.printLine("Smarty Kit Video Controller\n");
  
  //attaching an Interrupt Service Routine (ISR) to process print CPU print signal received at CPU_WRITESTOVIDEOPORT_PIN
  attachInterrupt(1, printCharToDisplay, RISING); 
  DisplayReady(); //default state after restart (ready to print) 
}

void loop() 
{
  //intentionally left blank
}

byte scan_code = 0;
//interruption service routine (ISR)
void printCharToDisplay(void) {   

  DisplayBusy();  
   
  scan_code = 0;
  for (int bit = 0; bit < 8 ; bit++) {
    int pinValue = digitalRead(VideoPort[bit]);    
    scan_code |= pinValue << (bit);   
  };
  scan_code = scan_code & 0x7F; //clear bit 7
  
  if (scan_code == 0x7F)
  {
     DisplayReady();    
     return; //skip initial setup value
  }
  else if (scan_code == 0x07) // 0x07 = BELL ASCII symbol
  {
    beep();
  }
  else if (scan_code == 0xD)
  {
     TV_terminal.printLine("");
  }
  else
  {         
    //make all symbols uppercase
    if (scan_code >= 0x60)
      scan_code -= 0x20;

     //print only visible chars, starting from blanc 
     if (scan_code >= 0x20)
     { 
      TV_terminal.send(scan_code);
        /* if (scan_code == 0x5C)      // prompt 
          Display_module.print((char)scan_code, CONSOLE_PROMPT_COLOR); 
         else if (scan_code == 0x3A) //:
          Display_module.print((char)scan_code, CONSOLE_COLON_COLOR); 
         else if (scan_code == 0x2E) //.
          Display_module.print((char)scan_code, CONSOLE_DOT_COLOR); 
         else
          Display_module.print((char)scan_code, TEXT_COLOR); 

        */
     }      
  }
  DisplayReady(); 
}

void DisplayReady()
{
  digitalWrite(VIDEO_BIT7_PIN, LOW); 
}

void DisplayBusy()
{
  digitalWrite(VIDEO_BIT7_PIN, HIGH); 
}
