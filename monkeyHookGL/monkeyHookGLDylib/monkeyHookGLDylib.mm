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


static void(*glDrawArraysFunc)(GLenum mode, GLint first, GLsizei count);
static void glDrawArraysNew(GLenum mode, GLint first, GLsizei count)
{
    NSLog(@"glDrawArrays(%d, %d, %d) called", mode, first, count);
    glClearColor(1, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
//    glDrawArraysFunc(mode, first, count);
}

static void (*glDrawElementsFun)(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
static void glDrawElementsNew(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices)
{
    NSLog(@"glDrawElementsNew(%d, %d, %d, %p) called", mode, count, type, indices);
//    glDrawElementsFun(mode, count, type, indices);
}

static int shaderIndex = 0;
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
    NSString* strFilePath = [shaderFolder stringByAppendingFormat:@"/%s.glsl", std::to_string(++shaderIndex).c_str()];
    /// 创建文件并将字符串写入文件
    NSData* fileData = [NSData dataWithBytes:source.UTF8String length:source.length];
    [fileManager createFileAtPath:strFilePath contents:fileData attributes:nil];
}

void (*glShaderSourceFunc)(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length);
static void glShaderSourceNew(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length)
{
    NSString* shaderSource = [NSString stringWithFormat:@"%s", *string];
    NSLog(@"glShaderSource(%d, %d, \n%@\n, %p) called", shader, count, shaderSource, length);
    saveShaderToFile(shaderSource);
    glShaderSourceFunc(shader, count, string, length);
}


CHConstructor{
    printf(INSERT_SUCCESS_WELCOME);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        GLHook glHook;
        glHook.begin();
        glHook.insertFunc("glDrawArrays", (void*)&glDrawArraysNew, (void**)&glDrawArraysFunc);
        glHook.insertFunc("glDrawElements", (void*)&glDrawElementsNew, (void**)&glDrawElementsFun);
        glHook.insertFunc("glShaderSource", (void*)&glShaderSourceNew, (void**)&glShaderSourceFunc);
        glHook.finish();
    }];
}
