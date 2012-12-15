//
//  LEColorPicker.h
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 10-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LEColorPicker : NSObject

/**
 This class methods is allow the client to generate three colors from a specific UIImage.
 @param image Input image, wich will be used to generate the three colors.
 @returns A NSDictionary with three UIColors, the keys are: "BackgroundColor", "PrimaryTextColor", and 
 "SecondaryTextColor".
 */
+ (NSDictionary*)dictionaryWithColorsPickedFromImage:(UIImage*)image;

/**
 This class methods is allow the client to generate three colors from a specific UIImage. The complete
 block recieves as parameter colorsDictionary, wich is the dictionary with the resultant colors.
 
    BackgroundColor : is the key for the background color.
    PrimaryTextColor : is the key for the primary text color.
    SecondaryTextColor : is the key for the secondary text color.
 
 @param image Input image, wich will be used to generate the three colors.
 @param completeBlock Execution block for when the task is complete.
 */
+ (void)pickColorFromImage:(UIImage*)image
                onComplete:(void (^)(NSDictionary *colorsPickedDictionary))completeBlock;


@end
