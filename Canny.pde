import java.util.Arrays;
import java.util.List;
import java.util.LinkedList;
import java.util.Iterator;
import java.util.Set;
import java.util.HashSet;

//Operator blur = new Operator(5, 159, new int[] {2, 4, 5, 9, 12, 15});
Operator blur = new Operator(3, 16, new int[] {1, 2, 4});

Operator sobelx = new Operator(4, 
    new int[] {-1, 0, 1},
    new int[] {-2, 0, 2},
    new int[] {-1, 0, 1});
Operator sobely = new Operator(4, 
    new int[] {-1, -2, -1},
    new int[] {0, 0, 0},
    new int[] {1, 2, 1}); 

PImage source;
PImage edit;

boolean isRGB = false;

void setup() {
  surface.setSize((int) (displayWidth*2/3f), (int) (displayHeight*3/4f));
  surface.setLocation((int) (displayWidth/6f), (int) (displayHeight/8f));
  surface.setResizable(true);

  source = loadImage("red.png");
  noSmooth();

  detectEdges(source);
}

void detectEdges(PImage img) {
  int imgWidth = img.width;
  int imgHeight = img.height;
 
  img.loadPixels();
  int[][] transform = gray(img.pixels, imgWidth);
  
  println("blur");
  transform = blur.apply(transform);

  println("x");
  int[][] gradientX = sobelx.apply(transform);
  println("y");
  int[][] gradientY = sobely.apply(transform);
  
  float[][] gradientIntensity = new float[imgWidth][imgHeight];
  //float[][] edgeAngles = new float[imgWidth][imgHeight];
  
  println("intensity");
  for (int x = 0; x < imgWidth; ++x) {
    for (int y = 0; y < imgHeight; ++y) {
      //int cosPhi = gradientX[x][y];
      //int sinPhi = gradientY[x][y];
      //edgeAngles[x][y] = atan2(sinPhi, cosPhi);
      gradientIntensity[x][y] = sqrt(pow(gradientX[x][y], 2) + pow(gradientY[x][y], 2));
    }
  }
  println("thin");
  thinEdges(gradientX, gradientY, gradientIntensity);
  
  println("copy");
  edit = img.copy();
  edit.loadPixels();
  
  for (int x = 0; x < imgWidth; ++x) {
    for (int y = 0; y < imgHeight; ++y) {
      float phi = atan2(gradientY[x][y], gradientX[x][y]);
      //edit.pixels[y*imgWidth + x] = color(constrain(gradientIntensity[x][y], 0, 255));
      edit.pixels[y*imgWidth + x] = rainbow((phi + PI) / TWO_PI, gradientIntensity[x][y] / 255);
    }
  }
  edit.updatePixels();  
  println("finish");
}


final float SIN_EIGHTH_PI = sin(PI / 8);

void thinEdges(int[][] gradientX, int[][] gradientY, float[][] gradientIntensity) {
  //float[][] edgeAngles = new float[gradientY.length];
  Set<int[]> thinnedOuts = new HashSet<int[]>();
  
  for (int x = 1; x < gradientIntensity.length - 1; ++x) {
    for (int y = 1; y < gradientIntensity[0].length - 1; ++y) {
      
      //make the edge direction in coordinate for point on one the surrounding 8 points
      int dx = constrain((int) (gradientX[x][y] / SIN_EIGHTH_PI), -1, 1);
      int dy = constrain((int) (gradientY[x][y] / SIN_EIGHTH_PI), -1, 1); //<>//
      
      float intensity = gradientIntensity[x][y];
      if (intensity < gradientIntensity[x+dx][y+dy] || intensity < gradientIntensity[x-dx][y-dy]) {
        thinnedOuts.add(new int[] {x, y});
      }
    }
  }
  for (int[] vec : thinnedOuts) {
    gradientIntensity[vec[0]][vec[1]] = 0;
  }
}




boolean displaySource = true;
PVector shift = new PVector();
float zoom = 0;

void draw() {
  background(196);
  
  translate(width/2, height/2);
  scale(getScale());

  PImage img = displaySource ? source : edit;
  //image(img, -img.width/2, -img.height/2);
  image(img, 
      -img.width/2 + (int) shift.x, 
      -img.height/2 + (int) shift.y);
  noStroke();
  rect(0, 0, 3, 3);
}

float getScale() {
  return pow(2, zoom);
}

void mouseDragged() {
  shift.add(
    (mouseX - pmouseX) / getScale(),
    (mouseY - pmouseY) / getScale());
}

float dZoom = 1;
void mouseClicked() {
  zoom += mouseButton == LEFT ? dZoom : -dZoom;
}

void keyPressed() {
  if (keyCode == ' ') {
    displaySource = !displaySource;
  }
}




int[][] gray(int[] pixels, int imgWidth) {
  int[][] out = new int[imgWidth][pixels.length / imgWidth];
  
  for (int i = 0; i < pixels.length; ++i) {
    out[i % imgWidth][i / imgWidth] = bright(pixels[i]);
  }
  return out;
}

//returns brightness of an RGB color int
int bright(int c) {
  return ((c >> 16 & 0xFF) * 299 +
          (c >> 8 & 0xFF) * 587 +
          (c & 0xFF) * 114) / 1000;      
}

//creates a HSB color from percentage
private color rainbow(float hue, float brightness) {
  float r, g, b;
  
  if (hue < 1 / 6f) {
    r = 255;
    g = 6 * hue * 255;
    b = 0;
  } else if (hue < 1 / 3f) {
    r = 255 - 6 * (hue - 1 / 6f) * 255;
    g = 255;
    b = 0;
  } else if (hue < 1 / 2f) {
    r = 0;
    g = 255;
    b = 6 * (hue - 1 / 3f) * 255;
  } else if (hue < 2 / 3f) {
    r = 0;
    g = 255 - 6 * (hue - 1 / 2f) * 255;
    b = 255;
  } else if (hue < 5 / 6f) {
    r = 6 * (hue - 2 / 3f) * 255;
    g = 0;
    b = 255;
  } else {
    r = 255;
    g = 0;
    b = 255 - 6 * (hue - 5 / 6f) * 255;
  }
  return color(
      brightness * constrain(r, 0, 255), 
      brightness * constrain(g, 0, 255), 
      brightness * constrain(b, 0, 255));
}
