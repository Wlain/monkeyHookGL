////
////  commonUtils.cpp
////  monkeyHookGLDylib
////
////  Created by william on 2021/4/25.
////
//
//#include "commonUtils.hpp"
//#include <vector>
//#include <iostream>
//#include <memory>
//#include "fishhook/fishhook.h"
//
//static std::vector<rebinding> s_rebindingArr;
//
//void hookCGlAPIBegin()
//{
//    s_rebindingArr.clear();
//}
//
//void hookCGlAPIInsert(const char* name,void *replacement,void **replaced)
//{
//    rebinding rebind;
//    rebind.name = name;
//    rebind.replacement = replacement;
//    rebind.replaced = replaced;
//    s_rebindingArr.push_back(rebind);
//}
//
//void hookCGlAPIFinish()
//{
//    if (s_rebindingArr.empty())
//    {
//        return;
//    }
//    size_t count = s_rebindingArr.size();
//    rebind_symbols(s_rebindingArr.data(), count);
//}
//
