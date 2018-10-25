// SPHERE
// Created 2018 by David Herren
// https://davidherren.ch
// https://github.com/herdav/sphere
// Licensed under the MIT License
// ----------------------------------------------------------------------

import controlP5.*;
import processing.pdf.*;
import processing.serial.*;

// SERIAL COMMUNICATION -------------------------------------------------
boolean stream_port_on = true; // set to true when port is connected

Serial stream_port;
String stream_data, stream_data_eff;
float[] stream_data_val;
float stream_data_angle_x, stream_data_angle_y, stream_data_angle_u,
stream_data_magni_u, stream_data_stp_yaw, stream_data_stp_cnt,
stream_data_poti, stream_data_rpm, stream_data_angle_stp,
stream_data_angle_rot;
int stream_data_fctr = 1000;

// POINTER --------------------------------------------------------------
Pointer pointer_yaw, pointer_x_axis, pointer_y_axis, pointer_stp;
Pointer pointer_targets;
PVector pointer_rstr = new PVector();
color pointer_gray = color(150);
color pointer_brgt = color(255);
boolean pointer_control = false;

// VECTORFIELD ----------------------------------------------------------
Vectorfield vctr;
ArrayList < Vectorfield > vectors;
PVector vectorfield_segment_pos = new PVector();
float vectorfield_segment_d, vectorfield_segment_r, vectorfield_maxDist;
float vectorfield_segment_delay = 0.03;
int vectorfield_segment_nx = 50, vectorfield_segment_ny;
int vectorfield_segment_n, vectorfield_segment_n_max = 300;

// TARGETS --------------------------------------------------------------
Target targt;
ArrayList < Target > targets;
boolean targets_removed = false;
boolean targets_pointer = false;
boolean targets_mouse = true;

// PARTICLES ------------------------------------------------------------
Particle part;
ArrayList < Particle > particles;
int particles_count;
int particles_birthrate = 1;
int particles_size = 1;
int particles_streams = 100;
int particles_streams_circle;
int particles_lifespan = 100;
int particles_saturation_min = 127;
int particles_saturation_max = 255;
int particles_saturation_min_limit = 0;
int particles_saturation_max_limit = 255;
float particles_speed = 8;
float particles_lx, particles_ly;
boolean particles_birth_square = false;
boolean particles_pulse = false;
boolean particles_noise = false;
boolean particles_pull = false;
boolean particles_birth_circle = true;
boolean particles_display = true;
boolean particles_freeze = false;
float particles_birth_circle_r;
PVector paricles_birth_circle_pos = new PVector();

// GUI & CONTROLS -------------------------------------------------------
ControlP5 cp5;
color color_a, color_b, color_c, color_d;
boolean controls_show = true;
boolean record_pdf = true;
boolean background_display = false;
int background_color = 0;
boolean targets_display = false;
int theme = 0;
int field_height = 900;
int field_width = field_height;
int field_border_left, field_border_top, field_border_bot;
PVector field_center = new PVector();

void setup() {
  size(1700, 900, P3D);
  //fullScreen(P3D);
  blendMode(ADD);

  if (stream_port_on) {
    String portName = Serial.list()[0];
    stream_port = new Serial(this, "COM3", 9600);
    stream_port.bufferUntil('\n');
  }

  fieldsize();

  pointer_rstr.x = 500;
  pointer_rstr.y = 200;
  pointer_x_axis = new Pointer(pointer_rstr.x, pointer_rstr.y, 200);
  pointer_y_axis = new Pointer(pointer_rstr.x, height / 2, 200);
  pointer_yaw = new Pointer(pointer_rstr.x, height - pointer_rstr.y, 200);
  pointer_stp = new Pointer(pointer_rstr.x, height - pointer_rstr.y, 200);

  pointer_targets = new Pointer(field_center.x, field_center.y, field_height / 1.5);

  vectors = new ArrayList < Vectorfield > ();
  particles = new ArrayList < Particle > ();
  targets = new ArrayList < Target > ();
  targets.add(new Target(field_center.x, field_center.y));

  gui();
}

void draw() {
  if (stream_port_on) stream();
  control();
  record();
  targets();
  field();
  particles();
  data();
  if (record_pdf) endRecord();
  if (pointer_control) pointer();
}

void stream() {
  if (stream_port.available() > 0 && stream_data.charAt(0) == '!') {
    stream_data_eff = stream_data.substring(stream_data.indexOf('!') + 1, stream_data.indexOf('#'));
    stream_data_val = float(split(stream_data_eff, ' '));
    stream_data_angle_x = stream_data_val[0] / stream_data_fctr;
    stream_data_angle_y = stream_data_val[1] / stream_data_fctr;
    stream_data_angle_u = stream_data_val[2] / stream_data_fctr;
    stream_data_magni_u = stream_data_val[3] / stream_data_fctr;
    stream_data_stp_yaw = stream_data_val[4];
    stream_data_stp_cnt = stream_data_val[5];
    stream_data_rpm = stream_data_val[6];
    stream_data_poti = stream_data_val[7];
  }

  if (stream_data_angle_u >= 0 && stream_data_angle_u < PI / 2) stream_data_angle_rot = stream_data_angle_u;
  if (stream_data_angle_u >= PI / 2 && stream_data_angle_u < PI) stream_data_angle_rot = PI - stream_data_angle_u;
  if (stream_data_angle_u >= PI && stream_data_angle_u < 2 / 3 * PI) stream_data_angle_rot = stream_data_angle_u - PI;
  if (stream_data_angle_u >= 2 / 3 * PI && stream_data_angle_u < 2 * PI) stream_data_angle_rot = 2 * PI - stream_data_angle_u;

  stream_data_angle_stp = 2 * PI / 600 * stream_data_stp_cnt;

  // println("x:" + int(stream_data_angle_x * 180 / PI), "y:" + int(stream_data_angle_y * 180 / PI), "u:" + int(stream_data_angle_u * 180 / PI), "m:" + int(100 * stream_data_magni_u), "stp:" + int(stream_data_stp_yaw), "cnt:" + int(stream_data_stp_cnt), "speed:" + int(stream_data_rpm), "poti:" + int(stream_data_poti));
}

void serialEvent(Serial stream_port) {
  stream_data = stream_port.readString();
}

void pointer() {
  pointer_x_axis.needle(stream_data_angle_x, true);
  //pointer_x_axis.graph(30);
  pointer_x_axis.magnitude(1, true);
  pointer_x_axis.path(color(0, 255, 0, 200));
  pointer_x_axis.info("x-axis");

  pointer_y_axis.needle(stream_data_angle_y, true);
  //pointer_y_axis.graph(30);
  pointer_y_axis.magnitude(1, true);
  pointer_y_axis.path(color(0, 255, 0, 200));
  pointer_y_axis.info("y-axis");

  pointer_stp.needle(stream_data_angle_stp, true);
  pointer_stp.magnitude(sqrt(sq(stream_data_rpm)) / 35, true);
  pointer_stp.path(color(255, 0, 255, 200));

  pointer_yaw.needle(stream_data_angle_rot, true);
  //pointer_yaw.graph(5);
  pointer_yaw.magnitude(stream_data_magni_u, true);
  pointer_yaw.path(color(0, 255, 0, 200));
  pointer_yaw.info("yaw-angle");
}

void fieldsize() {
  field_border_left = width - field_width;
  field_border_top = int((height - field_height) / 2);
  field_border_bot = field_border_top;
  field_center.x = field_width / 2 + field_border_left;
  field_center.y = field_height / 2 + field_border_top;
}

void gui() {
  int cp5_w = 220;
  int cp5_h = 14;
  int cp5_x = 20;
  int[] cp5_d = new int[20];

  for (int i = 0; i < cp5_d.length; i++) cp5_d[i] = int((i + 2) * cp5_h * 1.5);

  cp5 = new ControlP5(this);

  cp5.setColorBackground(color(50))
    .setColorForeground(color(100))
    .setColorActive(color(150));

  cp5.addButtonBar("theme")
    .setPosition(20, 20)
    .setSize(cp5_w, cp5_h)
    .addItems(split("PS VS LD HM FL", " "))
    .onMove(new CallbackListener() {
      public void controlEvent(CallbackEvent ev) {
        ButtonBar theme = (ButtonBar) ev.getController();
      }
    });

  cp5.addToggle("pointer_control", 20, 40, 80, 20).setCaptionLabel("POINTER CONTROL")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("targets_pointer", 160, 40, 80, 20).setCaptionLabel("POINTER TARGETS")
    .getCaptionLabel().align(CENTER, CENTER);

  // name, minValue, maxValue, x, y, width, height
  cp5.addSlider("vectorfield_segment_nx", 5, vectorfield_segment_n_max, cp5_x, cp5_d[1], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("vectorfield_segment_delay", 0, 0.1, cp5_x, cp5_d[2], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_streams", 1, 300, cp5_x, cp5_d[3], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_lifespan", 1, 200, cp5_x, cp5_d[4], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_speed", -20, 40, cp5_x, cp5_d[5], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_size", 1, 20, cp5_x, cp5_d[6], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);

  cp5.addRange("PARTICLES_SATURATION_SCOPE")
    .setBroadcast(false)
    .setPosition(cp5_x, cp5_d[7])
    .setSize(cp5_w, cp5_h)
    .setHandleSize(5)
    .setRange(0, 255)
    .setRangeValues(particles_saturation_min, particles_saturation_max)
    .setBroadcast(true);

  cp5.addRange("PARTICLES_SATURATION_LIMIT")
    .setBroadcast(false)
    .setPosition(cp5_x, cp5_d[8])
    .setSize(cp5_w, cp5_h)
    .setHandleSize(5)
    .setRange(0, 255)
    .setRangeValues(particles_saturation_min, particles_saturation_max)
    .setBroadcast(true);

  cp5.addSlider("particles_birth_circle_r", 1, field_height / 2 - 20, cp5_x, cp5_d[9], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE)
    .setCaptionLabel("PARTICLES_BIRTH_RADIUS")
    .setValue(field_height / 2 - vectorfield_segment_d);

  cp5.addSlider("background_color", 0, 255, cp5_x, cp5_d[10], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE)
    .setValue(100);

  cp5_d[11] = cp5_d[10] + cp5_h / 2;

  cp5.addToggle("targets_display", 20, cp5_d[11] + cp5_h, 40, 20).setCaptionLabel("TARGETS")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("background_display", 20, cp5_d[11] + cp5_h * 3, 40, 20).setCaptionLabel("GROUND")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_birth_square", cp5_w - 65, cp5_d[11] + cp5_h, 40, 20).setCaptionLabel("SQUARE")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_birth_circle", cp5_w - 20, cp5_d[11] + cp5_h, 40, 20).setCaptionLabel("CIRCLE")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addBang("particles_pulse", cp5_w - 20, cp5_d[11] + cp5_h * 3, 40, 20).setCaptionLabel("PULSE")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_pull", cp5_w - 65, cp5_d[11] + cp5_h * 3, 40, 20).setCaptionLabel("PULL")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_noise", cp5_w - 110, cp5_d[11] + cp5_h * 3, 40, 20).setCaptionLabel("NOISE")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_display", cp5_w - 65, cp5_d[11] + cp5_h * 5, 40, 20).setCaptionLabel("DISPLAY")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_freeze", cp5_w - 110, cp5_d[11] + cp5_h * 5, 40, 20).setCaptionLabel("FREEZE")
    .getCaptionLabel().align(CENTER, CENTER);

  cp5_d[12] = cp5_d[11] + cp5_h * 8;

  Group cp5_color = cp5.addGroup("COLOR")
    .setPosition(cp5_x, cp5_d[12])
    .setWidth(cp5_w)
    .setBackgroundHeight(250)
    .setBackgroundColor(color(255, 50));

  cp5.addColorWheel("color_a", 0, 10, 100).setRGB(color(255, 0, 0)).setCaptionLabel("LEFT").setGroup(cp5_color);
  cp5.addColorWheel("color_b", 120, 10, 100).setRGB(color(0, 255, 0)).setCaptionLabel("RIGHT").setGroup(cp5_color);
  cp5.addColorWheel("color_c", 0, 130, 100).setRGB(color(0, 0, 255)).setCaptionLabel("TOP").setGroup(cp5_color);
  cp5.addColorWheel("color_d", 120, 130, 100).setRGB(color(255, 0, 255)).setCaptionLabel("BOTTOM").setGroup(cp5_color);
}

void controlEvent(ControlEvent theControlEvent) {
  if (theControlEvent.isFrom("PARTICLES_SATURATION_SCOPE")) {
    particles_saturation_min = int(theControlEvent.getController().getArrayValue(0));
    particles_saturation_max = int(theControlEvent.getController().getArrayValue(1));
  }
  if (theControlEvent.isFrom("PARTICLES_SATURATION_LIMIT")) {
    particles_saturation_min_limit = int(theControlEvent.getController().getArrayValue(0));
    particles_saturation_max_limit = int(theControlEvent.getController().getArrayValue(1));
  }
}

void control() {
  if (keyPressed && key == 'q') {
    controls_show = false;
    cp5.hide();
  }
  if (keyPressed && key == 'w' || controls_show == false && mouseX < 100) {
    controls_show = true;
    cp5.show();
  }
}

void mouseClicked() {
  if (targets_mouse) {
    if (mouseButton == LEFT && mouseX > field_border_left) {
      targets.add(new Target(mouseX, mouseY));
    }
    if (mouseButton == RIGHT && targets.size() > 1 && mouseX > field_border_left) {
      for (int i = targets.size() - 1; i > 0; i--) targets.remove(i);
    }
  }
}

void targets() {
  if (targets_pointer) targets_mouse = false;
  else targets_mouse = true;

  if (targets_mouse) {
    if (mouseX >= field_border_left && mouseY >= field_border_top && mouseY <= height - field_border_bot) {
      if (targets_removed) {
        targets.get(0).update(mouseX, mouseY);
        targets_removed = false;
      } else targets.get(0).update(mouseX, mouseY);

    }
    if (mouseX < field_border_left || mouseY < field_border_top || mouseY > height - field_border_bot) {
      if (targets.size() == 1) {
        targets.get(0).update(field_center.x, field_center.y);
      }
      if (targets.size() > 1 && targets_removed == false) {
        targets.remove(0);
        targets_removed = true;
      }
    }
  }
  if (targets_pointer && stream_port_on) {
    pointer_targets.needle(stream_data_angle_rot, false);
    pointer_targets.magnitude(stream_data_magni_u, false);
    targets.get(0).update(pointer_targets.p2.x, pointer_targets.p2.y);
  }

  for (Target targets: targets) {
    targets.update();
    if (targets_display) targets.display();

  }
}

void particles() {
  if (particles_display) {
    particles_count++;
    if (particles_count == particles_birthrate) {
      particles_count = 0;
      if (particles_birth_square) {
        particles_ly = ((field_height - 2 * vectorfield_segment_d) / particles_streams);
        particles_lx = particles_ly;
        for (int i = 0; i <= particles_streams; i++) {
          particles.add(new Particle(field_border_left + vectorfield_segment_d, field_border_top + vectorfield_segment_d + particles_ly * i, particles_lifespan, color_a)); // left
          particles.add(new Particle(width - vectorfield_segment_d, field_border_top + vectorfield_segment_d + particles_ly * i, particles_lifespan, color_b)); // right
          particles.add(new Particle(field_border_left + vectorfield_segment_d + particles_lx * i, field_border_top + vectorfield_segment_d, particles_lifespan, color_c)); // top
          particles.add(new Particle(field_border_left + vectorfield_segment_d + particles_lx * i, height - field_border_bot - vectorfield_segment_d, particles_lifespan, color_d)); // bottom
        }
      }
      if (particles_birth_circle) {
        particles_streams_circle = 4 * particles_streams;
        for (int i = 0; i <= particles_streams_circle; i++) {
          paricles_birth_circle_pos.x = field_center.x + particles_birth_circle_r * cos((PI * i * 2) / (particles_streams_circle));
          paricles_birth_circle_pos.y = field_center.y - particles_birth_circle_r * sin((PI * i * 2) / (particles_streams_circle));
          if (i >= 0 && i < particles_streams_circle / 3) particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, particles_lifespan, color_a));
          if (i >= particles_streams_circle / 3 && i < particles_streams_circle / 3 * 2) particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, particles_lifespan, color_b));
          if (i >= particles_streams_circle / 3 * 2 && i < particles_streams_circle) particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, particles_lifespan, color_c));

        }
      }
    }

    for (int i = particles.size() - 1; i > 0; i--) {
      Particle part = particles.get(i);
      if (part.lifespan <= 0) particles.remove(i);
    }

    for (Particle particles: particles) {
      if (particles_freeze != true) {
        if (particles_pulse) particles.pulse();
        particles.update();
        particles.lifespan();
        if (particles_pull) particles.addPull();
        if (particles_noise) particles.addNoise();
      }
      particles.display();
    }
  }
}

void field() {
  vectorfield_segment_ny = vectorfield_segment_nx;
  vectorfield_segment_n = vectorfield_segment_nx * vectorfield_segment_ny;
  if (vectorfield_segment_n != vectors.size()) {
    for (int i = vectors.size() - 1; i >= 0; i--) vectors.remove(i);
    if (field_height % vectorfield_segment_ny > 0) vectorfield_segment_nx++;
    vectorfield_segment_d = field_height / vectorfield_segment_nx;
    vectorfield_segment_r = vectorfield_segment_d / 2;
    vectorfield_maxDist = sqrt(2 * sq((vectorfield_segment_nx - 1) * vectorfield_segment_d));
    for (int i = 0; i < vectorfield_segment_ny; i++) {
      for (int j = 0; j < vectorfield_segment_nx; j++) {
        vectorfield_segment_pos.x = field_border_left + j * vectorfield_segment_d + vectorfield_segment_r;
        vectorfield_segment_pos.y = field_border_top + i * vectorfield_segment_d + vectorfield_segment_r;
        vectors.add(new Vectorfield(vectorfield_segment_pos));
      }
    }
  }

  for (int i = 0; i < vectorfield_segment_n; i++) {
    Vectorfield vctr = vectors.get(i);
    for (int j = targets.size() - 1; j >= 0; j--) {
      vctr.target(targets.get(j).pos);
      vctr.magnitude(vectorfield_segment_delay);
    }
    vctr.colorize(theme);
    //vctr.grid();
  }
}

void data() {
  if (controls_show) {
    textSize(9);
    fill(255);
    textAlign(LEFT, BOTTOM);
    text("[s] : save frame as pdf\n" + "[q] : hide gui\n" + "[w] : show gui\n\n" +
      "FPS\n" + "VECTORS\n" + "PARTICLES\n" + "TARGETS\n\n" +
      year() + '/' + month() + '/' + day() + "\n\n" +
      "Sphere (concept vector field)\n" + "David Herren", 20, height - 20);

    text(float(int(float(frameCount) / millis() * 10000)) / 10 + "\n" +
      vectors.size() + "\n" +
      particles.size() + "\n" +
      targets.size() + "\n\n" +
      hour() + ':' + minute() + ':' + second() + "\n\n\n", 100, height - 20);
  }
}

void record() {
  background(0);
  record_pdf = false;
  if (keyPressed && key == 's') record_pdf = true;
  if (record_pdf) beginRecord(PDF, "\\export\\pdf\\frame-######.pdf");
  if (background_display) {
    fill(background_color);
    rectMode(CENTER);
    rect(field_center.x, field_center.y, field_height, field_width);
  }
}

class Pointer {
  PVector p0 = new PVector();
  PVector p1 = new PVector();
  PVector p2 = new PVector();
  PVector[] p3 = new PVector[1000];
  int count2 = 0;

  float d, a, a2, r;
  int count = 0;
  float[] store;

  Pointer(float xpos, float ypos, float dTemp) {
    p0.x = xpos;
    p0.y = ypos;
    d = dTemp;
    r = d / 2;
    store = new float[int(d)];
    for (int i = 0; i < p3.length; i++) p3[i] = new PVector();


  }

  void needle(float angle, boolean display) {
    a = angle;
    p1.x = p0.x + r * cos(a);
    p1.y = p0.y + r * sin(a);

    if (display) {
      noFill();
      stroke(pointer_gray);
      ellipse(p0.x, p0.y, d, d);
      line(p0.x, p0.y - r, p0.x, p0.y + r); // vertical line
      line(p0.x - r, p0.y, p0.x + r, p0.y); // horizontal line
      stroke(pointer_brgt);
      line(p0.x, p0.y, p1.x, p1.y);

      for (int i = 0; i <= 360; i += 30) {
        a2 = i * PI / 180;
        if (i % 90 > 0) {
          stroke(pointer_gray);
          line(p0.x + r * cos(a2), p0.y + r * sin(a2), p0.x + (r - 10) * cos(a2), p0.y + (r - 10) * sin(a2));
        }
      }
    }
  }

  void magnitude(float m, boolean display) {
    p2.x = p0.x + r * m * cos(a);
    p2.y = p0.y + r * m * sin(a);

    if (display) {
      noFill();
      stroke(pointer_brgt);
      ellipse(p2.x, p2.y, 8, 8);
    }
  }

  void path(color c) {
    count2++;
    if (count2 == p3.length - 1) count2 = 0;
    p3[count2].x = p2.x;
    p3[count2].y = p2.y;
    noStroke();
    fill(c);
    for (int i = 0; i < p3.length; i++) ellipse(p3[i].x, p3[i].y, 2, 2);
  }

  void graph(int f) {
    count++;
    if (count == d - 1) count = 0;
    store[count] = f * a;
    stroke(pointer_gray);
    for (int i = 0; i < store.length; i++) line(p0.x - r + i, p0.y + r + r / 1.5, p0.x - r + i, p0.y + r + r / 1.5 - store[i]);

  }

  void info(String title) {
    textSize(13);
    fill(255);
    textAlign(CENTER, CENTER);
    text(title + ": " + float(int(10 * a * 180 / PI)) / 10 + '°', p0.x, p0.y - r - r / 5);
  }
}

class Target {
  PVector pos = new PVector();

  Target(float x, float y) {
    pos.x = x;
    pos.y = y;
  }

  void update(float x, float y) {
    pos.x = x;
    pos.y = y;
  }

  void update() {}

  void display() {
    noStroke();
    fill(255);
    ellipse(pos.x, pos.y, 10, 10);
  }
}

class Vectorfield {
  PVector orgin = new PVector();
  PVector target = new PVector();
  PVector direct = new PVector();
  PVector offset = new PVector();
  PVector result = new PVector();
  PVector force = new PVector();

  color darkgray = color(90);

  float magnitude, dist;

  Vectorfield(PVector pos) {
    orgin.x = pos.x;
    orgin.y = pos.y;
  }

  void target(PVector target) {
    dist = orgin.dist(target);
    dist = vectorfield_segment_r - vectorfield_segment_r * dist / vectorfield_maxDist;
    direct = PVector.sub(target, orgin);
    direct.setMag(dist);
    direct.add(orgin);
  }

  void magnitude(float aclr) {
    offset = PVector.sub(direct, result);
    magnitude = offset.mag();
    offset.mult(aclr);
    result.add(offset);
    force = PVector.sub(result, orgin);
  }

  void grid() {
    noFill();
    stroke(darkgray);
    ellipse(orgin.x, orgin.y, vectorfield_segment_d, vectorfield_segment_d);
    rectMode(CENTER);
    //rect(orgin.x, orgin.y, vectorfield_segment_d, vectorfield_segment_d);
  }

  void colorize(int input) {
    float scope;
    int n, r;
    switch (input) {
      case 1: // vector field
        noFill();
        stroke(darkgray);
        line(orgin.x, orgin.y, direct.x, direct.y);
        line(direct.x, direct.y, result.x, result.y);
        stroke(255);
        line(orgin.x, orgin.y, result.x, result.y);
        break;

      case 2: // light dark
        scope = map(magnitude, 0, vectorfield_segment_d, 0, 255);
        fill(scope);
        break;

      case 3: // heat map
        n = 11;
        r = 128;
        scope = map(magnitude, 0, vectorfield_segment_d, 0, n * r);
        if (scope >= 0 * r) fill(0, 0, scope); // blue 
        if (scope >= 2 * r) fill(0, scope - 2 * r, 255); // cyan
        if (scope >= 4 * r) fill(0, 255, 6 * r - scope); // green
        if (scope >= 6 * r) fill(scope - 6 * r, 255, 0); // yellow
        if (scope >= 8 * r) fill(255, 10 * r - scope, 0); // red
        if (scope >= 10 * r) fill(12 * r - scope, 0, 0); // dark red
        break;

      case 4: // field lines
        n = 100;
        for (int i = 0; i <= n; i++) {
          scope = map(magnitude, 0, vectorfield_segment_d, 0, n);
          if (scope >= i * 2 && i % 2 == 0) fill(150);
          if (scope >= i * 2 && i % 2 > 0) fill(50);
        }
        break;

      default:
        noFill();
    }

    noStroke();
    rectMode(CENTER);
    rect(orgin.x, orgin.y, vectorfield_segment_d, vectorfield_segment_d);
  }
}

class Particle {
  PVector pos = new PVector();
  PVector aclr = new PVector();
  PVector force = new PVector();
  PVector pull = new PVector(0, 0);

  float dist;
  int active, lifespan, lifespan_start, lifespan_range, saturation;

  color argb;
  int a, r, g, b;

  int pulse_time_cnt;
  float particles_speed_save;
  float pulse_speed;
  float pulse_speed_min = 0.1;
  float pulse_speed_max = 20;
  float pulse_time_a = 20;
  float pulse_time_b = 20;
  float pulse_time_tot;

  Particle(float x, float y, int l, color c) {
    pos.x = x;
    pos.y = y;
    lifespan = l;
    lifespan_start = l;
    argb = c;
    particles_speed_save = particles_speed;
    pulse_time_tot = pulse_time_a + pulse_time_b;
  }

  void addPull() {
    pull = aclr.mult(-1);
  }

  void addNoise() {
    aclr.mult(random(0.95, 1.05));
  }

  void pulse() {
    pulse_time_cnt++;
    if (pulse_time_cnt <= pulse_time_a) {
      pulse_speed = pulse_speed_min - particles_speed;
    }
    if (pulse_time_cnt > pulse_time_a && pulse_time_cnt <= pulse_time_tot) {
      pulse_speed = particles_speed - (pulse_speed_max - particles_speed) / (pulse_time_b * (pulse_time_cnt - pulse_time_a));
    }
    if (pulse_time_cnt == pulse_time_tot) {
      pulse_speed = 0;
      pulse_time_cnt = 0;
      particles_pulse = false;
    }
  }

  void update() {
    active = int(round((pos.y - field_border_top) / vectorfield_segment_d) * vectorfield_segment_ny + round((pos.x - field_border_left) / vectorfield_segment_d)); // detect active vector
    if (active >= 0 && active < vectors.size()) {
      Vectorfield vctr = vectors.get(active);
      aclr.add(vctr.force);
    }
    force = PVector.sub(pos, aclr);
    aclr.setMag(particles_speed + pulse_speed);
    pos.add(aclr);
    pos.add(pull);
  }

  void lifespan() {
    lifespan--;
    if (pos.x <= vectorfield_segment_d + field_border_left || pos.x >= width - vectorfield_segment_d || pos.y <= field_border_top + vectorfield_segment_d || pos.y >= height - field_border_bot - vectorfield_segment_d) {
      lifespan = 0;
    }
  }

  void display() {
    lifespan_range = int(map(lifespan, 0, lifespan_start, 255, 0));
    if (lifespan_range < particles_saturation_min || lifespan_range > particles_saturation_max) saturation = particles_saturation_min_limit;
    else saturation = int(map(lifespan_range, particles_saturation_min, particles_saturation_max, particles_saturation_min_limit, particles_saturation_max_limit));

    a = saturation;
    r = (argb >> 16) & 0xFF;
    g = (argb >> 8) & 0xFF;
    b = argb & 0xFF;

    noStroke();
    fill(r, g, b, a);
    rectMode(CENTER);
    rect(pos.x, pos.y, particles_size, particles_size);
  }
}
