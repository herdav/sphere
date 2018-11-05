/*  SPHERE --------------------------------------------------------------
    Created 2018 by David Herren.                                       /
    https://davidherren.ch                                              /
    https://github.com/herdav/sphere                                    /
    Licensed under the MIT License.                                     /
    ---------------------------------------------------------------------
*/

/*  SHORT-KEYS ----------------------------------------------------------
    [q] .......... gui hide                                             /
    [w] .......... gui show                                             /
    [s] .......... save screen as pdf                                   /
    [ARROWS] ..... move center of particlesbirth                        /
    [.] .......... move center of particlesbirth to orgin               /
    [p] .......... save current setting as preset                       /
    [u] .......... update current preset                                /
    [0 - 3] ...... load preset                                          /
    mouse-left ... set target                                           /
    mouse-right .. clear all targets                                    /
    ---------------------------------------------------------------------
*/

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

// TARGETS --------------------------------------------------------------
Target targt;
ArrayList < Target > targets;
boolean targt_removed = false;
boolean targt_pointer = false;
boolean targt_mouse = true;

// VECTORFIELD ----------------------------------------------------------
Vectorfield vctr;
ArrayList < Vectorfield > vectors;
PVector vctr_segment_pos = new PVector();
float vctr_segment_d, vctr_segment_r, vctr_maxDist;
float vctr_segment_delay = 0.03;
int vctr_segment_nx = 50, vctr_segment_ny;
int vctr_segment_n, vctr_segment_n_max = 300;

// PARTICLE CELLS ------------------------------------------------------
Pariclecell cell;
ArrayList < Pariclecell > cells;
PVector cell_segment_pos = new PVector();
float cell_segment_d, cell_segment_r;
int cell_segment_nx = 20, cell_segment_ny;
int cell_segment_n, cell_segment_n_max = 100;
int cell_set_max_entries = 100;
int cell_calculationload_max, cell_calculationload_eff;
float cell_calculationload;
boolean cell_segment_display = false;
boolean cell_set_filter = true;

// PARTICLES ------------------------------------------------------------
Particle part;
ArrayList < Particle > particles;
int part_count_birthrate;
int part_birthrate = 1;
int part_size = 1;
int part_streams = 10;
int part_streams_circle;
int part_saturation_min = 0;
int part_saturation_max = 255;
int part_saturation_min_limit = 0;
int part_saturation_max_limit = 255;
float part_lifespan = 40;
float part_lifespan_max = 200;
float part_interaction_d_min = 5;
float part_interaction_d_max = 30;
float part_interaction_force = 0;
float part_extinction_d = 1;
float part_extinction_l = 1;
float part_speed = 8;
float part_lx, part_ly;
boolean part_clear = false;
boolean part_noise = false;
boolean part_pull = false;
boolean part_interaction = false;
boolean part_set_extinction = false;
boolean part_set_interaction = false;
boolean part_set_interaction_distancerelated = true;
boolean part_birth_circle = true;
boolean part_calculate = true;
boolean part_set = true;
float part_birth_circle_r;
PVector paricles_birth_circle_pos = new PVector();
PVector paricles_birth_center_pos = new PVector();

// GUI & CONTROLS -------------------------------------------------------
ControlP5 cp5;
int cp5_w = 320;
color color_a, color_b, color_c, color_d;
boolean controls_show = true;
boolean record_pdf = false;
boolean background_display = true;
boolean targt_display = false;
boolean load_preset_0, load_preset_1, load_preset_2, load_preset_3;
int load_preset_last = 0;
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
  pointer_rstr.y = 180;
  pointer_x_axis = new Pointer(pointer_rstr.x, 120, pointer_rstr.y);
  pointer_y_axis = new Pointer(pointer_rstr.x, 360, pointer_rstr.y);
  pointer_yaw = new Pointer(pointer_rstr.x, 600, pointer_rstr.y);
  pointer_stp = new Pointer(pointer_rstr.x, 600, pointer_rstr.y);

  pointer_targets = new Pointer(field_center.x, field_center.y, field_height / 1.5);
  vectors = new ArrayList < Vectorfield > ();
  cells = new ArrayList < Pariclecell > ();
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
  cells();
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
  if (set && controls_show) {
    pointer_x_axis.calculation(stream_data_angle_x, 1);
    pointer_x_axis.needle(true);
    pointer_x_axis.graph(false, 30);
    pointer_x_axis.magnitude();
    pointer_x_axis.path(true, color(0, 255, 0, 200));
    pointer_x_axis.title("X-AXIS");

    pointer_y_axis.calculation(stream_data_angle_y, 1);
    pointer_y_axis.needle(true);
    pointer_y_axis.graph(false, 30);
    pointer_y_axis.magnitude();
    pointer_y_axis.path(true, color(0, 255, 0, 200));
    pointer_y_axis.title("Y-AXIS");

    pointer_stp.calculation(stream_data_angle_stp, sqrt(sq(stream_data_rpm)) / 35);
    pointer_stp.needle(false);
    pointer_stp.magnitude();
    pointer_stp.path(true, color(255, 0, 255, 200));

    pointer_yaw.calculation(stream_data_angle_rot, stream_data_magni_u);
    pointer_yaw.needle(true);
    pointer_yaw.graph(false, 5);
    pointer_yaw.magnitude();
    pointer_yaw.path(true, color(0, 255, 0, 200));
    pointer_yaw.title("YAW-ANGLE");
  }
}

void fieldsize() {
  field_border_left = width - field_width;
  field_border_top = int((height - field_height) / 2);
  field_border_bot = field_border_top;
  field_center.x = field_width / 2 + field_border_left;
  field_center.y = field_height / 2 + field_border_top;
  paricles_birth_center_pos = field_center.copy();
}

void gui() {
  int cp5_h = 14;
  int cp5_s = 4;
  int cp5_x, cp5_y;
  int cp5_hs = cp5_h + cp5_s;
  int cp5_n;

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
    cp5.addToggle("pointer_control").setPosition(0, cp5_y = 3).setSize(110, cp5_h).setGroup(cp5_system).setCaptionLabel("DEVICE CONTROL DISPLAY").getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("targt_pointer").setPosition(0, cp5_y += cp5_hs).setSize(110, cp5_h).setGroup(cp5_system).setCaptionLabel("SET DEVICE AS TARGET").getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("stream_data_serial_print").setPosition(0, cp5_y += cp5_hs).setSize(110, cp5_h).setCaptionLabel("SERIAL PRINT DEVICE DATA").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("targt_display").setPosition(cp5_w - 113, cp5_y = 3).setSize(110, cp5_h).setValue(true).setCaptionLabel("TARGETS DISPLAY").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("part_calculate").setPosition(cp5_w - 113, cp5_y += cp5_hs).setSize(110, cp5_h).setCaptionLabel("PARTICLES CALCULATE").setGroup(cp5_system).getCaptionLabel().align(CENTER, CENTER);
  }

  cp5_n = 1;
  Group cp5_presets = cp5.addGroup("PRESETS")
    .setBackgroundColor(50)
    .setBarHeight(cp5_h)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s); {
    cp5_presets.getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_0").setPosition(cp5_x = 0, cp5_y = 3).setSize(78, cp5_h).setGroup(cp5_presets).setCaptionLabel("DEFAULT").getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_1").setPosition(cp5_x += 81, cp5_y).setSize(78, cp5_h).setGroup(cp5_presets).setCaptionLabel("PRESET 1").getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_2").setPosition(cp5_x += 81, cp5_y).setSize(78, cp5_h).setGroup(cp5_presets).setCaptionLabel("PRESET 2").getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_3").setPosition(cp5_x += 81, cp5_y).setSize(77, cp5_h).setGroup(cp5_presets).setCaptionLabel("PRESET 3").getCaptionLabel().align(CENTER, CENTER);
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
    cp5.addSlider("vctr_segment_nx", 5, vctr_segment_n_max, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_vectorfield);
    cp5.addSlider("vctr_segment_delay", 0.01, 0.2, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_vectorfield);
  }

  cp5_n = 7;
  Group cp5_particles = cp5.addGroup("PARTICLES")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5_particles.getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_streams", 1, 200, 0, cp5_y = 3, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addSlider("part_lifespan", 1, part_lifespan_max, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addSlider("part_speed", -2, 40, 0, cp5_y += cp5_hs, cp5_w, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addToggle("part_set").setPosition(0, cp5_y += cp5_hs).setSize(40, cp5_h).setCaptionLabel("set").setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_size", 1, 20, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addRange("part_saturation_scope").setGroup(cp5_particles)
      .setBroadcast(false)
      .setPosition(0, cp5_y += cp5_hs)
      .setSize(cp5_w, cp5_h)
      .setHandleSize(5)
      .setRange(0, 255)
      .setRangeValues(part_saturation_min, part_saturation_max)
      .setBroadcast(true);
    cp5.addRange("part_saturation_limit").setGroup(cp5_particles)
      .setBroadcast(false)
      .setPosition(0, cp5_y += cp5_hs)
      .setSize(cp5_w, cp5_h)
      .setHandleSize(5)
      .setRange(0, 255)
      .setRangeValues(part_saturation_min, part_saturation_max)
      .setBroadcast(true);
    cp5.addToggle("part_birth_circle").setPosition(0, cp5_y += cp5_hs).setSize(40, cp5_h).setCaptionLabel("set").setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_birth_circle_r", 1, field_height / 2 - 20, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles)
      .setValue(field_height / 2 - vctr_segment_d);
  }

  cp5_n = 8;
  Group cp5_part_interaction = cp5.addGroup("PARTICLES INTERACTION")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5_part_interaction.getCaptionLabel().align(CENTER, CENTER);
    cp5_vectorfield.getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("cell_set_filter").setPosition(0, cp5_y = 3).setSize(40, cp5_h).setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("cell_segment_nx", 8, cell_segment_n_max, 43, cp5_y = 3, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);
    cp5.addToggle("cell_segment_display").setPosition(0, cp5_y += cp5_hs).setSize(40, cp5_h).setCaptionLabel("SHOW").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("cell_set_max_entries", 2, 200, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);
    cp5.addToggle("part_interaction").setPosition(0, cp5_y += cp5_hs).setSize(40, cp5_h).setCaptionLabel("ADD").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addRange("part_interaction_range").setGroup(cp5_part_interaction)
      .setBroadcast(false)
      .setPosition(43, cp5_y)
      .setSize(cp5_w - 43, cp5_h)
      .setHandleSize(5)
      .setRange(0, 100)
      .setRangeValues(part_interaction_d_min, part_interaction_d_max)
      .setBroadcast(true);
    cp5.addToggle("part_set_interaction").setPosition(0, cp5_y += cp5_hs).setSize(40, cp5_h).setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_interaction_force", -1, 1, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);
    cp5.addToggle("part_set_interaction_distancerelated").setPosition(0, cp5_y += cp5_hs).setSize(40, cp5_h).setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("part_set_extinction").setPosition(0, cp5_y += cp5_hs).setSize(40, cp5_h * 2 + 4).setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_extinction_d", 0, 20, 43, cp5_y, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);
    cp5.addSlider("part_extinction_l", 0, 2, 43, cp5_y += cp5_hs, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);
  }

  cp5_n = 1;
  Group cp5_effects = cp5.addGroup("PARTICLES EFFECTS")
    .setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s)
    .setBarHeight(cp5_h); {
    cp5_effects.getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("part_clear").setPosition(0, cp5_y = 3).setSize(40, cp5_h).setCaptionLabel("CLEAR").setGroup(cp5_effects).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("part_pull").setPosition(43, cp5_y).setSize(40, cp5_h).setCaptionLabel("PULL").setGroup(cp5_effects).getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("part_noise").setPosition(86, cp5_y).setSize(40, cp5_h).setCaptionLabel("NOISE").setGroup(cp5_effects).getCaptionLabel().align(CENTER, CENTER);
  }

  Group cp5_color = cp5.addGroup("PARTICLES COLOR")
    .setBackgroundColor(50)
    .setBarHeight(cp5_h)
    .setBackgroundHeight(147); {
    cp5_color.getCaptionLabel().align(CENTER, CENTER);
    cp5.addColorWheel("color_a", 0, 10, 100).setRGB(color(255, 0, 0)).setCaptionLabel("LEFT").setGroup(cp5_color);
    cp5.addColorWheel("color_b", 110, 10, 100).setRGB(color(0, 255, 0)).setCaptionLabel("RIGHT").setGroup(cp5_color);
    cp5.addColorWheel("color_c", 220, 10, 100).setRGB(color(0, 0, 255)).setCaptionLabel("TOP").setGroup(cp5_color);
    cp5.addToggle("background_display").setPosition(0, 130).setSize(40, cp5_h).setCaptionLabel("set").setGroup(cp5_color).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("background_color", 0, 255, 43, 130, cp5_w - 43, cp5_h).setSliderMode(Slider.FLEXIBLE).setGroup(cp5_color);
  }

  cp5_x = 20;
  cp5_y = 20;
  cp5.addAccordion("acc").setPosition(cp5_x, cp5_y).setWidth(cp5_w)
    .setCollapseMode(Accordion.MULTI)
    .setMinItemHeight(0)
    .addItem(cp5_system)
    .addItem(cp5_presets)
    .addItem(cp5_vectorfield)
    .addItem(cp5_particles)
    .addItem(cp5_part_interaction)
    .addItem(cp5_effects)
    .addItem(cp5_color)
    .open();
}

void controlEvent(ControlEvent theControlEvent) {
  if (theControlEvent.isFrom("part_saturation_scope")) {
    part_saturation_min = int(theControlEvent.getController().getArrayValue(0));
    part_saturation_max = int(theControlEvent.getController().getArrayValue(1));
  }
  if (theControlEvent.isFrom("part_saturation_limit")) {
    part_saturation_min_limit = int(theControlEvent.getController().getArrayValue(0));
    part_saturation_max_limit = int(theControlEvent.getController().getArrayValue(1));
  }
  if (theControlEvent.isFrom("part_interaction_range")) {
    part_interaction_d_min = int(theControlEvent.getController().getArrayValue(0));
    part_interaction_d_max = int(theControlEvent.getController().getArrayValue(1));
  }
}

void control() {
  // visibility gui
  if (keyPressed && key == 'q') {
    controls_show = false;
    cp5.hide();
  }
  if (keyPressed && key == 'w' || !controls_show && mouseX < 100) {
    controls_show = true;
    cp5.show();
  }

  // visibility cursor
  if (mouseX >= field_border_left && mouseY >= field_border_top && mouseY <= height - field_border_bot) {
    noCursor();
  } else cursor();

  // move center of particlesbirth
  if (keyPressed) {
    if (key == CODED) {
      if (keyCode == UP) paricles_birth_center_pos.y -= 1;
      if (keyCode == DOWN) paricles_birth_center_pos.y += 1;
      if (keyCode == LEFT) paricles_birth_center_pos.x -= 1;
      if (keyCode == RIGHT) paricles_birth_center_pos.x += 1;
    }
    if (key == '.') {
      paricles_birth_center_pos = field_center.copy();
    }
  }

  // save and load presets
  if (keyPressed) {
    if (key == 'p') cp5.saveProperties(("\\presets\\preset.json"));
    if (key == 'u') cp5.saveProperties(("\\presets\\preset_" + str(load_preset_last) + ".json"));
  }
  if (load_preset_0) {
    cp5.loadProperties(("\\presets\\preset_0.json"));
    load_preset_last = 0;
    println(loaded(load_preset_last));;
    load_preset_0 = false;
  }
  if (load_preset_1) {
    cp5.loadProperties(("\\presets\\preset_1.json"));
    load_preset_last = 1;
    println(loaded(load_preset_last));
    load_preset_1 = false;
  }
  if (load_preset_2) {
    cp5.loadProperties(("\\presets\\preset_2.json"));
    load_preset_last = 2;
    println(loaded(load_preset_last));
    load_preset_2 = false;
  }
  if (load_preset_3) {
    cp5.loadProperties(("\\presets\\preset_3.json"));
    load_preset_last = 3;
    println(loaded(load_preset_last));
    load_preset_3 = false;
  }
}

String loaded(int i) {
  String t = "Preset " + str(i) + " is loaded.";
  return t;
}

void mouseClicked() {
  if (targt_mouse) {
    if (mouseButton == LEFT && mouseX > field_border_left) {
      targets.add(new Target(mouseX, mouseY));
    }
    if (mouseButton == RIGHT && targets.size() > 1 && mouseX > field_border_left) {
      for (int i = targets.size() - 1; i > 0; i--) targets.remove(i);
    }
  }
}

void targets() {
  if (targt_pointer) targt_mouse = false;
  else targt_mouse = true;

  if (targt_mouse) {
    if (mouseX >= field_border_left && mouseY >= field_border_top && mouseY <= height - field_border_bot) {
      if (targt_removed) {
        targets.get(0).update(mouseX, mouseY);
        targt_removed = false;
      } else targets.get(0).update(mouseX, mouseY);
    }

    if (mouseX < field_border_left || mouseY < field_border_top || mouseY > height - field_border_bot) {
      if (targets.size() == 1) {
        targets.get(0).update(field_center.x, field_center.y);
      }
      if (targets.size() > 1 && !targt_removed) {
        targets.remove(0);
        targt_removed = true;
      }
    }
  }

  if (targt_pointer && stream_port_on) {
    pointer_targets.calculation(stream_data_angle_rot, stream_data_magni_u);
    targets.get(0).update(pointer_targets.magnitude.x, pointer_targets.magnitude.y);
  }

  for (Target targets: targets) {
    targets.update();
    targets.display(targt_display);
  }
}

void particles() {
  if (part_calculate) {
    part_count_birthrate++;
    if (part_count_birthrate == part_birthrate) {
      part_count_birthrate = 0;

      if (part_birth_circle) {
        part_streams_circle = 4 * part_streams;
        for (int i = 0; i <= part_streams_circle; i++) {
          paricles_birth_circle_pos.x = paricles_birth_center_pos.x + part_birth_circle_r * cos((PI * i * 2) / (part_streams_circle));
          paricles_birth_circle_pos.y = paricles_birth_center_pos.y - part_birth_circle_r * sin((PI * i * 2) / (part_streams_circle));

          if (i >= 0 && i < part_streams_circle / 3) {
            particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, part_lifespan, color_a));
          }
          if (i >= part_streams_circle / 3 && i < part_streams_circle / 3 * 2) {
            particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, part_lifespan, color_b));
          }
          if (i >= part_streams_circle / 3 * 2 && i < part_streams_circle) {
            particles.add(new Particle(paricles_birth_circle_pos.x, paricles_birth_circle_pos.y, part_lifespan, color_c));
          }
        }
      }
    }

    for (int i = 0; i < particles.size(); i++) {
      Particle part = particles.get(i);
      part.clear(part_clear);
      part.lifespan();
      part.getVector();
      part.getCell(i);
      part.addPull(part_pull);
      part.addNoise(part_noise);
      part.addInteraction(part_interaction);
      part.colorize(true);
      part.display(part_set);
    }

    cell_calculationload_max = int(sq(particles.size()));
    cell_calculationload = float(int(1000 * float(cell_calculationload_eff) / float(cell_calculationload_max))) / 10;

    for (int i = particles.size() - 1; i >= 0; i--) {
      Particle part = particles.get(i);
      if (part.lifespan <= 0) particles.remove(i);
    }
  }
}

void cells() {
  cell_segment_ny = cell_segment_nx;
  cell_segment_n = cell_segment_nx * cell_segment_ny;

  if (cell_segment_n != cells.size()) {
    for (int i = particles.size() - 1; i >= 0; i--) particles.remove(i);
    for (int i = cells.size() - 1; i >= 0; i--) cells.remove(i);

    if (field_height % cell_segment_ny > 0) cell_segment_nx++;
    cell_segment_d = field_height / cell_segment_nx;
    cell_segment_r = cell_segment_d / 2;
    for (int i = 0; i < cell_segment_ny; i++) {
      for (int j = 0; j < cell_segment_nx; j++) {
        cell_segment_pos.x = field_border_left + j * cell_segment_d + cell_segment_r;
        cell_segment_pos.y = field_border_top + i * cell_segment_d + cell_segment_r;
        cells.add(new Pariclecell(cell_segment_pos));
      }
    }
  }

  cell_calculationload_eff = 0;
  for (int i = 0; i < cells.size(); i++) {
    Pariclecell cell = cells.get(i);
    if (cell.list.size() > 0) {
      cell.display(cell_segment_display);
      cell_calculationload_eff += int(sq(cell.list.size()));
    }
    cell.reset();
  }
}

void field() {
  vctr_segment_ny = vctr_segment_nx;
  vctr_segment_n = vctr_segment_nx * vctr_segment_ny;

  if (vctr_segment_n != vectors.size()) {
    for (int i = particles.size() - 1; i >= 0; i--) particles.remove(i);
    for (int i = vectors.size() - 1; i >= 0; i--) vectors.remove(i);

    if (field_height % vctr_segment_ny > 0) vctr_segment_nx++;
    vctr_segment_d = field_height / vctr_segment_nx;
    vctr_segment_r = vctr_segment_d / 2;
    vctr_maxDist = sqrt(2 * sq((vctr_segment_nx - 1) * vctr_segment_d));
    for (int i = 0; i < vctr_segment_ny; i++) {
      for (int j = 0; j < vctr_segment_nx; j++) {
        vctr_segment_pos.x = field_border_left + j * vctr_segment_d + vctr_segment_r;
        vctr_segment_pos.y = field_border_top + i * vctr_segment_d + vctr_segment_r;
        vectors.add(new Vectorfield(vctr_segment_pos));
      }
    }
  }

  for (int i = 0; i < vctr_segment_n; i++) {
    Vectorfield vctr = vectors.get(i);

    for (int j = targets.size() - 1; j >= 0; j--) {
      vctr.target(targets.get(j).pos);
      vctr.magnitude(vctr_segment_delay);
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
    text("FPS\n" + "VECTORS\n" + "PARTICLES\n" + "CELLS\n" + "INTERACTION\n" + "DIST\n" + "TARGETS\n" +
      "PRESET\n" + "DEVICE\n\n" + year() + '/' + month() + '/' + day() + "\n\n" +
      "David Herren", 20, height - 20);

    text(int(frameRate) + "\n" +
      vectors.size() + "\n" +
      particles.size() + "\n" +
      cells.size() + "\n" +
      cell_calculationload + "%\n" +
      "P" + int(part_interaction_d_max) + " / C" + int(cell_segment_d) + "\n" +
      targets.size() + "\n" +
      load_preset_last + " is loaded\n" +
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

  Pointer(float x, float y, float d) {
    orgin.x = x;
    orgin.y = y;
    this.d = d;
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
      for (int i = 0; i < graph_store.length; i++) line(orgin.x - r + i, orgin.y + d / 1.5, orgin.x - r + i, orgin.y + d / 1.5 - graph_store[i]);
    }
  }

  void title(String t) {
    textSize(9);
    fill(255);
    textAlign(CENTER, CENTER);
    text(t + ": " + float(int(10 * a * 180 / PI)) / 10 + '°', orgin.x, orgin.y + r + r / 5);
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

  Vectorfield(PVector orgin) {
    this.orgin.x = orgin.x;
    this.orgin.y = orgin.y;
  }

  void target(PVector target) {
    dist = orgin.dist(target);
    dist = vctr_segment_r - vctr_segment_r * dist / vctr_maxDist;
    direct = PVector.sub(target, orgin);
    direct.setMag(dist);
    direct.add(orgin);
  }

  void magnitude(float velocity) {
    offset = PVector.sub(direct, result);
    magnitude = offset.mag();
    offset.mult(velocity);
    result.add(offset);
    force = PVector.sub(result, orgin);
  }

  void grid(boolean ellipse, boolean rect) {
    noFill();
    stroke(darkgray);
    strokeWeight(1);
    if (ellipse) ellipse(orgin.x, orgin.y, vctr_segment_d, vctr_segment_d);
    rectMode(CENTER);
    if (rect) rect(orgin.x, orgin.y, vctr_segment_d, vctr_segment_d);
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
        scope = map(magnitude, 0, vctr_segment_d, 0, 255);
        fill(scope);
        break;

      case 3: // heat map
        n = 11;
        r = 255;
        scope = map(magnitude, 0, vctr_segment_d, 0, n * r);
        if (scope >= 0 * r) fill(0, 0, scope); // blue 
        if (scope >= 1 * r) fill(0, scope - 1 * r, 255); // cyan
        if (scope >= 2 * r) fill(0, 255, 3 * r - scope); // green
        if (scope >= 3 * r) fill(scope - 3 * r, 255, 0); // yellow
        if (scope >= 4 * r) fill(255, 5 * r - scope, 0); // red
        if (scope >= 5 * r) fill(6 * r - scope, 0, 0); // dark red
        break;

      case 4: // field lines
        n = 100;
        for (int i = 0; i <= n; i++) {
          scope = map(magnitude, 0, vctr_segment_d, 0, n);
          if (scope >= i * 2 && i % 2 == 0) fill(150);
          if (scope >= i * 2 && i % 2 > 0) fill(50);
        }
        break;

      default:
        noFill();
    }

    noStroke();
    rectMode(CENTER);
    rect(orgin.x, orgin.y, vctr_segment_d, vctr_segment_d);
  }
}

class Pariclecell {
  IntList list;
  PVector orgin = new PVector();

  Pariclecell(PVector orgin) {
    this.orgin.x = orgin.x;
    this.orgin.y = orgin.y;

    list = new IntList();
  }

  void reset() {
    list.clear();
  }

  void display(boolean set) {
    if (set) {
      fill(map(list.size(), 0, particles.size() / 10, 0, 255));
      noStroke();
      rectMode(CENTER);
      rect(orgin.x, orgin.y, cell_segment_d, cell_segment_d);
    }
  }
}

class Particle {
  PVector pos = new PVector();
  PVector velocity = new PVector();
  PVector force = new PVector();
  PVector dist = new PVector();
  PVector pull = new PVector();
  PVector repul = new PVector();

  float lifespan, lifespan_start, lifespan_range;
  int active_vector, saturation;

  int id;
  int active_cell_x, active_cell_y, active_cell;
  int active_cell_l, active_cell_r, active_cell_t, active_cell_b,
  active_cell_lt, active_cell_rt, active_cell_lb, active_cell_rb;

  boolean connected = false;

  color argb;
  int a, r, g, b;

  Particle(float x, float y, float lifespan, color argb) {
    pos.x = x;
    pos.y = y;

    this.lifespan = lifespan;
    this.argb = argb;

    lifespan_start = lifespan;
  }

  void lifespan() {
    lifespan--;
    if (pos.x <= vctr_segment_d + field_border_left || pos.x >= width - vctr_segment_d ||
      pos.y <= field_border_top + vctr_segment_d || pos.y >= height - field_border_bot - vctr_segment_d) {
      lifespan = 0;
    }
  }

  void getVector() {
    active_vector = int((pos.y - field_border_top) / vctr_segment_d) * vctr_segment_ny + int((pos.x - field_border_left) / vctr_segment_d); // detect active vector

    if (active_vector >= 0 && active_vector < vectors.size()) {
      Vectorfield vctr = vectors.get(active_vector);
      velocity.add(vctr.force);
    }

    velocity.setMag(part_speed);
    pos.add(velocity);
  }

  void getCell(int id) {
    this.id = id;

    active_cell_x = int((pos.x - field_border_left) / cell_segment_d);
    active_cell_y = int((pos.y - field_border_top) / cell_segment_d);

    active_cell = active_cell_y * cell_segment_ny + active_cell_x; // detect active cell

    if (active_cell >= 0 && active_cell < cells.size()) {
      Pariclecell cell = cells.get(active_cell);

      if (cell.list.size() < cell_set_max_entries) { // set max entries in cell
        cell.list.append(id);

        // define surrounding cells
        active_cell_l = active_cell_y * cell_segment_ny + (active_cell_x - 1);
        active_cell_r = active_cell_y * cell_segment_ny + (active_cell_x + 1);
        active_cell_t = (active_cell_y - 1) * cell_segment_ny + active_cell_x;
        active_cell_b = (active_cell_y + 1) * cell_segment_ny + active_cell_x;
        active_cell_lt = (active_cell_y - 1) * cell_segment_ny + (active_cell_x - 1);
        active_cell_rt = (active_cell_y - 1) * cell_segment_ny + (active_cell_x + 1);
        active_cell_lb = (active_cell_y + 1) * cell_segment_ny + (active_cell_x - 1);
        active_cell_rb = (active_cell_y + 1) * cell_segment_ny + (active_cell_x + 1);

        if (active_cell_x > 0 && active_cell_x <= cell_segment_nx - 1 && active_cell_y >= 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_l).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x < cell_segment_nx - 1 && active_cell_y >= 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_r).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x <= cell_segment_nx - 1 && active_cell_y > 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_t).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x <= cell_segment_nx - 1 && active_cell_y >= 0 && active_cell_y < cell_segment_ny - 1) {
          cells.get(active_cell_b).list.append(id);
        }
        if (active_cell_x > 0 && active_cell_x <= cell_segment_nx - 1 && active_cell_y > 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_lt).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x < cell_segment_nx - 1 && active_cell_y > 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_rt).list.append(id);
        }
        if (active_cell_x > 0 && active_cell_x <= cell_segment_nx - 1 && active_cell_y >= 0 && active_cell_y < cell_segment_ny - 1) {
          cells.get(active_cell_lb).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x < cell_segment_nx - 1 && active_cell_y >= 0 && active_cell_y < cell_segment_ny - 1) {
          cells.get(active_cell_rb).list.append(id);
        }
      }
    }
  }

  void addInteraction(boolean set) {
    if (set) {
      if (cell_set_filter) { // compare only the particles in cells
        if (active_cell >= 0 && active_cell < cells.size()) {
          Pariclecell cell = cells.get(active_cell);

          if (cell.list.size() > 0) {
            for (int i = 0; i < cell.list.size(); i++) {
              Particle part = particles.get(cell.list.get(i));

              dist = PVector.sub(part.pos, pos);
              float d = dist.mag();
              float s = d / (part_interaction_d_max - part_interaction_d_min); // if d = d_max -> s = 1, else s < 1
              float f = 1 / pow(s, 0.5);
              if (!part_set_interaction_distancerelated) f = 1;

              if (d < part_interaction_d_max && d > part_interaction_d_min) {
                if (part_set_interaction) {
                  force = dist.setMag(part_interaction_force * f);
                  velocity.add(force);

                  part.connected = true;
                  connected = false;
                }
                if (!connected) {
                  strokeWeight(1);
                  stroke(r, g, b, a);
                  line(pos.x, pos.y, part.pos.x, part.pos.y);
                }
              }

              if (d < part_extinction_d && part_set_extinction) {
                lifespan -= part_extinction_l;
              }
            }
          }
        }
      }
      if (!cell_set_filter) { // compare all particles
        for (int i = particles.size() - 1; i > 0; i--) {
          Particle part = particles.get(i);

          dist = PVector.sub(part.pos, pos);
          float d = dist.mag();

          if (d < part_extinction_d && part_set_extinction) {
            lifespan -= part_extinction_l;
          }

          if (d < part_interaction_d_max && d > part_interaction_d_min) {
            if (part_set_interaction) {
              force = dist.setMag(part_interaction_force);
              velocity.add(force);
              part.connected = true;
              connected = false;
            }
            if (!connected) {
              strokeWeight(1);
              stroke(r, g, b, a);
              line(pos.x, pos.y, part.pos.x, part.pos.y);
            }
          }
        }
      }
    }
  }

  void addPull(boolean set) {
    if (set) pull = velocity.mult(-1);
  }

  void addNoise(boolean set) {
    if (set) {
      pos.x += random(-0.1, 0.1);
      pos.y += random(-0.1, 0.1);
    }
  }

  void clear(boolean set) {
    if (set) lifespan = 0;
  }

  void colorize(boolean set) {
    if (set) {
      lifespan_range = int(map(lifespan, 0, lifespan_start, 255, 0));

      if (lifespan_range < part_saturation_min || lifespan_range > part_saturation_max) {
        saturation = part_saturation_min_limit;
      } else saturation = int(map(lifespan_range, part_saturation_min, part_saturation_max, part_saturation_min_limit, part_saturation_max_limit));

      a = saturation;
      r = (argb >> 16) & 0xFF;
      g = (argb >> 8) & 0xFF;
      b = argb & 0xFF;
    }
  }

  void display(boolean set) {
    if (set) {
      noStroke();
      fill(r, g, b, a);
      rectMode(CENTER);
      rect(pos.x, pos.y, part_size, part_size);
    }
  }
}
