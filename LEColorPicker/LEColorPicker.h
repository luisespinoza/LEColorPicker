//
//  LEColorPicker.h
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 10-12-12.
//  Copyright (c) 2012 Luis Espinoza. All rights reserved.
//

@import Foundation;
@import GLKit;
@import QuartzCore;

NS_ASSUME_NONNULL_BEGIN

@interface LEColorScheme : NSObject

@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic, nullable) UIColor *primaryTextColor;
@property (nonatomic, nullable) UIColor *secondaryTextColor;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface LEColorPicker : NSObject {
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
    UIImage *_Nullable _currentImage;
    EAGLContext *_Nullable _context;
}

/**
 This instance method allows the client object to generate three colors from a specific UIImage. This method generate synchronously colors for background, primary and secondary colors, encapsulated in a LEColorScheme object.

 @param image Input image, wich will be used to generate the three colors.
 @returns LEColorScheme with three output colors.
 */
- (nullable LEColorScheme *)colorSchemeFromImage:(UIImage *)image;

/**
 This instance method allows the client object to generate three colors from a specific UIImage. The complete
 block recieves as parameter a LEColorScheme wich is the object that encapsulates the output colors.

 @param image Input image, which will be used to generate the three colors.
 @param completeBlock Execution block for when the task is complete.
 */
- (void)pickColorsFromImage:(UIImage *)image onComplete:(void (^)(LEColorScheme *_Nullable colorScheme))completeBlock;

@end

NS_ASSUME_NONNULL_END
