//
//  UIColor+ColorScheme.h
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 07-09-13.
//  Copyright (c) 2013 LuisEspinoza. All rights reserved.
//

#import <UIKit/UIKit.h>

// Color Scheme Creation Enum
typedef enum
{
    ColorSchemeAnalagous = 0,
    ColorSchemeMonochromatic,
    ColorSchemeTriad,
    ColorSchemeComplementary,
    ColorSchemeSplitComplements,
} ColorScheme;

@interface UIColor (ColorScheme)

- (NSArray *)colorSchemeOfType:(ColorScheme)type;

- (NSArray *)hsbaArray;

+ (float)hueDifferenceFromColor:(UIColor*)fromColor toColor:(UIColor*)toColor;

@end
