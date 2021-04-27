//
//  glFunctions.m
//  monkeyHookGLDylib
//
//  Created by william on 2021/4/27.
//

#import "glFunctions.h"
#import "glHook.hpp"
#import "commomDefine.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <string>
#import <array>
#define MAX_GL_INFO_COUNT 1024

static std::array<GLHook::GLInfo, MAX_GL_INFO_COUNT> s_glInfoArr;
static int s_vertShaderIndex = 0;
static int s_fragShaderIndex = 0;
static GLHook::CurrentShaderStatus s_currentShaderStatus;
static bool s_isFinishHook = false;
static int s_textureID = 0;


static void dataProviderReleaseCallback(void *info, const void *data, size_t size)
{
    free((void*)data);
}

static UIImage* convertBufferToUIImage(void* rawImagePixels, int width, int height)
{
        int totalBytesForImage = width * height * 4;
        CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytesForImage, dataProviderReleaseCallback);
        CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
        CGImageRef cgImageFromBytes = CGImageCreate(width, height, 8, 32, 4 * width, defaultRGBColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaLast, dataProvider, NULL, NO, kCGRenderingIntentDefault);
        CGDataProviderRelease(dataProvider);
        CGColorSpaceRelease(defaultRGBColorSpace);
        UIImage *image = [UIImage imageWithCGImage:cgImageFromBytes];
        return image;
}

static void saveShaderToFile(NSString* source)
{
    NSString* documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)[0];
        /// 创建Shader目录
    NSString* shaderFolder = [documentPath stringByAppendingFormat:@"/Shader"];
        /// 创建目录
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isFileExists = [fileManager fileExistsAtPath:shaderFolder];
    if (!isFileExists)
    {
        [fileManager createDirectoryAtPath:shaderFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
        /// 得到完整的文件路径
    NSString* strFilePath = nil;
    if (s_currentShaderStatus == GLHook::CurrentShaderStatus::VertShader)
    {
        strFilePath = [shaderFolder stringByAppendingFormat:@"/program%s.vert", std::to_string(s_vertShaderIndex).c_str()];
    }
    else if (s_currentShaderStatus == GLHook::CurrentShaderStatus::FragShader)
    {
        strFilePath = [shaderFolder stringByAppendingFormat:@"/program%s.frag", std::to_string(s_fragShaderIndex).c_str()];
    }
    else
    {
        return;
    }
        /// 创建文件并将字符串写入文件
    NSData* fileData = [NSData dataWithBytes:source.UTF8String length:source.length];
    [fileManager createFileAtPath:strFilePath contents:fileData attributes:nil];
}


static CGColorSpaceRef cgeCGColorSpaceRGB()
{
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

static inline UIImage* cgeCreateUIImageWithBuffer(void* buffer, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow, int flag, CGColorSpaceRef colorSpaceRef)
{
    if (buffer == nullptr)
    {
        return nil;
    }
    assert(colorSpaceRef != nil);
    CGContextRef contextOut = CGBitmapContextCreate(buffer, width, height, bitsPerComponent, bytesPerRow, colorSpaceRef, flag);
    
    CGImageRef frame = CGBitmapContextCreateImage(contextOut);
    UIImage* newImage = [UIImage imageWithCGImage:frame];
    
    CGImageRelease(frame);
    CGContextRelease(contextOut);
    return newImage;
}

static UIImage* imageWithARGBData(unsigned char* data, int width, int height)
{
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width*4, colorspace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = nil;
    if (context != nil)
    {
        cgImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorspace);
    UIImage* image = nil;
    if(cgImage != nil)
    {
        image = [UIImage imageWithCGImage:cgImage];
    }
    
    CGImageRelease(cgImage);
    return image;
}

static UIImage* cgeCreateUIImageWithBufferRGBA(void* buffer, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow)
{
    return cgeCreateUIImageWithBuffer(buffer, width, height, bitsPerComponent, bytesPerRow, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big, cgeCGColorSpaceRGB());
}

static void saveImage(UIImage* image)
{
    NSString* strFileName = [NSString stringWithFormat:@"texture/texture%0.5d.png", s_textureID];
        // 获取 Document 目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        // 构造保存文件的名称 保存成功会返回YES
    NSString *filePath = [[paths objectAtIndex:0]stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@", strFileName]];
    NSLog(@"cwb:saveImage:Path%@", filePath);
        // 保存操作
    bool result =[UIImagePNGRepresentation(image)writeToFile:filePath atomically:YES];
    if (result == YES)
    {
        NSLog(@"%@save success!", strFileName);
    }
    else
    {
        NSLog(@"%@save failed!", strFileName);
    }
}

void glDrawArraysNew(GLenum mode, GLint first, GLsizei count)
{
    if (s_isFinishHook) { return; }
    LOG_INFO("glhook:glDrawArrays(%d, %d, %d) called", mode, first, count);
        //    glClearColor(1, 0, 0, 1);
        //    glClear(GL_COLOR_BUFFER_BIT);
    s_glDrawArraysFunc(mode, first, count);
}

void glDrawElementsNew(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices)
{
    if (s_isFinishHook) { return; }
    LOG_INFO("glhook:glDrawElementsNew(%d, %d, %d, %p) called", mode, count, type, indices);
    s_glDrawElementsFun(mode, count, type, indices);
}

GLuint glCreateShaderNew(GLenum type)
{
    LOG_INFO("glhook:glCreateShader called");
    if (s_isFinishHook) { return 0; }
    GLuint shaderID = s_glCreateShaderFunc(type);
    if (type == GL_VERTEX_SHADER)
    {
        s_currentShaderStatus = GLHook::CurrentShaderStatus::VertShader;
        s_glInfoArr[std::max(s_vertShaderIndex, s_fragShaderIndex)].vertShader = shaderID;
        s_vertShaderIndex++;
        if (s_vertShaderIndex > MAX_GL_INFO_COUNT)
        {
            s_isFinishHook = true;
        }
    }
    else if (type == GL_FRAGMENT_SHADER)
    {
        s_currentShaderStatus = GLHook::CurrentShaderStatus::FragShader;
        s_glInfoArr[std::max(s_vertShaderIndex, s_fragShaderIndex)].framebuffer = shaderID;
        s_fragShaderIndex++;
        if (s_fragShaderIndex > MAX_GL_INFO_COUNT)
        {
            s_isFinishHook = true;
        }
    }
    else
    {
        s_currentShaderStatus = GLHook::CurrentShaderStatus::OtherShader;
    }
    return shaderID;
}

GLuint glCreateProgramNew(void)
{
    LOG_INFO("glhook:glCreateProgram called");
    if (s_isFinishHook) { return 0; }
    GLuint programID = s_glCreateProgramFunc();
    s_glInfoArr[std::max(s_vertShaderIndex, s_fragShaderIndex)].program = programID;
    return programID;
}

void glShaderSourceNew(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length)
{
    NSString* shaderSource = [NSString stringWithFormat:@"%s", *string];
    LOG_INFO("glhook:glShaderSource(%d, %d, \n%@\n, %p) called", shader, count, shaderSource, length);
    if (s_isFinishHook) { return; }
//    saveShaderToFile(shaderSource);
    s_glShaderSourceFunc(shader, count, string, length);
}

GLuint glGenTexturesNew(GLsizei n, GLuint* textures)
{
    LOG_INFO("glhook:glGenTextures called");
    s_textureID = s_glGenTexturesFunc(n, textures);
    return s_textureID;
}

void glTexImage2DNew(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid* pixels)
{
    LOG_INFO("glhook:glTexImage2D called");
    if(internalformat == GL_RGBA)
    {
        UIImage* image = convertBufferToUIImage((void*)pixels, width, height);
        NSString* strFileName = [NSString stringWithFormat:@"texture/texture%0.5d.png", s_textureID];
        saveImage(image);
    }
    s_glTexImage2DFunc(target, level, internalformat, width, height, border, format, type, pixels);
}
