//
//  LEColorPickerGPU.h
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 30-01-13.
//  Copyright (c) 2013 LuisEspinoza. All rights reserved.
//

#import "LEColorPicker.h"
#import <GLKit/GLKit.h>

@interface LEColorPickerGPU : LEColorPicker
{
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _program;
}

@property (strong, nonatomic) EAGLContext *context;


@end
