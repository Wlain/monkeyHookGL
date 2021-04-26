//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  monkeyHookGLDylib.m
//  monkeyHookGLDylib
//
//  Created by william on 2021/4/24.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//

#import "monkeyHookGLDylib.h"
#import "glHook.hpp"
#import "fishhook/fishhook.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import <vector>
#import <GLKit/GLKit.h>
#import <string>
#import <string.h>
#import <array>

#define MAX_GL_INFO_COUNT 1024

static std::array<GLHook::GLInfo, MAX_GL_INFO_COUNT> s_glInfoArr;
static int s_vertShaderIndex = 0;
static int s_fragShaderIndex = 0;
static GLHook::CurrentShaderStatus s_currentShaderStatus;
static bool s_isFinishHook = false;

static void(*s_glDrawArraysFunc)(GLenum mode, GLint first, GLsizei count);
static void glDrawArraysNew(GLenum mode, GLint first, GLsizei count)
{
    if (s_isFinishHook) { return; }
    NSLog(@"glDrawArrays(%d, %d, %d) called", mode, first, count);
    glClearColor(1, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
//    s_glDrawArraysFunc(mode, first, count);
}

static void(*s_glDrawElementsFun)(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
static void glDrawElementsNew(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices)
{
    if (s_isFinishHook) { return; }
    NSLog(@"glDrawElementsNew(%d, %d, %d, %p) called", mode, count, type, indices);
//    s_glDrawElementsFun(mode, count, type, indices);
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

static GLuint(*s_glCreateShaderFunc)(GLenum type);
static GLuint glCreateShaderNew(GLenum type)
{
    NSLog(@"glCreateShader called");
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

static GLuint(*s_glCreateProgramFunc)(void);
static GLuint glCreateProgramNew(void)
{
    NSLog(@"glCreateProgram called");
    if (s_isFinishHook) { return 0; }
    GLuint programID = s_glCreateProgramFunc();
    s_glInfoArr[std::max(s_vertShaderIndex, s_fragShaderIndex)].program = programID;
    return programID;
}

void(*s_glShaderSourceFunc)(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length);
static void glShaderSourceNew(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length)
{
    NSString* shaderSource = [NSString stringWithFormat:@"%s", *string];
    NSLog(@"glShaderSource(%d, %d, \n%@\n, %p) called", shader, count, shaderSource, length);
    if (s_isFinishHook) { return; }
    saveShaderToFile(shaderSource);
    s_glShaderSourceFunc(shader, count, string, length);
}

CHConstructor{
    printf(INSERT_SUCCESS_WELCOME);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        GLHook glHook;
        glHook.begin();
        glHook.insertFunc("glCreateShader", (void*)&glCreateShaderNew, (void**)&s_glCreateShaderFunc);
        glHook.insertFunc("glCreateProgram", (void*)&glCreateProgramNew, (void**)&s_glCreateProgramFunc);
        glHook.insertFunc("glDrawArrays", (void*)&glDrawArraysNew, (void**)&s_glDrawArraysFunc);
        glHook.insertFunc("glDrawElements", (void*)&glDrawElementsNew, (void**)&s_glDrawElementsFun);
        glHook.insertFunc("glShaderSource", (void*)&glShaderSourceNew, (void**)&s_glShaderSourceFunc);
        glHook.finish();
    }];
}
