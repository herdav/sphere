// Sphere (concept vector field), David Herren, 2018

import controlP5.*;
import processing.pdf.*;

ControlP5 cp5;

Vectorfield vctr;
ArrayList < Vectorfield > vectors;

PVector pos_segment_vectorfield = new PVector();
float d_segment_vectorfield, r_segment_vectorfield, maxDist_vectorfield;
float delay_segment_vectorfield = 0.03;
int nx_segment_vectorfield = 50;
int ny_segment_vectorfield;
int n_segment_vectorfield;

Target targt;
ArrayList < Target > targets;

Particle part;
ArrayList < Particle > particles;

int count_particles;
int birthrate_particles = 1;
int size_particles = 1;
int streams_particles = 100;
int lifespan_particles = 100;
float speed_particles = 12;
int lx_particles, ly_particles;
int saturationMin_particles = 0;
int saturationMax_particles = 127;

int border_left;

color gray = color(180);
color darkgray = color(90);

color color_a, color_b, color_c, color_d;

boolean record = true;

void setup() {
  size(1800, 1000, P2D);
  blendMode(ADD);

  textSize(10);

  control();

  border_left = width - height;

  vectors = new ArrayList < Vectorfield > ();
  particles = new ArrayList < Particle > ();
  targets = new ArrayList < Target > ();
  targets.add(new Target(border_left + (width - border_left) / 2, height / 2));
}

void draw() {
  pictures();
  if (record) {
    beginRecord(PDF, "\\export\\pdf\\frame-######.pdf");
  }
  background(0);
  field();
  targets();
  particles();
  data();
  if (record) {
    endRecord();
    record = false;
  }
}

void control() {
  int cp5w = 220;
  int cp5h = 14;
  int cp5x = 20;
  int cp5y = 20;
  int[] cp5d = new int[10];

  for (int i = 0; i < cp5d.length; i++) {
    cp5d[i] = int(cp5y + i * cp5h * 1.5);
  }

  cp5 = new ControlP5(this);

  cp5.setColorBackground(color(50))
    .setColorForeground(color(100))
    .setColorActive(color(150));

  // name, minValue, maxValue, x, y, width, height
  cp5.addSlider("nx_segment_vectorfield", 5, 300, cp5x, cp5d[0], cp5w, cp5h).setCaptionLabel("VECTORFIELD_SEGMENTS");
  cp5.addSlider("delay_segment_vectorfield", 0, 0.1, cp5x, cp5d[1], cp5w, cp5h).setCaptionLabel("VECTORFIELD_DELAY");

  cp5.addSlider("birthrate_particles", 1, 60, cp5x, cp5d[2], cp5w, cp5h).setCaptionLabel("PARTICLE_BIRTHRATE");
  cp5.addSlider("streams_particles", 1, 200, cp5x, cp5d[3], cp5w, cp5h).setCaptionLabel("PARTICLE_STREAMS");
  cp5.addSlider("lifespan_particles", 1, 200, cp5x, cp5d[4], cp5w, cp5h).setCaptionLabel("PARTICLE_LIFESPAN");
  cp5.addSlider("speed_particles", 1, 30, cp5x, cp5d[5], cp5w, cp5h).setCaptionLabel("PARTICLE_SPEED");
  cp5.addSlider("size_particles", 1, 20, cp5x, cp5d[6], cp5w, cp5h).setCaptionLabel("PARTICLE_SIZE");

  cp5.addRange("PARTICLE_SATURATION")
    .setBroadcast(false)
    .setPosition(cp5x, cp5d[7])
    .setSize(cp5w, cp5h)
    .setHandleSize(5)
    .setRange(0, 255)
    .setRangeValues(saturationMin_particles, saturationMax_particles)
    .setBroadcast(true);

  Group cp5g1 = cp5.addGroup("COLOR")
    .setPosition(cp5x, cp5d[8] + 20)
    .setWidth(cp5w)
    .setBackgroundHeight(250)
    .setBackgroundColor(color(255, 50));

  cp5.addColorWheel("color_a", 0, 10, 100).setRGB(color(0, 255, 0)).setCaptionLabel("LEFT").setGroup(cp5g1);
  cp5.addColorWheel("color_b", 120, 10, 100).setRGB(color(0, 0, 255)).setCaptionLabel("RIGHT").setGroup(cp5g1);
  cp5.addColorWheel("color_c", 0, 130, 100).setRGB(color(255, 0, 0)).setCaptionLabel("TOP").setGroup(cp5g1);
  cp5.addColorWheel("color_d", 120, 130, 100).setRGB(color(255, 0, 255)).setCaptionLabel("BOTTOM").setGroup(cp5g1);

  cp5.addRadioButton("THEME")
    .setPosition(400, 20)
    .setSize(20, cp5h)
    .addItem("PARTICLES", 0)
    .addItem("VECTORFIELD", 1)
    .addItem("LIGHT_DARK", 2)
    .addItem("HEAT_MAP", 3)
    .addItem("FIELD_LINES", 4);
}


void controlEvent(ControlEvent theControlEvent) {
  if (theControlEvent.isFrom("PARTICLE_SATURATION")) {
    saturationMin_particles = int(theControlEvent.getController().getArrayValue(0));
    saturationMax_particles = int(theControlEvent.getController().getArrayValue(1));
  }
}

void targets() {
  if (mouseX >= border_left) {
    targets.get(0).display(mouseX, mouseY);
  }
  if (mouseX < border_left) {
    targets.get(0).display((width - border_left) / 2 + border_left, height / 2);
  }
  for (Target targets: targets) {
    targets.display();
  }
}

void particles() {
  count_particles++;
  if (count_particles == birthrate_particles) {
    count_particles = 0;
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(border_left + d_segment_vectorfield, d_segment_vectorfield + ly_particles * i, lifespan_particles, color_a)); // left
    }
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(width - d_segment_vectorfield, d_segment_vectorfield + ly_particles * i, lifespan_particles, color_b)); // right
    }
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(border_left + d_segment_vectorfield + lx_particles * i, d_segment_vectorfield, lifespan_particles, color_c)); // top
    }
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(border_left + d_segment_vectorfield + lx_particles * i, height - d_segment_vectorfield, lifespan_particles, color_d)); // bottom
    }
  }

  for (int i = particles.size() - 1; i > 0; i--) {
    Particle part = particles.get(i);
    if (part.lifespan <= 0) {
      particles.remove(i);
    }
  }
  for (Particle particles: particles) {
    particles.update();
    particles.lifespan();
    particles.display();
  }
}

void field() {
  ny_segment_vectorfield = nx_segment_vectorfield;
  n_segment_vectorfield = nx_segment_vectorfield * ny_segment_vectorfield;
  if (n_segment_vectorfield != vectors.size()) {
    for (int i = vectors.size() - 1; i >= 0; i--) {
      vectors.remove(i);
    }

    if (height % ny_segment_vectorfield > 0) {
      nx_segment_vectorfield++;
    }

    d_segment_vectorfield = height / nx_segment_vectorfield;
    r_segment_vectorfield = d_segment_vectorfield / 2;
    maxDist_vectorfield = sqrt(2 * sq((nx_segment_vectorfield - 1) * d_segment_vectorfield));

    ly_particles = int((height - 2 * d_segment_vectorfield) / streams_particles);
    lx_particles = ly_particles;

    for (int i = 0; i < ny_segment_vectorfield; i++) {
      for (int j = 0; j < nx_segment_vectorfield; j++) {
        pos_segment_vectorfield.x = border_left + j * d_segment_vectorfield + r_segment_vectorfield;
        pos_segment_vectorfield.y = i * d_segment_vectorfield + r_segment_vectorfield;
        vectors.add(new Vectorfield(pos_segment_vectorfield));
      }
    }
  }

  for (int i = 0; i < n_segment_vectorfield; i++) {
    Vectorfield vctr = vectors.get(i);
    for (int j = targets.size() - 1; j >= 0; j--) {
      vctr.target(targets.get(j).pos);
      vctr.magnitude(delay_segment_vectorfield);
    }
    vctr.colorize(key);
    //vctr.grid(darkgray);
  }
}

void mouseClicked() {
  if (mouseButton == LEFT && mouseX > border_left) {
    targets.add(new Target(mouseX, mouseY));
  }
  if (mouseButton == RIGHT && targets.size() > 1 && mouseX > border_left) {
    for (int i = targets.size() - 1; i > 0; i--) {
      targets.remove(i);
    }
  }
}

void data() {
  fill(255);
  textAlign(LEFT, BOTTOM);
  text(float(int(float(frameCount) / millis() * 10000)) / 10 + " fps" + "\n" +
    vectors.size() + " vectors" + "\n" +
    targets.size() + " targets" + "\n" +
    particles.size() + " particles", 20, height - 20);
}

void pictures() {
  //saveFrame("\\export\\img\\frame-######.png");
  if (key == 's') {
    record = true;
  }
}

class Target {
  PVector pos = new PVector();

  Target(float x, float y) {
    pos.x = x;
    pos.y = y;
  }

  void display(float x, float y) {
    pos.x = x;
    pos.y = y;
    noStroke();
    fill(255);
    ellipse(pos.x, pos.y, 10, 10);
  }

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

  float magnitude, dist;

  Vectorfield(PVector pos) {
    orgin.x = pos.x;
    orgin.y = pos.y;
  }

  void target(PVector target) {
    dist = orgin.dist(target);
    dist = r_segment_vectorfield - r_segment_vectorfield * dist / maxDist_vectorfield;
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

  void grid(color c) {
    noFill();
    stroke(c);
    ellipse(orgin.x, orgin.y, d_segment_vectorfield, d_segment_vectorfield);
    rectMode(CENTER);
    //rect(orgin.x, orgin.y, d_segment_vectorfield, d_segment_vectorfield);
  }

  void colorize(char input) {
    float scope;
    int n, r;
    switch (input) {
      case '1': // vector field
        noFill();
        stroke(darkgray);
        line(orgin.x, orgin.y, direct.x, direct.y);
        line(direct.x, direct.y, result.x, result.y);
        stroke(255);
        line(orgin.x, orgin.y, result.x, result.y);
        break;

      case '2': // light dark
        scope = map(magnitude, 0, d_segment_vectorfield, 0, 255);
        fill(scope);
        break;

      case '3': // heat map
        n = 11;
        r = 128;
        scope = map(magnitude, 0, d_segment_vectorfield, 0, n * r);

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

      case '4': // field lines
        n = 100;
        for (int i = 0; i <= n; i++) {
          scope = map(magnitude, 0, d_segment_vectorfield, 0, n);
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
    rect(orgin.x, orgin.y, d_segment_vectorfield, d_segment_vectorfield);
  }
}

class Particle {
  PVector pos = new PVector();
  PVector aclr = new PVector();
  PVector force = new PVector();

  float dist;
  int active, lifespan, startlifespan;
  color argb;
  int a, r, g, b;

  Particle(float x, float y, int l, color c) {
    pos.x = x;
    pos.y = y;
    lifespan = l;
    startlifespan = l;
    argb = c;
  }

  void update() {
    active = int(round(pos.y / d_segment_vectorfield) * ny_segment_vectorfield + round((pos.x - border_left) / d_segment_vectorfield)); // detect active vector
    if (active >= 0 && active < vectors.size()) {
      Vectorfield vctr = vectors.get(active);
      aclr.add(vctr.force);
    }
    force = PVector.add(pos, aclr);
    aclr.setMag(speed_particles);
    pos.add(aclr);
  }

  void lifespan() {
    lifespan--;
    if (pos.x <= d_segment_vectorfield + border_left || pos.x >= width - d_segment_vectorfield || pos.y <= d_segment_vectorfield || pos.y >= height - d_segment_vectorfield) {
      lifespan = 0;
    }
  }

  void display() {
    a = int(map(lifespan, startlifespan, 0, saturationMin_particles, saturationMax_particles));
    r = (argb >> 16) & 0xFF;
    g = (argb >> 8) & 0xFF;
    b = argb & 0xFF;
    noStroke();
    fill(r, g, b, a);
    rectMode(CENTER);
    rect(pos.x, pos.y, size_particles, size_particles);
  }
}
