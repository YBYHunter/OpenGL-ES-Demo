//
//  ViewController.m
//  YUMedia
//
//  Created by yuboyang02 on 2020/6/12.
//  Copyright © 2020 yuboyang02. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>
#import <GLKit/GLKit.h>

@interface ViewController ()<GLKViewDelegate>

@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) GLKBaseEffect *glEffect;
@property (nonatomic, assign) int count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化Context
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    GLKView *view = [[GLKView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    view.delegate = self;
    view.frame = CGRectMake(0, 0, 200, 200);
    view.context = self.glContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    [EAGLContext setCurrentContext:self.glContext];
    //设置顶点数据
    [self setSquareVertexData];

    CVPixelBufferRef texture = [self getPixelBuffer];
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = [self imageFromPixelBuffer:texture];
    imageView.frame = self.view.bounds;
    [self.view addSubview:imageView];
    //添加纹理
    [self addTexture];
    //上屏
    [imageView addSubview:view];
}

#pragma mark - Private Method

//GLKit
//UIimage -> GLKTextureInfo(通过着色器) 
- (void)addTexture {
    //纹理贴图
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"abc" ofType:@"png"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    //着色器
    self.glEffect = [[GLKBaseEffect alloc] init];
    self.glEffect.texture2d0.enabled = GL_TRUE;
    self.glEffect.texture2d0.name = textureInfo.name;
}

//CoreVideo
//UIimage -> CVPixelBufferRef -> CVOpenGLESTextureRef
- (CVPixelBufferRef)getPixelBuffer {
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &coreVideoTextureCache);
    UIImage *image = [UIImage imageNamed:@"test.jpeg"];
    renderTarget = [self pixelBufferFromCGImage:image.CGImage];

    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage
                    (kCFAllocatorDefault,
                     coreVideoTextureCache,
                     renderTarget,
                     NULL,          // texture attributes
                     GL_TEXTURE_2D,
                     GL_RGBA,       // opengl format
                     (int)CGImageGetWidth(image.CGImage),
                     (int)CGImageGetHeight(image.CGImage),
                     GL_RGBA,       // native iOS format
                     GL_UNSIGNED_BYTE,
                     0,
                     &renderTexture);
    if (err){
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }

    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    return renderTarget;
}

//设置顶点
- (void)setSquareVertexData {
    
    //顶点数据
    GLfloat squareVertexData[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下 - 右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下 - 右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
    };

    //顶点索引
    GLuint indices[] =
    {
        0, 1, 2,
        3, 4, 5
    };
    self.count = sizeof(indices) / sizeof(GLuint);

    //顶点缓存
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);

    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);

    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

//加载着色器
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
        
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

#pragma mark - GLKViewDelegate

/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.f, 0.f, 0.f, 0.f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //启动着色器
    [self.glEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

#pragma mark - tool

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef) image
{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
                              };
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer = pixelBufferRef;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}


@end
