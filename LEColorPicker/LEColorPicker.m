//
//  LEColorPicker.m
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 10-12-12.
//  Copyright (c) 2012 Luis Espinoza. All rights reserved.
//

#import "LEColorPicker.h"
#import "UIImage+LEColorPicker.h"
#import "UIColor+YUVSpace.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation LEColorScheme
@end

@implementation LEColorPicker

#pragma mark - Preprocessor definitions
#define LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE                           32
#define LECOLORPICKER_BACKGROUND_FILTER_TOLERANCE                       0.5
#define LECOLORPICKER_PRIMARY_TEXT_FILTER_TOLERANCE                     0.3
#define LECOLORPICKER_DEFAULT_COLOR_DIFFERENCE                          500
#define LECOLORPICKER_DEFAULT_BRIGHTNESS_DIFFERENCE                     125//125*1

#pragma mark - C structures and constants
// Vertex structure
typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2]; 
} Vertex;

// LEColor structure
typedef struct {
    unsigned int red;
    unsigned int green;
    unsigned int blue;
} LEColor;

// Add texture coordinates to Vertices as follows
const Vertex Vertices[] = {
    // Front
    {{1, -1, 0}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, 0}, {0, 1, 0, 1}, {1, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}, {0, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}, {0, 0}},
};

// Triangles coordinates
const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
};

#pragma mark - C internal functions
/**
 Function for free output buffer data.
 **/
void freeImageData(void *info, const void *data, size_t size)
{
    //printf("freeImageData called");
    free((void*)data);
}

/**
 Function for calculating the square euclidian distance between 2 RGB colors in RGB space.
 @param colorA A RGB color.
 @param colorB Another RGB color.
 @return The square of euclidian distance in RGB space.
 */
unsigned int squareDistanceInRGBSpaceBetweenColor(LEColor colorA, LEColor colorB)
{
    NSUInteger squareDistance = ((colorA.red - colorB.red)*(colorA.red - colorB.red))+
    ((colorA.green - colorB.green) * (colorA.green - colorB.green))+
    ((colorA.blue - colorB.blue) * (colorA.blue - colorB.blue));
    return squareDistance;
}

#pragma mark - Obj-C interface methods

- (id)init
{
    self = [super init];
    if (self) {
        //Create queue and set working flag initial state
        taskQueue = dispatch_queue_create("ColorPickerQueue", DISPATCH_QUEUE_SERIAL);
        _isWorking = NO;
    }
    return self;
}


- (void)pickColorsFromImage:(UIImage *)image
                 onComplete:(void (^)(LEColorScheme *colorsPickedDictionary))completeBlock
{
    if (!_isWorking) {
        dispatch_async(taskQueue, ^{
            // Get date for debug porpuses
            NSDate *startDate = [NSDate date];
            
            // Color calculation process
            _isWorking = YES;
            LEColorScheme *colorScheme = [self colorSchemeFromImage:image];
            
            // Gete time difference for debug porpuses
            NSDate *endDate = [NSDate date];
            NSTimeInterval timeDifference = [endDate timeIntervalSinceDate:startDate];
            double timePassed_ms = timeDifference * -1000.0;
            LELog(@"Computation time: %f", timePassed_ms);
            
            // Call complete block and pass colors result
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(colorScheme);
            });
            _isWorking = NO;
        });
    }
}

- (LEColorScheme*)colorSchemeFromImage:(UIImage*)inputImage
{
    // First, we scale the input image, to get a constant image size and square texture.
    UIImage *scaledImage = [self scaleImage:inputImage
                                      width:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                     height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/scaledImage.png" atomically:YES];
    //[UIImagePNGRepresentation(scaledImage) writeToFile:@"/Users/Luis/Input.png" atomically:YES];
    
    // Now, We set the initial OpenGL ES 2.0 state. LUCHIN: Aquí estamos trabajando
    [self setupOpenGL];
    
    // Then we set the scaled image as the texture to render.
    _aTexture = [self setupTextureFromImage:scaledImage];
    
    //Now that all is ready, proceed we the render, to find the dominant color
    [self renderDominant];
    
    //Now that we have the rendered result, we start the color calculations.
    LEColorScheme *colorScheme = [[LEColorScheme alloc] init];
    UIColor *backgroundColor=nil;
    
    savedImage = [self dumpImageWithWidth:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                                   height:LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE
                  biggestAlphaColorReturn:&backgroundColor];
    [UIImagePNGRepresentation(savedImage) writeToFile:@"/Users/Luis/Input.png" atomically:YES];
    colorScheme.backgroundColor = backgroundColor;
    //Now, filter the backgroundColor.
    [self findTextColorsTaskForColorScheme:colorScheme];
    //});
    return colorScheme;
}

#pragma mark - OpenGL ES 2 custom methods

- (void)setupOpenGL
{
    // Start openGLES
    [self setupContext];
    
    [self setupFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupDepthBuffer];
    
    [self setupOpenGLForDominantColor];
    
    [self setupVBOs];
}

- (void)renderDominant
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
    
    //[_context presentRenderbuffer:GL_RENDERBUFFER];
}

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

- (void)setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}


- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE , LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE);
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

//- (void)setupDisplayLink {
//    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
//    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//}


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

-(UIColor *)colorFromImageWithWidth:(NSUInteger)width
                             height:(NSUInteger)height
                     filteringColor:(UIColor*)colorToFilter
                          tolerance:(GLfloat)tolerance
{
    GLubyte *buffer = (GLubyte *) malloc(width * height * 4);
    
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid *)buffer);
    
    /* Find bigger Alpha color*/
    NSUInteger biggerR = 0;
    NSUInteger biggerG = 0;
    NSUInteger biggerB = 0;
    NSUInteger biggerAlpha = 0;
    CGFloat filteringRedFloat = 0;
    CGFloat filteringGreenFloat = 0;
    CGFloat filteringBlueFloat = 0;
    
    [colorToFilter getRed:&filteringRedFloat
                    green:&filteringGreenFloat
                     blue:&filteringBlueFloat
                    alpha:nil];
    
    NSUInteger filteringRed = (NSUInteger)(filteringRedFloat*255);
    NSUInteger filteringGreen = (NSUInteger)(filteringGreenFloat*255);
    NSUInteger filteringBlue = (NSUInteger)(filteringBlueFloat*255);
    
    for (NSUInteger y=0; y<(height/2); y++) {
        for (NSUInteger x=0; x<(width/2)*4; x++) {
            //NSLog(@"x=%d y=%d pixel=%d",x/4,y,buffer[y * 4 * width + x]);
            if ((!((x+1)%4)) && (x>0)) {
                NSUInteger currentRed = buffer[y * 4 * width + (x-3)];
                NSUInteger currentGreen = buffer[y * 4 * width + (x-2)];
                NSUInteger currentBlue = buffer[y * 4 * width + (x-1)];
                
                NSUInteger squareDistance = (currentRed-filteringRed)*(currentRed-filteringRed)+
                (currentGreen-filteringGreen)*(currentGreen-filteringGreen)+
                (currentBlue-filteringBlue)*(currentBlue-filteringBlue);
                
                NSUInteger thresholdSquareDistance = (255*tolerance)*(255*tolerance);
                
                if (squareDistance > thresholdSquareDistance) {
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
    }
    
    return [UIColor colorWithRed:biggerR/255.0
                           green:biggerG/255.0
                            blue:biggerB/255.0
                           alpha:1.0];
}

-(void)findTextColorsTaskForColorScheme:(LEColorScheme*)colorScheme
{
    //Set sizes for buffer index calculations
    NSUInteger width = LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE;
    NSUInteger height = LECOLORPICKER_GPU_DEFAULT_SCALED_SIZE;
    
    //Read Render buffer
    GLubyte *buffer = (GLubyte *) malloc(width * height * 4);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid *)buffer);
    
    //Set initials values for local variables
    NSUInteger primaryColorR = 0;
    NSUInteger primaryColorG = 0;
    NSUInteger primaryColorB = 0;
    NSUInteger primaryColorAlpha = 0;
    
    CGFloat backgroundRedFloat = 0;
    CGFloat backgroundGreenFloat = 0;
    CGFloat backgroundBlueFloat = 0;
    
    [colorScheme.backgroundColor getRed:&backgroundRedFloat
                                  green:&backgroundGreenFloat
                                   blue:&backgroundBlueFloat
                                  alpha:nil];
    
    LEColor backgroundColor = {(unsigned int)(backgroundRedFloat*255),
        (unsigned int)(backgroundGreenFloat*255),
        (unsigned int)(backgroundBlueFloat*255)};
    
    for (NSUInteger y=0; y<(height/2); y++) {
        for (NSUInteger x=0; x<(width/2)*4; x++) {
            //NSLog(@"x=%d y=%d pixel=%d",x/4,y,buffer[y * 4 * width + x]);
            if ((!((x+1)%4)) && (x>0)) {
                NSUInteger currentRed = buffer[y * 4 * width + (x-3)];
                NSUInteger currentGreen = buffer[y * 4 * width + (x-2)];
                NSUInteger currentBlue = buffer[y * 4 * width + (x-1)];
                
                LEColor currentColor = {currentRed,currentGreen,currentBlue};
                NSUInteger squareDistance = squareDistanceInRGBSpaceBetweenColor(currentColor, backgroundColor);
                NSUInteger thresholdSquareDistance = (255*LECOLORPICKER_BACKGROUND_FILTER_TOLERANCE)*(255*LECOLORPICKER_BACKGROUND_FILTER_TOLERANCE);
                
                if (squareDistance > thresholdSquareDistance) {
                    if (buffer[y * 4 * width + x] > primaryColorAlpha ) {
                        
                        primaryColorAlpha = buffer[y * 4 * width + x];
                        primaryColorR = buffer[y * 4 * width + (x-3)];
                        primaryColorG = buffer[y * 4 * width + (x-2)];
                        primaryColorB = buffer[y * 4 * width + (x-1)];
                        //        NSLog(@"biggerR=%d biggerG=%d biggerB=%d biggerAlpha=%d",biggerR,biggerG,biggerB,biggerAlpha);
                    }
                }
            }
        }
    }
    
    UIColor *tmpColor = [UIColor colorWithRed:primaryColorR/255.0
                                        green:primaryColorG/255.0
                                         blue:primaryColorB/255.0
                                        alpha:1.0];
    
    //    if ([self isSufficienteContrastBetweenBackground:colorScheme.backgroundColor
    //                                        andForground:tmpColor]) {
    colorScheme.primaryTextColor = tmpColor;
    //    } else {
    //        if ([UIColor yComponentFromColor:colorScheme.backgroundColor] < 0.5) {
    //            colorScheme.primaryTextColor = [UIColor whiteColor];
    //        } else {
    //            colorScheme.primaryTextColor = [UIColor blackColor];
    //        }
    //    }
    
    NSUInteger secondaryColorR = 0;
    NSUInteger secondaryColorG = 0;
    NSUInteger secondaryColorB = 0;
    NSUInteger secondaryColorAlpha = 0;
    
    LEColor primaryTextColor = {primaryColorR,primaryColorG,primaryColorB};
    for (NSUInteger y=0; y<(height/2); y++) {
        for (NSUInteger x=0; x<(width/2)*4; x++) {
            //NSLog(@"x=%d y=%d pixel=%d",x/4,y,buffer[y * 4 * width + x]);
            if ((!((x+1)%4)) && (x>0)) {
                NSUInteger currentRed = buffer[y * 4 * width + (x-3)];
                NSUInteger currentGreen = buffer[y * 4 * width + (x-2)];
                NSUInteger currentBlue = buffer[y * 4 * width + (x-1)];
                
                LEColor currentColor = {currentRed,currentGreen,currentBlue};
                NSUInteger squareDistanceToBackground = squareDistanceInRGBSpaceBetweenColor(currentColor, backgroundColor);
                NSUInteger squareDistanceToPrimary = squareDistanceInRGBSpaceBetweenColor(currentColor, primaryTextColor);
                NSUInteger thresholdSquareDistanceToBackground = (255*LECOLORPICKER_BACKGROUND_FILTER_TOLERANCE)*(255*LECOLORPICKER_BACKGROUND_FILTER_TOLERANCE);
                NSUInteger thresholdSquareDistanceToPrimary = (255*LECOLORPICKER_PRIMARY_TEXT_FILTER_TOLERANCE)*(255*LECOLORPICKER_PRIMARY_TEXT_FILTER_TOLERANCE);
                if ((squareDistanceToBackground > thresholdSquareDistanceToBackground) && (squareDistanceToPrimary > thresholdSquareDistanceToPrimary)) {
                    if (buffer[y * 4 * width + x] > secondaryColorAlpha ) {
                        secondaryColorAlpha = buffer[y * 4 * width + x];
                        secondaryColorR = buffer[y * 4 * width + (x-3)];
                        secondaryColorG = buffer[y * 4 * width + (x-2)];
                        secondaryColorB = buffer[y * 4 * width + (x-1)];
                        //        NSLog(@"biggerR=%d biggerG=%d biggerB=%d biggerAlpha=%d",biggerR,biggerG,biggerB,biggerAlpha);
                    }
                }
            }
        }
    }
    
    tmpColor = [UIColor colorWithRed:secondaryColorR/255.0
                               green:secondaryColorG/255.0
                                blue:secondaryColorB/255.0
                               alpha:1.0];
    
    if ([self isSufficienteContrastBetweenBackground:colorScheme.backgroundColor
                                        andForground:tmpColor]) {
        colorScheme.secondaryTextColor = tmpColor;
    } else {
        if ([UIColor yComponentFromColor:colorScheme.backgroundColor] < 0.5) {
            colorScheme.secondaryTextColor = [UIColor whiteColor];
        } else {
            colorScheme.secondaryTextColor = [UIColor blackColor];
        }
    }
}

- (UIImage*)scaleImage:(UIImage*)image width:(CGFloat)width height:(CGFloat)height
{
    UIImage *scaledImage =  [UIImage imageWithImage:image scaledToSize:CGSizeMake(width,height)];
    return scaledImage;
}

- (BOOL)isSufficienteContrastBetweenBackground:(UIColor*)backgroundColor andForground:(UIColor*)foregroundColor
{
    float backgroundColorBrightness = [UIColor yComponentFromColor:backgroundColor];
    float foregroundColorBrightness = [UIColor yComponentFromColor:foregroundColor];
    float brightnessDifference = fabsf(backgroundColorBrightness-foregroundColorBrightness)*255;
    
    NSLog(@"BrightnessDifference %f ",brightnessDifference);
    
    if (brightnessDifference>=LECOLORPICKER_DEFAULT_BRIGHTNESS_DIFFERENCE) {
        float backgroundRed = 0.0;
        float backgroundGreen = 0.0;
        float backgroundBlue = 0.0;
        float foregroundRed = 0.0;
        float foregroundGreen = 0.0;
        float foregroundBlue = 0.0;
        
        int numComponents = CGColorGetNumberOfComponents(backgroundColor.CGColor);
        
        if (numComponents == 4) {
            const CGFloat *components = CGColorGetComponents(backgroundColor.CGColor);
            backgroundRed = components[0];
            backgroundGreen = components[1];
            backgroundBlue = components[2];
        }
        
        numComponents = CGColorGetNumberOfComponents(foregroundColor.CGColor);
        
        if (numComponents == 4) {
            const CGFloat *components = CGColorGetComponents(foregroundColor.CGColor);
            foregroundRed = components[0];
            foregroundGreen = components[1];
            foregroundBlue = components[2];
        }
        
        //Compute "Color Diference"
        float colorDifference = (MAX(backgroundRed,foregroundRed)-MIN(backgroundRed, foregroundRed)) +
        (MAX(backgroundGreen,foregroundGreen)-MIN(backgroundGreen, foregroundGreen)) +
        (MAX(backgroundBlue,foregroundBlue)-MIN(backgroundBlue, foregroundBlue));
        NSLog(@"ColorDifference = %f",colorDifference*255);
        if ((colorDifference*255)>LECOLORPICKER_DEFAULT_COLOR_DIFFERENCE) {
            return YES;
        }
    }
    
    return NO;
}

@end


