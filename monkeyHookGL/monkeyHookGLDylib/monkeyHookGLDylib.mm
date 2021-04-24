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
#import "commonUtils.hpp"
#import "glHook.h"
#import "fishhook/fishhook.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import <vector>
#import <GLKit/GLKit.h>

static std::vector<rebinding> s_rebindingArr;

static void hookCGlAPIBegin()
{
    s_rebindingArr.clear();
}

static void hookCGlAPIInsert(const char* name,void *replacement,void **replaced)
{
    rebinding rebind;
    rebind.name = name;
    rebind.replacement = replacement;
    rebind.replaced = replaced;
    s_rebindingArr.push_back(rebind);
}

static void hookCGlAPIFinish()
{
    if (s_rebindingArr.empty())
    {
        return;
    }
    size_t count = s_rebindingArr.size();
    rebind_symbols(s_rebindingArr.data(), count);
}

static void(*glDrawArraysFunc)(GLenum mode, GLint first, GLsizei count);
static void glDrawArraysNew(GLenum mode, GLint first, GLsizei count)
{
    NSLog(@"glDrawArrays called");
    glClearColor(1, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
//    glDrawArraysFunc(mode, first, count);
}

void (*glDrawElementsFun)(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
static void glDrawElementsNew(GLenum mode, GLint first, GLsizei count)
{
    NSLog(@"glDrawElementsNew called");
//    glDrawArraysFunc(mode, first, count);
}

//void glShaderSourceNew(GLuint shader, GLsizei count, const GLchar* const *string, const GLint* length)
//{
//    NSLog(@"glShaderSourceNew called");
//}


CHConstructor{
    printf(INSERT_SUCCESS_WELCOME);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        hookCGlAPIBegin();
        hookCGlAPIInsert("glDrawArrays", (void*)&glDrawArraysNew, (void**)&glDrawArraysFunc);
        hookCGlAPIInsert("glDrawElements", (void*)&glDrawElementsNew, (void**)&glDrawElementsFun);
//        hookCGlAPIInsert"glShaderSource",(void*)&glShaderSourcenew, (void**)&glShaderSourceFunc);
        hookCGlAPIFinish();
    }];
}


CHDeclareClass(CustomViewController)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

//add new method
CHDeclareMethod1(void, CustomViewController, newMethod, NSString*, output){
    NSLog(@"This is a new method : %@", output);
}

#pragma clang diagnostic pop

CHOptimizedClassMethod0(self, void, CustomViewController, classMethod){
    NSLog(@"hook class method");
    CHSuper0(CustomViewController, classMethod);
}

CHOptimizedMethod0(self, NSString*, CustomViewController, getMyName){
    //get origin value
    NSString* originName = CHSuper(0, CustomViewController, getMyName);
    
    NSLog(@"origin name is:%@",originName);
    
    //get property
    NSString* password = CHIvar(self,_password,__strong NSString*);
    
    NSLog(@"password is %@",password);
    
    [self newMethod:@"output"];
    
    //set new property
    self.newProperty = @"newProperty";
    
    NSLog(@"newProperty : %@", self.newProperty);
    
    //change the value
    return @"william";
    
}

//add new property
CHPropertyRetainNonatomic(CustomViewController, NSString*, newProperty, setNewProperty);

CHConstructor{
    CHLoadLateClass(CustomViewController);
    CHClassHook0(CustomViewController, getMyName);
    CHClassHook0(CustomViewController, classMethod);
    
    CHHook0(CustomViewController, newProperty);
    CHHook1(CustomViewController, setNewProperty);
}

