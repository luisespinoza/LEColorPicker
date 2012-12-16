//
//  LEColorPickerAbstract.m
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 15-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import "LEColorPickerAbstract.h"

@implementation LEColorPickerAbstract

-   (void)pickColorFromImage:(UIImage *)image
                onComplete:(void (^)(NSDictionary *colorsPickedDictionary))completeBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *colorsPickedDictionary = [self dictionaryWithColorsPickedFromImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(colorsPickedDictionary);
        });
    });
}

- (NSDictionary *)dictionaryWithColorsPickedFromImage:(UIImage *)image
{
    NSDate *startDate = [NSDate date];

    //Transform image
    UIImage *transformedImage = [self transformImage:image];
    if (!transformedImage) {
        return nil;
    }
    
    //Quantization
    NSArray *colorQuantumsArray = [self quantizeImage:transformedImage numberOfColors:3];
    if (!colorQuantumsArray) {
        return nil;
    }
    
    //Test colors and repair
    NSDictionary *finalColors = [self testAndRepairColors:colorQuantumsArray];
    if (!finalColors) {
        return nil;
    }
    
    NSDate *endDate = [NSDate date];
    NSTimeInterval timeDifference = [endDate timeIntervalSinceDate:startDate];
    double timePassed_ms = timeDifference * -1000.0;
    NSLog(@"Computation time: %f", timePassed_ms);
    
    return finalColors;
}

- (UIImage*)transformImage:(UIImage*)image
{
    return nil;
}

- (NSArray*)quantizeImage:(UIImage*)image numberOfColors:(NSUInteger)numOfColors
{
    return nil;
}

- (NSDictionary*)testAndRepairColors:(NSArray*)colorsArray
{
    return nil;
}
@end
