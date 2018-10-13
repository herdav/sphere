// Sphere (Concept vector field), David Herren, 2018

Vectorfield[] vector;
PVector pos = new PVector();

Target trgt;
ArrayList < Target > targets;

float d, r;
int n = 200;

color gray = color(200);
color darkgray = color(100);

void setup() {
  size(600, 600, P2D);
  d = width / n;
  r = d / 2;

  targets = new ArrayList < Target > ();
  targets.add(new Target(0, 0));

  vector = new Vectorfield[n * n];
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      pos.x = j * d + r;
      pos.y = i * d + r;
      vector[i * n + j] = new Vectorfield(pos);
    }
  }
}

void draw() {
  background(0);
  field();
  targets();
  data();
  //pictures();
}

void targets() {
  targets.get(0).display(mouseX, mouseY);
  for (Target target: targets) {
    target.display();
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
  for (int i = 0; i < n * n; i++) {
    for (int j = targets.size() - 1; j >= 0; j--) {
      vector[i].target(targets.get(j).pos);
      vector[i].magnitude(0.05);
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
  text(float(int(float(frameCount) / millis() * 10000)) / 10 + " fps  //  " + n * n + " vectors  //  " +
    targets.size() + " targets  //  David Herren  //  2018", 3, 3);
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
    noStroke();
    fill(255, 0, 0);
    ellipse(pos.x, pos.y, 10, 10);
  }

  void display() {
    noStroke();
    fill(255, 0, 0);
    ellipse(pos.x, pos.y, 10, 10);
  }
}

class Vectorfield {
  PVector orgin = new PVector();
  PVector target = new PVector();
  PVector direct = new PVector();
  PVector offset = new PVector();
  PVector result = new PVector();

  float magnitude, maxDist, dist;

  Vectorfield(PVector pos) {
    orgin.x = pos.x;
    orgin.y = pos.y;

    maxDist = sqrt(2 * sq((n - 1) * d));
  }

  void target(PVector target) {
    dist = orgin.dist(target);
    dist = r - (r / maxDist) * dist;
    direct = PVector.sub(target, orgin);
    direct = direct.setMag(dist);
    direct.add(orgin);
  }

  void magnitude(float aclr) {
    offset = PVector.sub(direct, result);
    magnitude = offset.mag();
    offset.mult(aclr);
    result.add(offset);
  }

  void grid(color c) {
    noFill();
    stroke(c);
    rectMode(CENTER);
    //rect(orgin.x, orgin.y, d, d);
    ellipse(orgin.x, orgin.y, d, d);
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
        scope = map(magnitude, 0, d, 0, 255);
        fill(scope);
        break;

      case '3': // heat map
        n = 11;
        r = 128;
        scope = map(magnitude, 0, d, 0, n * r);

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
          scope = map(magnitude, 0, d, 0, n);
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
    rect(orgin.x, orgin.y, d, d);
  }
}
