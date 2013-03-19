//
//  LEColorPickerGPU.m
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 30-01-13.
//  Copyright (c) 2013 LuisEspinoza. All rights reserved.
//

#import "LEColorPickerGPU.h"
#import "UIImage+LEColorPicker.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>


#define LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE                   36
#define LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH           3*(LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE)

#pragma mark - C Code

GLfloat yComponentFromColor(GLfloat red, GLfloat green, GLfloat blue)
{
    GLfloat y = 0.299*red + 0.587*green+ 0.114*blue;
    return y;
}

GLfloat uComponentFromColor(GLfloat red, GLfloat green, GLfloat blue)
{
    GLfloat u = (-0.14713)*red + (-0.28886)*green + (0.436)*blue;
    return u;
}

GLfloat vComponentFromColor(GLfloat red, GLfloat green, GLfloat blue)
{
    
    GLfloat v = 0.615*red + (-0.51499)*green + (-0.10001)*blue;
    return v;
}

void arrayOfColorVertexesFromImage(UIImage *image,
                                   NSUInteger xx,
                                   NSUInteger yy,
                                   CGFloat resultArray[LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH])
{
    // First put image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
    for (int i = 0 ; i < LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH ; i+=3)
    {
        GLfloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        GLfloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        GLfloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        //CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        
        resultArray[i]      = yComponentFromColor(red, blue, green);
        resultArray[i+1]    = uComponentFromColor(red, blue, green);
        resultArray[i+2]    = vComponentFromColor(red, blue, green);
    }
    
    free(rawData);
}

//GLfloat randomFloat(float upperLimit, float lowerLimit) {
//    float diff = upperLimit - lowerLimit;
//    return (((GLfloat) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + lowerLimit;
//}

//void populateArrayOfRandomColors(NSUInteger count, CGFloat resultArray[256][3])
//{
//    for (int ii = 0 ; ii < count ; ++ii)
//    {
//        CGFloat red   = randomFloat(0, 1);
//        CGFloat green = randomFloat(0, 1);
//        CGFloat blue  = randomFloat(0, 1);
//        //CGFloat alpha = randomFloat(0, 1);;
//
//        resultArray[ii][0] = red;
//        resultArray[ii][1] = green;
//        resultArray[ii][2] = blue;
//    }
//}

void printVertexArray(CGFloat vertex[LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH])
{
    for (NSUInteger i=0; i<LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2; i+=3) {
        printf("Vertex number:%d R:%f G:%f B:%f \n",i,vertex[i],vertex[i+1],vertex[i+2]);
    }
}

//void printColorArray(CGFloat colorArray[256][3])
//{
//    for (NSUInteger i=0; i<256; i++) {
//        printf("Color number:%d R:%f G:%f B:%f \n",i,colorArray[i][0],colorArray[i][1],colorArray[i][2]);
//    }
//}

#pragma mark - Obj-C code

@implementation LEColorPickerGPU

- (NSDictionary*)dictionaryWithColorsPickedFromImage:(UIImage *)image
{
    //First scale a generate pixel array
    UIImage *scaledImage = [LEColorPicker scaleImage:image
                                               width:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                              height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    UIImage *croppedImage = [scaledImage crop:CGRectMake(0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE/2, 2)];
    //[UIImagePNGRepresentation(croppedImage) writeToFile:@"/Users/Luis/croppedImage.png" atomically:YES];
    
    //vertexArray = training vectors
    GLfloat vertexArray[LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH];
    arrayOfColorVertexesFromImage(croppedImage, 0, 0, vertexArray);
    printVertexArray(vertexArray);
    
    //Create opengl es texture
    [self setupGL];
    
    
    //Create Vertex array or Vertex Data
    
    return nil;
}

#pragma mark - OpenGL Methods
- (void)setupGL
{/*
    [EAGLContext setCurrentContext:self.context];
    
    GLfloat triangle[18] = {     // Data layout for each line below is:
        // positionX, positionY, positionZ,     normalX, normalY, normalZ,
        0.0f, 0.0f, -0.0f,        0.0f, 0.0f, 1.0f,
        0.5f, 0.0f, -0.0f,         0.0f, 0.0f, 1.0f,
        0.0f, 0.5f, 0.0f,         0.0f, 0.0f, 1.0f,};
    
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(triangle), triangle, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
  */
}


#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    //uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    //uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void)prepareLightShader
{
    
}
@end
