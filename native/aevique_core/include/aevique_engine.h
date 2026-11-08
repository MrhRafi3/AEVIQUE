#ifndef AEVIQUE_ENGINE_H
#define AEVIQUE_ENGINE_H

#include <stdint.h>
#include <stddef.h>
#include "aevique_export.h"

#ifdef __cplusplus
extern "C" {
#endif

#define AEVIQUE_VERSION_MAJOR 1
#define AEVIQUE_VERSION_MINOR 2
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
 * Vignette adjustment parameters matching AEVIQUE EditState.vignette semantics.
 */
typedef struct AeviqueVignetteParameters {
    float amount;   /* -100.0f .. 100.0f (0 = neutral/identity; negative = dark edge, positive = bright) */
    float radius;   /* 0.0f .. 100.0f (default 50.0f) */
    float feather;  /* 0.0f .. 100.0f (default 50.0f) */
    float center_x; /* 0.0f .. 1.0f (normalized center X, default 0.5f) */
    float center_y; /* 0.0f .. 1.0f (normalized center Y, default 0.5f) */
} AeviqueVignetteParameters;

/**
 * Single color band HSL adjustments matching AEVIQUE HslAdjustments semantics.
 */
typedef struct AeviqueHslBand {
    float hue;        /* -100.0f .. 100.0f (angular hue shift) */
    float saturation; /* -100.0f .. 100.0f (saturation multiplier) */
    float luminance;  /* -100.0f .. 100.0f (luminance offset) */
} AeviqueHslBand;

/**
 * 8-channel HSL Color Mixer matching AEVIQUE HslAdjustments model.
 */
typedef struct AeviqueHslParameters {
    AeviqueHslBand red;
    AeviqueHslBand orange;
    AeviqueHslBand yellow;
    AeviqueHslBand green;
    AeviqueHslBand aqua;
    AeviqueHslBand blue;
    AeviqueHslBand purple;
    AeviqueHslBand magenta;
} AeviqueHslParameters;

/**
 * Photographic style effects parameters matching AEVIQUE EditState.effects semantics.
 */
typedef struct AeviqueEffectsParameters {
    int32_t bw_mode;             /* 0 = standard color, 1 = B&W monochrome conversion */
    float grain;                 /* 0.0f .. 100.0f (photographic film grain synthesis) */
    float vintage;               /* 0.0f .. 100.0f (vintage film tone and lifted blacks) */
    float drama;                 /* 0.0f .. 100.0f (moody chiaroscuro contrast) */
    float bloom;                 /* 0.0f .. 100.0f (highlight bloom glow) */
    float glow;                  /* 0.0f .. 100.0f (soft diffusion mist glow) */
    float chromatic_aberration;  /* 0.0f .. 100.0f (color fringing offset) */
    float lens_blur;             /* 0.0f .. 100.0f (optical bokeh / defocus blur) */
} AeviqueEffectsParameters;

/**
 * Unified image pipeline parameters executing multiple compatible operations in one pass.
 *
 * Sequence:
 *   Tone & Curves -> Vibrance -> Clarity -> HSL Mixer -> Saturation & B/W -> Vintage -> Drama -> Grain -> Bloom/Glow -> Vignette -> Structure -> Lens Blur
 */
typedef struct AeviquePipelineParameters {
    AeviqueAdvancedToneParameters tone;
    float vibrance;                     /* -100.0f .. 100.0f (skin-tone preserving saturation) */
    float clarity;                      /* -100.0f .. 100.0f (local midtone contrast) */
    AeviqueHslParameters hsl;
    AeviqueEffectsParameters effects;
    AeviqueVignetteParameters vignette;
    float structure;                    /* 0.0f .. 100.0f (local micro-contrast detail) */
} AeviquePipelineParameters;

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

/**
 * Processes an image buffer with skin-tone preserving Vibrance.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param vibrance Amount in range [-100.0f .. 100.0f].
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_vibrance_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    float vibrance
);

/**
 * Processes an image buffer with local midtone Clarity.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param clarity Amount in range [-100.0f .. 100.0f].
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_clarity_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    float clarity
);

/**
 * Processes an image buffer with Saturation and Monochrome B&W conversion.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param saturation Amount in range [-100.0f .. 100.0f].
 * @param bw_mode 1 for monochrome conversion, 0 for standard saturation.
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_monochrome_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    float saturation,
    int32_t bw_mode
);

/**
 * Processes an image buffer with radial Vignette falloff.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to vignette parameters.
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_vignette_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueVignetteParameters* params
);

/**
 * Processes an image buffer with the 8-channel HSL Color Mixer.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to HSL parameters.
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_hsl_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueHslParameters* params
);

/**
 * Unified image processing pipeline: executes multiple compatible adjustments in a single native call.
 *
 * Fuses Tone & Curves, Vibrance, Clarity, Saturation/B&W, Vintage, Drama, Grain, and Vignette
 * in a cache-friendly pixel pass with zero intermediate heap allocations, followed by Structure
 * when active. Preserves alpha channel and supports in-place processing (`src->data == dst->data`).
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to unified pipeline parameters.
 * @param curves Pointer to quad-channel tone curves (may be NULL for identity).
 * @return AEVIQUE_SUCCESS on success, or a negative AeviqueStatus error code.
 */
AEVIQUE_API AeviqueStatus aevique_process_pipeline_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviquePipelineParameters* params,
    const AeviqueToneCurves* curves
);

#ifdef __cplusplus
}
#endif

#endif /* AEVIQUE_ENGINE_H */

