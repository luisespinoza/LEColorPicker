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

#define LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE                   32
#define LECOLORPICKER_GPU_DEFAULT_VERTEX_ARRAY_LENGTH           3*(LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE*LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE)
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_VERTEX_POSITIONS,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Add texture coordinates to Vertex structure as follows
typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2]; // New
} Vertex;

#define TEX_COORD_MAX   1

// Add texture coordinates to Vertices as follows
const Vertex Vertices[] = {
    // Front
    {{1, -1, 0}, {1, 0, 0, 1}, {TEX_COORD_MAX, 0}},
    {{1, 1, 0}, {0, 1, 0, 1}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{-1, 1, 0}, {0, 0, 1, 1}, {0, TEX_COORD_MAX}},
    {{-1, -1, 0}, {0, 0, 0, 1}, {0, 0}},
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
};

void freeImageData(void *info, const void *data, size_t size)
{
    //printf("freeImageData called");
    free((void*)data);
}

#pragma mark - Obj-C interface methods

- (id)init
{
    self = [super init];
    if (self) {
        //Do something?
        taskQueue = dispatch_queue_create("ColorPickerQueue", DISPATCH_QUEUE_SERIAL);
        self.frame = CGRectMake(0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE);
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
            self.image = savedImage;
            completeBlock(colorScheme);
        });
    });
}

- (LEColorScheme*)colorSchemeFromImage:(UIImage*)inputImage
{
    //1. First, we scale the input image, to get a constant image size.
    UIImage *scaledImage = [LEColorPicker scaleImage:inputImage
                                               width:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                              height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    //UIImage *croppedImage = [scaledImage crop:CGRectMake(0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE/2, 2)];
    [UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/Input.png" atomically:YES];
    
    //2. Then, we set the initial openGL ES 2.0 state.
    [self setupOpenGL];
    _aTexture = [self setupTextureFromImage:scaledImage];
    
    //3. Now that all is ready, proceed we the first render, to find the dominant color
    [self render];
    
    //Save output png file
    //[UIImagePNGRepresentation([self dumpImageWithWidth:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
    //                                        height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE])
    // writeToFile:@"/Users/Luis/Output.png"
    // atomically:YES];
    
    LEColorScheme *colorScheme = [[LEColorScheme alloc] init];
    UIColor *backgroundColor=nil;
    //Create Vertex array or Vertex Data
    //dispatch_async(dispatch_get_main_queue(), ^{
        savedImage = [self dumpImageWithWidth:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                       height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                      biggestAlphaColorReturn:&backgroundColor];
    colorScheme.backgroundColor = backgroundColor;
    //});
    return colorScheme;
}

#pragma mark - OpenGL ES 2 custom methods

- (void)setupOpenGL
{
    [self setupLayer];
    
    [self setupContext];
    
    [self setupRenderBuffer];
    
    [self setupDepthBuffer];
    
    [self setupFrameBuffer];
    
    [self setupOpenGLForDominantColor];
    
    [self setupVBOs];
    
    //[self setupDisplayLink];
}

- (void)render
{
    //start up
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ZERO);
    //glClearColor(0.0, 0.0, 0.0, 1.0);
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //glEnable(GL_DEPTH_TEST);
    glEnable(GL_TEXTURE_2D);
    
    //Setup inputs
    glViewport(0, 0, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));
    
    glUniform1i(_proccesedWidthSlot, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE/2);
    glUniform1i(_totalWidthSlot, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _aTexture);
    glUniform1i(_textureUniform, 0);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;}

- (GLuint)setupTextureFromImage:(UIImage*)image
{
    //2 Get core graphics image reference
    CGImageRef inputTextureImage = image.CGImage;
    
    if (!inputTextureImage) {
        LELog(@"Failed to load image for texture");
        exit(1);
    }
    
    size_t width = CGImageGetWidth(inputTextureImage);
    size_t height = CGImageGetHeight(inputTextureImage);
    
    GLubyte *inputTextureData = (GLubyte*)calloc(width*height*4, sizeof(GLubyte));
    CGColorSpaceRef inputTextureColorSpace = CGImageGetColorSpace(inputTextureImage);
    CGContextRef inputTextureContext = CGBitmapContextCreate(inputTextureData, width, height, 8, width*4, inputTextureColorSpace , kCGImageAlphaPremultipliedLast);
    //3 Draw image into the context
    CGContextDrawImage(inputTextureContext, CGRectMake(0, 0, width, height),inputTextureImage);
    CGContextRelease(inputTextureContext);
    
    
    //4 Send the pixel data to OpenGL
    GLuint inputTexName;
    glGenTextures(1, &inputTexName);
    glBindTexture(GL_TEXTURE_2D, inputTexName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA , width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, inputTextureData);
    free(inputTextureData);
    return inputTexName;
    
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE , LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE);
}

- (void)setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (void)setupVBOs {
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}


- (BOOL)setupOpenGLForDominantColor
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"DominantColorShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"DominantColorShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    //glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    
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
    
    glUseProgram(_program);
    
    //Get attributes locations
    _positionSlot = glGetAttribLocation(_program, "Position");
    _colorSlot = glGetAttribLocation(_program, "SourceColor");
    _texCoordSlot = glGetAttribLocation(_program, "TexCoordIn");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    glEnableVertexAttribArray(_texCoordSlot);
    
    _textureUniform = glGetUniformLocation(_program, "Texture");
    _proccesedWidthSlot = glGetUniformLocation(_program, "ProccesedWidth");
    _totalWidthSlot = glGetUniformLocation(_program, "TotalWidth");
    return YES;
}

- (BOOL)setupOpenGlForColorFiltering
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"ColorFilterShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"ColorFilterShader" ofType:@"fsh"];
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
    glBindAttribLocation(_program, GLKVertexAttribPosition, "Position");
    
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

#pragma mark -  OpenGL ES 2 shader compilation

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

#pragma mark - Convert GL image to UIImage
-(UIImage *)dumpImageWithWidth:(NSUInteger)width height:(NSUInteger)height biggestAlphaColorReturn:(UIColor**)returnColor
{
    GLubyte *buffer = (GLubyte *) malloc(width * height * 4);
    //GLubyte *buffer2 = (GLubyte *) malloc(width * height * 4);
    
    //GLvoid *pixel_data = nil;
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid *)buffer);
    
    /* Find bigger Alpha color*/
    NSUInteger biggerR = 0;
    NSUInteger biggerG = 0;
    NSUInteger biggerB = 0;
    NSUInteger biggerAlpha = 0;
    
    for (NSUInteger y=0; y<(height/2); y++) {
        for (NSUInteger x=0; x<(width/2)*4; x++) {
            //buffer2[y * 4 * width + x] = buffer[(height - y - 1) * width * 4 + x];
           //NSLog(@"x=%d y=%d pixel=%d",x/4,y,buffer[y * 4 * width + x]);
            if ((!((x+1)%4)) && (x>0)) {
                if (buffer[y * 4 * width + x] > biggerAlpha ) {
                    
                    biggerAlpha = buffer[y * 4 * width + x];
                    biggerR = buffer[y * 4 * width + (x-3)];
                    biggerG = buffer[y * 4 * width + (x-2)];
                    biggerB = buffer[y * 4 * width + (x-1)];
            //        NSLog(@"biggerR=%d biggerG=%d biggerB=%d biggerAlpha=%d",biggerR,biggerG,biggerB,biggerAlpha);
                }
            }
        }
    }
    
    *returnColor = [UIColor colorWithRed:biggerR/255.0
                                   green:biggerG/255.0
                                    blue:biggerB/255.0
                                   alpha:1.0];
    
    // make data provider from buffer
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, width * height * 4, freeImageData);
    
    // set up for CGImage creation
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    // Use this to retain alpha
    //CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // make UIImage from CGImage
    UIImage *newUIImage = [UIImage imageWithCGImage:imageRef];
    
    return newUIImage;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

+ (UIImage*)scaleImage:(UIImage*)image width:(CGFloat)width height:(CGFloat)height
{
    UIImage *scaledImage =  [UIImage imageWithImage:image scaledToSize:CGSizeMake(width,height)];
    return scaledImage;
}

@end
