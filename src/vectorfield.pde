// Sphere (concept vector field), David Herren, 2018

Vectorfield[] vector;
PVector pos_segment_vectorfield = new PVector();
float d_segment_vectorfield, r_segment_vectorfield, maxDist_vectorfield;
int nx_segment_vectorfield = 20;
int ny_segment_vectorfield = nx_segment_vectorfield;
int n_segment_vectorfield;

Target targt;
ArrayList < Target > targets;

Particle part;
ArrayList < Particle > particles;

int count_particles;
int birthrate_particles = 1;
int streams_particles = 100;
int lifespan_particles = 50;
float speed_particles = 20;
int detectionfactor_particles = 2;

color gray = color(180);
color darkgray = color(90);

void setup() {
  size(900, 900, P2D);

  d_segment_vectorfield = width / nx_segment_vectorfield;
  r_segment_vectorfield = d_segment_vectorfield / 2;
  n_segment_vectorfield = nx_segment_vectorfield * ny_segment_vectorfield;
  maxDist_vectorfield = sqrt(2 * sq((nx_segment_vectorfield - 1) * d_segment_vectorfield));

  targets = new ArrayList < Target > ();
  targets.add(new Target(0, 0));

  vector = new Vectorfield[n_segment_vectorfield];
  for (int i = 0; i < ny_segment_vectorfield; i++) {
    for (int j = 0; j < nx_segment_vectorfield; j++) {
      pos_segment_vectorfield.x = j * d_segment_vectorfield + r_segment_vectorfield;
      pos_segment_vectorfield.y = i * d_segment_vectorfield + r_segment_vectorfield;
      vector[i * ny_segment_vectorfield + j] = new Vectorfield(pos_segment_vectorfield);
    }
  }

  particles = new ArrayList < Particle > ();
}

void draw() {
  background(0);
  field();
  targets();
  particles();
  data();
  //pictures();
}

void targets() {
  targets.get(0).display(mouseX, mouseY);
  for (Target targets: targets) {
    targets.display();
  }
}

void particles() {
  count_particles++;
  if (count_particles == birthrate_particles) {
    count_particles = 0;
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(0, height / streams_particles * i, lifespan_particles));
    }
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(width / 20 * i, height, lifespan_particles));
    }
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(width, height / streams_particles * i, lifespan_particles));
    }
    for (int i = 0; i <= streams_particles; i++) {
      particles.add(new Particle(width / streams_particles * i, 0, lifespan_particles));
    }
  }

  for (Particle particles: particles) {
    particles.update(detectionfactor_particles);
    particles.lifespan();
    particles.display();
  }
  for (int i = particles.size() - 1; i > 0; i--) {
    Particle part = particles.get(i);
    if (part.lifespan <= 0) {
      particles.remove(i);
    }
  }
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    targets.add(new Target(mouseX, mouseY));
  }
  if (mouseButton == RIGHT && targets.size() > 1) {
    for (int i = targets.size() - 1; i > 0; i--) {
      targets.remove(i);
    }
  }
}

void field() {
  for (int i = 0; i < n_segment_vectorfield; i++) {
    for (int j = targets.size() - 1; j >= 0; j--) {
      vector[i].target(targets.get(j).pos);
      vector[i].magnitude(0.03);
    }
    vector[i].colorize(key);
    //vector[i].grid(darkgray);
  }

  fill(255, 0, 0);
  noStroke();
}

void data() {
  noStroke();
  fill(255);
  rectMode(CORNER);
  rect(0, 0, width, 19);
  fill(0);
  textAlign(LEFT, TOP);
  text("Sphere  //  Vector field  //  " + float(int(float(frameCount) / millis() * 10000)) / 10 + " fps  //  " +
    n_segment_vectorfield + " vectors  //  " + targets.size() + " targets  //  " + particles.size() + " particles  //  David Herren  //  2018", 3, 3);
}

void pictures() {
  saveFrame("\\export\\img\\frame-######.png");
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
    /*noStroke();
    fill(255, 0, 0);
    ellipse(pos.x, pos.y, 10, 10);*/
  }

  void display() {
    /*noStroke();
    fill(255, 0, 0);
    ellipse(pos.x, pos.y, 10, 10);*/
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
    //rectMode(CENTER);
    //rect(orgin.x, orgin.y, d, d);
    ellipse(orgin.x, orgin.y, d_segment_vectorfield, d_segment_vectorfield);
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
  color c = color(255, 0, 0);

  Particle(float x, float y, int l) {
    pos.x = x;
    pos.y = y;
    lifespan = l;
    startlifespan = l;
  }

  void update(int q) {
    //active = round(pos.y / n) * n + round(pos.x / n); // detect active vector

    for (int i = 0; i < vector.length; i++) {
      dist = pos.dist(vector[i].orgin);
      if (dist <= q * d_segment_vectorfield) {
        aclr.add(vector[i].force);
      }
    }
    force = PVector.add(pos, aclr);
    aclr.setMag(speed_particles);
    pos.add(aclr);
  }

  void lifespan() {
    lifespan--;
  }

  void display() {
    noStroke();
    fill(255, map(lifespan, startlifespan, 0, 0, 200));
    //ellipse(pos.x, pos.y, 2, 2);
    rectMode(CENTER);
    rect(pos.x, pos.y, 1, 1);

    /*noFill();
    stroke(c);
    ellipse(pos.x, pos.y, n * d, n * d);
    line(pos.x, pos.y, force.x, force.y);*/
  }
}
