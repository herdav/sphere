#include <math.h>
#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include <Filters.h>

Adafruit_MotorShield AFMS = Adafruit_MotorShield();

// STEPPER MOTOR
Adafruit_StepperMotor *STEPPER = AFMS.getStepper(200, 2);
const int gear_cog = 600;
int stp_cnt = 130;
int stp_yaw, stp_yaw_left, stp_yaw_rght;

// FAN DC MOTOR
Adafruit_DCMotor *FAN = AFMS.getMotor(1);

// CONTROL BUTTONS
constexpr auto BTN_PIN_STRT = 13;
constexpr auto BTN_PIN_STOP = 12;
bool run_strt_btn, run_stop_btn;
bool run_auto = false;
bool run_forw = false;
bool run_back = false;

// ACCELERATION SENSOR
const int ACLR_PIN_X = A3;
const int ACLR_PIN_Y = A2;
const int ACLR_PIN_Z = A1;
int aclr_x, aclr_y, aclr_z;

float filterFrequency = 0.4;
FilterOnePole lowpass_x(LOWPASS, filterFrequency);
FilterOnePole lowpass_y(LOWPASS, filterFrequency);
FilterOnePole lowpass_z(LOWPASS, filterFrequency);

float  aclr_x_val, aclr_y_val, aclr_z_val;
double angle_x, angle_x_val;
double angle_y, angle_y_val;
double angle_u, mgni_u;

// STREAM
String stream;
int fctr = 1000;

void setup() {
  pinMode(BTN_PIN_STRT, INPUT);
  pinMode(BTN_PIN_STOP, INPUT);

  Serial.begin(9600);

  AFMS.begin();
  TWBR = ((F_CPU / 400000l) - 16) / 2; // change the i2c clock to 400KHz
  STEPPER->setSpeed(60);
  FAN->setSpeed(255);
  FAN->run(RELEASE);
}

void loop() {
  control();
  fan();
  accelerometer();
  stepper();
  data();
}

void control() {
  run_strt_btn = digitalRead(BTN_PIN_STRT);  // start taster
  run_stop_btn = digitalRead(BTN_PIN_STOP);  // stop taster

  if (run_strt_btn == true && run_stop_btn == false && run_auto == false) {
    run_auto = true;
  }
  if (run_strt_btn == false && run_stop_btn == true && run_auto == true) {
    run_auto = false;
  }
}

void accelerometer() {
  // view from center in direction axis, rotation counterclockwise = positive angle

  aclr_x = analogRead(ACLR_PIN_X);
  aclr_y = analogRead(ACLR_PIN_Y);
  aclr_z = analogRead(ACLR_PIN_Z);

  aclr_x_val = 2.0 / 93 * (aclr_x - 197) - 1;  // calibrated acceleration x-axis [g]
  aclr_y_val = 2.0 / 95 * (aclr_y - 197) - 1;  // calibrated acceleration y-axis [g]
  aclr_z_val = 2.0 / 98 * (aclr_z - 203) - 1;  // calibrated acceleration z-axis [g]

  aclr_x_val = lowpass_x.input(aclr_x_val);    // low pass filter x-axis
  aclr_y_val = lowpass_y.input(aclr_y_val);    // low pass filter y-axis
  aclr_z_val = lowpass_z.input(aclr_z_val);    // low pass filter z-axis

  angle_x = -aclr_y_val / aclr_z_val;          // rotation around x-axis (beta)
  angle_y = aclr_x_val / aclr_z_val;           // rotation around y-axis (alpha)

  if (angle_x > PI / 2) {
    angle_x = PI / 2;
  }
  if (angle_x < -PI / 2) {
    angle_x = -PI / 2;
  }
  if (angle_y > PI / 2) {
    angle_y = PI / 2;
  }
  if (angle_y < -PI / 2) {
    angle_y = -PI / 2;
  }

  if (angle_y != 0) {
    angle_u = -atan(tan(angle_x) / sin(angle_y));           // yaw-angle [y != 0]
  }
  if (angle_y == 0 && angle_x != 0) {
    angle_u = PI / 2 + atan(sin(angle_y) / tan(angle_x));   // yaw-angle [y == 0]
  }
  if (angle_y == 0 && angle_x == 0) {
    angle_u = 0;                                            // yaw-angle [x == 0 && y == 0]
  }

  mgni_u = hypot(cos(angle_x)*sin(angle_y), sin(angle_x));  // magnitude of yaw-angle

  if (angle_y < 0 && angle_x > 0) {                         // determine yaw-angle between 0 and 2PI
    angle_u = angle_u;
  }
  if (angle_y > 0 && angle_x > 0) {
    angle_u = PI + angle_u;
  }
  if (angle_y > 0 && angle_x < 0) {
    angle_u = PI + angle_u;
  }
  if (angle_y < 0 && angle_x < 0) {
    angle_u = 2 * PI + angle_u;
  }
  if (angle_u > 2 * PI) {
    angle_u = 2 * PI;
  }
}

void fan() {
  if (run_auto == true) {
    FAN->run(FORWARD);
  }
  else {
    FAN->run(RELEASE);
  }
}

void stepper() {
  stp_yaw = gear_cog - gear_cog / (2 * PI) * angle_u;  // yaw-angle in steps

  if (stp_yaw > stp_cnt) {  // calculate steps in both directions
    stp_yaw_left = stp_yaw - stp_cnt;
    stp_yaw_rght = stp_cnt + gear_cog - stp_yaw;
  }
  if (stp_yaw < stp_cnt) {
    stp_yaw_left = gear_cog - stp_cnt + stp_yaw;
    stp_yaw_rght = stp_cnt - stp_yaw;
  }

  const int stp_tol = 6;  // tolrance measurement fluctuations

  if (stp_yaw_left < stp_yaw_rght && stp_yaw_left > stp_tol) {  // define direction of rotation according to least steps
    run_forw = true;
    run_back = false;
  }
  else {
    run_forw = false;
  }
  if (stp_yaw_left > stp_yaw_rght && stp_yaw_rght > stp_tol) {
    run_back = true;
    run_forw = false;
  }
  else {
    run_back = false;
  }

  if (run_auto == true && run_forw == true) {
    STEPPER->step(1, FORWARD, MICROSTEP);
    stp_cnt++;
  }
  if (run_auto == true && run_back == true) {
    STEPPER->step(1, BACKWARD, MICROSTEP);
    stp_cnt--;
  }
  if (run_forw == false && run_back == false || run_auto == false) {
    STEPPER->release();
  }

  if (stp_cnt == gear_cog) {  // rotation over zero
    stp_cnt = 0;
  }
  if (stp_cnt == -1) {
    stp_cnt = gear_cog - 1;
  }
}

void data() {
  stream = normdata(fctr*angle_x, fctr*angle_y, fctr*angle_u, fctr*mgni_u, stp_yaw, stp_cnt);
  Serial.println(stream);
}

String normdata(float a, float b, float c, float d, int e, int f) {
  String ret = String('!') + String(a) + String(' ') + String(b) + String(' ') + String(c) + String(' ') + String(d) + String(' ') + String(e) + String(' ') + String(f) + String('#');
  return ret;
}
