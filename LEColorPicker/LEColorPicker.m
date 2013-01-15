//
//  LEColorPicker.m
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 10-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import "LEColorPicker.h"

#define LECOLORPICKER_CONCRETE                  @"LEColorPickerGPU"

@implementation LEColorPicker

+ (LEColorPicker*)colorPicker
{
    return [[NSClassFromString(LECOLORPICKER_CONCRETE) alloc] init];
}

@end
