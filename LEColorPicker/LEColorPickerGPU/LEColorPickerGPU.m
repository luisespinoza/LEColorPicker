//
//  LEColorPickerGPU.m
//  LEColorPickerDemo
//
//  Created by Luis Espinoza on 15-01-13.
//  Copyright (c) 2013 LuisEspinoza. All rights reserved.
//

#import "LEColorPickerGPU.h"
#import "GPUImage.h"

@implementation LEColorPickerGPU

- (NSDictionary*)dictionaryWithColorsPickedFromImage:(UIImage *)image
{
    GPUImageFilter *filter = [[GPUImageHistogramFilter alloc] initWithHistogramType:kGPUImageHistogramRGB];
    UIImage *filteredImage = [filter imageByFilteringImage:image];
    
    [UIImagePNGRepresentation(filteredImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    
    return nil;
}
@end
