// SPHERE (Concept vector field)
// Created 2018 by David Herren
// https://davidherren.ch
// https://github.com/herdav/sphere
// Licensed under the MIT License
// ----------------------------------------------------------------------

import controlP5.*;
import processing.pdf.*;

// VECTORFIELD ----------------------------------------------------------
Vectorfield vctr;
ArrayList < Vectorfield > vectors;
PVector vectorfield_segment_pos = new PVector();
float vectorfield_segment_d, vectorfield_segment_r, vectorfield_maxDist;
float vectorfield_segment_delay = 0.03;
int vectorfield_segment_nx = 50;
int vectorfield_segment_ny;
int vectorfield_segment_n, vectorfield_segment_n_max = 300;

// TARGETS --------------------------------------------------------------
Target targt;
ArrayList < Target > targets;
boolean targets_removed = false;

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
boolean particles_birth_circle = true;
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
int field_height = 800;
int field_width = field_height;
int field_border_left, field_border_top, field_border_bot;
PVector field_centre = new PVector();

void setup() {
  size(1400, 900, P2D);
  //fullScreen();
  blendMode(ADD);
  textSize(9);
  fieldsize();
  vectors = new ArrayList < Vectorfield > ();
  particles = new ArrayList < Particle > ();
  targets = new ArrayList < Target > ();
  targets.add(new Target(field_centre.x, field_centre.y));
  gui();
}



void draw() {
  control();
  record();
  targets();
  field();
  particles();
  data();
  if (record_pdf) {
    endRecord();
    record_pdf = false;
  }
}

void fieldsize() {
  field_border_left = width - field_width;
  field_border_top = int((height - field_height) / 2);
  field_border_bot = field_border_top;
  field_centre.x = field_width / 2 + field_border_left;
  field_centre.y = field_height / 2 + field_border_top;
}

void gui() {
  int cp5_w = 220;
  int cp5_h = 14;
  int cp5_x = 20;
  int[] cp5_d = new int[20];

  for (int i = 0; i < cp5_d.length; i++) {
    cp5_d[i] = int((i + 2) * cp5_h * 1.5);
  }

  cp5 = new ControlP5(this);

  cp5.setColorBackground(color(50))
    .setColorForeground(color(100))
    .setColorActive(color(150));

  cp5.addButtonBar("theme")
    .setPosition(20, 20)
    .setSize(cp5_w, cp5_h)
    .addItems(split("1 2 3 4 5", " "))
    .onMove(new CallbackListener() {
      public void controlEvent(CallbackEvent ev) {
        ButtonBar theme = (ButtonBar) ev.getController();
      }
    });

  // name, minValue, maxValue, x, y, width, height
  cp5.addSlider("vectorfield_segment_nx", 5, vectorfield_segment_n_max, cp5_x, cp5_d[1], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("vectorfield_segment_delay", 0, 0.1, cp5_x, cp5_d[2], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_birthrate", 1, 60, cp5_x, cp5_d[3], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_streams", 1, 300, cp5_x, cp5_d[4], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_lifespan", 1, 200, cp5_x, cp5_d[5], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_speed", -2, 30, cp5_x, cp5_d[6], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);
  cp5.addSlider("particles_size", 1, 20, cp5_x, cp5_d[7], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE);

  cp5.addRange("PARTICLES_SATURATION_SCOPE")
    .setBroadcast(false)
    .setPosition(cp5_x, cp5_d[8])
    .setSize(cp5_w, cp5_h)
    .setHandleSize(5)
    .setRange(0, 255)
    .setRangeValues(particles_saturation_min, particles_saturation_max)
    .setBroadcast(true);

  cp5.addRange("PARTICLES_SATURATION_LIMIT")
    .setBroadcast(false)
    .setPosition(cp5_x, cp5_d[9])
    .setSize(cp5_w, cp5_h)
    .setHandleSize(5)
    .setRange(0, 255)
    .setRangeValues(particles_saturation_min, particles_saturation_max)
    .setBroadcast(true);

  cp5.addSlider("particles_birth_circle_r", 1, field_height / 2 - 20, cp5_x, cp5_d[10], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE)
    .setCaptionLabel("BIRTH_SIZE")
    .setValue(field_height / 2 - vectorfield_segment_d);

  cp5.addSlider("background_color", 0, 255, cp5_x, cp5_d[11], cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE)
    .setValue(100);

  cp5_d[12] = cp5_d[11] + cp5_h / 2;

  cp5.addToggle("targets_display", 20, cp5_d[12] + cp5_h, 40, 20).setCaptionLabel("TARGETS")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("background_display", 20, cp5_d[12] + cp5_h * 3, 40, 20).setCaptionLabel("FOIL")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_birth_square", cp5_w - 65, cp5_d[12] + cp5_h, 40, 20).setCaptionLabel("SQUARE")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addToggle("particles_birth_circle", cp5_w - 20, cp5_d[12] + cp5_h, 40, 20).setCaptionLabel("CIRCLE")
    .getCaptionLabel().align(CENTER, CENTER);
  cp5.addBang("particles_pulse", cp5_w - 20, cp5_d[12] + cp5_h * 3, 40, 20).setCaptionLabel("PULSE")
    .getCaptionLabel().align(CENTER, CENTER);

  cp5_d[14] = cp5_d[13] + 80;

  Group cp5_color = cp5.addGroup("COLOR")
    .setPosition(cp5_x, cp5_d[14])
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
  if (mouseButton == LEFT && mouseX > field_border_left) {
    targets.add(new Target(mouseX, mouseY));
  }
  if (mouseButton == RIGHT && targets.size() > 1 && mouseX > field_border_left) {
    for (int i = targets.size() - 1; i > 0; i--) {
      targets.remove(i);
    }
  }
}

void targets() {
  if (mouseX >= field_border_left && mouseY >= field_border_top && mouseY <= height - field_border_bot) {
    if (targets_removed) {
      targets.get(0).update(mouseX, mouseY);
      targets_removed = false;
    } else {
      targets.get(0).update(mouseX, mouseY);
    }
  }
  if (mouseX < field_border_left || mouseY < field_border_top || mouseY > height - field_border_bot) {
    if (targets.size() == 1) {
      targets.get(0).update(field_centre.x, field_centre.y);
    }
    if (targets.size() > 1 && targets_removed == false) {
      targets.remove(0);
      targets_removed = true;
    }
  }
  for (Target targets: targets) {
    targets.update();
    if (targets_display) {
      targets.display();
    }
  }
}

void particles() {
  particles_count++;
  if (particles_count == particles_birthrate) {
    particles_count = 0;
    if (particles_birth_square == true) {
      particles_ly = ((field_height - 2 * vectorfield_segment_d) / particles_streams);
      particles_lx = particles_ly;
      for (int i = 0; i <= particles_streams; i++) {
        particles.add(new Particle(field_border_left + vectorfield_segment_d, field_border_top + vectorfield_segment_d + particles_ly * i, particles_lifespan, color_a)); // left
        particles.add(new Particle(width - vectorfield_segment_d, field_border_top + vectorfield_segment_d + particles_ly * i, particles_lifespan, color_b)); // right
        particles.add(new Particle(field_border_left + vectorfield_segment_d + particles_lx * i, field_border_top + vectorfield_segment_d, particles_lifespan, color_c)); // top
        particles.add(new Particle(field_border_left + vectorfield_segment_d + particles_lx * i, height - field_border_bot - vectorfield_segment_d, particles_lifespan, color_d)); // bottom
      }
    }
    if (particles_birth_circle == true) {
      particles_streams_circle = 4 * particles_streams;
      for (int i = 0; i <= particles_streams_circle; i++) {
        paricles_birth_circle_pos.x = field_centre.x + particles_birth_circle_r * cos((PI * i * 2) / (particles_streams_circle));
        paricles_birth_circle_pos.y = field_centre.y - particles_birth_circle_r * sin((PI * i * 2) / (particles_streams_circle));
        if (i >= 0 && i < particles_streams_circle / 3) {
          particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, particles_lifespan, color_a));
        }
        if (i >= particles_streams_circle / 3 && i < particles_streams_circle / 3 * 2) {
          particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, particles_lifespan, color_b));
        }
        if (i >= particles_streams_circle / 3 * 2 && i < particles_streams_circle) {
          particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, particles_lifespan, color_c));
        }
      }
    }
  }

  for (int i = particles.size() - 1; i > 0; i--) {
    Particle part = particles.get(i);
    if (part.lifespan <= 0) {
      particles.remove(i);
    }
  }
  for (Particle particles: particles) {
    if (particles_pulse) {
      particles.pulse();
    }
    particles.update();
    particles.lifespan();
    particles.display();
  }
}

void field() {
  vectorfield_segment_ny = vectorfield_segment_nx;
  vectorfield_segment_n = vectorfield_segment_nx * vectorfield_segment_ny;
  if (vectorfield_segment_n != vectors.size()) {
    for (int i = vectors.size() - 1; i >= 0; i--) {
      vectors.remove(i);
    }
    if (field_height % vectorfield_segment_ny > 0) {
      vectorfield_segment_nx++;
    }
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
  if (keyPressed && key == 's') {
    record_pdf = true;
  }
  if (record_pdf) {
    beginRecord(PDF, "\\export\\pdf\\frame-######.pdf");
  }
  background(0);

  if (background_display) {
    fill(background_color);
    rectMode(CORNER);
    rect(field_border_left, field_border_top, field_height, field_height);
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

        if (scope >= 0 * r) { // blue
          fill(0, 0, scope);
        }
        if (scope >= 2 * r) { // cyan
          fill(0, scope - 2 * r, 255);
        }
        if (scope >= 4 * r) { // green
          fill(0, 255, 6 * r - scope);
        }
        if (scope >= 6 * r) { // yellow
          fill(scope - 6 * r, 255, 0);
        }
        if (scope >= 8 * r) { // red
          fill(255, 10 * r - scope, 0);
        }
        if (scope >= 10 * r) { // dark red
          fill(12 * r - scope, 0, 0);
        }
        break;

      case 4: // field lines
        n = 100;
        for (int i = 0; i <= n; i++) {
          scope = map(magnitude, 0, vectorfield_segment_d, 0, n);
          if (scope >= i * 2 && i % 2 == 0) {
            fill(150);
          }
          if (scope >= i * 2 && i % 2 > 0) {
            fill(50);
          }
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
  }

  void lifespan() {
    lifespan--;
    if (pos.x <= vectorfield_segment_d + field_border_left || pos.x >= width - vectorfield_segment_d || pos.y <= field_border_top + vectorfield_segment_d || pos.y >= height - field_border_bot - vectorfield_segment_d) {
      lifespan = 0;
    }
  }

  void display() {
    lifespan_range = int(map(lifespan, 0, lifespan_start, 255, 0));
    if (lifespan_range < particles_saturation_min || lifespan_range > particles_saturation_max) {
      saturation = particles_saturation_min_limit;
    } else {
      saturation = int(map(lifespan_range, particles_saturation_min, particles_saturation_max, particles_saturation_min_limit, particles_saturation_max_limit));
    }

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
