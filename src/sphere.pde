/*  SPHERE --------------------------------------------------------------------------------------------------------
    Created 2018 by David Herren.                                                                                 /
    https://davidherren.ch                                                                                        /
    https://github.com/herdav/sphere                                                                              /
    Licensed under the MIT License.                                                                               /
    Built for 4K display.                                                                                         /
    ---------------------------------------------------------------------------------------------------------------
*/

/*  SHORT-KEYS ----------------------------------------------------------------------------------------------------
    [q, w] ........ gui hide/show                                                                                 /
    [s] ........... save screen as pdf                                                                            /
    [p] ........... save current setting as preset                                                                /
    [o] ........... update current preset                                                                         /
    mouse-left .... set target                                                                                    /
    mouse-right ... clear all targets                                                                             /
    [1 - 9] ....... select target                                                                                 /
    [r + ARROWS] .. move current target                                                                           /
    [t, u] ........ sub/add strength to the current target                                                        /
    [z] ........... reverse polarity of the current target                                                        /
    ---------------------------------------------------------------------------------------------------------------
*/

import controlP5.*;
import processing.pdf.*;
import processing.serial.*;

// SERIAL COMMUNICATION -------------------------------------------------------------------------------------------
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

// POINTER --------------------------------------------------------------------------------------------------------
Pointer pointer_yaw, pointer_x_axis, pointer_y_axis, pointer_stp;
Pointer pointer_targets;
boolean pointer_control = false;

// TARGETS --------------------------------------------------------------------------------------------------------
Target targt;
ArrayList < Target > targets;
boolean targt_removed = false;
boolean targt_pointer = false;
boolean targt_mouse = true;
boolean targt_set_polarisation = true;
boolean targt_0_pol, targt_1_pol, targt_2_pol;
float targt_0_x, targt_1_x, targt_2_x;
float targt_0_y, targt_1_y, targt_2_y;
float targt_0_strgth = 1, targt_1_strgth, targt_2_strgth;
float targt_strgth_min = 0.1, targt_strgth_max = 10;
float targt_set_strength = 1;
float targt_get_strength;

// VECTORFIELD ----------------------------------------------------------------------------------------------------
Vectorfield vctr;
ArrayList < Vectorfield > vectors;
PVector vctr_segment_pos = new PVector();
float vctr_segment_d, vctr_segment_r, vctr_dist_max;
float vctr_segment_delay = 0.03;
float vctr_dist_factor = 1;
int vctr_segment_nx = 200, vctr_segment_ny;
int vctr_segment_n, vctr_segment_n_max = 400;

// CLUSTER --------------------------------------------------------------------------------------------------------
Cluster cell;
ArrayList < Cluster > cells;
PVector cell_segment_pos = new PVector();
float cell_segment_d, cell_segment_r, cell_segment_i;
float cell_limitter_factor = 1;
int cell_segment_nx = 20, cell_segment_ny;
int cell_segment_n, cell_segment_n_max = 200;
int cell_max_entries = 100;
int cell_calculationload_max, cell_calculationload_eff;
float cell_calculationload;
boolean cell_segment_display = false;

// PARTICLES ------------------------------------------------------------------------------------------------------
Particle part;
ArrayList < Particle > particles;
int part_size = 1;
int part_streams = 10;
int part_streams_max_1 = 200;
int part_streams_max_2 = 100;
int part_saturation_min = 0;
int part_saturation_max = 255;
int part_saturation_min_limit = 0;
int part_saturation_max_limit = 255;
int part_lines_count = 0;
int part_lines_weight = 1;
int part_lines_max = 10;
int part_streams_max = 200;
float part_lifespan = 80;
float part_lifespan_max = 400;
float part_interaction_d_min = 0;
float part_interaction_d_max = 60;
float part_interaction_border = 0;
float part_interaction_force = 0;
float part_interaction_draw_d_min = 0;
float part_interaction_draw_d_max = 60;
float part_speed = 14;
float part_acceleration_factor = 0;
boolean part_birth_circle_rot = false;
boolean part_clear = false;
boolean part_interaction = false;
boolean part_interaction_draw = false;
boolean part_set_interaction = false;
boolean part_set_interaction_draw = true;
boolean part_set_limitter = false;
boolean part_set_acceleration = false;
boolean part_birth_field = true;
boolean part_set = true;
PVector part_birth_field_pos = new PVector();

// GUI & CONTROLS -------------------------------------------------------------------------------------------------
ControlP5 cp5;
color color_a, color_b, color_c, color_d;
boolean controls_show = true;
boolean record_pdf = false;
boolean background_display = false;
boolean targt_display = false;
boolean load_preset_0, load_preset_1, load_preset_2, load_preset_3;
boolean move_target = false, move_particles = false;
int load_preset_last = 0;
int background_color = 0;
int theme = 0;
int field_height = 2000;
int field_width = field_height;
int field_border_left, field_border_top, field_border_bot;
int textSize = 21;
PVector field_center = new PVector();

void setup() {
  //size(3800, 2000, P2D);
  fullScreen(P2D);
  blendMode(ADD);
  noSmooth();

  String[] ports = Serial.list();
  if (ports.length <= 1) println("No ports found!");
  if (ports.length > 1) {
    stream_port_name = Serial.list()[1];
    stream_port = new Serial(this, stream_port_name, 9600);
    stream_port.bufferUntil('\n');
    stream_port_on = true;
    println("Device is connected to " + stream_port_name + '.');
  }

  fieldsize();

  int pointer_x = 1300;
  int pointer_d = 320;
  pointer_x_axis = new Pointer(pointer_x, 250, pointer_d);
  pointer_y_axis = new Pointer(pointer_x, 650, pointer_d);
  pointer_yaw = new Pointer(pointer_x, 1050, pointer_d);
  pointer_stp = new Pointer(pointer_x, 1050, pointer_d);

  pointer_targets = new Pointer(field_center.x, field_center.y, field_height / 1.5);
  vectors = new ArrayList < Vectorfield > ();
  cells = new ArrayList < Cluster > ();
  particles = new ArrayList < Particle > ();
  targets = new ArrayList < Target > ();
  targets.add(new Target(field_center.x, field_center.y, targt_set_polarisation, targt_set_strength));

  gui();
}

void draw() {
  background(0);
  control();
  record();
  targets();
  field();
  cluster();
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

    if (stream_data_angle_u >= 0 && stream_data_angle_u < PI / 2) {
      stream_data_angle_rot = stream_data_angle_u;
    }
    if (stream_data_angle_u >= PI / 2 && stream_data_angle_u < PI) {
      stream_data_angle_rot = PI - stream_data_angle_u;
    }
    if (stream_data_angle_u >= PI && stream_data_angle_u < 2 / 3 * PI) {
      stream_data_angle_rot = stream_data_angle_u - PI;
    }
    if (stream_data_angle_u >= 2 / 3 * PI && stream_data_angle_u < 2 * PI) {
      stream_data_angle_rot = 2 * PI - stream_data_angle_u;
    }

    stream_data_angle_stp = 2 * PI / 600 * stream_data_stp_cnt;

    if (stream_data_serial_print) {
      println("x:" + int(stream_data_angle_x * 180 / PI), "y:" + int(stream_data_angle_y * 180 / PI),
        "u:" + int(stream_data_angle_u * 180 / PI), "m:" + int(100 * stream_data_magni_u),
        "stp:" + int(stream_data_stp_yaw), "cnt:" + int(stream_data_stp_cnt),
        "speed:" + int(stream_data_rpm), "poti:" + int(stream_data_poti));
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
}

void gui() {
  int cp5_w = 620, cp5_h = 30;
  int cp5_s1 = 2, cp5_s2 = 10;
  int cp5_l0 = 80, cp5_l1 = cp5_l0 + cp5_s1, cp5_l2;
  int cp5_x, cp5_y, cp5_hs = cp5_h + cp5_s1, cp5_n;

  cp5 = new ControlP5(this);

  PFont p = createFont("", textSize);
  ControlFont font = new ControlFont(p);
  cp5.setFont(font);

  cp5.setColorBackground(color(50))
    .setColorForeground(color(100))
    .setColorActive(color(150));

  cp5_n = 3;
  cp5_l2 = (cp5_w - 1 * cp5_s1) / 2;
  Group cp5_system = cp5.addGroup("SYSTEM").setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s1).setBarHeight(cp5_h); {

    cp5_system.getCaptionLabel().align(CENTER, CENTER);

    cp5.addToggle("pointer_control").setPosition(0, cp5_y = cp5_s1)
      .setSize(cp5_l2, cp5_h).setGroup(cp5_system).setCaptionLabel("DEVICE CONTROL DISPLAY")
      .getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("targt_pointer").setPosition(0, cp5_y += cp5_hs)
      .setSize(cp5_l2, cp5_h).setGroup(cp5_system).setCaptionLabel("SET DEVICE AS TARGET")
      .getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("stream_data_serial_print").setPosition(0, cp5_y += cp5_hs)
      .setSize(cp5_l2, cp5_h).setCaptionLabel("SERIAL PRINT DEVICE DATA").setGroup(cp5_system)
      .getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("targt_display").setPosition(cp5_w - cp5_l2, cp5_y = cp5_s1)
      .setSize(cp5_l2, cp5_h).setValue(true).setCaptionLabel("TARGETS DISPLAY").setGroup(cp5_system)
      .getCaptionLabel().align(CENTER, CENTER);
    cp5.addToggle("part_clear").setPosition(cp5_w - cp5_l2, cp5_y += cp5_hs).setSize(cp5_l2, cp5_h)
      .setCaptionLabel("PARTICLES CLEAR").setGroup(cp5_system)
      .getCaptionLabel().align(CENTER, CENTER);
  }

  cp5_n = 1;
  cp5_l2 = (cp5_w - 3 * cp5_s1) / 4;
  Group cp5_presets = cp5.addGroup("PRESETS").setBackgroundColor(50)
    .setBarHeight(cp5_h).setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s1); {

    cp5_presets.getCaptionLabel().align(CENTER, CENTER);

    cp5.addBang("load_preset_0").setPosition(cp5_x = 0, cp5_y = cp5_s1).setSize(cp5_l2, cp5_h)
      .setGroup(cp5_presets).setCaptionLabel("DEFAULT").getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_1").setPosition(cp5_x += cp5_l2 + cp5_s1, cp5_y).setSize(cp5_l2, cp5_h)
      .setGroup(cp5_presets).setCaptionLabel("PRESET 1").getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_2").setPosition(cp5_x += cp5_l2 + cp5_s1, cp5_y).setSize(cp5_l2, cp5_h)
      .setGroup(cp5_presets).setCaptionLabel("PRESET 2").getCaptionLabel().align(CENTER, CENTER);
    cp5.addBang("load_preset_3").setPosition(cp5_x += cp5_l2 + cp5_s1, cp5_y).setSize(cp5_l2 + 2, cp5_h)
      .setGroup(cp5_presets).setCaptionLabel("PRESET 3").getCaptionLabel().align(CENTER, CENTER);
  }

  cp5_n = 3;
  cp5_l2 = (cp5_w - 3 * cp5_s1 - cp5_l0) / 3;
  Group cp5_targets = cp5.addGroup("TARGETS").setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s1).setBarHeight(cp5_h); {

    cp5_targets.getCaptionLabel().align(CENTER, CENTER);

    cp5.addToggle("targt_0_pol").setValue(true).setMode(ControlP5.SWITCH).setColorActive(color(100))
      .setPosition(0, cp5_y = cp5_s1).setSize(cp5_l0, cp5_h).setCaptionLabel("").setGroup(cp5_targets)
      .getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("targt_0_strgth", targt_strgth_min, targt_strgth_max, cp5_l1, cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("").setGroup(cp5_targets);
    cp5.addSlider("targt_0_x", 0, field_width, cp5_l1 + cp5_l2 + cp5_s1, cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("").setGroup(cp5_targets);
    cp5.addSlider("targt_0_y", 0, field_height, cp5_l1 + 2 * (cp5_l2 + cp5_s1), cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("targt_0").setGroup(cp5_targets);

    cp5.addToggle("targt_1_pol").setValue(true).setMode(ControlP5.SWITCH).setColorActive(color(100))
      .setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h).setCaptionLabel("").setGroup(cp5_targets)
      .getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("targt_1_strgth", targt_strgth_min, targt_strgth_max, cp5_l1, cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("").setGroup(cp5_targets);
    cp5.addSlider("targt_1_x", 0, field_width, cp5_l1 + cp5_l2 + cp5_s1, cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("").setGroup(cp5_targets);
    cp5.addSlider("targt_1_y", 0, field_height, cp5_l1 + 2 * (cp5_l2 + cp5_s1), cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("targt_1").setGroup(cp5_targets);

    cp5.addToggle("targt_2_pol").setValue(true).setMode(ControlP5.SWITCH).setColorActive(color(100))
      .setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h).setCaptionLabel("").setGroup(cp5_targets)
      .getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("targt_2_strgth", targt_strgth_min, targt_strgth_max, cp5_l1, cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("").setGroup(cp5_targets);
    cp5.addSlider("targt_2_x", 0, field_width, cp5_l1 + cp5_l2 + cp5_s1, cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("").setGroup(cp5_targets);
    cp5.addSlider("targt_2_y", 0, field_height, cp5_l1 + 2 * (cp5_l2 + cp5_s1), cp5_y, cp5_l2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("targt_2").setGroup(cp5_targets);
  }

  cp5_n = 4;
  Group cp5_vectorfield = cp5.addGroup("VECTORFIELD").setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s1).setBarHeight(cp5_h); {

    cp5.addButtonBar("theme").setGroup(cp5_vectorfield).setPosition(0, cp5_y = cp5_s1)
      .setSize(cp5_w, cp5_h).addItems(split("PS VS LD HM FL", " "))
      .onMove(new CallbackListener() {
        public void controlEvent(CallbackEvent ev) {
          ButtonBar theme = (ButtonBar) ev.getController();
        }
      });

    cp5_vectorfield.getCaptionLabel().align(CENTER, CENTER);

    cp5.addSlider("vctr_segment_nx", 5, vctr_segment_n_max, 0, cp5_y += cp5_hs, cp5_w, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_vectorfield);
    cp5.addSlider("vctr_segment_delay", 0.01, 0.2, 0, cp5_y += cp5_hs, cp5_w, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_vectorfield);
    cp5.addSlider("vctr_dist_factor", 0, 10, 0, cp5_y += cp5_hs, cp5_w, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_vectorfield);
  }

  cp5_n = 8;
  cp5_l2 = (cp5_w - cp5_s1 - cp5_l0) / 2;
  Group cp5_particles = cp5.addGroup("PARTICLES").setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s1).setBarHeight(cp5_h); {

    cp5_particles.getCaptionLabel().align(CENTER, CENTER);

    cp5.addToggle("part_birth_field").setPosition(0, cp5_y = cp5_s1).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("set").setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("", 0, width, cp5_l1, cp5_y, cp5_w - cp5_l1, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("part_birth_field").setGroup(cp5_particles);

    cp5.addToggle("part_set").setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h).setCaptionLabel("set")
      .setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_size", 1, 20, cp5_l1, cp5_y, cp5_w - cp5_l1, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);

    cp5.addSlider("part_streams", 1, part_streams_max_1, 0, cp5_y += cp5_hs, cp5_w, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addSlider("part_lifespan", 1, part_lifespan_max, 0, cp5_y += cp5_hs, cp5_w, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);
    cp5.addSlider("part_speed", -2, 40, 0, cp5_y += cp5_hs, cp5_w, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);

    cp5.addToggle("part_set_acceleration").setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("SET").setGroup(cp5_particles).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_acceleration_factor", -2, 2, cp5_l1, cp5_y, cp5_w - cp5_l1, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_particles);

    cp5.addRange("part_saturation_scope").setGroup(cp5_particles).setBroadcast(false)
      .setPosition(0, cp5_y += cp5_hs).setSize(cp5_w, cp5_h).setHandleSize(cp5_s2)
      .setRange(0, 255).setRangeValues(part_saturation_min, part_saturation_max).setBroadcast(true);

    cp5.addRange("part_saturation_limit").setGroup(cp5_particles).setBroadcast(false)
      .setPosition(0, cp5_y += cp5_hs).setSize(cp5_w, cp5_h).setHandleSize(cp5_s2)
      .setRange(0, 255).setRangeValues(part_saturation_min, part_saturation_max).setBroadcast(true);
  }

  cp5_n = 7;
  cp5_l2 = (cp5_w - cp5_s1 - cp5_l0) / 2;
  Group cp5_part_interaction = cp5.addGroup("PARTICLES INTERACTION").setBackgroundColor(50)
    .setBackgroundHeight(cp5_n * cp5_h + (cp5_n + 1) * cp5_s1).setBarHeight(cp5_h); {

    cp5_part_interaction.getCaptionLabel().align(CENTER, CENTER);
    cp5_vectorfield.getCaptionLabel().align(CENTER, CENTER);

    cp5.addSlider("cell_segment_nx", 1, cell_segment_n_max, 0, cp5_y = cp5_s1, cp5_w, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);

    cp5.addToggle("cell_segment_display").setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("SHOW").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("cell_max_entries", 2, 200, cp5_l1, cp5_y, cp5_w - cp5_l1, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);

    cp5.addToggle("part_set_limitter").setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("cell_limitter_factor", 0, 100, cp5_l1, cp5_y, cp5_w - cp5_l1, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);

    cp5.addToggle("part_interaction").setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addRange("part_interaction_scope").setGroup(cp5_part_interaction).setBroadcast(false)
      .setPosition(cp5_l1, cp5_y).setSize(cp5_l2, cp5_h).setHandleSize(cp5_s2).setCaptionLabel("")
      .setRange(0, 200).setRangeValues(part_interaction_d_min, part_interaction_d_max).setBroadcast(true);
    cp5.addSlider("part_interaction_border", 0, 100, cp5_l1 + cp5_l2 + cp5_s1, cp5_y, cp5_l2 - 2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setCaptionLabel("part_interaction_scope")
      .setGroup(cp5_part_interaction);

    cp5.addToggle("part_set_interaction_draw").setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addRange("part_interaction_draw").setGroup(cp5_part_interaction).setBroadcast(false)
      .setPosition(cp5_l1, cp5_y).setSize(cp5_l2, cp5_h).setHandleSize(cp5_s2)
      .setRange(0, 200).setCaptionLabel("").setRangeValues(part_interaction_draw_d_min, part_interaction_draw_d_max)
      .setBroadcast(true);
    cp5.addSlider("part_lines_max", 1, 50, cp5_l1 + cp5_l2 + cp5_s1, cp5_y, cp5_l2 - 2, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction).setCaptionLabel("part_interaction_draw");

    cp5.addToggle("part_set_interaction").setPosition(0, cp5_y += cp5_hs).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("SET").setGroup(cp5_part_interaction).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("part_interaction_force", -10, 10, cp5_l1, cp5_y, cp5_w - cp5_l1, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_part_interaction);
  }

  cp5_l2 = (cp5_w - 20) / 3;
  Group cp5_color = cp5.addGroup("PARTICLES COLOR").setBackgroundColor(50).setBarHeight(cp5_h)
    .setBackgroundHeight(cp5_l2 + 50); {

    cp5_color.getCaptionLabel().align(CENTER, CENTER);

    cp5.addColorWheel("color_a", 0, 10, cp5_l2).setRGB(color(255, 0, 0))
      .setCaptionLabel("LEFT").setGroup(cp5_color);
    cp5.addColorWheel("color_b", cp5_l2 + 10, 10, cp5_l2).setRGB(color(0, 255, 0))
      .setCaptionLabel("RIGHT").setGroup(cp5_color);
    cp5.addColorWheel("color_c", cp5_y = 2 * cp5_l2 + 20, 10, cp5_l2).setRGB(color(0, 0, 255))
      .setCaptionLabel("TOP").setGroup(cp5_color);

    cp5.addToggle("background_display").setPosition(0, cp5_l2 = cp5_l2 + 50).setSize(cp5_l0, cp5_h)
      .setCaptionLabel("set").setGroup(cp5_color).getCaptionLabel().align(CENTER, CENTER);
    cp5.addSlider("background_color", 0, 255, cp5_l1, cp5_l2, cp5_w - cp5_l1, cp5_h)
      .setSliderMode(Slider.FLEXIBLE).setGroup(cp5_color);
  }

  cp5_x = 20;
  cp5_y = 20;
  cp5.addAccordion("acc").setPosition(cp5_x, cp5_y).setWidth(cp5_w)
    .setCollapseMode(Accordion.MULTI).setMinItemHeight(0)
    .addItem(cp5_system)
    .addItem(cp5_presets)
    .addItem(cp5_targets)
    .addItem(cp5_vectorfield)
    .addItem(cp5_particles)
    .addItem(cp5_part_interaction)
    .addItem(cp5_color)
    .open();
}

void controlEvent(ControlEvent ce) {
  if (ce.isFrom("part_saturation_scope")) {
    part_saturation_min = int(ce.getController().getArrayValue(0));
    part_saturation_max = int(ce.getController().getArrayValue(1));
  }
  if (ce.isFrom("part_saturation_limit")) {
    part_saturation_min_limit = int(ce.getController().getArrayValue(0));
    part_saturation_max_limit = int(ce.getController().getArrayValue(1));
  }
  if (ce.isFrom("part_interaction_scope")) {
    part_interaction_d_min = int(ce.getController().getArrayValue(0));
    part_interaction_d_max = int(ce.getController().getArrayValue(1));
  }
  if (ce.isFrom("part_interaction_draw")) {
    part_interaction_draw_d_min = int(ce.getController().getArrayValue(0));
    part_interaction_draw_d_max = int(ce.getController().getArrayValue(1));
  }
}

void control() {
  // hide gui
  if (keyPressed && key == 'q') {
    controls_show = false;
    cp5.hide();
  }

  // show gui
  if (keyPressed && key == 'w' || !controls_show && mouseX < 100) {
    controls_show = true;
    cp5.show();
  }

  // visibility cursor
  if (mouseX >= field_border_left && mouseY >= field_border_top && mouseY <= height - field_border_bot) {
    noCursor();
  } else cursor();

  // save and load presets
  if (keyPressed) {
    if (key == 'p') cp5.saveProperties(("\\presets\\preset.json"));
    if (key == 'o') cp5.saveProperties(("\\presets\\preset_" + str(load_preset_last) + ".json"));
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
    // set new target
    if (mouseButton == LEFT && mouseX > field_border_left) {
      targets.add(new Target(mouseX, mouseY, targt_set_polarisation, targt_set_strength));
    }
    // delete all targets
    if (mouseButton == RIGHT && targets.size() > 1 && mouseX > field_border_left) {
      for (int i = targets.size() - 1; i > 0; i--) targets.remove(i);
    }
  }
}

void targets() {
  // set reverse polarity of the current target 
  if (keyPressed && key == 'z') {
    targt_set_polarisation = false;
  } else targt_set_polarisation = true;

  // add strength to the current target
  if (keyPressed && key == 'u' && targt_set_strength <= targt_strgth_max) {
    targt_set_strength += 0.1;
  }

  // sub strength from the current target
  if (keyPressed && key == 't' && targt_set_strength >= targt_strgth_min) {
    targt_set_strength -= 0.1;
  }

  // interlocking mouse<>device
  if (targt_pointer) {
    targt_mouse = false;
  } else targt_mouse = true;

  // last target set
  int n = targets.size() - 1;
  Target targt = targets.get(n);

  // if target controlled by mouse
  if (targt_mouse) {
    // if mouse on the field
    if (mouseX >= field_border_left && mouseY >= field_border_top && mouseY <= height - field_border_bot) {
      if (targt_removed) {
        targt.update(mouseX, mouseY);
        targt.polarisation(targt_set_polarisation);
        targt.strength(targt_set_strength);
        for (int i = 0; i < targets.size(); i++) targets.get(i).select(false);
        targt_removed = false;
      } else {
        targt.update(mouseX, mouseY);
        targt.polarisation(targt_set_polarisation);
        targt.strength(targt_set_strength);
      }
      for (int i = 0; i < targets.size(); i++) {
        targt = targets.get(i);

        // update pos of the first three targets in the gui
        if (i < 3) {
          cp5.getController("targt_" + i + "_pol").setValue(int(targt.pol));
          cp5.getController("targt_" + i + "_x").setValue(targt.pos.x - field_border_left);
          cp5.getController("targt_" + i + "_y").setValue(targt.pos.y - field_border_top);
          cp5.getController("targt_" + i + "_strgth").setValue(targt.strgth);
        }
      }
    }

    // if mouse leaves the field
    if (mouseX < field_border_left || mouseY < field_border_top || mouseY > height - field_border_bot) {
      targt_set_strength = 1;

      for (int i = 0; i < targets.size(); i++) {
        targt = targets.get(i);

        // update pos of the first three targets from the gui
        if (i < 3) {
          if (i == 0) {
            if (targt_0_pol != targt.pol) {
              targt.polarisation(targt_0_pol);
            }
            if (targt_0_x != targt.pos.x - field_border_left || targt_0_y != targt.pos.y - field_border_top) {
              targt.update(targt_0_x + field_border_left, targt_0_y + field_border_top);
            }
            if (targt_0_strgth != targt.strgth) {
              targt.strength(targt_0_strgth);
            }
          }
          if (i == 1) {
            if (targt_1_pol != targt.pol) {
              targt.polarisation(targt_1_pol);
            }
            if (targt_1_x != targt.pos.x - field_border_left || targt_1_y != targt.pos.y - field_border_top) {
              targt.update(targt_1_x + field_border_left, targt_1_y + field_border_top);
            }
            if (targt_1_strgth != targt.strgth) {
              targt.strength(targt_1_strgth);
            }
          }
          if (i == 2) {
            if (targt_2_pol != targt.pol) {
              targt.polarisation(targt_2_pol);
            }
            if (targt_2_x != targt.pos.x - field_border_left || targt_2_y != targt.pos.y - field_border_top) {
              targt.update(targt_2_x + field_border_left, targt_2_y + field_border_top);
            }
            if (targt_2_strgth != targt.strgth) {
              targt.strength(targt_2_strgth);
            }
          }
        }
      }

      if (targets.size() == 1 && targt.pos.x < field_border_left + 100) {
        targt.update(field_center.x, field_center.y);

        // update gui
        cp5.getController("targt_0_x").setValue(targt.pos.x - field_border_left);
        cp5.getController("targt_0_y").setValue(targt.pos.y - field_border_top);
        cp5.getController("targt_0_strgth").setValue(targt.strgth);
      }
      if (targets.size() > 1 && !targt_removed) {
        targets.remove(n);
        targt_removed = true;
      }
    }
  }

  // if target contolled by device
  if (targt_pointer && stream_port_on) {
    pointer_targets.calculation(stream_data_angle_rot, stream_data_magni_u);
    targt.update(pointer_targets.magnitude.x, pointer_targets.magnitude.y);
  }

  targt_get_strength = 0; // reset strengths
  for (int i = 0; i < targets.size(); i++) {
    targt = targets.get(i);
    targt.display(targt_display);

    // add all strengths
    targt_get_strength += targt.strgth;

    if (keyPressed) {
      // select target
      if (key >= 49) {
        if (key == i + 49) {
          targt.select(true);
        } else if (key >= 49 && key <= 49 + targets.size()) {
          targt.select(false);
        }
      }

      // change selected target
      if (targets.get(i).sel) {
        if (key == 'u' && targets.get(i).strgth <= targt_strgth_max) {
          targt.strgth += 0.1;
          if (i < 3) cp5.getController("targt_" + i + "_strgth").setValue(targt.strgth);
        }
        if (key == 't' && targets.get(i).strgth >= targt_strgth_min) {
          targt.strgth -= 0.1;
          if (i < 3) cp5.getController("targt_" + i + "_strgth").setValue(targt.strgth);
        }
        if (key == 'z') {
          if (targets.get(i).pol == false) {
            targt.pol = true;
            if (i < 3) cp5.getController("targt_" + i + "_pol").setValue(int(targt.pol));
          } else if (targets.get(i).pol == true) {
            targt.pol = false;
            if (i < 3) cp5.getController("targt_" + i + "_pol").setValue(int(targt.pol));
          }
        }

        // move target
        if (key == 'r') move_target = true;
        if (move_target) {
          move_particles = false;
          if (keyCode == UP) {
            targt.pos.y -= 1;
            if (i < 3) cp5.getController("targt_" + i + "_y").setValue(targt.pos.y - field_border_top);
          }
          if (keyCode == DOWN) {
            targt.pos.y += 1;
            if (i < 3) cp5.getController("targt_" + i + "_y").setValue(targt.pos.y - field_border_top);
          }
          if (keyCode == LEFT) {
            targt.pos.x -= 1;
            if (i < 3) cp5.getController("targt_" + i + "_x").setValue(targt.pos.x - field_border_left);
          }
          if (keyCode == RIGHT) {
            targt.pos.x += 1;
            if (i < 3) cp5.getController("targt_" + i + "_x").setValue(targt.pos.x - field_border_left);
          }
        }
      }
    }
  }

  // mean value of all strengths for calculation in vectorfield
  targt_get_strength /= targets.size();
}

float decimalPlaces(float x, float d) {
  float r = float(int(x / d * 10)) / 10;
  return r;
}

void particles() {
  // set birth of particles as field
  if (part_birth_field) {
    int part_streams_field = int(sqrt(part_streams));
    float part_streams_field_d = field_width / (part_streams_field + 1);
    for (int i = 1; i <= part_streams_field; i++) {
      for (int j = 1; j <= part_streams_field; j++) {
        part_birth_field_pos.x = field_border_left + j * part_streams_field_d;
        part_birth_field_pos.y = field_border_top + i * part_streams_field_d;

        if (i > 0 && i < (part_streams_field + 1) / 3) {
          particles.add(new Particle(part_birth_field_pos.x, part_birth_field_pos.y, part_lifespan, color_a));
        }
        if (i >= part_streams_field / 3 && i < (part_streams_field + 1) / 3 * 2) {
          particles.add(new Particle(part_birth_field_pos.x, part_birth_field_pos.y, part_lifespan, color_b));
        }
        if (i >= part_streams_field / 3 * 2 && i < (part_streams_field + 1)) {
          particles.add(new Particle(part_birth_field_pos.x, part_birth_field_pos.y, part_lifespan, color_c));
        }
      }
    }
  }

  // reset particle interaction lines count
  part_lines_count = 0;

  // call particle class
  for (int i = 0; i < particles.size(); i++) {
    Particle part = particles.get(i);
    part.clear(part_clear);
    part.lifespan();
    part.getVector();
    part.getCell(i);
    part.addInteraction(part_interaction);
    part.addAcceleration();
    part.update();
    part.colorize(true);
    part.display(part_set);
  }

  // calculate particle interactions
  cell_calculationload_max = int(sq(particles.size()));
  cell_calculationload = 100 * float(cell_calculationload_eff) / float(cell_calculationload_max);

  // delete passed particles
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle part = particles.get(i);
    if (part.lifespan <= 0) particles.remove(i);
  }

  if (part_interaction) {
    cp5.getController("part_streams").setMax(part_streams_max_2);
  } else cp5.getController("part_streams").setMax(part_streams_max_1);
}

void cluster() {
  cell_segment_ny = cell_segment_nx;
  cell_segment_n = cell_segment_nx * cell_segment_ny;

  if (cell_segment_n != cells.size()) {
    for (int i = particles.size() - 1; i >= 0; i--) particles.remove(i);
    for (int i = cells.size() - 1; i >= 0; i--) cells.remove(i);

    if (field_height % cell_segment_ny > 0) {
      cell_segment_nx++;
    }

    cell_segment_d = field_height / cell_segment_nx;
    cell_segment_r = cell_segment_d / 2;
    cell_segment_i = 2 * cell_segment_d;

    // update gui
    cp5.getController("cell_segment_nx").setValue(cell_segment_nx);
    cp5.getController("part_interaction_scope").setMax(cell_segment_i);
    cp5.getController("part_interaction_draw").setMax(cell_segment_i);

    for (int i = 0; i < cell_segment_ny; i++) {
      for (int j = 0; j < cell_segment_nx; j++) {
        cell_segment_pos.x = field_border_left + j * cell_segment_d + cell_segment_r;
        cell_segment_pos.y = field_border_top + i * cell_segment_d + cell_segment_r;
        cells.add(new Cluster(cell_segment_pos));
      }
    }
  }

  // calculate cell load
  cell_calculationload_eff = 0;
  for (int i = 0; i < cells.size(); i++) {
    Cluster cell = cells.get(i);
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

    if (field_height % vctr_segment_ny > 0) {
      vctr_segment_nx++;

      // update gui
      cp5.getController("vctr_segment_nx").setValue(vctr_segment_nx);
    }

    vctr_segment_d = field_height / vctr_segment_nx;
    vctr_segment_r = vctr_segment_d / 2;
    vctr_dist_max = sqrt(sq(field_width - vctr_segment_r) + sq(field_height - vctr_segment_r));

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
      vctr.target(targets.get(j).pos, targets.get(j).pol, targets.get(j).strgth);
      vctr.magnitude(vctr_segment_delay);
    }
    vctr.colorize(theme);
    vctr.grid(false, false);
  }
}

void data() {
  if (controls_show) {
    noStroke();
    fill(0);
    rectMode(CORNER);
    rect(0, 0, field_border_left, height);
    textSize(textSize);
    fill(255);
    textAlign(LEFT, BOTTOM);
    text("FPS\n" + "VECTORS\n" + "PARTICLES\n" + "CLUSTERCELLS\n" + "INTERACTION\n" + "LINES\n" + "DISTANCE\n" +
      "TARGETS\n" + "PRESET\n" + "DEVICE\n\n" + year() + '/' + month() + '/' + day() + "\n\n" +
      "David Herren", 20, height - 20);

    text(int(frameRate) + "\n" +
      vectors.size() + "\n" +
      decimalPlaces(particles.size(), 1000) + "k\n" +
      cells.size() + "\n" +
      decimalPlaces(cell_calculationload_eff, 1000000) + "M (" +
      decimalPlaces(cell_calculationload, 1) + "%) of " +
      decimalPlaces(cell_calculationload_max, 1000000) + "M\n" +
      decimalPlaces(part_lines_count, 1000) + "k\n" +
      "P" + int(part_interaction_d_max) + " / C" + int(cell_segment_i) + "\n" +
      targets.size() + "\n" +
      load_preset_last + " is loaded\n" +
      stream_port_name + "\n\n" +
      hour() + ':' + minute() + ':' + second() + "\n\nsphere.pde", 200, height - 20);
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
        line(orgin.x + r * cos(s), orgin.y + r * sin(s), orgin.x + (r - 10) * cos(s),
          orgin.y + (r - 10) * sin(s));
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
      for (int i = 0; i < graph_store.length; i++) line(orgin.x - r + i, orgin.y + d / 1.5,
        orgin.x - r + i, orgin.y + d / 1.5 - graph_store[i]);
    }
  }

  void title(String t) {
    textSize(textSize);
    fill(255);
    textAlign(CENTER, CENTER);
    text(t + ": " + float(int(10 * a * 180 / PI)) / 10 + '°', orgin.x, orgin.y + r + r / 5);
  }
}

class Target {
  PVector pos = new PVector();
  boolean pol, sel;
  float strgth;

  color red = color(255, 0, 0);
  color blue = color(0, 0, 255);

  Target(float x, float y, boolean pol, float strgth) {
    pos.x = x;
    pos.y = y;

    this.pol = pol;
    this.strgth = strgth;
  }

  void polarisation(boolean pol) {
    this.pol = pol;
  }

  void select(boolean sel) {
    this.sel = sel;
  }

  void strength(float strgth) {
    this.strgth = strgth;
  }

  void update(float x, float y) {
    pos.x = x;
    pos.y = y;
  }

  void display(boolean set) {
    if (set) {
      if (pol) {
        stroke(255, 0, 0);
      } else stroke(0, 0, 255);

      if (sel) {
        fill(255, 127);
      } else noFill();

      strokeWeight(2);
      float d = 15 * strgth;
      ellipse(pos.x, pos.y, d, d);
    }
  }
}

class Vectorfield {
  PVector orgin = new PVector();
  PVector direct = new PVector();
  PVector result = new PVector();
  PVector force = new PVector();

  color c = color(90);

  float magnitude;

  Vectorfield(PVector orgin) {
    this.orgin.x = orgin.x;
    this.orgin.y = orgin.y;
  }

  float strength(float d, float d_max, float n) {
    float s = d / d_max;
    float f = 1 - pow(s, n);
    return f;
  }

  void target(PVector target, boolean polarisation, float factor) {
    float dist = orgin.dist(target);
    float f = strength(dist, vctr_dist_max, 0.5);

    direct = PVector.sub(target, orgin);
    direct.setMag(f * vctr_segment_r * vctr_dist_factor * factor);
    if (!polarisation) direct.mult(-1);
    direct.add(orgin);
  }

  void magnitude(float delay) {
    PVector offset = new PVector();
    PVector.sub(direct, result, offset);
    magnitude = offset.mag();
    offset.mult(delay);
    result.add(offset);
    force = PVector.sub(result, orgin);
  }

  void grid(boolean ellipse, boolean rect) {
    noFill();
    stroke(c);
    strokeWeight(1);
    if (ellipse) ellipse(orgin.x, orgin.y, vctr_segment_d, vctr_segment_d);
    rectMode(CENTER);
    if (rect) rect(orgin.x, orgin.y, vctr_segment_d, vctr_segment_d);
  }

  void colorize(int input) {
    float scope;
    int n, r;

    magnitude /= vctr_dist_factor * targt_get_strength;

    strokeWeight(1);

    switch (input) {
      case 1: // vector field
        noFill();
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

class Cluster {
  IntList list;
  PVector orgin = new PVector();

  Cluster(PVector orgin) {
    this.orgin.x = orgin.x;
    this.orgin.y = orgin.y;

    list = new IntList();
  }

  void reset() {
    list.clear();
  }

  void display(boolean set) {
    if (set) {
      fill(map(list.size(), 0, cell_max_entries, 0, 255));
      noStroke();
      rectMode(CENTER);
      rect(orgin.x, orgin.y, cell_segment_d, cell_segment_d);
    }
  }
}

class Particle {
  PVector pos = new PVector();
  PVector pos_before = new PVector();
  PVector velocity = new PVector();

  float lifespan, lifespan_start;
  int id, active_cell;
  boolean connected = false;
  color argb;
  int a, r, g, b;

  Particle(float x, float y, float lifespan, color argb) {
    pos.x = x;
    pos.y = y;

    this.lifespan = lifespan;
    this.argb = argb;

    lifespan_start = lifespan;
    pos_before = pos.copy();
  }

  float strength(float d, float d_max, float n) {
    float s = d / d_max;
    float f = 1 - pow(s, n);
    return f;
  }

  void getVector() {
    // detect active vector
    int active_vector = int((pos.y - field_border_top) / vctr_segment_d) * vctr_segment_ny +
      int((pos.x - field_border_left) / vctr_segment_d);

    if (active_vector >= 0 && active_vector < vectors.size()) {
      Vectorfield vctr = vectors.get(active_vector);
      velocity.add(vctr.force);
    }
  }

  void getCell(int id) {
    this.id = id;

    int active_cell_x = int((pos.x - field_border_left) / cell_segment_d);
    int active_cell_y = int((pos.y - field_border_top) / cell_segment_d);

    // detect active cell
    active_cell = active_cell_y * cell_segment_ny + active_cell_x;

    if (active_cell >= 0 && active_cell < cells.size()) {
      Cluster cell = cells.get(active_cell);

      // set max entries in cell
      if (cell.list.size() < cell_max_entries) {
        cell.list.append(id);

        // define surrounding cells
        int active_cell_l = active_cell_y * cell_segment_ny + (active_cell_x - 1);
        int active_cell_r = active_cell_y * cell_segment_ny + (active_cell_x + 1);
        int active_cell_t = (active_cell_y - 1) * cell_segment_ny + active_cell_x;
        int active_cell_b = (active_cell_y + 1) * cell_segment_ny + active_cell_x;
        int active_cell_lt = (active_cell_y - 1) * cell_segment_ny + (active_cell_x - 1);
        int active_cell_rt = (active_cell_y - 1) * cell_segment_ny + (active_cell_x + 1);
        int active_cell_lb = (active_cell_y + 1) * cell_segment_ny + (active_cell_x - 1);
        int active_cell_rb = (active_cell_y + 1) * cell_segment_ny + (active_cell_x + 1);

        if (active_cell_x > 0 && active_cell_x <= cell_segment_nx - 1 &&
          active_cell_y >= 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_l).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x < cell_segment_nx - 1 &&
          active_cell_y >= 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_r).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x <= cell_segment_nx - 1 &&
          active_cell_y > 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_t).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x <= cell_segment_nx - 1 &&
          active_cell_y >= 0 && active_cell_y < cell_segment_ny - 1) {
          cells.get(active_cell_b).list.append(id);
        }
        if (active_cell_x > 0 && active_cell_x <= cell_segment_nx - 1 &&
          active_cell_y > 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_lt).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x < cell_segment_nx - 1 &&
          active_cell_y > 0 && active_cell_y <= cell_segment_ny - 1) {
          cells.get(active_cell_rt).list.append(id);
        }
        if (active_cell_x > 0 && active_cell_x <= cell_segment_nx - 1 &&
          active_cell_y >= 0 && active_cell_y < cell_segment_ny - 1) {
          cells.get(active_cell_lb).list.append(id);
        }
        if (active_cell_x >= 0 && active_cell_x < cell_segment_nx - 1 &&
          active_cell_y >= 0 && active_cell_y < cell_segment_ny - 1) {
          cells.get(active_cell_rb).list.append(id);
        }
      }
    }
  }

  void addInteraction(boolean set) {
    if (set) {
      PVector dist = new PVector();
      PVector force = new PVector();

      float part_saturation_scope_min = cp5.getController("part_saturation_scope").getMin();

      if (active_cell >= 0 && active_cell < cells.size()) {
        Cluster cell = cells.get(active_cell);

        // compare only the particles in cells
        if (cell.list.size() > 0) {
          for (int i = 0; i < cell.list.size(); i++) {
            Particle part = particles.get(cell.list.get(i));

            PVector.sub(part.pos, pos, dist);
            float d = dist.mag();
            float f = strength(d, part_interaction_d_max, 0.5);

            if (d < part_interaction_d_max && d > part_interaction_d_min && part_set_interaction) {
              force = dist.setMag(f * part_interaction_force);
              float d_delta = part_interaction_d_max - part_interaction_d_min;
              float d_border = d_delta / 100 * part_interaction_border + part_interaction_d_min;

              if (d > d_border) {
                velocity.add(force);
              } else velocity.sub(force);
            }

            if (part_set_interaction_draw && d < part_interaction_draw_d_max && d > part_interaction_draw_d_min) {
              part.connected = true;
              connected = false;

              if (!connected && a > part_saturation_scope_min && i < part_lines_max) {
                strokeWeight(part_lines_weight);
                stroke(r, g, b, a);
                line(pos.x, pos.y, part.pos.x, part.pos.y);
                part_lines_count++;
              }
            }
          }

          if (part_set_limitter) {
            float limitter = cell.list.size() / cell_max_entries;
            lifespan -= limitter * cell_limitter_factor;
          }
        }
      }
    }
  }

  void addAcceleration() {
    if (part_set_acceleration) {
      PVector aclr = new PVector();
      PVector.sub(pos, pos_before, aclr);
      float f = strength(lifespan, lifespan_start, 0.5);
      aclr.mult(f * part_acceleration_factor);
      pos.add(aclr);
    }
  }

  void lifespan() {
    lifespan--;
    if (pos.x <= vctr_segment_d + field_border_left || pos.x >= width - vctr_segment_d ||
      pos.y <= field_border_top + vctr_segment_d || pos.y >= height - field_border_bot - vctr_segment_d) {
      lifespan = 0;
    }
  }

  void update() {
    velocity.setMag(part_speed);
    pos_before = pos.copy();
    pos.add(velocity);
  }

  void clear(boolean set) {
    if (set) lifespan = 0;
  }

  void colorize(boolean set) {
    if (set) {
      int saturation;
      int lifespan_color = int(map(lifespan, 0, lifespan_start, 255, 0));

      if (lifespan_color < part_saturation_min || lifespan_color > part_saturation_max) {
        saturation = part_saturation_min_limit;
      } else saturation = int(map(lifespan_color, part_saturation_min, part_saturation_max,
        part_saturation_min_limit, part_saturation_max_limit));

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
