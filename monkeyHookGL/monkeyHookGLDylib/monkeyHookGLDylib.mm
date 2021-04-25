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


static void(*glDrawArraysFunc)(GLenum mode, GLint first, GLsizei count);
static void glDrawArraysNew(GLenum mode, GLint first, GLsizei count)
{
    NSLog(@"glDrawArrays called");
//    glClearColor(1, 0, 0, 1);
//    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArraysFunc(mode, first, count);
}

void (*glDrawElementsFun)(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
static void glDrawElementsNew(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices)
{
    NSLog(@"glDrawElementsNew called");
    glDrawElementsFun(mode, count, type, indices);
}

CHConstructor{
    printf(INSERT_SUCCESS_WELCOME);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        GLHook glHook;
        glHook.begin();
        glHook.insertFunc("glDrawArrays", (void*)&glDrawArraysNew, (void**)&glDrawArraysFunc);
        glHook.insertFunc("glDrawElements", (void*)&glDrawElementsNew, (void**)&glDrawElementsFun);
        glHook.finish();
    }];
}
