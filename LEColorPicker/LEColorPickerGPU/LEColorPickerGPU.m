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
    GPUImageHistogramFilter *filter = [[GPUImageHistogramFilter alloc] initWithHistogramType:kGPUImageHistogramLuminance];
    
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    //[videoCamera addTarget:gammaFilter];
    [gammaFilter addTarget:filter];
    
    GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
    
    [histogramGraph forceProcessingAtSize:CGSizeMake(image.size.width, image.size.height)];
    [filter addTarget:histogramGraph];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 0.75;
    [blendFilter forceProcessingAtSize:CGSizeMake(image.size.width, image.size.height)];
    
    //[videoCamera addTarget:blendFilter];
    [histogramGraph addTarget:blendFilter];
    
    UIImage *filteredImage = [histogramGraph imageByFilteringImage:image];
    
    //[UIImagePNGRepresentation(filteredImage) writeToFile:@"/Users/Luis/histogram.png" atomically:YES];
    
    return nil;
}
@end
