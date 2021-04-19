import java.util.Arrays;
import java.util.List;
import java.util.LinkedList;
import java.util.Iterator;
import java.util.Set;
import java.util.HashSet;
import java.util.Collections;
import java.util.Arrays;

//Operator blur = new Operator(5, 159, new int[] {2, 4, 5, 9, 12, 15});
Operator blur = new Operator(3, 16, new int[] {1, 2, 4});

Operator sobelY = new Operator(4, 
    new int[] {-1, 0, 1},
    new int[] {-2, 0, 2},
    new int[] {-1, 0, 1});
    
Operator sobelX = new Operator(4, 
    new int[] {-1, -2, -1},
    new int[] {0, 0, 0},
    new int[] {1, 2, 1}); 

PImage source;
PImage edited;

boolean isRGB = false;
int[][] gradientIntensity;

void setup() {
  surface.setSize((int) (displayWidth*2/3f), (int) (displayHeight*3/4f));
  surface.setLocation((int) (displayWidth/6f), (int) (displayHeight/8f));
  surface.setResizable(true);
  
  source = loadImage("C:/Users/Fred Feuerpferd/Pictures/fox model/Blatt01.jpeg");
  //source = loadImage("red.png");
  noSmooth();  
  detectEdges(source);
}

void detectEdges(PImage img) {
  int imgWidth = img.width;
  int imgHeight = img.height;
 
  img.loadPixels();
  int[][] grayscale = gray(img.pixels, imgWidth);
  
  println("blur");
  grayscale = blur.apply(grayscale);

  println("x");
  int[][] gradientX = sobelX.apply(grayscale);
  println("y");
  int[][] gradientY = sobelY.apply(grayscale);
  
  gradientIntensity = new int[imgWidth][imgHeight];
  float[][] gradientAngles = new float[imgWidth][imgHeight];
  
  println("intensity / angles");
  for (int x = 0; x < imgWidth; ++x) {
    for (int y = 0; y < imgHeight; ++y) {
      int gx = gradientX[x][y];
      int gy = gradientY[x][y];
      gradientAngles[x][y] = atan2(gy, gx);
      gradientIntensity[x][y] = (int) sqrt(pow(gx, 2) + pow(gy, 2));
    }
  }
  
  println("thinning");
  thinEdges(gradientX, gradientY, gradientIntensity);
  println("tresh");
  threshold(gradientIntensity, 10, 25);
  println("hysterisis");
  hysteresis(gradientIntensity);
  
  println("copy");
  edited = img.copy();
  edited.loadPixels();
  
  for (int x = 0; x < imgWidth; ++x) {
    for (int y = 0; y < imgHeight; ++y) {
      
      float phi = gradientAngles[x][y];
      edited.pixels[y*imgWidth + x] = color(constrain(gradientIntensity[x][y], 0, 255));
      //edited.pixels[y*imgWidth + x] = rainbow((phi + PI) / TWO_PI, gradientIntensity[x][y] / 255);
    }
  }
  edited.updatePixels();  
  println("finish");
  println();
}


final float SIN_EIGHTH_PI = sin(PI / 8);

void thinEdges(int[][] gradientX, int[][] gradientY, int[][] gradientIntensity) {
  Set<int[]> thinnedOuts = new HashSet<int[]>();
  
  for (int x = 1; x < gradientIntensity.length - 1; ++x) {
    for (int y = 1; y < gradientIntensity[0].length - 1; ++y) {
      
      //make the edge direction in coordinate for point on one the surrounding 8 points
      int dx = constrain((int) (gradientX[x][y] / SIN_EIGHTH_PI), -1, 1);
      int dy = constrain((int) (gradientY[x][y] / SIN_EIGHTH_PI), -1, 1);
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

List<PVector> edgePixels = new LinkedList<PVector>();

void threshold(int[][] gradientIntensity, int low, int high) {
  for (int x = 1; x < gradientIntensity.length - 1; ++x) {
    for (int y = 1; y < gradientIntensity[0].length - 1; ++y) {
      float intensity = gradientIntensity[x][y];
      
      if (intensity >= high) {
        gradientIntensity[x][y] = 255;
          edgePixels.add(new PVector(x, y));
      }else {
        gradientIntensity[x][y] = intensity > low ? 128 : 0;
      }
    }
  }
}

void hysteresis(int[][] gradientIntensity) {
  for (int x = 1; x < gradientIntensity.length - 1; ++x) {
    for (int y = 1; y < gradientIntensity[0].length - 1; ++y) {
      
      if (gradientIntensity[x][y] != 128) {
        continue;
      }
      if ((gradientIntensity[x-1][y] == 255 && gradientIntensity[x+1][y] == 255) ||
          (gradientIntensity[x][y-1] == 255 && gradientIntensity[x][y+1] == 255)) {
            gradientIntensity[x][y] = 255;
            edgePixels.add(new PVector(x, y));
      }else {
        gradientIntensity[x][y] = 0;
      }
    }
  }
}

//List<List> contours = new LinkedList<Contour>();

void findContours(int[][] gradientIntensity) {
  
  if (edgePixels.isEmpty()) {
    return;
  }
  //while (!edges.isEmpty()) {
    PVector pixel = edgePixels.remove(0);
    List<PVector> contour = new LinkedList<PVector>();
    contour.add(pixel);
    
    List<PVector> edgeNeighbors = new LinkedList<PVector>();
    edgeNeighbors.add(pixel);
    
    while (!edgeNeighbors.isEmpty()) {
      PVector next = edgeNeighbors.remove(0);
      
      for (int dx = -1; dx <= 1; ++dx) {
        for (int dy = -1; dy <= 1; ++dy) {
          
          if (dx == 0 && dy == 0) {
            continue; 
          }
          PVector neighbor = next.copy().add(dx, dy);
          
          if (gradientIntensity[(int) neighbor.x][(int) neighbor.y] == 255 && !contour.contains(neighbor)) {
             edgePixels.remove(neighbor);
             contour.add(neighbor);
             edgeNeighbors.add(neighbor);
             edited.set((int) neighbor.x, (int) neighbor.y, color(255, 0, 0));
          }
        }
      }
    }
    println("contour " + contour.size());
  //}
}


boolean displaySource = true;
PVector shift = new PVector();
float zoom = 0;

void draw() {
  background(196);
  findContours(gradientIntensity);
  
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
