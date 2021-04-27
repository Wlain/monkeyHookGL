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
#import "fishhook/fishhook.h"
#import "glHook.hpp"
#import "glFunctions.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import <vector>
#import <GLKit/GLKit.h>

CHConstructor{
    printf(INSERT_SUCCESS_WELCOME);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        GLHook glHook;
        glHook.begin();
        glHook.insertFunc("glGenTextures", (void*)&glGenTexturesNew, (void**)&s_glGenTexturesFunc);
        glHook.insertFunc("glTexImage2D", (void*)&glTexImage2DNew, (void**)&s_glTexImage2DFunc);
        glHook.insertFunc("glCreateShader", (void*)&glCreateShaderNew, (void**)&s_glCreateShaderFunc);
        glHook.insertFunc("glCreateProgram", (void*)&glCreateProgramNew, (void**)&s_glCreateProgramFunc);
        glHook.insertFunc("glDrawArrays", (void*)&glDrawArraysNew, (void**)&s_glDrawArraysFunc);
        glHook.insertFunc("glDrawElements", (void*)&glDrawElementsNew, (void**)&s_glDrawElementsFun);
        glHook.insertFunc("glShaderSource", (void*)&glShaderSourceNew, (void**)&s_glShaderSourceFunc);
        glHook.finish();
    }];
}
