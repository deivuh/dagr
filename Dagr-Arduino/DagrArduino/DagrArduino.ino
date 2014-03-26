

//"services.h/spi.h/boards.h" is needed in every new project
#include <SPI.h>
#include <boards.h>
#include <ble_shield.h>
#include <services.h>
#include <Adafruit_NeoPixel.h>

//Pin used to connect to LED strip
#define PIN 3
//LED count on strip
#define LED_COUNT 7

//Initialize LED strip
Adafruit_NeoPixel strip = Adafruit_NeoPixel(LED_COUNT, PIN, NEO_GRB + NEO_KHZ800);


void setup()
{

  
  // Init. and start BLE library.
  ble_begin();
  
  // Enable serial debug
  Serial.begin(57600);
    
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'
}

void loop()
{
  static boolean analog_enabled = false;
  static byte old_state = LOW;
  
  // If data is ready
  while(ble_available())
  {
    // read out command and data
    byte data0 = ble_read();
    byte data1 = ble_read();
    byte data2 = ble_read();
    byte data3 = ble_read();    
 if (data0 == 0x02) // Command is to control PWM pin
    {

      //Some printing to console for debugging
      Serial.print((int)data1);
      Serial.print((int)data2);
      Serial.print((int)data3);    
    
      //Set use received data to set new RGB color
      colorWipe(strip.Color((int)data1, (int)data2, (int)data3)); // Red      
    }
   
  }
  
  //  If not connected..
  if (!ble_connected())
  {

  }
  
  // Allow BLE Shield to send/receive data
  ble_do_events();  
}

//Change all LEDs to color
void colorWipe(uint32_t c) {
  for(uint16_t i=0; i<strip.numPixels(); i++) {
      strip.setPixelColor(i, c);
      strip.show();

  }
}


