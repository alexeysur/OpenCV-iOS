//
//  OpenCVWrapper.m
//  CustomCamera
//
//  Created by Alexey on 05.04.2023.
//  Copyright © 2023 ca.alexs. All rights reserved.
//
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#include <opencv2/imgproc.hpp>

#import "OpenCVWrapper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//using namespace cv;

@implementation OpenCVWrapper

- (void) isThisWorking {
    std::cout << "Hey" << std::endl;
}

-(UIImage *) checkForBlurryImage:(UIImage *) image {
    cv::Mat src, src_gauss, src_gray, dst;
    int kernel_size = 3;
    int scale = 1;
    int delta = 0;
    int ddepth = CV_16S;
    
    //UIImageToMat(image, src);
    cv::Mat matImage = [self convertUIImageToCVMat:image];
    
    // Reduce noise by blurring with a Gaussian filter ( kernel size = 3 )
    cv::GaussianBlur(src, src_gauss, cv::Size(3, 3), 0, 0, cv::BORDER_DEFAULT);
    cv::Mat abs_dst;
    cv::cvtColor( src, src_gray, cv::COLOR_BGR2GRAY); // Convert the image to grayscale
    cv::Laplacian(src_gray, dst, ddepth, kernel_size, scale, delta, cv::BORDER_DEFAULT);
       // converting back to CV_8U
    cv::convertScaleAbs(dst, abs_dst);
    UIImage *finalImage = [self UIImageFromCVMat:abs_dst];
    return finalImage;
  
    
    /*
    cv::Mat matImage;// = [self convertUIImageToCVMat:image];
    UIImageToMat(image, matImage);
    
    cv::Mat finalImage;
    cv::Mat matImageGrey;
    cv::cvtColor(matImage, matImageGrey, cv::COLOR_BGR2GRAY);
    matImage.release();
    cv::Mat newEX;
    const int MEDIAN_BLUR_FILTER_SIZE = 15; // odd number
    cv::medianBlur(matImageGrey, newEX, MEDIAN_BLUR_FILTER_SIZE);
    matImageGrey.release();
    cv::Mat laplacianImage;
    cv::Laplacian(newEX, laplacianImage, CV_8U); // CV_8U
    newEX.release();
    cv::Mat laplacianImage8bit;
    laplacianImage.convertTo(laplacianImage8bit, CV_8UC1);
    laplacianImage.release();
    cv::cvtColor(laplacianImage8bit,finalImage,CV_GRAY2BGRA);
    laplacianImage8bit.release();
    int rows = finalImage.rows;
    int cols= finalImage.cols;
    char *pixels = reinterpret_cast<char *>( finalImage.data);
    finalImage.release();
    int maxLap = -16777216;
    for (int i = 0; i < (rows*cols); i++) {
        if (pixels[i] > maxLap) {  maxLap = pixels[i]; }
    }
    int soglia = -6118750;
    printf("\n maxLap : %i",maxLap);
    if (maxLap < soglia || maxLap == soglia) {
        printf("\n\n***** blur image *****");
    } else {
        printf("\nNOT a blur image");
    }
    
    int kBlurThreshhold = 200;
    pixels = NULL;
    BOOL isBlur = (maxLap < kBlurThreshhold)?  YES :  NO;
    return isBlur;
*/
}


- (BOOL) isImageBlurry:(UIImage *) image {
    // converting UIImage to OpenCV format - Mat
    cv::Mat matImage = [self convertUIImageToCVMat:image];
    cv::Mat matImageGrey;
    // converting image's color space (RGB) to grayscale
    cv::cvtColor(matImage, matImageGrey, CV_BGR2GRAY);

    cv::Mat dst2 = [self convertUIImageToCVMat:image];
    cv::Mat laplacianImage;
    dst2.convertTo(laplacianImage, CV_8UC1);

    // applying Laplacian operator to the image
    cv::Laplacian(matImageGrey, laplacianImage, CV_8U);
    cv::Mat laplacianImage8bit;
    laplacianImage.convertTo(laplacianImage8bit, CV_8UC1);

    unsigned char *pixels = laplacianImage8bit.data;

    // 16777216 = 256*256*256
    int maxLap = -16777216;
    for (int i = 0; i < ( laplacianImage8bit.elemSize()*laplacianImage8bit.total()); i++) {
        if (pixels[i] > maxLap) {
            maxLap = pixels[i];
        }
    }
    std::cout << "maxLap = " << maxLap << std::endl;
    
    // one of the main parameters here: threshold sets the sensitivity for the blur check
    // smaller number = less sensitive; default = 180
    int threshold = 180;

    return (maxLap <= threshold);
}

- (cv::Mat)convertUIImageToCVMat:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);

    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;
  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8,                                          //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                     kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                     provider,                                   //CGDataProviderRef
                                     NULL,                                       //decode
                                     false,                                      //should interpolate
                                     kCGRenderingIntentDefault                   //intent
                                     );
  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  return finalImage;
 }


@end
