//Class:        Introduction to Operating Systems
//Date:         11/16/18

// Base code by Bidur Bohara (LSU) in collaboration with Brygg Ullmer

// Compilation command: nvcc main.cu -o convert

#include <math.h>
#include <stdio.h>

//Declaration of class
class Bitmap
{
public:
    Bitmap();

    unsigned int bmpWidth;
    unsigned int bmpHeight;
    unsigned int bmpSize;

    unsigned char* readGrayBitmap(const char*file);
    void writeGrayBmp(unsigned char* data);

private:
    unsigned char* bmpHeader;
    unsigned int offset;
    unsigned int bitsPerPixel;

};

Bitmap::Bitmap()
{
    bmpWidth = 0;
    bmpHeight = 0;
    bmpSize = 0;
    offset = 0;
    bitsPerPixel = 0;
}

unsigned char* Bitmap::readGrayBitmap(const char *file)
{
    // Open bitmap file to read
    FILE *fp = fopen(file, "rb");
    if(!fp)
    {
        printf("Error! Cannot open input file.\n");
        return 0;
    }

    unsigned int status = 0;
    status = fseek(fp, 10, SEEK_SET); // Seek to width
    status = fread((void*)&offset, sizeof(unsigned int), 1, fp);

    status = fseek(fp, 18, SEEK_SET); // Seek to width
    status = fread((void*)&bmpWidth, sizeof(int), 1, fp);

    status = fseek(fp, 22, SEEK_SET); // Seek to height
    status = fread((void*)&bmpHeight, sizeof(int), 1, fp);

    status = fseek(fp, 28, SEEK_SET); // Seek to bits per pixel
    status = fread((void*)&bitsPerPixel, sizeof(unsigned short), 1, fp);

    status = fseek(fp, 34, SEEK_SET); // Seek to bitmap image size
    status = fread((void*)&bmpSize, sizeof(unsigned int), 1, fp);

    /// Read the Bitmap Header info.
    bmpHeader = new unsigned char[offset];
    status = fseek(fp, 0, SEEK_SET);
    status = fread((void*)bmpHeader, sizeof(unsigned char), offset, fp);

    /// Read the Bitmap image data.
    unsigned char* bmpData = new unsigned char[bmpSize];

    /// Seek to the position of image data.
    status = fseek(fp, offset, SEEK_SET);
    status = fread(bmpData, sizeof(unsigned char), bmpSize, fp);
    //bmpSize = status > 0 ? status : bmpSize;

    if(status){}

    fclose(fp);
    return bmpData;
}

void Bitmap::writeGrayBmp(unsigned char* data)
{
    FILE *wp = fopen("1.bmp", "wb");

    if(!data)
        printf("No data to be written!!!");

    unsigned int status = 0;

    status = fwrite((const void*)bmpHeader, sizeof(unsigned char),
                    offset, wp);
    status = fwrite((const void*)data, sizeof(unsigned char), bmpSize, wp);

    if(status){}

    fclose(wp);
}

/// Function that implements broken Sobel operator.
/// Returns image data after applying Sobel operator to the original image. Modified to function on a GPU.

__global__ void findEdge(const unsigned int w,
         const unsigned int h, const int threads, unsigned char* inData, unsigned char* image_sobeled)
{
    int gradient_X = 0;
    int gradient_Y = 0;
    int value = 0;

    int sobel_x[3][3] = { { 1, 0,-1},
                        { 2, 0,-2},
                        { 1, 0,-1}};

    int sobel_y[3][3] = { { 1, 2, 1},
                        { 0, 0, 0},
                        {-1,-2,-1}};

    int chunksize = ceilf((float)(h/threads));

    // The FOR loop apply Sobel operator
    // to bitmap image data in per-pixel level.
    for(unsigned int y = blockIdx.x*chunksize+1; y < ((blockIdx.x+1)*chunksize)+1; ++y)
    {
        if(y>=h)
        {

        }
        else
        {
          for(unsigned int x = 1; x < w-1; ++x)
          {
              // Compute gradient in +ve x direction
              gradient_X = sobel_x[0][0] * inData[ (x-1) + (y-1) * w ]
                      + sobel_x[0][1] * inData[  x    + (y-1) * w ]
                      + sobel_x[0][2] * inData[ (x+1) + (y-1) * w ]
                      + sobel_x[1][0] * inData[ (x-1) +  y    * w ]
                      + sobel_x[1][1] * inData[  x    +  y    * w ]
                      + sobel_x[1][2] * inData[ (x+1) +  y    * w ]
                      + sobel_x[2][0] * inData[ (x-1) + (y+1) * w ]
                      + sobel_x[2][1] * inData[  x    + (y+1) * w ]
                      + sobel_x[2][2] * inData[ (x+1) + (y+1) * w ];

                      // Compute gradient in +ve y direction
                      gradient_Y = sobel_y[0][0] * inData[ (x-1) + (y-1) * w ]
                      + sobel_y[0][1] * inData[  x    + (y-1) * w ]
                      + sobel_y[0][2] * inData[ (x+1) + (y-1) * w ]
                      + sobel_y[1][0] * inData[ (x-1) +  y    * w ]
                      + sobel_y[1][1] * inData[  x    +  y    * w ]
                      + sobel_y[1][2] * inData[ (x+1) +  y    * w ]
                      + sobel_y[2][0] * inData[ (x-1) + (y+1) * w ]
                      + sobel_y[2][1] * inData[  x    + (y+1) * w ]
                      + sobel_y[2][2] * inData[ (x+1) + (y+1) * w ];

                      value = (int)ceilf((sqrtf((float)(gradient_X * gradient_X + gradient_Y * gradient_Y))));

                      if(value>255) value=255;
                      if(value<0) value=0;

                      image_sobeled[ x + y*w ] = 255 - value;
          }
        }
    }
    // Thanks to Thomas Peters.
}

// Creates and runs a specified number of threads inside main function. Workload is divided amongst every GPU thread
int main(int argc, char *argv[])
{
    char* bmpFile; //Name of file to convert
    char* threads;
    int threadCount;

    /// Memory to hold input image data
    unsigned char* inData;
    unsigned char* image_sobeled;

    if( argc < 3) //./convert [FILENAME] [THREADS]
      {
	       printf("Filename and thread count arguments required!\n");
         printf("Usage: ./convert [FILENAME] [THREADS]\n");
	       return 0;
      }
    else
      bmpFile = argv[1]; //Save filename to pointer
      threads = argv[2]; //Save # of threads to spin up

    threadCount = atoi(threads);

    if(threadCount<=0)
    {
      printf("Thread count cannot be 0 or negative!\n");
      return 0;
    }

    /// Open and read bmp file.
    Bitmap *image = new Bitmap(); //Initialize Bitmap object
    unsigned char*data = image->readGrayBitmap(bmpFile); //Use member method to read

    //Allocate CUDA Unified Memory to allow CPU and GPU to access same memory space
    cudaMallocManaged(&image_sobeled, image->bmpSize*sizeof(unsigned char));
    cudaMallocManaged(&inData, image->bmpSize*sizeof(unsigned char));

    //Allocation done, initialize
    for(int i = 0; i < image->bmpSize; i++)
    {
      image_sobeled[i] = 255; //Refactoring vector initialization
    }

    for(int n = 0; n < image->bmpSize; n++)
    {
      inData[n] = data[n];
    }

    //Execute CUDA kernel for specified number of threads
    findEdge<<<threadCount, 1>>>(image->bmpWidth, image->bmpHeight, threadCount, inData, image_sobeled);//Apply Sobel

    //Check for any errors thrown by the kernel
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess)
    {
    printf("Error: %s\n", cudaGetErrorString(err));
    }

    cudaDeviceSynchronize();//Wait for GPU's to finish processing

    printf("Threads done!\n");

    /// Write image data passed as argument to a bitmap file
    image->writeGrayBmp(&image_sobeled[0]);

    //Clean up
    cudaFree(image_sobeled);
    cudaFree(inData);
    delete data;

    return 0;
}