//
//  LEColorPicker.m
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 10-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import "LEColorPicker.h"
#import "UIImage+LEColorPicker.h"
#import "UIColor+YUVSpace.h"

#define LECOLORPICKER_DEFAULT_SCALED_SIZE                               36      //px
#define LECOLORPICKER_DEFAULT_DOMINANTS_TRESHOLD                        0.1     //Distance in YUV Space
#define LECOLORPICKER_DEFAULT_NUM_OF_DOMINANTS                          3
#define LECOLORPICKER_DEFAULT_COLOR_DIFFERENCE                          0.75
#define LECOLORPICKER_DEFAULT_BRIGHTNESS_DIFFERENCE                     0.125

@implementation LEColorPicker

+ (void)pickColorFromImage:(UIImage *)image
                onComplete:(void (^)(NSDictionary *colorsPickedDictionary))completeBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *colorsPickedDictionary = [LEColorPicker dictionaryWithColorsPickedFromImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(colorsPickedDictionary);
        });
    });
}

+ (NSDictionary *)dictionaryWithColorsPickedFromImage:(UIImage *)image
{
    UIColor *backgroundColor;
    UIColor *primaryTextColor;
    UIColor *secondaryTextColor;
    NSDate *startDate = [NSDate date];
    
    NSMutableDictionary *colorsDictionary = [[NSMutableDictionary alloc] init];
    
    //Number of pixels reduction
    UIImage *scaledImage =  [LEColorPicker imageWithImage:image scaledToSize:CGSizeMake(LECOLORPICKER_DEFAULT_SCALED_SIZE,
                                                                                        LECOLORPICKER_DEFAULT_SCALED_SIZE)];
    
    //Get the three more dominants colors
    NSArray *colorSchemeArray =[UIImage dominantsColorsFromImage:scaledImage
                                                       threshold:LECOLORPICKER_DEFAULT_DOMINANTS_TRESHOLD
                                                  numberOfColors:LECOLORPICKER_DEFAULT_NUM_OF_DOMINANTS];
    
    if ([colorSchemeArray count]>=1 ) {
        backgroundColor = [colorSchemeArray objectAtIndex:0];
        NSLog(@"First dominant color : %@",[backgroundColor description]);
        [colorsDictionary setObject:backgroundColor forKey:@"BackgroundColor"];
    }
    
    if ([colorSchemeArray count]>=2 ) {
        primaryTextColor = [colorSchemeArray objectAtIndex:1];
        NSLog(@"Second dominant color : %@",[primaryTextColor description]);
        if ([LEColorPicker isSufficienteContrastBetweenBackground:backgroundColor
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
    
    if ([colorSchemeArray count]>=3 ) {
        secondaryTextColor = [colorSchemeArray objectAtIndex:2];
        NSLog(@"Third dominant color : %@",[secondaryTextColor description]);
        if ([LEColorPicker isSufficienteContrastBetweenBackground:backgroundColor
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
    
    NSDate *endDate = [NSDate date];
    NSTimeInterval timeDifference = [endDate timeIntervalSinceDate:startDate];
    double timePassed_ms = timeDifference * -1000.0;
    NSLog(@"Computation time: %f", timePassed_ms);
    return colorsDictionary;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
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
