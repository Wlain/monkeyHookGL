//
//  commomDefine.h
//  monkeyHookGL
//
//  Created by william on 2021/4/27.
//

#ifndef commomDefine_h
#define commomDefine_h

#define LOG_INFO(...)          \
    do                         \
    {                          \
        printf(__VA_ARGS__);   \
        fflush(stdout);        \
    } while (0)


#endif /* commomDefine_h */
