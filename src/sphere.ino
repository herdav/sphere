#include <math.h>
#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include <Filters.h>

// STEPPER MOTOR
Adafruit_MotorShield AFMS = Adafruit_MotorShield();
Adafruit_StepperMotor *STEPPER = AFMS.getStepper(200, 2);
const int gear_cog = 799;
int stp_cnt = 399;
double yaw_stp;

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
double angle_u, length_u;

// Stream
String stream;
int factor = 1000;

void setup() {

	pinMode(BTN_PIN_STRT, INPUT);
	pinMode(BTN_PIN_STOP, INPUT);

	Serial.begin(9600);

	AFMS.begin();
	STEPPER->setSpeed(1);
}

void loop() {

	accelerometer();
	stepper();
}

void accelerometer() {

#pragma region acceleration and yaw angle
	// view from center in direction axis, rotation counterclockwise = positive angle

	aclr_x = analogRead(ACLR_PIN_X);
	aclr_y = analogRead(ACLR_PIN_Y);
	aclr_z = analogRead(ACLR_PIN_Z);

	aclr_x_val = 2.0 / 93 * (aclr_x - 197) - 1; // calibrated acceleration x-axis [g]
	aclr_y_val = 2.0 / 95 * (aclr_y - 197) - 1;	// calibrated acceleration y-axis [g]
	aclr_z_val = 2.0 / 98 * (aclr_z - 203) - 1;	// calibrated acceleration z-axis [g]

	aclr_x_val = lowpass_x.input(aclr_x_val);   // low pass filter
	aclr_y_val = lowpass_y.input(aclr_y_val);
	aclr_z_val = lowpass_z.input(aclr_z_val);

	angle_x = -aclr_y_val / aclr_z_val;         // rotation around x-axis (beta)
	angle_y = aclr_x_val / aclr_z_val;          // rotation around y-axis (alpha)

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
		angle_u = -atan(tan(angle_x) / sin(angle_y));           // yaw angle
	}
	length_u = hypot(cos(angle_x)*sin(angle_y), sin(angle_x));  // length of yaw angle

	if (angle_y < 0 && angle_x > 0) {
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

#pragma endregion

#pragma region serial print
	
	stream = normdata(factor*angle_x, factor*angle_y, factor*angle_u, factor*length_u);
	Serial.println(stream);
	
#pragma endregion
}

void stepper() {
	run_strt_btn = digitalRead(BTN_PIN_STRT);
	run_stop_btn = digitalRead(BTN_PIN_STOP);

	if (run_strt_btn == true && run_stop_btn == false && run_auto == false) {
		run_auto = true;
	}
	if (run_strt_btn == false && run_stop_btn == true && run_auto == true) {
		run_auto = false;
	}

	yaw_stp = gear_cog / (2 * PI) * angle_u; // yaw angle in steps

	const int stp_tol = 10;

	if (stp_cnt < yaw_stp && yaw_stp - stp_cnt > stp_tol) {
		run_forw = true;
		run_back = false;
	}
	else {
		run_forw = false;
	}
	if (stp_cnt > yaw_stp && stp_cnt - yaw_stp > stp_tol) {
		run_back = true;
		run_forw = false;
	}
	else {
		run_back = false;
	}

	const int stp_delay = 10;

	if (run_auto == true && run_forw == true) {
		STEPPER->onestep(FORWARD, SINGLE);
		stp_cnt++;
		delay(stp_delay);
	}
	if (run_auto == true && run_back == true) {
		STEPPER->onestep(BACKWARD, SINGLE);
		stp_cnt--;
		delay(stp_delay);
	}
	if (run_forw == false && run_back == false || run_auto == false) {
		STEPPER->release();
	}

	if (stp_cnt == gear_cog || stp_cnt == -gear_cog) {
		stp_cnt = 0;
	}
}

String normdata(float a, float b, float c, float d) {
	String ret = String('_') + String(a) + String(' ') + String(b) + String(' ') + String(c) + String(' ') + String(d) + String('#');
	return ret;
}
