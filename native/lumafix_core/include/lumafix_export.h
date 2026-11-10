#ifndef LUMAFIX_EXPORT_H
#define LUMAFIX_EXPORT_H

#if defined(_WIN32) || defined(__CYGWIN__)
  #if defined(LUMAFIX_BUILDING_DLL)
    #define LUMAFIX_API __declspec(dllexport)
  #else
    #define LUMAFIX_API __declspec(dllimport)
  #endif
#elif defined(__GNUC__) && __GNUC__ >= 4
  #define LUMAFIX_API __attribute__((visibility("default")))
#else
  #define LUMAFIX_API
#endif

#endif /* LUMAFIX_EXPORT_H */
