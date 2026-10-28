#ifndef AEVIQUE_EXPORT_H
#define AEVIQUE_EXPORT_H

#if defined(_WIN32) || defined(__CYGWIN__)
  #if defined(AEVIQUE_BUILDING_DLL)
    #define AEVIQUE_API __declspec(dllexport)
  #else
    #define AEVIQUE_API __declspec(dllimport)
  #endif
#elif defined(__GNUC__) && __GNUC__ >= 4
  #define AEVIQUE_API __attribute__((visibility("default")))
#else
  #define AEVIQUE_API
#endif

#endif /* AEVIQUE_EXPORT_H */

