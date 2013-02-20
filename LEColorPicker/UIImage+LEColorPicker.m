//
//  UIImage+LEColorPicker.m
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 04-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import "UIImage+LEColorPicker.h"
#import "UIColor+YUVSpace.h"

@implementation UIImage (LEColorPicker)

+ (NSArray *)dominantsColorsFromImage:(UIImage *)image
                            threshold:(float)threshold
                       numberOfColors:(NSUInteger)numberOfColors
{
    NSArray *pixelArray;
    NSArray *buckets;
    NSArray *sortedBuckets;
    UIColor *dominantColor;
    
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    CGFloat count = image.size.width * image.size.height;
    
    for (NSUInteger i=0; i<numberOfColors; i++) {
        @autoreleasepool {
            //Pick most dominant color
            if (i==0) {
                pixelArray = [UIImage arrayOfColorPixelsFromImage:image
                                                              atX:0
                                                             andY:0
                                                            count:(NSUInteger)count];
            } else {
                pixelArray = [self filterColor:dominantColor fromPixelArray:pixelArray threshold:0.3];
            }
            //NSLog(@"PixelArray = \n %@",[pixelArray description]);
            
            buckets = [UIImage gather:pixelArray forThreshold:threshold];
            //NSLog(@"Buckets = \n %@",[buckets description]);
            
            sortedBuckets = [UIImage sortedBucketsFromArray:buckets
                                                     forKey:@"@count"
                                                  ascending:NO];
            //NSLog(@"SortedBuckets = \n %@",[sortedBuckets description]);
            if ([sortedBuckets count]) {
                dominantColor = [[sortedBuckets objectAtIndex:0] objectAtIndex:0];
                [returnArray addObject:dominantColor];
            }
        }
    }
    
    return returnArray;
}

+ (NSArray *)gather:(NSArray*)pixelArray forThreshold:(float)threshold
{
    NSUInteger i = 0;
    NSUInteger j = 0;
    NSMutableArray *finalArray = [[NSMutableArray alloc] init];
    NSMutableArray *auxPixelArray = [[NSMutableArray alloc] initWithArray:pixelArray];
    if ([pixelArray count]) {
        for (i=0; i<[pixelArray count]; i++) {
            UIColor *aColor = [pixelArray objectAtIndex:i];
            NSMutableArray *aArray = [[NSMutableArray alloc] init];
            for (j=0; j<[auxPixelArray count]; j++) {
                @autoreleasepool {
                    UIColor *otherColor = [auxPixelArray objectAtIndex:j];
                    float distance = [UIColor YUVSpaceSquareDistanceToColor:aColor fromColor:otherColor];
                    if (distance<(threshold*threshold)) {
                        [aArray addObject:otherColor];
                    }
                }
            }
            [auxPixelArray removeObjectsInArray:aArray];
            [finalArray addObject:aArray];
        }
    }
    return finalArray;
}

+ (NSArray*)sortedBucketsFromArray:(NSArray*)array forKey:(NSString*)key ascending:(BOOL)ascending
{
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:key
                                                         ascending:ascending];
    NSArray *sds = [NSArray arrayWithObject:sd];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:sds];
    
    return sortedArray;
}

+ (NSArray*)filterColor:(UIColor*)color fromPixelArray:(NSArray*)pixelArray threshold:(float)threshold
{
    NSUInteger i = 0;
    NSMutableArray *filteredArray = [[NSMutableArray alloc] init];
    if ([pixelArray count]) {
        for (i=0; i<[pixelArray count]; i++) {
            @autoreleasepool {
                UIColor *aColor = [pixelArray objectAtIndex:i];
                float distance = [UIColor YUVSpaceSquareDistanceToColor:aColor fromColor:color];
                if (distance>(threshold*threshold)) {
                    [filteredArray addObject:aColor];
                }
            }
        }
    }
    return (NSArray*)filteredArray;
}

//http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics
+ (NSArray*)arrayOfColorPixelsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
    // First get the image into your data buffer
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
        @autoreleasepool {
            CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
            CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
            CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
            CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
            byteIndex += 4;
            
            UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            [result addObject:acolor];
        }
    }
    
    free(rawData);
    
    return result;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

//http://stackoverflow.com/questions/158914/cropping-a-uiimage
- (UIImage *)crop:(CGRect)rect {
    
    rect = CGRectMake(rect.origin.x*self.scale,
                      rect.origin.y*self.scale,
                      rect.size.width*self.scale,
                      rect.size.height*self.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef
                                          scale:self.scale
                                    orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

@end


