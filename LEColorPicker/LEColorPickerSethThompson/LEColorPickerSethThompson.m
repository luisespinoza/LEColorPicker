//
//  LEColorPickerSethThompson.m
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 17-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import "LEColorPickerSethThompson.h"
#import "UIImage+LEColorPicker.h"
#import "UIColor+YUVSpace.h"

#define LECOLORPICKER_SETHTHOMPSON_DEFAULT_SCALED_SIZE                  36
#define LECOLORPICKER_DEFAULT_DOMINANTS_TRESHOLD                        0.1     //Distance in YUV Space
#define LECOLORPICKER_DEFAULT_NUM_OF_DOMINANTS                          3
#define LECOLORPICKER_DEFAULT_COLOR_DIFFERENCE                          0.5
#define LECOLORPICKER_DEFAULT_BRIGHTNESS_DIFFERENCE                     0.125

@implementation LEColorPickerSethThompson
#pragma mark - Template methods

+ (NSDictionary*)dictionaryWithColorsPickedFromImage:(UIImage *)image
{
    UIImage *scaledImage = [self scaleImage:image
                                      width:LECOLORPICKER_SETHTHOMPSON_DEFAULT_SCALED_SIZE
                                     height:LECOLORPICKER_SETHTHOMPSON_DEFAULT_SCALED_SIZE];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    UIImage *croppedImage = [scaledImage crop:CGRectMake(0, 0, LECOLORPICKER_SETHTHOMPSON_DEFAULT_SCALED_SIZE/2, 2)];
    //[UIImagePNGRepresentation(croppedImage) writeToFile:@"/Users/Luis/croppedImage.png" atomically:YES];
    
    NSArray *pixelArray = [UIImage arrayOfColorPixelsFromImage:croppedImage
                                                 atX:0
                                                andY:0
                                               count:(LECOLORPICKER_SETHTHOMPSON_DEFAULT_SCALED_SIZE*2)];
    NSArray *backgroundArray = [self quantizePixelArray:pixelArray
                                      distanceThreshold:LECOLORPICKER_DEFAULT_DOMINANTS_TRESHOLD
                                       numberOfQuantums:1];
    
    NSMutableArray *colorsMutableArray = [[NSMutableArray alloc] init];
    [colorsMutableArray addObject:[backgroundArray objectAtIndex:0]];
    
    pixelArray = [UIImage arrayOfColorPixelsFromImage:scaledImage
                                        atX:0
                                       andY:0
                                      count:(LECOLORPICKER_SETHTHOMPSON_DEFAULT_SCALED_SIZE*LECOLORPICKER_SETHTHOMPSON_DEFAULT_SCALED_SIZE)];
    
    
    NSArray *filteredPixelArray = [self filterColor:[backgroundArray objectAtIndex:0]
                                     fromPixelArray:pixelArray threshold:0.3];
    
    NSArray *textColors = [self quantizePixelArray:filteredPixelArray
                                 distanceThreshold:LECOLORPICKER_DEFAULT_DOMINANTS_TRESHOLD
                                  numberOfQuantums:2];
    
    [colorsMutableArray addObjectsFromArray:textColors];
    
    return [self testAndRepairColors:colorsMutableArray];
}

#pragma mark Internal methods
+ (NSDictionary*)testAndRepairColors:(NSArray*)colorsArray
{
    UIColor *backgroundColor;
    UIColor *primaryTextColor;
    UIColor *secondaryTextColor;
    
    NSMutableDictionary *colorsDictionary = [[NSMutableDictionary alloc] init];
    
    if ([colorsArray count]>=1 ) {
        backgroundColor = [colorsArray objectAtIndex:0];
        NSLog(@"First dominant color : %@",[backgroundColor description]);
        [colorsDictionary setObject:backgroundColor forKey:@"BackgroundColor"];
    }
    
    if ([colorsArray count]>=2 ) {
        primaryTextColor = [colorsArray objectAtIndex:1];
        NSLog(@"Second dominant color : %@",[primaryTextColor description]);
        if ([self isSufficienteContrastBetweenBackground:backgroundColor
                                            andForground:primaryTextColor]) {
            [colorsDictionary setObject:primaryTextColor forKey:@"PrimaryTextColor"];
        } else {
            NSLog(@"No enough contrast!");
            if ([UIColor yComponentFromColor:backgroundColor] < 0.5) {
                [colorsDictionary setObject:[UIColor whiteColor] forKey:@"PrimaryTextColor"];
            } else {
                [colorsDictionary setObject:[UIColor blackColor] forKey:@"PrimaryTextColor"];
            }
        }
    } else {
        NSLog(@"No dominant!");
        if ([UIColor yComponentFromColor:backgroundColor] < 0.5) {
            [colorsDictionary setObject:[UIColor whiteColor] forKey:@"PrimaryTextColor"];
        } else {
            [colorsDictionary setObject:[UIColor blackColor] forKey:@"PrimaryTextColor"];
        }
    }
    
    if ([colorsArray count]>=3 ) {
        secondaryTextColor = [colorsArray objectAtIndex:2];
        NSLog(@"Third dominant color : %@",[secondaryTextColor description]);
        if ([self isSufficienteContrastBetweenBackground:backgroundColor
                                            andForground:secondaryTextColor]) {
            [colorsDictionary setObject:secondaryTextColor forKey:@"SecondaryTextColor"];
        } else {
            NSLog(@"No enough contrast!");
            if ([UIColor yComponentFromColor:backgroundColor] < 0.5) {
                [colorsDictionary setObject:[UIColor whiteColor] forKey:@"SecondaryTextColor"];
            } else {
                [colorsDictionary setObject:[UIColor blackColor] forKey:@"SecondaryTextColor"];
            }
        }
    } else {
        NSLog(@"No dominant!");
        if ([UIColor yComponentFromColor:backgroundColor] < 0.5) {
            [colorsDictionary setObject:[UIColor whiteColor] forKey:@"SecondaryTextColor"];
        } else {
            [colorsDictionary setObject:[UIColor blackColor] forKey:@"SecondaryTextColor"];
        }
    }
    
    return colorsDictionary;
}

+ (NSArray*)quantizePixelArray:(NSArray*)pixelArray
             distanceThreshold:(float)distanceThreshold
              numberOfQuantums:(NSUInteger)numberOfQuantuns
{
    NSArray *buckets;
    NSArray *sortedBuckets;
    UIColor *dominantColor;
    
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    
    for (NSUInteger i=0; i<numberOfQuantuns; i++) {
        @autoreleasepool {
            //Pick most dominant color
            if (i!=0){
                pixelArray = [self filterColor:dominantColor fromPixelArray:pixelArray threshold:0.3];
            }
            //NSLog(@"PixelArray = \n %@",[pixelArray description]);
            
            buckets = [self gather:pixelArray forThreshold:distanceThreshold];
            //NSLog(@"Buckets = \n %@",[buckets description]);
            
            sortedBuckets = [self sortedBucketsFromArray:buckets
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

+ (BOOL)isSufficienteContrastBetweenBackground:(UIColor*)backgroundColor andForground:(UIColor*)foregroundColor
{
    float backgroundColorBrightness = [UIColor yComponentFromColor:backgroundColor];
    float foregroundColorBrightness = [UIColor yComponentFromColor:foregroundColor];
    float brightnessDifference = fabsf(backgroundColorBrightness-foregroundColorBrightness);
    
    if (brightnessDifference>=LECOLORPICKER_DEFAULT_BRIGHTNESS_DIFFERENCE) {
        float backgroundRed = 0.0;
        float backgroundGreen = 0.0;
        float backgroundBlue = 0.0;
        float foregroundRed = 0.0;
        float foregroundGreen = 0.0;
        float foregroundBlue = 0.0;
        
        int numComponents = CGColorGetNumberOfComponents(backgroundColor.CGColor);
        
        if (numComponents == 4) {
            const CGFloat *components = CGColorGetComponents(backgroundColor.CGColor);
            backgroundRed = components[0];
            backgroundGreen = components[1];
            backgroundBlue = components[2];
        }
        
        numComponents = CGColorGetNumberOfComponents(foregroundColor.CGColor);
        
        if (numComponents == 4) {
            const CGFloat *components = CGColorGetComponents(foregroundColor.CGColor);
            foregroundRed = components[0];
            foregroundGreen = components[1];
            foregroundBlue = components[2];
        }
        
        //Compute "Color Diference"
        float colorDifference = (MAX(backgroundRed,foregroundRed)-MIN(backgroundRed, foregroundRed)) +
        (MAX(backgroundGreen,foregroundGreen)-MIN(backgroundGreen, foregroundGreen)) +
        (MAX(backgroundBlue,foregroundBlue)-MIN(backgroundBlue, foregroundBlue));
        if (colorDifference>LECOLORPICKER_DEFAULT_COLOR_DIFFERENCE) {
            return YES;
        }
    }
    
    return NO;
}
@end
