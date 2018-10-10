// Sphere (Concept), David Herren, 2018

Vectors[][] vector;

PShader blur;

float d;
int n = 150;

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

  saveFrame("\\export\\frame-######.png");
}

void vectorfield() {
  background(0);
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      //vector[i][j].grid();
      vector[i][j].target(mouseX, mouseY);
      vector[i][j].magnitude();
    }
  }

}

void data() {
  noStroke();
  fill(255);
  rectMode(CORNER);
  rect(0, 0, width / 3 * 2, 18);
  fill(0);
  textAlign(LEFT, TOP);
  text(float(int(float(frameCount) / millis() * 10000)) / 10 + " fps  //  " + n * n + "  vectors  //  David Herren, 2018", 2, 3);

  //println(vector[1][1].m);
}

class Vectors {
  PVector p0 = new PVector();
  PVector p1 = new PVector();
  PVector p2 = new PVector();
  PVector p3 = new PVector();
  PVector p4 = new PVector();

  float m, c1, c2;
  float aclr = 0.05;
  float r = d / 2;

  Vectors(float xpos, float ypos) {
    p0.x = xpos;
    p0.y = ypos;
    p4.x = p0.x;
    p4.y = p0.y;
  }

  void grid() {
    noFill();
    stroke(gray);
    rectMode(CENTER);
    rect(p0.x, p0.y, d, d);
    ellipse(p0.x, p0.y, d, d);
  }

  void target(float x, float y) {
    p1.x = x;
    p1.y = y;
    p2 = PVector.sub(p1, p0);
    p2.normalize();
    p2.mult(r);
    p2.add(p0);

    /*stroke(gray);
    line(p0.x, p0.y, p2.x, p2.y);*/
  }

  void magnitude() {
    p3 = PVector.sub(p2, p4);
    m = p3.mag();
    p3.mult(aclr);
    p4.add(p3);

    c1 = map(m, 0, d, 0, 255);
    c2 = map(m, 0, d, 0, 11 * 255 / 2);

    switch (key) {
      case '1': // heatmap
        if (c2 >= 0) { // dark blue
          fill(0, 0, c2);
        }
        if (c2 > 0.5 * 255) { // blue
          fill(0, 0, c2);
        }
        if (c2 > 1 * 255) { // cyan
          fill(0, c2 - 255, 255);
        }
        if (c2 > 2 * 255) { // green
          fill(0, 255, 3 * 255 - c2);
        }
        if (c2 > 3 * 255) { // yellow
          fill(c2 - 3 * 255, 255, 0);
        }
        if (c2 > 4 * 255) { // orange
          fill(255, 255 - c2 + 4 * 255, 0);
        }
        if (c2 > 4.5 * 255) { // red
          fill(255, 127 - c2 + 4.5 * 255, 0);
        }
        if (c2 > 5 * 255) { // dark red
          fill(255 - c2 + 5 * 255, 0, 0);
        }
        break;

      case '2':
        fill(c1); // light dark
        break;

      default: // vectorfield
        noFill();
        stroke(255);
        line(p0.x, p0.y, p4.x, p4.y);
        break;
    }

    noStroke();
    rectMode(CENTER);
    rect(p0.x, p0.y, d, d);
  }
}