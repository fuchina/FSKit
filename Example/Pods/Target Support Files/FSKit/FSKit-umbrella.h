#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FSKit.h"
#import "FuSoft.h"

FOUNDATION_EXPORT double FSKitVersionNumber;
FOUNDATION_EXPORT const unsigned char FSKitVersionString[];

