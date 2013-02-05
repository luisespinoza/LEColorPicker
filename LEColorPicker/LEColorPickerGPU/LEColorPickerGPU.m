//
//  LEColorPickerGPU.m
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 30-01-13.
//  Copyright (c) 2013 LuisEspinoza. All rights reserved.
//

#import "LEColorPickerGPU.h"
#import "UIImage+LEColorPicker.h"


#define LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE                   36

@implementation LEColorPickerGPU

+ (NSDictionary*)dictionaryWithColorsPickedFromImage:(UIImage *)image
{
    //First scale a generate pixel array
    UIImage *scaledImage = [self scaleImage:image
                                      width:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                     height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    UIImage *croppedImage = [scaledImage crop:CGRectMake(0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE/2, 2)];
    //[UIImagePNGRepresentation(croppedImage) writeToFile:@"/Users/Luis/croppedImage.png" atomically:YES];
    
    NSArray *pixelArray = [UIImage getRGBAsFromImage:croppedImage
                                                 atX:0
                                                andY:0
                                               count:(LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2)];
    
    
    
    return nil;
}



@end
