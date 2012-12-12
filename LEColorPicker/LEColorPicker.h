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

@end
