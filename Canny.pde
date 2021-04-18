import java.util.Arrays;
import java.util.List;
import java.util.LinkedList;
import java.util.Iterator;
import java.util.Set;
import java.util.HashSet;
import java.util.Collections;
import java.util.Arrays;

Operator blur5 = new Operator(5, 159, new int[] {2, 4, 5, 9, 12, 15});
Operator blur3 = new Operator(3, 16, new int[] {1, 2, 4});

Operator sobelx = new Operator(4, 
    new int[] {-1, 0, 1},
    new int[] {-2, 0, 2},
    new int[] {-1, 0, 1});
Operator sobely = new Operator(4, 
    new int[] {-1, -2, -1},
    new int[] {0, 0, 0},
    new int[] {1, 2, 1}); 

PImage source;
PImage edited;

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
  transform = blur3.apply(transform);

  println("x");
  int[][] gradientX = sobelx.apply(transform);
  println("y");
  int[][] gradientY = sobely.apply(transform);
  
  float[][] gradientIntensity = new float[imgWidth][imgHeight];
  float[][] gradientAngles = new float[imgWidth][imgHeight];
  
  println("intensity / angles");
  for (int x = 0; x < imgWidth; ++x) {
    for (int y = 0; y < imgHeight; ++y) {
      int gx = gradientX[x][y];
      int gy = gradientY[x][y];
      gradientAngles[x][y] = atan2(gy, gx);
      gradientIntensity[x][y] = sqrt(pow(gx, 2) + pow(gy, 2));
    }
  }
  
  println("thinning");
  thinEdges(gradientX, gradientY, gradientIntensity);
  println("tresh");
  threshold(gradientIntensity, 10, 30);
  println("hysterisis");
  hysterisis(gradientIntensity);
  
  println("copy");
  edited = img.copy();
  edited.loadPixels();
  
  for (int x = 0; x < imgWidth; ++x) {
    for (int y = 0; y < imgHeight; ++y) {
      float phi = atan2(gradientY[x][y], gradientX[x][y]);
      //edited.pixels[y*imgWidth + x] = color(constrain(gradientIntensity[x][y], 0, 255));
      edited.pixels[y*imgWidth + x] = rainbow((phi + PI) / TWO_PI, gradientIntensity[x][y] / 255);
    }
  }
  edited.updatePixels();  
  println("finish");
}


final float SIN_EIGHTH_PI = sin(PI / 8);

void thinEdges(int[][] gradientX, int[][] gradientY, float[][] gradientIntensity) {
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

void threshold(float[][] gradientIntensity, int low, int high) {
  for (int x = 1; x < gradientIntensity.length - 1; ++x) {
    for (int y = 1; y < gradientIntensity[0].length - 1; ++y) {
      float intensity = gradientIntensity[x][y];
      gradientIntensity[x][y] = intensity < low ? 0 : intensity < high ? 128 : 255;
    }
  }
}

void hysterisis(float[][] gradientIntensity) {
  int i = 0;
  for (int x = 1; x < gradientIntensity.length - 1; ++x) {
    for (int y = 1; y < gradientIntensity[0].length - 1; ++y) {
      
      if (gradientIntensity[x][y] == 255) {
        continue;
      }
      if ((gradientIntensity[x-1][y] == 255 && gradientIntensity[x+1][y] == 255) ||
          (gradientIntensity[x][y-1] == 255 && gradientIntensity[x][y+1] == 255)) {
            gradientIntensity[x][y] = 255;
            ++i;
      }else {
        gradientIntensity[x][y] = 0;
      }
    }
  }
  println(i);
}
 


boolean displaySource = true;
PVector shift = new PVector();
float zoom = 0;

void draw() {
  background(196);
  
  push();
  translate(width/2, height/2);
  scale(getScale());

  PImage img = displaySource ? source : edited;
  image(img, 
      -img.width/2 + (int) shift.x, 
      -img.height/2 + (int) shift.y);
  noStroke();
  rect(0, 0, 3, 3);
  pop();
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
