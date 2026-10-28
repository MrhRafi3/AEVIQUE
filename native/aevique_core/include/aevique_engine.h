#ifndef AEVIQUE_ENGINE_H
#define AEVIQUE_ENGINE_H

#include <stdint.h>
#include <stddef.h>
#include "aevique_export.h"

#ifdef __cplusplus
extern "C" {
#endif

#define AEVIQUE_VERSION_MAJOR 1
#define AEVIQUE_VERSION_MINOR 1
#define AEVIQUE_VERSION_PATCH 0

/**
 * Standard status codes returned by all AEVIQUE C ABI functions.
 */
typedef enum AeviqueStatus {
    AEVIQUE_SUCCESS                     =  0,
    AEVIQUE_ERROR_NULL_POINTER          = -1,
    AEVIQUE_ERROR_INVALID_DIMENSIONS    = -2,
    AEVIQUE_ERROR_INVALID_STRIDE        = -3,
    AEVIQUE_ERROR_UNSUPPORTED_FORMAT    = -4,
    AEVIQUE_ERROR_INVALID_PARAMETER     = -5,
    AEVIQUE_ERROR_BUFFER_TOO_SMALL      = -6,
    AEVIQUE_ERROR_UNKNOWN               = -99,
} AeviqueStatus;

/**
 * Pixel formats supported by AEVIQUE buffers.
 * In Phase 1, AEVIQUE_PIXEL_FORMAT_RGBA8888 is the primary tested format.
 */
typedef enum AeviquePixelFormat {
    AEVIQUE_PIXEL_FORMAT_RGBA8888       = 0,
    AEVIQUE_PIXEL_FORMAT_BGRA8888       = 1,
    AEVIQUE_PIXEL_FORMAT_RGB888         = 2,
} AeviquePixelFormat;

/**
 * Image buffer descriptor with explicit stride for strided or padded memory layouts.
 *
 * Buffer ownership: Caller owns both `data` and the `AeviqueImageBuffer` struct.
 * C++ functions read from `src->data` and write to `dst->data` without freeing or reallocating.
 */
typedef struct AeviqueImageBuffer {
    uint8_t* data;
    int32_t width;
    int32_t height;
    int32_t stride_bytes;      /* Stride in bytes per row (e.g. width * 4) */
    int32_t format;            /* AeviquePixelFormat */
} AeviqueImageBuffer;

/**
 * Tone adjustment parameters matching AEVIQUE EditState.tune semantics.
 *
 * All values are expressed on the range [-100.0f, 100.0f], where 0.0f is neutral/identity.
 */
typedef struct AeviqueToneParameters {
    float exposure;   /* -100.0f .. 100.0f (EV tone scaling factor) */
    float contrast;   /* -100.0f .. 100.0f (Midtone 128 expansion/compression) */
    float saturation; /* -100.0f .. 100.0f (Rec. 709 luminance saturation) */
} AeviqueToneParameters;

/**
 * Single control point on a 2D spline curve in normalized coordinates [0.0f .. 1.0f].
 */
typedef struct AeviqueCurvePoint {
    float x; /* Normalized input coordinate [0.0f .. 1.0f] */
    float y; /* Normalized output coordinate [0.0f .. 1.0f] */
} AeviqueCurvePoint;

/**
 * Control point channel containing an array of points and point count.
 */
typedef struct AeviqueCurveChannel {
    const AeviqueCurvePoint* points;
    int32_t point_count;
} AeviqueCurveChannel;

/**
 * Quad-channel tone curve descriptor matching AEVIQUE ToneCurves model.
 */
typedef struct AeviqueToneCurves {
    AeviqueCurveChannel rgb;
    AeviqueCurveChannel red;
    AeviqueCurveChannel green;
    AeviqueCurveChannel blue;
} AeviqueToneCurves;

/**
 * Advanced tone parameters matching AEVIQUE EditState.tune semantics.
 */
typedef struct AeviqueAdvancedToneParameters {
    float exposure;   /* -100.0f .. 100.0f (EV tone scaling factor) */
    float contrast;   /* -100.0f .. 100.0f (Midtone 128 expansion/compression) */
    float saturation; /* -100.0f .. 100.0f (Rec. 709 luminance saturation) */
    float brightness; /* -100.0f .. 100.0f (Linear luminance shift) */
    float warmth;     /* -100.0f .. 100.0f (Color temperature: +Red/-Blue) */
    float tint;       /* -100.0f .. 100.0f (Color tint: +Magenta/-Green) */
    float highlights; /* -100.0f .. 100.0f (Highlights recovery/boost for > 100) */
    float shadows;    /* -100.0f .. 100.0f (Shadows recovery/boost for < 155) */
    float whites;     /* -100.0f .. 100.0f (White point scaling for > 180) */
    float blacks;     /* -100.0f .. 100.0f (Black point scaling for < 75) */
    float ambiance;   /* -100.0f .. 100.0f (Midtone contrast and depth) */
} AeviqueAdvancedToneParameters;

/**
 * Returns the version encoded as:
 * (major << 16) | (minor << 8) | patch
 */
AEVIQUE_API uint32_t aevique_get_version(void);

/**
 * Returns a human-readable description for an AeviqueStatus code.
 */
AEVIQUE_API const char* aevique_status_to_string(AeviqueStatus status);

/**
 * Processes an RGBA8 image buffer with Exposure, Contrast, and Saturation adjustments.
 *
 * Semantics:
 * - 1. Tone mapping: Exposure and Contrast are combined into a 256-entry 1D LUT matching
 *      Dart's LutGenerator formulation.
 * - 2. Saturation: Applied to tone-mapped pixels using Rec. 709 luminance weights:
 *      lum = 0.2126 * R + 0.7152 * G + 0.0722 * B
 *      Ch' = clamp_u8(round(lum + (Ch - lum) * satFactor))
 * - 3. Alpha channel: Completely preserved (src alpha copied to dst alpha).
 * - 4. In-place support: If `src->data == dst->data`, processing is performed in-place
 *      with zero intermediate buffer allocations.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to tone adjustment parameters.
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_tone_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueToneParameters* params
);

/**
 * Processes an RGBA8 image buffer with Tone Curves, Exposure, Contrast, and Saturation.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param tone_params Pointer to exposure, contrast, saturation parameters.
 * @param curves Pointer to tone curves descriptor (may be NULL for identity curves).
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_curves_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueToneParameters* tone_params,
    const AeviqueToneCurves* curves
);

/**
 * Processes an RGBA8 image buffer with complete advanced tone parameters and tone curves.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to advanced tone parameters (exposure, contrast, saturation,
 *               brightness, warmth, tint, highlights, shadows, whites, blacks, ambiance).
 * @param curves Pointer to tone curves descriptor (may be NULL for identity curves).
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_advanced_tone_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueAdvancedToneParameters* params,
    const AeviqueToneCurves* curves
);

#ifdef __cplusplus
}
#endif

#endif /* AEVIQUE_ENGINE_H */

