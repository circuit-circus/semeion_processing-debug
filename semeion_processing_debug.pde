// Example by Tom Igoe

import processing.serial.*;

int lf = 10;    // Linefeed in ASCII
String myString = null;
Serial myPort;  // The serial port

static int spectrumSteps = 32;
static int extraDataCount = 3;
int readStart = -1;
int[] data;

// Average values
static int avrgSampleCount = 25;
int[][] avrgCounterSamples;
int avrgSampleIndex = 0;
float[] movingAvrg;
float avrgAvrg = 0.0f;

// Used to automatically scale the mapping
int smallestY = 300;
int largestY = 400;

// Show the graph as filled?
boolean showFilled = false;

int  numberOfTests = 10, sensorThreshold = 8;
float threshold, previousThreshold;
boolean sensorCalibrated;
float newAvrg;
 
color bgColor;

void setup() {
  String[] ports = Serial.list(); 
  String portName = ""; //change the 0 to a 1 or 2 etc. to match your port

  // Automatically connect to the one named cu.usbmodem (for Macs only)
  for (int i = 0; i < ports.length; i++) {
    if (ports[i].indexOf("cu.usbmodem") > -1) {
      portName = ports[i];
      println("Connecting to: " + portName);
      break;
    }
  }

  if (portName != "") {
    myPort = new Serial(this, portName, 115200);
  }
  myPort.clear();
  // Throw out the first reading, in case we started reading 
  // in the middle of a string from the sender.
  myString = myPort.readStringUntil(lf);
  myString = null;

  //size(600, 300);
  fullScreen();

  // We also get the bias, peak and spectrumstart, so we add these two
  data = new int[spectrumSteps + extraDataCount];

  avrgCounterSamples = new int[spectrumSteps][avrgSampleCount];
  movingAvrg = new float[spectrumSteps];
  
  bgColor = color(0, 0, 0);
}

void draw() {
  

  while (myPort.available() > 0) {
    myString = myPort.readStringUntil(lf);
    if (myString != null) {
      data = int(split(myString, ','));
    }
  }
  
  fill(bgColor);
  rect(0, 0, width, height);

  if (data.length > -1) {
    if (readStart != data[2]) {
      //println("Bias: " + data[0]);
      //println("Peak: " + data[1]);
      readStart = data[2];
      println("Spectrum Start: " + readStart);
    }
  }
  textSize(16);
  fill(255);
  text(smallestY, 0, 16);
  text(largestY, 0, height);

  stroke(255);
  if (!showFilled) noFill();
  if (data.length > 0 && data.length > extraDataCount) {
    beginShape();
    if (showFilled) vertex(0, height);

    // Keep track of how many samples we've gotten
    avrgSampleIndex = avrgSampleIndex < avrgSampleCount-1 ? avrgSampleIndex + 1 : 0;

    // Scale graph if necessary, then draw data
    for (int i = extraDataCount; i < spectrumSteps; i++) {

      // Scale the bounds of the graph
      if (data[i] != 0) {
        if (data[i] < smallestY) {
          smallestY = data[i];
        }

        if (data[i] > largestY) {
          largestY = data[i];
        }
      }

      // Shift the index, so that we get a curve from 0
      int shiftedIndex = i - extraDataCount;
      float x = shiftedIndex * (width / spectrumSteps + extraDataCount);
      float y = MapToGraph(data[i]);
      vertex(x, y);

      // Fill avrg samples
      avrgCounterSamples[i][avrgSampleIndex] = data[i];
    }
    if (showFilled) vertex(width, height);
    endShape();

    // Draw moving avrg
    movingAvrg = GetMovingAverage(avrgCounterSamples);
    beginShape();
    stroke(255, 0, 0);
    for (int a = 3; a < movingAvrg.length; a++) {
      int shiftedIndex = a - extraDataCount;
      float x = shiftedIndex * (width / movingAvrg.length + extraDataCount);
      float y = MapToGraph(movingAvrg[a]);
      vertex(x, y);
    }
    endShape();

    // Draw average average
    stroke(0, 0, 255);
    avrgAvrg = GetAverageAverage(movingAvrg);
    float avrgY = MapToGraph(avrgAvrg);
    line(0, avrgY, width, avrgY);
   
    if(abs(avrgAvrg-threshold) > 0.5){
      newAvrg= abs(avrgAvrg-threshold);
    }
    else{
      newAvrg = 0;
    }
    fill(0,200,0);
    text(newAvrg, 0, avrgY);
    if(newAvrg < 75) {
      float tempBgMap = map(newAvrg, 0, 30, 0, 255);
      bgColor = color(tempBgMap, tempBgMap, tempBgMap);
    }
    else {
      bgColor = color(0, 0, 255);
    }
  }
  
  if(!sensorCalibrated) {
    bgColor = color(255, 0, 0);
  }
  
  if(millis()%10000<1000 && !sensorCalibrated){
    calibrateSensor();
    sensorCalibrated = true;
  }
  
  if(keyPressed) {
    if(key == 'c' || key == 'C') {
      sensorCalibrated = false;
    }
  }
  
}

float MapToGraph(float num) {
  return map(num, smallestY, largestY, 0, height);
}

float[] GetMovingAverage(int[][] arr) {
  int[] avrgTotalArr = new int[arr.length];
  float[] avrgArr = new float[arr.length];
  for (int i = 0; i < arr.length; i++) {
    for (int j = 0; j < arr[i].length; j++) {
      avrgTotalArr[i] += arr[i][j];
    }
    avrgArr[i] = avrgTotalArr[i] / arr[i].length;
  }
  return avrgArr;
}

float GetAverageAverage(float[] avrgArr) {
  float tempAvrg = 0.0f;
  for (int i = 0; i < avrgArr.length; i++) {
    tempAvrg += avrgArr[i];
  }
  tempAvrg /= avrgArr.length;
  return tempAvrg;
}

void calibrateSensor() {
  long vals = 0;
  for (int i = 0; i < numberOfTests; i++) {
    float reading = avrgAvrg;
    vals += reading;
  }
  float calibratedAverage = vals / numberOfTests;
  threshold = calibratedAverage;

}