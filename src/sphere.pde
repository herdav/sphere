import processing.serial.*;

Serial myPort;
String portStream, portStreamData;
float[] portStreamDataVal;
int factor = 1000;

float angle_x, angle_y, angle_u, magni_u, angle_rot, stp_yaw, stp_cnt, angle_stp;

Pointer yaw, x_axis, y_axis, stp;

PVector rstr = new PVector();

void setup() {
  size(1800, 900);
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');
  delay(500);

  rstr.x = width/18;
  rstr.y = height/8;

  x_axis = new Pointer(rstr.x*3, rstr.y*4, rstr.y*4);
  y_axis = new Pointer(rstr.x*9, rstr.y*4, rstr.y*4);
  yaw    = new Pointer(rstr.x*15, rstr.y*4, rstr.y*4);
  stp    = new Pointer(rstr.x*15, rstr.y*4, rstr.y*4);
}

void draw() {
  background(0);
  stream();
  visual();

  x_axis.path();
  x_axis.needle(angle_x);
  x_axis.graph(30);
  x_axis.magnitude(1);
  x_axis.info("around x-axis");

  y_axis.path();
  y_axis.needle(angle_y);
  y_axis.graph(30);
  y_axis.magnitude(1);
  y_axis.info("around y-axis");

  yaw.path();
  stp.needle(angle_stp);
  yaw.needle(angle_rot);
  yaw.graph(5);
  yaw.magnitude(magni_u);
  yaw.info("yaw-angle");
}

void visual() {
  if (angle_u >= 0 && angle_u < PI/2) {
    angle_rot = angle_u;
  }
  if (angle_u >= PI/2 && angle_u < PI) {
    angle_rot = PI-angle_u;
  }
  if (angle_u >= PI && angle_u < 2/3*PI) {
    angle_rot = angle_u-PI;
  }
  if (angle_u >= 2/3*PI && angle_u < 2*PI) {
    angle_rot = 2*PI-angle_u;
  }

  angle_stp = 2*PI / 600 * stp_cnt;

  textAlign(LEFT, TOP);
  text(int(float(frameCount)/millis()*1000) + "fps", 10, 10);
}

void stream() {
  if (myPort.available() > 0 && portStream.charAt(0) == '!') {
    portStreamData = portStream.substring(portStream.indexOf('!')+1, portStream.indexOf('#'));
    portStreamDataVal = float(split(portStreamData, ' '));
    angle_x = portStreamDataVal[0]/factor;
    angle_y = portStreamDataVal[1]/factor;
    angle_u = portStreamDataVal[2]/factor;
    magni_u = portStreamDataVal[3]/factor;
    stp_yaw = portStreamDataVal[4];
    stp_cnt = portStreamDataVal[5];
  }
  println("x:" + int(angle_x*180/PI), "y:" + int(angle_y*180/PI), "u:" + int(angle_u*180/PI), "m:" + int(100*magni_u), "stp:" + int(stp_yaw), "cnt:" + int(stp_cnt));
}

void serialEvent(Serial myPort) {
  portStream = myPort.readString();
}

class Pointer {
  PVector p0 = new PVector();
  PVector p1 = new PVector();
  PVector p2 = new PVector();
  PVector[] p3 = new PVector[1000];
  int count2 = 0;

  float d, a, r;
  int count = 0;
  float[] store;

  Pointer(float xpos, float ypos, float dTemp) {
    p0.x = xpos;
    p0.y = ypos;
    d = dTemp;
    r = d/2;
    store = new float[int(d)];
    for (int i = 0; i < p3.length; i++) {
      p3[i] = new PVector();
    }
  }

  void needle(float angle) {
    a = angle;
    p1.x = p0.x + r * cos(a);
    p1.y = p0.y + r * sin(a);

    noFill();
    stroke(120);
    ellipse(p0.x, p0.y, d, d);
    line(p0.x, p0.y-r, p0.x, p0.y+r);
    line(p0.x-r, p0.y, p0.x+r, p0.y);

    stroke(255);
    line(p0.x, p0.y, p1.x, p1.y);
  }

  void magnitude(float m) {
    p2.x = p0.x + r*m * cos(a);
    p2.y = p0.y + r*m * sin(a);
    ellipse(p2.x, p2.y, 8, 8);
  }

  void path() {
    count2++;
    if (count2 == p3.length-1) {
      count2 = 0;
    }
    p3[count2].x = p2.x;
    p3[count2].y = p2.y;
    
    noStroke();
    fill(0, 255, 0);
    for (int i = 0; i < p3.length; i++) {
      ellipse(p3[i].x, p3[i].y, 2, 2);
    }
  }

  void graph(int f) {
    count++;
    if (count == d-1) {
      count = 0;
    }
    store[count] = f*a;

    fill(255);
    for (int i = 0; i < store.length; i++) {
      line(p0.x-r+i, p0.y+r+r/2, p0.x-r+i, p0.y+r+r/2-store[i]);
    }
  }

  void info(String title) {
    fill(255);
    textSize(13);
    textAlign(CENTER, CENTER);
    text(title + ": " + float(int(10*a*180/PI))/10 + '°', p0.x, p0.y - r - r/5);
  }
}
