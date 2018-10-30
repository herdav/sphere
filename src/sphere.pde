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
boolean stream_port_on = false;
boolean stream_data_serial_print = false;
Serial stream_port;
String stream_data, stream_data_eff;
String stream_port_name = "N/A";
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
boolean pointer_control = false;
int pointer_margin_x = 300;

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
int particles_streams = 10;
int particles_streams_circle;
int particles_lifespan = 40;
int particles_saturation_min = 0;
int particles_saturation_max = 255;
int particles_saturation_min_limit = 0;
int particles_saturation_max_limit = 255;
int particles_interaction_d_min = 5;
int particles_interaction_d_max = 30;
float particles_interaction_force = 0;
float particles_extinction_d = 1;
float particles_extinction_l = 1;
float particles_speed = 8;
float particles_lx, particles_ly;
boolean particles_birth_square = false;
boolean particles_pulse = false;
boolean particles_noise = false;
boolean particles_pull = false;
boolean particles_interaction = false;
boolean particles_extinction = false;
boolean addInteraction_force = false;
boolean particles_birth_circle = true;
boolean particles_calculate = true;
boolean particles_set = true;
boolean particles_freeze = false;
float particles_birth_square_d;
float particles_birth_circle_r;
PVector paricles_birth_circle_pos = new PVector();

// GUI & CONTROLS -------------------------------------------------------
ControlP5 cp5;
int cp5_w = 320;
color color_a, color_b, color_c, color_d;
boolean controls_show = true;
boolean record_pdf = false;
boolean background_display = true;
boolean targets_display = false;
boolean load_default, load_preset_1, load_preset_2, load_preset_3, load_preset_4,
load_preset_5;
int background_color = 0;
int theme = 0;
int field_height = 1000;
int field_width = field_height;
int field_border_left, field_border_top, field_border_bot;
PVector field_center = new PVector();

void setup() {
  size(1800, 1000, P2D);
  //fullScreen(P2D);
  blendMode(ADD);

  String[] ports = Serial.list();
  if (ports.length == 0) println("No ports found!");
  if (ports.length != 0) {
    stream_port_name = Serial.list()[0];
    stream_port = new Serial(this, stream_port_name, 9600);
    stream_port.bufferUntil('\n');
    stream_port_on = true;
    println("Device is connected to " + stream_port_name + '.');
  }

  fieldsize();

  pointer_rstr.x = 600;
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
  background(0);
  control();
  record();
  targets();
  field();
  particles();
  data();
  endRecord();
  pointer(pointer_control);
}

void serialEvent(Serial stream_port) {
  stream_data = stream_port.readString();
  if (stream_data.charAt(0) == '!') {
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

    if (stream_data_angle_u >= 0 && stream_data_angle_u < PI / 2) stream_data_angle_rot = stream_data_angle_u;
    if (stream_data_angle_u >= PI / 2 && stream_data_angle_u < PI) stream_data_angle_rot = PI - stream_data_angle_u;
    if (stream_data_angle_u >= PI && stream_data_angle_u < 2 / 3 * PI) stream_data_angle_rot = stream_data_angle_u - PI;
    if (stream_data_angle_u >= 2 / 3 * PI && stream_data_angle_u < 2 * PI) stream_data_angle_rot = 2 * PI - stream_data_angle_u;

    stream_data_angle_stp = 2 * PI / 600 * stream_data_stp_cnt;

    if (stream_data_serial_print) {
      println("x:" + int(stream_data_angle_x * 180 / PI), "y:" + int(stream_data_angle_y * 180 / PI), "u:" + int(stream_data_angle_u * 180 / PI),
        "m:" + int(100 * stream_data_magni_u), "stp:" + int(stream_data_stp_yaw), "cnt:" + int(stream_data_stp_cnt), "speed:" + int(stream_data_rpm), "poti:" + int(stream_data_poti));
    }
  }
}

void pointer(boolean set) {
  if (set) {
    pointer_x_axis.calculation(stream_data_angle_x, 1);
    pointer_x_axis.needle(true);
    pointer_x_axis.graph(false, 30);
    pointer_x_axis.magnitude();
    pointer_x_axis.path(true, color(0, 255, 0, 200));
    pointer_x_axis.title("x-axis");

    pointer_y_axis.calculation(stream_data_angle_y, 1);
    pointer_y_axis.needle(true);
    pointer_y_axis.graph(false, 30);
    pointer_y_axis.magnitude();
    pointer_y_axis.path(true, color(0, 255, 0, 200));
    pointer_y_axis.title("y-axis");

    pointer_stp.calculation(stream_data_angle_stp, sqrt(sq(stream_data_rpm)) / 35);
    pointer_stp.needle(false);
    pointer_stp.magnitude();
    pointer_stp.path(true, color(255, 0, 255, 200));

    pointer_yaw.calculation(stream_data_angle_rot, stream_data_magni_u);
    pointer_yaw.needle(true);
    pointer_yaw.graph(false, 5);
    pointer_yaw.magnitude();
    pointer_yaw.path(true, color(0, 255, 0, 200));
    pointer_yaw.title("yaw-angle");
  }
}

void fieldsize() {
  field_border_left = width - field_width;
  field_border_top = int((height - field_height) / 2);
  field_border_bot = field_border_top;
  field_center.x = field_width / 2 + field_border_left;
  field_center.y = field_height / 2 + field_border_top;
}

void gui() {
  int cp5_h = 14;
  int cp5_x = 20;
  int cp5_y = 0;
  int cp5_s = 4;
  int cp5_hs = cp5_h + cp5_s;
  int cp5_n, cp5_hn;

  cp5 = new ControlP5(this);
  cp5.setColorBackground(color(50))
    .setColorForeground(color(100))
    .setColorActive(color(150));

  cp5_n = 3;
  Group cp5_system = cp5.addGroup("SYSTEM")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5_system.getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("pointer_control", 0, cp5_y = 3, 110, cp5_h).setCaptionLabel("DEVICE CONTROL DISPLAY").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("targets_pointer", 0, cp5_y += cp5_hs, 110, cp5_h).setCaptionLabel("SET DEVICE AS TARGET").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("stream_data_serial_print", 0, cp5_y += cp5_hs, 110, cp5_h).setCaptionLabel("SERIAL PRINT DEVICE DATA").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("targets_display", cp5_w - 113, cp5_y = 3, 110, cp5_h).setValue(true).setCaptionLabel("TARGETS DISPLAY").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("particles_calculate", cp5_w - 113, cp5_y += cp5_hs, 110, cp5_h).setCaptionLabel("PARTICLES CALCULATE").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
  }

  cp5_n = 2;
  Group cp5_presets = cp5.addGroup("PRESETS")
    .setBackgroundColor(50)
    .setBarHeight(cp5_h)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s); {
    cp5_presets.getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_default", 0, cp5_y = 3, 40, cp5_h).setCaptionLabel("DEFAULT").setGroup(cp5_presets).getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_1", 43, cp5_y, 40, cp5_h).setCaptionLabel("PRESET 1").setGroup(cp5_presets).getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_2", 86, cp5_y, 40, cp5_h).setCaptionLabel("PRESET 2").setGroup(cp5_presets).getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_3", 129, cp5_y, 40, cp5_h).setCaptionLabel("PRESET 3").setGroup(cp5_presets).getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_4", 0, cp5_y += cp5_hs, 40, cp5_h).setCaptionLabel("PRESET 4").setGroup(cp5_presets).getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_5", 43, cp5_y, 40, cp5_h).setCaptionLabel("PRESET 5").setGroup(cp5_presets).getCaptionLabel().align(CENTER, CENTER);
  }

  cp5_n = 3;
  Group cp5_vectorfield = cp5.addGroup("VECTORFIELD")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5.addButtonBar("theme")
      .setGroup(cp5_vectorfield)
      .setPosition(0, cp5_y = 3)
      .setSize(cp5_w, cp5_h)
      .addItems(split("PS VS LD HM FL", " "))
      .onMove(new CallbackListener() {
        public void controlEvent(CallbackEvent ev) {
          ButtonBar theme = (ButtonBar) ev.getController();
        }
      });
    cp5_vectorfield.getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("vectorfield_segment_nx", 5, vectorfield_segment_n_max, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_vectorfield);
    cp5.addSlider("vectorfield_segment_delay", 0.01, 0.2, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_vectorfield);
  }

  cp5_n = 8;
  Group cp5_particles = cp5.addGroup("PARTICLES")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5_particles.getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("particles_streams", 1, 200, 0, cp5_y = 3, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addSlider("particles_lifespan", 1, 200, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addSlider("particles_speed", -2, 40, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addToggle("particles_set", 0, cp5_y += cp5_hs, 40, cp5_h).setCaptionLabel("set").setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("particles_size", 1, 20, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addRange("PARTICLES_SATURATION_SCOPE").setGroup(cp5_particles)
      .setBroadcast(false)
      .setPosition(0, cp5_y += cp5_hs)
      .setSize(cp5_w, cp5_h)
      .setHandleSize(5)
      .setRange(0, 255)
      .setRangeValues(particles_saturation_min, particles_saturation_max)
      .setBroadcast(true);
    cp5.addRange("PARTICLES_SATURATION_LIMIT").setGroup(cp5_particles)
      .setBroadcast(false)
      .setPosition(0, cp5_y += cp5_hs)
      .setSize(cp5_w, cp5_h)
      .setHandleSize(5)
      .setRange(0, 255)
      .setRangeValues(particles_saturation_min, particles_saturation_max)
      .setBroadcast(true);
    cp5.addToggle("particles_birth_circle", 0, cp5_y += cp5_hs, 40, cp5_h).setCaptionLabel("set").setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("particles_birth_circle_r", 1, field_height / 2 - 20, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles)
      .setValue(field_height / 2 - vectorfield_segment_d);
    cp5.addToggle("particles_birth_square", 0, cp5_y += cp5_hs, 40, cp5_h).setCaptionLabel("set").setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("particles_birth_square_d", 1, field_height / 2 - 20, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles)
      .setValue(field_height / 2 - vectorfield_segment_d);
  }

  cp5_n = 4;
  Group cp5_particles_interaction = cp5.addGroup("PARTICLES INTERACTION")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5_particles_interaction.getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("particles_interaction", 0, cp5_y = 3, 40, cp5_h).setCaptionLabel("ADD").setGroup(cp5_particles_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addRange("PARTICLES_INTERACTION_RANGE").setGroup(cp5_particles_interaction)
      .setBroadcast(false)
      .setPosition(43, cp5_y)
      .setSize(cp5_w - 43, cp5_h)
      .setHandleSize(5)
      .setRange(0, 100)
      .setRangeValues(particles_interaction_d_min, particles_interaction_d_max)
      .setBroadcast(true);
    cp5.addToggle("addInteraction_force", 0, cp5_y += cp5_hs, 40, cp5_h).setCaptionLabel("ADD").setGroup(cp5_particles_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("particles_interaction_force", -0.5, 0.5, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles_interaction);
    cp5.addToggle("particles_extinction", 0, cp5_y += cp5_hs, 40, cp5_h * 2 + 4).setCaptionLabel("ADD").setGroup(cp5_particles_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("particles_extinction_d", 0, 20, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles_interaction);
    cp5.addSlider("particles_extinction_l", 0, 3, 43, cp5_y += cp5_hs, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles_interaction);
  }

  cp5_n = 1;
  Group cp5_effects = cp5.addGroup("PARTICLES EFFECTS")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5_effects.getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("particles_pulse", 0, cp5_y = 3, 40, cp5_h).setCaptionLabel("PULSE").setGroup(cp5_effects).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("particles_pull", 43, cp5_y, 40, cp5_h).setCaptionLabel("PULL").setGroup(cp5_effects).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("particles_noise", 86, cp5_y, 40, cp5_h).setCaptionLabel("NOISE").setGroup(cp5_effects).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("particles_freeze", 129, cp5_y, 40, cp5_h).setCaptionLabel("FREEZE").setGroup(cp5_effects).getCaptionLabel().align(CENTER, CENTER);
  }

  Group cp5_color = cp5.addGroup("PARTICLES COLOR")
    .setBackgroundColor(50)
    .setBarHeight(cp5_h)
    .setBackgroundHeight(147); {
    cp5_color.getCaptionLabel().align(CENTER, CENTER);
    cp5.addColorWheel("color_a", 0, 10, 100).setRGB(color(255, 0, 0)).setCaptionLabel("LEFT").setGroup(cp5_color);
    cp5.addColorWheel("color_b", 110, 10, 100).setRGB(color(0, 255, 0)).setCaptionLabel("RIGHT").setGroup(cp5_color);
    cp5.addColorWheel("color_c", 220, 10, 100).setRGB(color(0, 0, 255)).setCaptionLabel("TOP").setGroup(cp5_color);
    cp5.addToggle("background_display", 0, 130, 40, cp5_h).setCaptionLabel("set").setGroup(cp5_color).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("background_color", 0, 255, 43, 130, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_color);
  }

  cp5.addAccordion("acc").setPosition(20, 20).setWidth(cp5_w)
    .setCollapseMode(Accordion.MULTI)
    .setMinItemHeight(0)
    .addItem(cp5_system)
    .addItem(cp5_presets)
    .addItem(cp5_vectorfield)
    .addItem(cp5_particles)
    .addItem(cp5_particles_interaction)
    .addItem(cp5_effects)
    .addItem(cp5_color)
    .open();
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
  if (theControlEvent.isFrom("PARTICLES_INTERACTION_RANGE")) {
    particles_interaction_d_min = int(theControlEvent.getController().getArrayValue(0));
    particles_interaction_d_max = int(theControlEvent.getController().getArrayValue(1));
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

  if (keyPressed && key == 'p') cp5.saveProperties(("\\presets\\preset.json"));

  if (load_default) {
    cp5.loadProperties(("\\presets\\default.json"));
    load_default = false;
  }
  if (load_preset_1) {
    cp5.loadProperties(("\\presets\\preset_1.json"));
    load_preset_1 = false;
  }
  if (load_preset_2) {
    cp5.loadProperties(("\\presets\\preset_2.json"));
    load_preset_2 = false;
  }
  if (load_preset_3) {
    cp5.loadProperties(("\\presets\\preset_3.json"));
    load_preset_3 = false;
  }
  if (load_preset_4) {
    cp5.loadProperties(("\\presets\\preset_4.json"));
    load_preset_4 = false;
  }
  if (load_preset_5) {
    cp5.loadProperties(("\\presets\\preset_5.json"));
    load_preset_5 = false;
  }

  if (mouseX >= field_border_left && mouseY >= field_border_top && mouseY <= height - field_border_bot) noCursor();
  else cursor();
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
    pointer_targets.calculation(stream_data_angle_rot, stream_data_magni_u);
    targets.get(0).update(pointer_targets.magnitude.x, pointer_targets.magnitude.y);
  }

  for (Target targets: targets) {
    targets.update();
    targets.display(targets_display);
  }
}

void particles() {
  if (particles_calculate) {
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
          particles.add(new Particle(field_border_left + vectorfield_segment_d + particles_lx * i, height - field_border_bot - vectorfield_segment_d, particles_lifespan, color_c)); // bottom
        }
      }
      if (particles_birth_circle) {
        particles_streams_circle = 4 * particles_streams;
        for (int i = 0; i <= particles_streams_circle; i++) {
          paricles_birth_circle_pos.x = field_center.x + particles_birth_circle_r * cos((PI * i * 2) / (particles_streams_circle));
          paricles_birth_circle_pos.y = field_center.y - particles_birth_circle_r * sin((PI * i * 2) / (particles_streams_circle));

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
      if (part.lifespan <= 0) particles.remove(i);
    }

    int n = particles.size();
    for (Particle particles: particles) {
      if (particles_freeze != true) {
        particles.update();
        particles.lifespan();
        particles.addPulse(particles_pulse);
        particles.addPull(particles_pull);
        particles.addNoise(particles_noise);
        if (particles_streams <= 10 && n < 3000) {
          particles.addInteraction(particles_interaction, particles_interaction_d_min, particles_interaction_d_max, particles_interaction_force, particles_extinction, particles_extinction_d, particles_extinction_l);
        }
      }
      particles.display(particles_set);
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
    vctr.grid(false, false);
  }
}

void data() {
  if (controls_show) {
    textSize(9);
    fill(255);
    textAlign(LEFT, BOTTOM);
    text("FPS\n" + "VECTORS\n" + "PARTICLES\n" + "TARGETS\n\n" + "DEVICE\n\n" +
      year() + '/' + month() + '/' + day() + "\n\n" +
      "David Herren", 20, height - 20);

    text(float(int(float(frameCount) / millis() * 10000)) / 10 + "\n" +
      vectors.size() + "\n" +
      particles.size() + "\n" +
      targets.size() + "\n\n" +
      stream_port_name + "\n\n" +
      hour() + ':' + minute() + ':' + second() + "\n\nsphere.pde", 100, height - 20);
  }
}

void record() {
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
  PVector orgin = new PVector();
  PVector needle = new PVector();
  PVector magnitude = new PVector();
  PVector[] path_store = new PVector[100];
  float a, d, r;
  float[] graph_store;
  int graph_count = 0, path_count = 0;
  color gray = color(50), brgt = color(255);

  Pointer(float x, float y, float diameter) {
    orgin.x = x;
    orgin.y = y;
    d = diameter;
    r = d / 2;
    graph_store = new float[int(d)];
    for (int i = 0; i < path_store.length; i++) path_store[i] = new PVector();
  }

  void calculation(float angle, float m) {
    a = angle;
    needle.x = orgin.x + r * cos(a);
    needle.y = orgin.y + r * sin(a);
    magnitude.x = orgin.x + r * cos(a) * m;
    magnitude.y = orgin.y + r * sin(a) * m;
  }

  void needle(boolean b) {
    noFill();
    stroke(gray);
    if (b) ellipse(orgin.x, orgin.y, d, d);
    line(orgin.x, orgin.y - r, orgin.x, orgin.y + r);
    line(orgin.x - r, orgin.y, orgin.x + r, orgin.y);
    stroke(brgt);
    line(orgin.x, orgin.y, needle.x, needle.y);

    for (int i = 0; i <= 360; i += 30) {
      float s = i * PI / 180;
      if (i % 90 > 0) {
        stroke(gray);
        line(orgin.x + r * cos(s), orgin.y + r * sin(s), orgin.x + (r - 10) * cos(s), orgin.y + (r - 10) * sin(s));
      }
    }
  }

  void magnitude() {
    noFill();
    stroke(brgt);
    ellipse(magnitude.x, magnitude.y, 8, 8);
  }

  void path(boolean set, color c) {
    if (set) {
      path_count++;
      if (path_count == path_store.length - 1) path_count = 0;
      path_store[path_count].x = magnitude.x;
      path_store[path_count].y = magnitude.y;
      noStroke();
      fill(c);
      for (int i = 0; i < path_store.length; i++) ellipse(path_store[i].x, path_store[i].y, 2, 2);
    }
  }

  void graph(boolean set, int f) {
    if (set) {
      graph_count++;
      if (graph_count == d - 1) graph_count = 0;
      graph_store[graph_count] = f * a;
      stroke(gray);
      for (int i = 0; i < graph_store.length; i++) line(orgin.x - r + i, orgin.y + r + r / 1.5, orgin.x - r + i, orgin.y + r + r / 1.5 - graph_store[i]);
    }
  }

  void title(String t) {
    textSize(9);
    fill(255);
    textAlign(CENTER, CENTER);
    text(t + ": " + float(int(10 * a * 180 / PI)) / 10 + '°', orgin.x, orgin.y - r - r / 5);
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

  void display(boolean set) {
    if (set) {
      noFill();
      stroke(255, 200);
      strokeWeight(2);
      ellipse(pos.x, pos.y, 15, 15);
    }
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

  void grid(boolean ellipse, boolean rect) {
    noFill();
    stroke(darkgray);
    strokeWeight(1);
    if (ellipse) ellipse(orgin.x, orgin.y, vectorfield_segment_d, vectorfield_segment_d);
    rectMode(CENTER);
    if (rect) rect(orgin.x, orgin.y, vectorfield_segment_d, vectorfield_segment_d);
  }

  void colorize(int input) {
    float scope;
    int n, r;
    strokeWeight(1);

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
  PVector pull = new PVector();
  PVector repul = new PVector();

  float dist;
  int active, lifespan, lifespan_start, lifespan_range, saturation;

  boolean connected = false;
  boolean extinguished = false;

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

  void addPull(boolean set) {
    if (set) pull = aclr.mult(-1);
  }

  void addNoise(boolean set) {
    if (set) aclr.mult(random(0.95, 1.05));
  }

  void addPulse(boolean set) {
    if (set) {
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
      pos.add(pull);
    }
  }

  void addInteraction(boolean set, int d_min, int d_max, float f, boolean e, float e_d, float e_l) {
    if (set) {
      for (int i = particles.size() - 1; i > 0; i--) {
        Particle part = particles.get(i);
        force = PVector.sub(part.pos, pos);
        float d = force.mag();

        if (d < d_max && d > d_min) {
          if (addInteraction_force) {
            force.setMag(f);
            aclr.add(force);
            part.connected = true;
            connected = false;
          }
          if (connected == false) {
            strokeWeight(1);
            stroke(r, g, b, a);
            line(pos.x, pos.y, part.pos.x, part.pos.y);
          }
        }

        if (d < e_d && e) {
          lifespan -= e_l;
        }
      }
    }
  }

  void update() {
    active = int(round((pos.y - field_border_top) / vectorfield_segment_d) * vectorfield_segment_ny + round((pos.x - field_border_left) / vectorfield_segment_d)); // detect active vector

    if (active >= 0 && active < vectors.size()) {
      Vectorfield vctr = vectors.get(active);
      aclr.add(vctr.force);
    }

    aclr.setMag(particles_speed + pulse_speed);
    pos.add(aclr);
  }

  void lifespan() {
    lifespan--;
    if (pos.x <= vectorfield_segment_d + field_border_left || pos.x >= width - vectorfield_segment_d ||
      pos.y <= field_border_top + vectorfield_segment_d || pos.y >= height - field_border_bot - vectorfield_segment_d) {
      lifespan = 0;
    }
  }

  void display(boolean set) {
    lifespan_range = int(map(lifespan, 0, lifespan_start, 255, 0));

    if (lifespan_range < particles_saturation_min || lifespan_range > particles_saturation_max) saturation = particles_saturation_min_limit;
    else saturation = int(map(lifespan_range, particles_saturation_min, particles_saturation_max, particles_saturation_min_limit, particles_saturation_max_limit));

    a = saturation;
    r = (argb >> 16) & 0xFF;
    g = (argb >> 8) & 0xFF;
    b = argb & 0xFF;

    if (set) {
      noStroke();
      fill(r, g, b, a);
      rectMode(CENTER);
      rect(pos.x, pos.y, particles_size, particles_size);
    }
  }
}
