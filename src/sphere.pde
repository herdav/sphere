// Sphere (Concept), David Herren, 2018

import processing.serial.*;

// STREAM
Serial myPort;
String portStream, portStreamData;
float[] portStreamDataVal;
float angle_x, angle_y, angle_u, magni_u, stp_yaw, stp_cnt, poti, rpm;
float angle_stp, angle_rot;
int fctr = 1000;

// INDICATOR
Indicator yaw, x_axis, y_axis, stp;
PVector rstr = new PVector();
color gray = color(150);
color brgt = color(255);
int textsize = 13;

void setup() {
  size(1600, 800);
  //fullScreen();
  String portName = Serial.list()[0];
  myPort = new Serial(this, "COM3", 9600);
  myPort.bufferUntil('\n');
  delay(500);

  rstr.x = width/18;
  rstr.y = height/8;

  x_axis = new Indicator(rstr.x*3, rstr.y*3.7, rstr.y*4);
  y_axis = new Indicator(rstr.x*9, rstr.y*3.7, rstr.y*4);
  yaw    = new Indicator(rstr.x*15, rstr.y*3.7, rstr.y*4);
  stp    = new Indicator(rstr.x*15, rstr.y*3.7, rstr.y*4);
}

void draw() {
  stream();
  indicator();
}

void indicator() {
  background(0);
  textAlign(LEFT, TOP);

  text("Sphere (Concept), David Herren, 2018", 10, textsize);
  text(float(int(float(frameCount)/millis()*10000))/10 + "fps", 10, textsize*2.5);
  text(float(int(10*rpm))/10 + "rpm", 10, textsize*4);

  x_axis.needle(angle_x);
  x_axis.graph(30);
  x_axis.magnitude(1);
  x_axis.path(color(0, 255, 0, 200));
  x_axis.info("around x-axis");

  y_axis.needle(angle_y);
  y_axis.graph(30);
  y_axis.magnitude(1);
  y_axis.path(color(0, 255, 0, 200));
  y_axis.info("around y-axis");

  stp.needle(angle_stp);
  stp.magnitude(sqrt(sq(rpm)) / 35);
  stp.path(color(255, 0, 255, 200));

  yaw.needle(angle_rot);
  yaw.graph(5);
  yaw.magnitude(magni_u);
  yaw.path(color(0, 255, 0, 200));
  yaw.info("yaw-angle");
}

void stream() {
  if (myPort.available() > 0 && portStream.charAt(0) == '!') {
    portStreamData = portStream.substring(portStream.indexOf('!')+1, portStream.indexOf('#'));
    portStreamDataVal = float(split(portStreamData, ' '));
    angle_x   = portStreamDataVal[0]/fctr;
    angle_y   = portStreamDataVal[1]/fctr;
    angle_u   = portStreamDataVal[2]/fctr;
    magni_u   = portStreamDataVal[3]/fctr;
    stp_yaw   = portStreamDataVal[4];
    stp_cnt   = portStreamDataVal[5];
    rpm       = portStreamDataVal[6];
    poti      = portStreamDataVal[7];
  }

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

  println("x:" + int(angle_x*180/PI), "y:" + int(angle_y*180/PI), "u:" + int(angle_u*180/PI), "m:" + int(100*magni_u), "stp:" + int(stp_yaw), "cnt:" + int(stp_cnt), "speed:" + int(rpm), "poti:" + int(poti));
}

void serialEvent(Serial myPort) {
  portStream = myPort.readString();
}

class Indicator {
  PVector p0 = new PVector();
  PVector p1 = new PVector();
  PVector p2 = new PVector();
  PVector[] p3 = new PVector[1000];
  int count2 = 0;

  float d, a, a2, r;
  int count = 0;
  float[] store;

  Indicator(float xpos, float ypos, float dTemp) {
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
    stroke(gray);
    ellipse(p0.x, p0.y, d, d); 
    line(p0.x, p0.y-r, p0.x, p0.y+r); // vertical line
    line(p0.x-r, p0.y, p0.x+r, p0.y); // horizontal line

    stroke(brgt);
    line(p0.x, p0.y, p1.x, p1.y);

    for (int i = 0; i <= 360; i += 30) {
      a2 = i * PI / 180;
      if (i % 90 > 0) {
        stroke(gray);
        line(p0.x + r * cos(a2), p0.y + r * sin(a2), p0.x + (r - 10) * cos(a2), p0.y + (r - 10) * sin(a2));
      }
    }
  }

  void magnitude(float m) {
    p2.x = p0.x + r*m * cos(a);
    p2.y = p0.y + r*m * sin(a);
    noFill();
    stroke(brgt);
    ellipse(p2.x, p2.y, 8, 8);
  }

  void path(color c) {
    count2++;
    if (count2 == p3.length-1) {
      count2 = 0;
    }
    p3[count2].x = p2.x;
    p3[count2].y = p2.y;
    noStroke();
    fill(c);
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
    stroke(gray);
    for (int i = 0; i < store.length; i++) {
      line(p0.x-r+i, p0.y+r+r/1.5, p0.x-r+i, p0.y+r+r/1.5-store[i]);
    }
  }

  void info(String title) {
    fill(gray);
    textSize(13);
    textAlign(CENTER, CENTER);
    text(title + ": " + float(int(10*a*180/PI))/10 + '°', p0.x, p0.y - r - r/5);
  }
}
