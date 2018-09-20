import processing.serial.*;

Serial myPort;
String portStream, portStreamData;
float[] portStreamDataVal;

float angle_x, angle_y, angle_u, magni_u, angle_rot;
PVector p1 = new PVector();
PVector p2 = new PVector();
float l, r, r1, r2, r3, r4;
int factor = 1000;

void setup() {
  size(800, 800);
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');
}

void draw() {
  stream();
  visual();
}

void visual() {
  translate(width/2, height/2);
  rotate(angle_rot);
  background(200);

  l = height/10 * magni_u;

  if (angle_u >= 0 && angle_u <= PI/2) {
    angle_rot = angle_u;
  }
  if (angle_u > PI/2 && angle_u <= PI) {
    angle_rot = PI-angle_u;
  }
  if (angle_u > PI && angle_u <= 2/3*PI) {
    angle_rot = angle_u-PI;
  }
  if (angle_u > 2/3*PI && angle_u <= 2*PI) {
    angle_rot = 2*PI-angle_u;
  }

  r = 0.7 * height;
  r1 = r*map(magni_u, 0, 1, 1, 0.98);
  r2 = 0.98*r;
  noStroke();
  fill(0);
  ellipse(l, 0, r1, r2);

  r3 = map(magni_u, 0, 1, 1, 0.98)*r4;
  r4 = r*map(magni_u, 0, 1, 1, 1.2);
  //stroke(0, 100);
  //fill(200, 240);
  fill(200);
  ellipse(0, 0, r3, r4);

  stroke(255);
  line(0, 0, l, 0);
}

void stream() {
  if (myPort.available() != 0 && portStream.charAt(0) == '_') {
    portStreamData = portStream.substring(portStream.indexOf('_')+1, portStream.indexOf('#'));
    portStreamDataVal = float(split(portStreamData, ' '));
    angle_x  = portStreamDataVal[0]/factor;
    angle_y  = portStreamDataVal[1]/factor;
    angle_u  = portStreamDataVal[2]/factor;
    magni_u  = portStreamDataVal[3]/factor;
  }
  println(int(angle_x*180/PI), int(angle_y*180/PI), int(angle_u*180/PI), magni_u);
}

void serialEvent(Serial myPort) {
  portStream = myPort.readString();
}
