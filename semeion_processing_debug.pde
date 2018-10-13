  

// Example by Tom Igoe

import processing.serial.*;

int lf = 10;    // Linefeed in ASCII
String myString = null;
Serial myPort;  // The serial port

int[] data;

void setup() {
  // List all the available serial ports
  printArray(Serial.list());
  // Open the port you are using at the rate you want:
  myPort = new Serial(this, Serial.list()[1], 9600);
  myPort.clear();
  // Throw out the first reading, in case we started reading 
  // in the middle of a string from the sender.
  myString = myPort.readStringUntil(lf);
  myString = null;
  
  size(600, 300);
  
  data = new int[32];
}

void draw() {
  while (myPort.available() > 0) {
    myString = myPort.readStringUntil(lf);
    if (myString != null) {
      data = int(split(myString, ','));
    }
  }
  
  background(0);
  for(int i = 0; i < data.length; i++) {
    ellipse(20 + i * (width / data.length), map(data[i], 0, 500, 0, height), 10, 10); 
  }
}