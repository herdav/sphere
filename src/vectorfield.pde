// Sphere (Concept), David Herren, 2018

Vectors[][] vector;

float d;
int n = 200;

color gray = color(180);

void setup() {
  size(600, 600, P2D);
  d = width / n;
  vector = new Vectors[n][n];
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      vector[i][j] = new Vectors(d / 2 + j * d, d / 2 + i * d);
    }
  }
}

void draw() {
  vectorfield();
  data();
  //pictures();
}

void vectorfield() {
  background(0);
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      vector[i][j].target(mouseX, mouseY);
      vector[i][j].magnitude();
      //vector[i][j].grid();
    }
  }
}

void pictures() {
  saveFrame("\\export\\img\\frame-######.png");
}

void data() {
  noStroke();
  fill(255);
  rectMode(CORNER);
  rect(0, 0, width / 3 * 2, 18);
  fill(0);
  textAlign(LEFT, TOP);
  text(float(int(float(frameCount) / millis() * 10000)) / 10 + " fps  //  " + n * n + "  vectors  //  David Herren, 2018", 2, 3);
}

class Vectors {
  PVector v0 = new PVector();
  PVector v1 = new PVector();
  PVector v2 = new PVector();
  PVector v3 = new PVector();
  PVector v4 = new PVector();

  float m, c1, c2, c3;
  float aclr = 0.08;
  float r = d / 2;

  Vectors(float xpos, float ypos) {
    v0.x = xpos;
    v0.y = ypos;
    v4.x = v0.x;
    v4.y = v0.y;
  }

  void grid() {
    noFill();
    stroke(0);
    rectMode(CENTER);
    rect(v0.x, v0.y, d, d);
    //ellipse(v0.x, v0.y, d, d);
  }

  void target(float x, float y) {
    v1.x = x;
    v1.y = y;
    v2 = PVector.sub(v1, v0);
    v2.normalize();
    v2.mult(r);
    v2.add(v0);

    /*stroke(gray);
    line(v0.x, v0.y, v2.x, v2.y);*/
  }

  void magnitude() {
    int r = 128;
    int n = 11;

    int n2 = 100;

    v3 = PVector.sub(v2, v4);
    m = v3.mag();
    v3.mult(aclr);
    v4.add(v3);

    c1 = map(m, 0, d, 0, 255);
    c2 = map(m, 0, d, 0, n * r);
    c3 = map(m, 0, d, 0, n2);

    switch (key) {
      case '1': // heatmap
        if (c2 >= 0 * r) { // blue
          fill(0, 0, c2);
        }
        if (c2 >= 2 * r) { // cyan
          fill(0, c2 - 2 * r, 255);
        }
        if (c2 >= 4 * r) { // green
          fill(0, 255, 6 * r - c2);
        }
        if (c2 >= 6 * r) { // yellow
          fill(c2 - 6 * r, 255, 0);
        }
        if (c2 >= 8 * r) { // red
          fill(255, 10 * r - c2, 0);
        }
        if (c2 >= 10 * r) { // dark red
          fill(12 * r - c2, 0, 0);
        }
        break;

      case '2': // light-dark
        fill(c1);
        break;

      case '3': // field lines
        for (int i = 0; i <= n2; i++) {
          if (c3 >= i * 2 && i % 2 == 0) {
            fill(150);
          }
          if (c3 >= i * 2 && i % 2 > 0) {
            fill(50);
          }
        }
        break;

      default: // vectorfield
        noFill();
        stroke(255);
        line(v0.x, v0.y, v4.x, v4.y);
        break;
    }

    noStroke();
    rectMode(CENTER);
    rect(v0.x, v0.y, d, d);
  }
}
