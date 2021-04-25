//
//  glHook.m
//  monkeyHookGLDylib
//
//  Created by william on 2021/4/24.
//

#import "glHook.hpp"

GLHook::GLHook() = default;

GLHook::~GLHook() = default;

bool GLHook::begin()
{
    m_rebindingArr.clear();
    return true;
}

bool GLHook::insertFunc(const char* name, void* replacement, void** replaced)
{
    rebinding rebinding;
    rebinding.name = name;
    rebinding.replacement = replacement;
    rebinding.replaced = replaced;
    m_rebindingArr.push_back(rebinding);
    return true;
}

bool GLHook::finish()
{
    if (m_rebindingArr.empty())
    {
        return false;
    }
    size_t count = m_rebindingArr.size();
    rebind_symbols(m_rebindingArr.data(), count);
    return true;
}
