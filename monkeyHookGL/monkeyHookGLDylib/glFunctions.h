//
//  glFunctions.h
//  monkeyHookGLDylib
//
//  Created by william on 2021/4/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static void(*s_glDrawArraysFunc)(GLenum mode, GLint first, GLsizei count);
void glDrawArraysNew(GLenum mode, GLint first, GLsizei count);

static void(*s_glDrawElementsFun)(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
void glDrawElementsNew(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);

static GLuint(*s_glCreateShaderFunc)(GLenum type);
GLuint glCreateShaderNew(GLenum type);

static GLuint(*s_glCreateProgramFunc)(void);
GLuint glCreateProgramNew(void);

static void(*s_glShaderSourceFunc)(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length);
void glShaderSourceNew(GLuint shader, GLsizei count, const GLchar* const* string, const GLint* length);

static GLuint(*s_glGenTexturesFunc)(GLsizei n, GLuint* textures);
GLuint glGenTexturesNew(GLsizei n, GLuint* textures);

static void(*s_glTexImage2DFunc)(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid* pixels);
void glTexImage2DNew(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid* pixels);


NS_ASSUME_NONNULL_END
