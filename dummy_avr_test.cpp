#include <Arduino.h>
#include <IRremote.h> // To test if IRremote headers are found via the interface library

void setup() {
  // Dummy setup
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  // Dummy loop
  digitalWrite(LED_BUILTIN, HIGH);
  delay(500);
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
}

// The main() function is provided by the Arduino core library (main.cpp)
// when we link against arduino_core.a, so it's not needed here. 