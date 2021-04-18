
class Operator {
  
  int[][] kernel;
  int factor;
  int size;  
  int radius;
  
  //create kernel from given verctors
  Operator(int factor, int[]... vectors) {
    this.factor = factor;
    this.size = vectors[0].length;
    this.radius = ceil(size / 2f);
    this.kernel = new int[size][size];
    
    for (int i = 0; i < kernel.length; ++i) {
      kernel[i] = vectors[i];
    }
  }
  
  //create kernel that is horizontally, vertically and diagonally symmetrical
  Operator(int size, int factor, int... values) {
    this.factor = factor;
    this.size = size;
    this.radius = ceil(size / 2f);
    this.kernel = new int[size][size];

    int end = size-1;
    for (int i = 0; i < values.length; ++i) {
      int col = 0;
      int row = 0;
      int rest = i;
      int val = values[i];

      for (int rowSize = radius; rowSize > 0; --rowSize) {
        if (rest < rowSize) {
          break;
        }else {
          ++row;
          ++col; 
          rest -= rowSize;
        }
      }
      row += rest;
      kernel[col][row] = val;
      kernel[end-col][row] = val;
      kernel[end-col][end-row] = val;
      kernel[col][end-row] = val;
      
      if (col != row) {
        kernel[row][col] = val;
        kernel[end-row][col] = val;
        kernel[end-row][end-col] = val;
        kernel[row][end-col] = val;
      }
    }
  }
  
  int[][] apply(int[][] gray) {
    int[][] out = new int[gray.length][gray[0].length];
    
    for (int x = 0; x < gray.length; ++x) {
      for (int y = 0; y < gray[0].length - 1; ++y) {
        out[x][y] = (int) apply(x, y, gray);
      }
    }
    return out;
  }
  
  float apply(int x, int y, int[][] pixels) {
    float value = 0;
    
    for(int dx = -size/2; dx <= size/2; ++dx) {
      for(int dy = -size/2; dy <= size/2; ++dy) {
        int newX = x + dx;
        int newY = y + dy;
        
        //retuns zero if too close to border to apply kernel
        if (newX < 0 || newX >= pixels.length || newY < 0 || newY >= pixels[0].length) {
           return kernel[size/2][size/2] * pixels[x][y];
        }
        value += kernel[dx + size/2][dy + size/2] * pixels[newX][newY];
      }
    }
    return 1f / factor * value;
  }
}
