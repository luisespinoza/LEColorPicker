//
//  LEColorPickerGPU.m
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 30-01-13.
//  Copyright (c) 2013 LuisEspinoza. All rights reserved.
//

#import "LEColorPickerGPU.h"
#import "UIImage+LEColorPicker.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>


#define LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE                   36

void arrayOfColorVertexesFromImage(UIImage *image, NSUInteger xx, NSUInteger yy, NSUInteger count, CGFloat resultArray[LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2][3])
{
    // First put image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
    for (int ii = 0 ; ii < count ; ++ii)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        //CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        
        resultArray[ii][0] = red;
        resultArray[ii][1] = green;
        resultArray[ii][2] = blue;
    }
    
    free(rawData);
}

CGFloat randomFloat(float smallNumber, float bigNumber) {
    float diff = bigNumber - smallNumber;
    return (((CGFloat) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

void populateArrayOfRandomColors(NSUInteger count, CGFloat resultArray[256][3])
{
    for (int ii = 0 ; ii < count ; ++ii)
    {
        CGFloat red   = randomFloat(0, 1);
        CGFloat green = randomFloat(0, 1);
        CGFloat blue  = randomFloat(0, 1);
        //CGFloat alpha = randomFloat(0, 1);;
        
        resultArray[ii][0] = red;
        resultArray[ii][1] = green;
        resultArray[ii][2] = blue;
    }
}

void printVertexArray(CGFloat vertex[LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2][3])
{
    for (NSUInteger i=0; i<LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2; i++) {
        printf("Vertex number:%d R:%f G:%f B:%f \n",i,vertex[i][0],vertex[i][1],vertex[i][2]);
    }
}

void printColorArray(CGFloat colorArray[256][3])
{
    for (NSUInteger i=0; i<256; i++) {
        printf("Color number:%d R:%f G:%f B:%f \n",i,colorArray[i][0],colorArray[i][1],colorArray[i][2]);
    }
}

@implementation LEColorPickerGPU

+ (NSDictionary*)dictionaryWithColorsPickedFromImage:(UIImage *)image
{
    //First scale a generate pixel array
    UIImage *scaledImage = [self scaleImage:image
                                      width:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                     height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    UIImage *croppedImage = [scaledImage crop:CGRectMake(0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE/2, 2)];
    //[UIImagePNGRepresentation(croppedImage) writeToFile:@"/Users/Luis/croppedImage.png" atomically:YES];
    
    CGFloat vertexArray[LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2][3];
    arrayOfColorVertexesFromImage(croppedImage, 0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2, vertexArray);
    printVertexArray(vertexArray);
    
    CGFloat colorPaletteArray[256][3];
    populateArrayOfRandomColors(256, colorPaletteArray);
    printColorArray(colorPaletteArray);
    
    //Create context
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        return nil;
    }
    
    //Render buffer
    //Create new render buffer object
    GLuint _colorRenderBuffer;
    glGenRenderbuffers(1, &_colorRenderBuffer);
    //Bind it to GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //Allocate renderbuffer storage
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    //Frame buffer
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    //This function attach the previous render buffer to the new frame buffer.
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    
    //Create Vertex array or Vertex Data
    
    return nil;
}

                         

@end
