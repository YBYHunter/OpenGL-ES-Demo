//
//  ShaderViewController.m
//  YUMedia
//
//  Created by yuboyang02 on 2020/6/15.
//  Copyright © 2020 yuboyang02. All rights reserved.
//

#import "ShaderViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKit.h>

@interface ShaderViewController ()

@property (nonatomic, strong) GLKView *glkView;

// 上下文
@property (nonatomic, strong) EAGLContext* myContext;

// 展示区域
@property (nonatomic, strong) CAEAGLLayer* myEagLayer;

// 链接程序（连接着色器，并且简介一个最终可执行的程序）
// GLuint 句柄
@property (nonatomic, assign) GLuint       myProgram;

// 缓存数据句柄
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;

// 纹理句柄
@property (nonatomic, assign) GLuint myTexture0;

// 当前旋转角度
@property (nonatomic, assign) NSInteger currentRotationAngle;

@end

@implementation ShaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentRotationAngle = 0;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.glkView];
    
    [self myContext];
    [self destoryRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    
    [self renderDdvance];
    [self render];
}

#pragma mark - Private Method

- (void)renderDdvance {
    //获取视图放大倍数
    CGFloat scale = [[UIScreen mainScreen] scale];
    //设置视口大小
    glViewport(self.glkView.frame.origin.x * scale,
               self.glkView.frame.origin.y * scale,
               self.glkView.frame.size.width * scale,
               self.glkView.frame.size.height * scale);
    
    //读取文件路径
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    
    //加载shader
    self.myProgram = [self loadShaders:vertFile frag:fragFile];
    
    //链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return ;
    }
    else {
        NSLog(@"link ok");
        glUseProgram(self.myProgram); //成功便使用，避免由于未使用导致的的bug
    }

    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 1.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 0.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 1.0f, //左下
        
        0.5, -0.5, 0.0f,    1.0f, 1.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 0.0f, //左上
        0.5, 0.5, -0.0f,    1.0f, 0.0f, //右上
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    // 设置顶点属性对象
    {
        // 从着色器中取 position 的句柄
        GLuint position = glGetAttribLocation(self.myProgram, "position");
                              
        glVertexAttribPointer(
                              //参数的句柄
                              position,
                              
                              //指定顶点属性大小(矩阵的列数)
                              3,
                              
                              //指定数据类型
                              GL_FLOAT,
                              
                              //是否希望数据被标准化（归一化）
                              GL_FALSE,
                              
                              //步长
                              sizeof(GLfloat) * 5,
                              
                              //缓冲区起始位置的偏移量
                              NULL);
        glEnableVertexAttribArray(position);
    }
    
    
    
    GLuint textCoor = glGetAttribLocation(self.myProgram, "textCoordinate");
    glVertexAttribPointer(textCoor,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(GLfloat) * 5,
                          (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
    //加载纹理
    [self setupTexture:@"abc"];
}

- (void)render {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //获取rotate矩阵 的句柄
    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
    float radians = -_currentRotationAngle * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);
    
    NSLog(@"arc:%ld",(long)_currentRotationAngle);
    //z轴旋转矩阵
    GLfloat zRotation[16] = {   //
        c,  -s, 0,   0,         //
        s,  c,  0,   0,         //
        0,  0,  1.0, 0,         //
        0,  0,  0,   1.0        //
    };
    
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    _currentRotationAngle++;
    if (_currentRotationAngle >= 360) {
        _currentRotationAngle = 0;
    }
//    [self performSelector:@selector(render) withObject:nil afterDelay:1/60];
}

//
- (void)destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

// 为 颜色缓冲区 分配存储空间
- (void)setupRenderBuffer {
    //声明缓存区的句柄
    GLuint buffer;
    //返回1个渲染缓冲区对象名
    glGenRenderbuffers(1, &buffer);
    //绑定
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    // 为 颜色缓冲区 分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              self.myColorRenderBuffer);
}

#pragma mark - getter

- (GLKView *)glkView {
    if (_glkView == nil) {
        _glkView = [[GLKView alloc] init];
        _glkView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width);
        _glkView.backgroundColor = [UIColor clearColor];
    }
    return _glkView;
}

- (CAEAGLLayer *)myEagLayer {
    if (_myEagLayer == nil) {
        _myEagLayer = (CAEAGLLayer *)self.glkView.layer;
        //设置放大倍数
        [self.glkView setContentScaleFactor:[[UIScreen mainScreen] scale]];
        
        // CALayer 默认是透明的，必须将它设为不透明才能让其可见
        _myEagLayer.opaque = YES;
        
        // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
        _myEagLayer.drawableProperties =
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithBool:NO],
         kEAGLDrawablePropertyRetainedBacking,
         kEAGLColorFormatRGBA8,
         kEAGLDrawablePropertyColorFormat, nil];
        
        _myEagLayer.backgroundColor = [UIColor clearColor].CGColor;
    }
    return _myEagLayer;
}

- (EAGLContext *)myContext {
    if (_myContext == nil) {
        EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3;
        _myContext = [[EAGLContext alloc] initWithAPI:api];
        if (!_myContext) {
            NSLog(@"Failed to initialize OpenGLES 3.0 context");
            exit(1);
        }
        
        // 设置为当前上下文
        if (![EAGLContext setCurrentContext:_myContext]) {
            NSLog(@"Failed to set current OpenGL context");
            exit(1);
        }
    }
    return _myContext;
}

#pragma mark - tool

- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //链接
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    //返回链接程序
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

#pragma mark - 图片绑定纹理

- (GLuint)setupTexture:(NSString *)fileName {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    // rgba共4个byte
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    CGContextRef spriteContext =
    CGBitmapContextCreate(spriteData,
                          width,    //单位为像素
                          height,   //单位为像素
                          8,        //内存中像素的每个组件的位数
                          width * 4,//每一行在内存所占的比特数
                          CGImageGetColorSpace(spriteImage),
                          kCGImageAlphaPremultipliedLast);
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext,
                       CGRectMake(0, 0, width, height),
                       spriteImage);
    CGContextRelease(spriteContext);
    
    // 4绑定纹理到默认的纹理ID
    glGenTextures(1, &_myTexture0);
    glBindTexture(GL_TEXTURE_2D, self.myTexture0);
    
    // 纹理放大时，使用线性过滤(GL_NEAREST使用邻近过滤)
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    // 纹理缩小时，使用线性过滤
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    // 纹理环绕方式
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    free(spriteData);
    return 0;
}

@end
