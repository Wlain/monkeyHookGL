//
//  glHook.hpp
//  monkeyHookGLDylib
//
//  Created by william on 2021/4/24.
//

#ifndef glHook_hpp
#define glHook_hpp

#include "fishhook/fishhook.h"
#include <vector>

class GLHook
{
public:
    GLHook();
    ~GLHook();
    
public:
    bool begin();
    bool insertFunc(const char* name, void* replacement, void** replaced);
    bool finish();
    
public:
    std::vector<rebinding> m_rebindingArr;
};


#endif /* glHook_hpp */
