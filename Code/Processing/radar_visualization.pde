/**
 * Radar Visualization (Processing)
 * - Reads "angle,distance" from Arduino @ 9600 baud
 * - Draws polar sweep with points
 * 
 * Setup:
 * 1) Tools → Add Tool → Libraries… (no external libs needed)
 * 2) Set PORT_INDEX or PORT_NAME to match your Arduino port
 */

import processing.serial.*;

Serial port;

// Choose one of the following:
int PORT_INDEX = 0;        // Use index from the printed list
String PORT_NAME = null;   // OR set explicit name like "COM3" or "/dev/ttyACM0"

int[] distances = new int[181];  // latest distance per degree
int currentAngle = 0;

void settings() {
  size(900, 600);
}

void setup() {
  surface.setTitle("Arduino Radar Visualization");
  background(0);
  smooth();

  println("Available serial ports:");
  printArray(Serial.list());

  if (PORT_NAME != null) {
    port = new Serial(this, PORT_NAME, 9600);
  } else {
    String[] ports = Serial.list();
    if (ports.length == 0) {
      println("No serial ports found! Connect Arduino and restart.");
      exit();
    }
    int idx = constrain(PORT_INDEX, 0, ports.length - 1);
    port = new Serial(this, ports[idx], 9600);
    println("Using port: " + ports[idx]);
  }

  // Init distances with a large value
  for (int i = 0; i < distances.length; i++) distances[i] = 300;
}

String buffer = "";

void draw() {
  // Read serial
  while (port != null && port.available() > 0) {
    char c = port.readChar();
    if (c == '\n' || c == '\r') {
      parseLine(buffer.trim());
      buffer = "";
    } else {
      buffer += c;
    }
  }

  // Draw UI
  drawRadar();
}

void parseLine(String line) {
  if (line.length() == 0) return;
  // Expected format: angle,distance
  String[] parts = split(line, ',');
  if (parts.length != 2) return;

  try {
    int angle = constrain(parseInt(parts[0]), 0, 180);
    int dist  = max(0, parseInt(parts[1]));
    distances[angle] = dist;
    currentAngle = angle;
  } catch (Exception e) {
    // ignore malformed lines
  }
}

void drawRadar() {
  background(12);

  // Radar center
  float cx = width * 0.33;
  float cy = height * 0.85;
  float maxR = min(width * 0.6, height * 0.9);

  // Grid arcs
  stroke(40);
  noFill();
  for (int i = 1; i <= 5; i++) {
    float r = map(i, 1, 5, maxR*0.2, maxR);
    arc(cx, cy, r*2, r*2, PI, TWO_PI);
  }

  // Baseline
  line(cx - maxR, cy, cx + maxR, cy);

  // Angle ticks every 30 deg
  stroke(60);
  for (int ang = 0; ang <= 180; ang += 30) {
    float a = radians(ang);
    float x = cx + maxR * cos(a);
    float y = cy - maxR * sin(a);
    line(cx, cy, x, y);
  }

  // Sweep line
  stroke(100, 255, 100);
  float a = radians(currentAngle);
  line(cx, cy, cx + maxR * cos(a), cy - maxR * sin(a));

  // Plot points for recent distances
  stroke(0, 255, 0);
  for (int ang = 0; ang <= 180; ang++) {
    int d = distances[ang];
    // Map 0..300 cm to 0..maxR
    float r = map(min(d, 300), 0, 300, 0, maxR);
    float aa = radians(ang);
    float x = cx + r * cos(aa);
    float y = cy - r * sin(aa);
    point(x, y);
  }

  // Labels
  fill(200);
  noStroke();
  text("Angle: " + currentAngle + "°", 20, 24);
  text("Port: " + (PORT_NAME != null ? PORT_NAME : Serial.list()[constrain(PORT_INDEX,0,Serial.list().length-1)]), 20, 44);
  text("Distance scale: 0–300 cm", 20, 64);
}
