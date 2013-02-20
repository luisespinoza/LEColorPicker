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

+ (NSArray*)arrayOfColorPixelsFromImage:(UIImage*)image
                          atX:(int)xx
                         andY:(int)yy
                        count:(int)count;

+ (UIImage *)imageWithImage:(UIImage *)image
               scaledToSize:(CGSize)newSize;

- (UIImage *)crop:(CGRect)rect;
@end

