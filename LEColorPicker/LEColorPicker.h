//
//  LEColorPicker.h
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 10-12-12.
//  Copyright (c) 2012 Luis Espinoza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>

#import "LEColorScheme.h"

#ifdef DEBUG
#	 define LELog(s,...) NSLog((@"[%s] " s),__func__,## __VA_ARGS__);
#else
#	 define LELog(...) /* */
#endif

@interface LEColorPicker : UIImageView
{
    //GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _colorRenderBuffer;
    GLuint _depthRenderBuffer;
    GLuint _program;
    GLuint _proccesedWidthSlot;
    GLuint _totalWidthSlot;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    GLuint _aTexture;
    GLuint _tolerance;
    GLuint _colorToFilter;
    UIImage *_currentImage;
    CAEAGLLayer* _eaglLayer;
    EAGLContext *_context;
    dispatch_queue_t taskQueue;
    UIImage *savedImage;
}

/**
 This class methods is allow the client to generate three colors from a specific UIImage. The complete
 block recieves as parameter colorsDictionary, wich is the dictionary with the resultant colors.
 
 BackgroundColor : is the key for the background color.
 PrimaryTextColor : is the key for the primary text color.
 SecondaryTextColor : is the key for the secondary text color.
 
 @param image Input image, wich will be used to generate the three colors.
 @param completeBlock Execution block for when the task is complete.
 */
- (void)pickColorsFromImage:(UIImage*)image onComplete:(void (^)(LEColorScheme *colorScheme))completeBlock;

/**
 This class methods allows image scalation.
 
 @param image Source image.
 @param width New width.
 @param height New height.
 @returns A new image like "image" but with width "width" and height "height".
 */
+ (UIImage*)scaleImage:(UIImage*)image width:(CGFloat)width height:(CGFloat)height;

- (void)render;
@end
