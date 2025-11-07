/*
  Arduino Radar
  - Servo on D11
  - HC-SR04 Trig D9, Echo D10
  - Sweeps 0..180..0 and prints "angle,distance_cm" at 9600 baud
*/

#include <Servo.h>

const int PIN_TRIG = 9;
const int PIN_ECHO = 10;
const int PIN_SERVO = 11;

const int STEP_DEG = 2;           // sweep step in degrees (1–3 is smooth)
const int SERVO_DELAY_MS = 20;    // settle time between steps
const unsigned int MAX_CM = 300;  // clamp max distance to 3 m

Servo radarServo;

// Measure distance (cm) using HC-SR04
unsigned int readDistanceCm() {
  digitalWrite(PIN_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(PIN_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(PIN_TRIG, LOW);

  unsigned long duration = pulseIn(PIN_ECHO, HIGH, 30000UL); // 30 ms timeout ~5 m
  if (duration == 0) return MAX_CM; // timeout → no echo
  unsigned int cm = (unsigned int)(duration * 0.0343 / 2.0);
  if (cm > MAX_CM) cm = MAX_CM;
  return cm;
}

void setup() {
  pinMode(PIN_TRIG, OUTPUT);
  pinMode(PIN_ECHO, INPUT);
  radarServo.attach(PIN_SERVO);

  Serial.begin(9600);
  delay(300);
}

void loop() {
  // Sweep 0 → 180
  for (int angle = 0; angle <= 180; angle += STEP_DEG) {
    radarServo.write(angle);
    delay(SERVO_DELAY_MS);

    unsigned int d = readDistanceCm();
    Serial.print(angle);
    Serial.print(",");
    Serial.println(d);
  }

  // Sweep 180 → 0
  for (int angle = 180; angle >= 0; angle -= STEP_DEG) {
    radarServo.write(angle);
    delay(SERVO_DELAY_MS);

    unsigned int d = readDistanceCm();
    Serial.print(angle);
    Serial.print(",");
    Serial.println(d);
  }
}
