//
//  LEColorPicker.m
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 10-12-12.
//  Copyright (c) 2012 Luis Espinoza. All rights reserved.
//

#import "LEColorPicker.h"
#import "UIImage+LEColorPicker.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation LEColorPicker

#pragma mark - C Code

#define LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE                   36
#define LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH           3*(LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE)
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_VERTEX_POSITIONS,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    NUM_ATTRIBUTES
};

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

void printVertexArray(CGFloat vertex[LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH])
{
    for (NSUInteger i=0; i<LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*2; i+=3) {
        printf("Vertex number:%d Y:%f U:%f V:%f \n",i,vertex[i],vertex[i+1],vertex[i+2]);
    }
}

#pragma mark - Obj-C code

- (id)init
{
    self = [super init];
    if (self) {
        //Do something?
        taskQueue = dispatch_queue_create("ColorPickerQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)pickColorsFromImage:(UIImage *)image
                 onComplete:(void (^)(LEColorScheme *colorsPickedDictionary))completeBlock
{
    dispatch_async(taskQueue, ^{
        NSDate *startDate = [NSDate date];
        LEColorScheme *colorScheme = [self colorSchemeFromImage:image];
        
        NSDate *endDate = [NSDate date];
        NSTimeInterval timeDifference = [endDate timeIntervalSinceDate:startDate];
        double timePassed_ms = timeDifference * -1000.0;
        
        LELog(@"Computation time: %f", timePassed_ms);
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(colorScheme);
        });
    });
}

- (LEColorScheme*)colorSchemeFromImage:(UIImage*)inputImage
{
    //1 Scale and crop Image
    //First scale a generate pixel array
    UIImage *scaledImage = [LEColorPicker scaleImage:inputImage
                                               width:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                              height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    UIImage *croppedImage = [scaledImage crop:CGRectMake(0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE/2, 2)];
    //[UIImagePNGRepresentation(croppedImage) writeToFile:@"/Users/Luis/croppedImage.png" atomically:YES];
    
    //2 Get core graphics image reference
    CGImageRef inputTextureImage = croppedImage.CGImage;
    size_t width = CGImageGetWidth(inputTextureImage);
    size_t height = CGImageGetHeight(inputTextureImage);
    
    GLubyte *inputTextureData = (GLubyte*)calloc(width*height*4, sizeof(GLubyte));
    CGContextRef inputTextureContext = CGBitmapContextCreate(inputTextureData, width, height, 8, width*4, CGImageGetColorSpace(inputTextureImage), kCGImageAlphaPremultipliedLast);
    
    //3 Draw image into the context
    CGContextDrawImage(inputTextureContext, CGRectMake(0, 0, width, height),inputTextureImage);
    CGContextRelease(inputTextureContext);
    
    
    //4 Send the pixel data to OpenGL
    GLuint inputTexName;
    glGenTextures(1, &inputTexName);
    glBindTexture(GL_TEXTURE_2D, inputTexName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, inputTextureData);
    free(inputTextureData);
    
    //Load shaders
    [self setupGL];
    
    
    //Create Vertex array or Vertex Data
    
    return nil;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:_context];
    
    [self loadShaders];
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_vertexArray), _vertexArray, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    //Print the 
    
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
    uniforms[UNIFORM_VERTEX_POSITIONS] = glGetUniformLocation(_program, "otherPositions");
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


+ (UIImage*)scaleImage:(UIImage*)image width:(CGFloat)width height:(CGFloat)height
{
    UIImage *scaledImage =  [UIImage imageWithImage:image scaledToSize:CGSizeMake(width,height)];
    return scaledImage;
}

@end
