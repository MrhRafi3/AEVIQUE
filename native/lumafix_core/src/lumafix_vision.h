#ifndef LUMAFIX_VISION_H
#define LUMAFIX_VISION_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __APPLE__
int lumafix_apple_vision_segment_person(
    const uint8_t* rgba_data,
    int32_t width,
    int32_t height,
    int32_t stride_bytes,
    uint8_t* out_mask,
    int32_t out_w,
    int32_t out_h
);
#endif

#ifdef __cplusplus
}
#endif

#endif // LUMAFIX_VISION_H
