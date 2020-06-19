//
//  BoxViewController.m
//  YUMedia
//
//  Created by yuboyang02 on 2020/6/19.
//  Copyright © 2020 yuboyang02. All rights reserved.
//

#import "BoxViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKit.h>
#import "GLESUtils.h"
#import "GLESMath.h"

@interface BoxViewController ()

@property (nonatomic , strong) GLKView *glkView;
@property (nonatomic , strong) EAGLContext* myContext;
@property (nonatomic , strong) CAEAGLLayer* myEagLayer;
@property (nonatomic , assign) GLuint       myProgram;
@property (nonatomic , assign) GLuint       myVertices;

//渲染缓存
@property (nonatomic , assign) GLuint myColorRenderBuffer;
//帧缓存
@property (nonatomic , assign) GLuint myColorFrameBuffer;
//深度缓存
@property (nonatomic , assign) GLuint depthRenderBuffer;

// 纹理句柄
@property (nonatomic, assign) GLuint myTexture0;

@property (nonatomic, assign) CGFloat xdegree;
@property (nonatomic, assign) CGFloat yDegree;

@end

@implementation BoxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //配置环境
    [self.view addSubview:self.glkView];
    [self setupLayer];
    [self setupContext];
    [self destoryRenderAndFrameBuffer];
    //申请缓存区
    [self setupBuffer];
    //渲染
    [self renderDdvance];
    [self render];
}

- (void)renderDdvance {
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.glkView.frame.origin.x * scale,
               self.glkView.frame.origin.y * scale,
               self.glkView.frame.size.width * scale,
               self.glkView.frame.size.height * scale);
    
    
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    self.myProgram = [self loadShaders:vertFile frag:fragFile];
    
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);

        return ;
    }
    else {
        glUseProgram(self.myProgram);
    }
    
    
    
    GLfloat attrArr[] = {
        // 顶点                   纹理
        // 前面
        -0.5f, 0.5f, 0.5f,      0.0f, 0.0f, // 前左上 0
        -0.5f, -0.5f, 0.5f,     0.0f, 1.0f, // 前左下 1
        0.5f, -0.5f, 0.5f,      1.0f, 1.0f, // 前右下 2
        0.5f, 0.5f, 0.5f,       1.0f, 0.0f, // 前右上 3
        // 后面
        -0.5f, 0.5f, -0.5f,     1.0f, 0.0f, // 后左上 4
        -0.5f, -0.5f, -0.5f,    1.0f, 1.0f, // 后左下 5
        0.5f, -0.5f, -0.5f,     0.0f, 1.0f, // 后右下 6
        0.5f, 0.5f, -0.5f,      0.0f, 0.0f, // 后右上 7
        // 左面
        -0.5f, 0.5f, -0.5f,     0.0f, 0.0f, // 后左上 8
        -0.5f, -0.5f, -0.5f,    0.0f, 1.0f, // 后左下 9
        -0.5f, 0.5f, 0.5f,      1.0f, 0.0f, // 前左上 10
        -0.5f, -0.5f, 0.5f,     1.0f, 1.0f, // 前左下 11
        // 右面
        0.5f, 0.5f, 0.5f,       0.0f, 0.0f, // 前右上 12
        0.5f, -0.5f, 0.5f,      0.0f, 1.0f, // 前右下 13
        0.5f, -0.5f, -0.5f,     1.0f, 1.0f, // 后右下 14
        0.5f, 0.5f, -0.5f,      1.0f, 0.0f, // 后右上 15
        // 上面
        -0.5f, 0.5f, -0.5f,     0.0f, 0.0f, // 后左上 16
        -0.5f, 0.5f, 0.5f,      0.0f, 1.0f, // 前左上 17
        0.5f, 0.5f, 0.5f,       1.0f, 1.0f, // 前右上 18
        0.5f, 0.5f, -0.5f,      1.0f, 0.0f, // 后右上 19
        // 下面
        -0.5f, -0.5f, 0.5f,     0.0f, 0.0f, // 前左下 20
        0.5f, -0.5f, 0.5f,      1.0f, 0.0f, // 前右下 21
        -0.5f, -0.5f, -0.5f,    0.0f, 1.0f, // 后左下 22
        0.5f, -0.5f, -0.5f,     1.0f, 1.0f, // 后右下 23
    };
    glGenBuffers(1, &_myVertices);
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    // 让opengl es为当前绑定的缓存分配并初始化足够的连续内存
    //（通常是从CPU控制的内存复制数据到分配的内存）
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    //告诉OpenGL ES缓存中的数据 的类型和偏移量
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    //告诉OpenGL ES在接下来的渲染中使用缓存中的数据
    glEnableVertexAttribArray(position);
    
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glVertexAttribPointer(positionColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(positionColor);
    
    //加载纹理
    [self setupTexture:@"abc"];
    
    //开启面剔除
    glEnable(GL_CULL_FACE);
    //开启深度测试
    glEnable(GL_DEPTH_TEST);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    UITouch * touch = touches.anyObject;
    
    CGPoint currentPoint = [touch locationInView:self.view];
    CGPoint previousPoint = [touch previousLocationInView:self.view];

    _xdegree += previousPoint.y - currentPoint.y;
    _yDegree += previousPoint.x - currentPoint.x;
    
    [self render];
}

- (void)render {
    //先清除深度缓冲区
    glClear(GL_DEPTH_BUFFER_BIT);
    
    GLuint indices[] =
    {
        // 前面
        0, 1, 2,
        0, 2, 3,
        // 后面
        5, 4, 6,
        6, 4, 7,
        // 左面
        8, 9, 11,
        8, 11, 10,
        // 右面
        12, 13, 14,
        12, 14, 15,
        // 上面
        16, 17, 18,
        16, 18, 19,
        // 下面
        20, 22, 23,
        20, 23, 21,
    };
    glClearColor(0, 0.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    

    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = width / height; //长宽比
    
    //透视变换，视角30°
    ksPerspective(&_projectionMatrix, 30.0, aspect, 1.f, 100.0f);
    
    //设置glsl里面的投影矩阵
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    
    //平移
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    
    //旋转
    ksRotate(&_rotationMatrix, _xdegree, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, _yDegree, 0.0, 1.0, 0.0); //绕Y轴
    
    //把变换矩阵相乘，注意先后顺序
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    // 引用将一致变量值传入渲染管线
    glUniformMatrix4fv(//矩阵句柄
                       modelViewMatrixSlot,
                       //需要修改的矩阵的数量
                       1,
                       //指明矩阵是列优先矩阵（GL_FALSE）
                       //还是行优先矩阵（GL_TRUE）
                       GL_FALSE,
                       //指向由count个元素的数组的指针
                       (GLfloat*)&_modelViewMatrix.m[0][0]);
    

    //用作同glDrawArrays ， 可以指定顶点索引
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    
    // Free up no longer needed shader resources
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

- (void)setupLayer {
    self.myEagLayer = (CAEAGLLayer*) self.glkView.layer;
    [self.glkView setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    self.myContext = context;
}

// 申请缓存
- (void)setupBuffer {
    // 创建 绑定 渲染缓存
    glGenRenderbuffers(1, &_myColorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _myColorRenderBuffer);
    
    // 该方法最好在绑定渲染后立即设置，不然后面会被绑定为深度渲染缓存
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
    // 创建 绑定帧缓存
    glGenFramebuffers(1, &_myColorFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _myColorFrameBuffer);
    
    // 在帧缓存 和 渲染缓存创建 和 绑定结束后需要
    // 渲染缓存作为帧缓存的某种（颜色、深度、模板）附件
    glFramebufferRenderbuffer(
                              //帧缓冲区类型
                              GL_FRAMEBUFFER,
                              //缓冲附件类型
                              GL_COLOR_ATTACHMENT0,
                              //渲染缓冲区类型
                              GL_RENDERBUFFER,
                              //渲染缓冲句柄
                              _myColorRenderBuffer);
    
    // 深度缓存
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    // 申请深度渲染缓存
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    // 设置深度测试的存储信息
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    // 关联深度缓冲到帧缓冲区
    // 将渲染缓存挂载到GL_DEPTH_ATTACHMENT这个挂载点上
    glFramebufferRenderbuffer(
                              GL_FRAMEBUFFER,
                              GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER,
                              _depthRenderBuffer);
    // GL_RENDERBUFFER绑定的是深度测试渲染缓存，所以要绑定回色彩渲染缓存
    glBindRenderbuffer(GL_RENDERBUFFER, _myColorRenderBuffer);
    
    // 检查帧缓存状态
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Error: Frame buffer is not completed.");
        exit(1);
    }
}

- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
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

#pragma mark - getter

- (GLKView *)glkView {
    if (_glkView == nil) {
        _glkView = [[GLKView alloc] init];
        _glkView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        _glkView.backgroundColor = [UIColor clearColor];
    }
    return _glkView;
}

@end
