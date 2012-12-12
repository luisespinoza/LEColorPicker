//
//  UIImage+LEColorPicker.h
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 04-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LEColorPicker)

+ (NSArray*)dominantsColorsFromImage:(UIImage*)image
                           threshold:(float)threshold
                      numberOfColors:(NSUInteger)numberOfColors;

+ (NSArray*)getRGBAsFromImage:(UIImage*)image
                          atX:(int)xx
                         andY:(int)yy
                        count:(int)count;

@end
