#ifndef LUMAFIX_ENGINE_H
#define LUMAFIX_ENGINE_H

#include <stdint.h>
#include <stddef.h>
#include "lumafix_export.h"

#ifdef __cplusplus
extern "C" {
#endif

#define LUMAFIX_VERSION_MAJOR 1
#define LUMAFIX_VERSION_MINOR 2
#define LUMAFIX_VERSION_PATCH 0

/**
 * Standard status codes returned by all LumaFix C ABI functions.
 */
typedef enum LumaFixStatus {
    LUMAFIX_SUCCESS                     =  0,
    LUMAFIX_ERROR_NULL_POINTER          = -1,
    LUMAFIX_ERROR_INVALID_DIMENSIONS    = -2,
    LUMAFIX_ERROR_INVALID_STRIDE        = -3,
    LUMAFIX_ERROR_UNSUPPORTED_FORMAT    = -4,
    LUMAFIX_ERROR_INVALID_PARAMETER     = -5,
    LUMAFIX_ERROR_BUFFER_TOO_SMALL      = -6,
    LUMAFIX_ERROR_UNKNOWN               = -99,
} LumaFixStatus;

/**
 * Pixel formats supported by LumaFix buffers.
 * In Phase 1, LUMAFIX_PIXEL_FORMAT_RGBA8888 is the primary tested format.
 */
typedef enum LumaFixPixelFormat {
    LUMAFIX_PIXEL_FORMAT_RGBA8888       = 0,
    LUMAFIX_PIXEL_FORMAT_BGRA8888       = 1,
    LUMAFIX_PIXEL_FORMAT_RGB888         = 2,
} LumaFixPixelFormat;

/**
 * Image buffer descriptor with explicit stride for strided or padded memory layouts.
 *
 * Buffer ownership: Caller owns both `data` and the `LumaFixImageBuffer` struct.
 * C++ functions read from `src->data` and write to `dst->data` without freeing or reallocating.
 */
typedef struct LumaFixImageBuffer {
    uint8_t* data;
    int32_t width;
    int32_t height;
    int32_t stride_bytes;      /* Stride in bytes per row (e.g. width * 4) */
    int32_t format;            /* LumaFixPixelFormat */
} LumaFixImageBuffer;

/**
 * Tone adjustment parameters matching LumaFix EditState.tune semantics.
 *
 * All values are expressed on the range [-100.0f, 100.0f], where 0.0f is neutral/identity.
 */
typedef struct LumaFixToneParameters {
    float exposure;   /* -100.0f .. 100.0f (EV tone scaling factor) */
    float contrast;   /* -100.0f .. 100.0f (Midtone 128 expansion/compression) */
    float saturation; /* -100.0f .. 100.0f (Rec. 709 luminance saturation) */
} LumaFixToneParameters;

/**
 * Single control point on a 2D spline curve in normalized coordinates [0.0f .. 1.0f].
 */
typedef struct LumaFixCurvePoint {
    float x; /* Normalized input coordinate [0.0f .. 1.0f] */
    float y; /* Normalized output coordinate [0.0f .. 1.0f] */
} LumaFixCurvePoint;

/**
 * Control point channel containing an array of points and point count.
 */
typedef struct LumaFixCurveChannel {
    const LumaFixCurvePoint* points;
    int32_t point_count;
} LumaFixCurveChannel;

/**
 * Quad-channel tone curve descriptor matching LumaFix ToneCurves model.
 */
typedef struct LumaFixToneCurves {
    LumaFixCurveChannel rgb;
    LumaFixCurveChannel red;
    LumaFixCurveChannel green;
    LumaFixCurveChannel blue;
} LumaFixToneCurves;

/**
 * Advanced tone parameters matching LumaFix EditState.tune semantics.
 */
typedef struct LumaFixAdvancedToneParameters {
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
} LumaFixAdvancedToneParameters;

/**
 * Vignette adjustment parameters matching LumaFix EditState.vignette semantics.
 */
typedef struct LumaFixVignetteParameters {
    float amount;   /* -100.0f .. 100.0f (0 = neutral/identity; negative = dark edge, positive = bright) */
    float radius;   /* 0.0f .. 100.0f (default 50.0f) */
    float feather;  /* 0.0f .. 100.0f (default 50.0f) */
    float center_x; /* 0.0f .. 1.0f (normalized center X, default 0.5f) */
    float center_y; /* 0.0f .. 1.0f (normalized center Y, default 0.5f) */
} LumaFixVignetteParameters;

/**
 * Single color band HSL adjustments matching LumaFix HslAdjustments semantics.
 */
typedef struct LumaFixHslBand {
    float hue;        /* -100.0f .. 100.0f (angular hue shift) */
    float saturation; /* -100.0f .. 100.0f (saturation multiplier) */
    float luminance;  /* -100.0f .. 100.0f (luminance offset) */
} LumaFixHslBand;

/**
 * 8-channel HSL Color Mixer matching LumaFix HslAdjustments model.
 */
typedef struct LumaFixHslParameters {
    LumaFixHslBand red;
    LumaFixHslBand orange;
    LumaFixHslBand yellow;
    LumaFixHslBand green;
    LumaFixHslBand aqua;
    LumaFixHslBand blue;
    LumaFixHslBand purple;
    LumaFixHslBand magenta;
} LumaFixHslParameters;

/**
 * Photographic style effects parameters matching LumaFix EditState.effects semantics.
 */
typedef struct LumaFixEffectsParameters {
    int32_t bw_mode;             /* 0 = standard color, 1 = B&W monochrome conversion */
    float grain;                 /* 0.0f .. 100.0f (photographic film grain synthesis) */
    float vintage;               /* 0.0f .. 100.0f (vintage film tone and lifted blacks) */
    float drama;                 /* 0.0f .. 100.0f (moody chiaroscuro contrast) */
    float bloom;                 /* 0.0f .. 100.0f (highlight bloom glow) */
    float glow;                  /* 0.0f .. 100.0f (soft diffusion mist glow) */
    float chromatic_aberration;  /* 0.0f .. 100.0f (color fringing offset) */
    float lens_blur;             /* 0.0f .. 100.0f (optical bokeh / defocus blur) */
} LumaFixEffectsParameters;

/**
 * Unified image pipeline parameters executing multiple compatible operations in one pass.
 *
 * Sequence:
 *   Tone & Curves -> Vibrance -> Clarity -> HSL Mixer -> Saturation & B/W -> Vintage -> Drama -> Grain -> Bloom/Glow -> Vignette -> Structure -> Lens Blur
 */
typedef struct LumaFixPipelineParameters {
    LumaFixAdvancedToneParameters tone;
    float vibrance;                     /* -100.0f .. 100.0f (skin-tone preserving saturation) */
    float clarity;                      /* -100.0f .. 100.0f (local midtone contrast) */
    LumaFixHslParameters hsl;
    LumaFixEffectsParameters effects;
    LumaFixVignetteParameters vignette;
    float structure;                    /* 0.0f .. 100.0f (local micro-contrast detail) */
    float sharpening;                   /* 0.0f .. 100.0f (edge-preserving high-frequency sharpening) */
} LumaFixPipelineParameters;

/**
 * Returns the version encoded as:
 * (major << 16) | (minor << 8) | patch
 */
LUMAFIX_API uint32_t lumafix_get_version(void);

/**
 * Returns a human-readable description for an LumaFixStatus code.
 */
LUMAFIX_API const char* lumafix_status_to_string(LumaFixStatus status);

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
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_tone_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixToneParameters* params
);

/**
 * Processes an RGBA8 image buffer with Tone Curves, Exposure, Contrast, and Saturation.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param tone_params Pointer to exposure, contrast, saturation parameters.
 * @param curves Pointer to tone curves descriptor (may be NULL for identity curves).
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_curves_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixToneParameters* tone_params,
    const LumaFixToneCurves* curves
);

/**
 * Processes an RGBA8 image buffer with complete advanced tone parameters and tone curves.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to advanced tone parameters (exposure, contrast, saturation,
 *               brightness, warmth, tint, highlights, shadows, whites, blacks, ambiance).
 * @param curves Pointer to tone curves descriptor (may be NULL for identity curves).
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_advanced_tone_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixAdvancedToneParameters* params,
    const LumaFixToneCurves* curves
);

/**
 * Processes an image buffer with skin-tone preserving Vibrance.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param vibrance Amount in range [-100.0f .. 100.0f].
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_vibrance_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    float vibrance
);

/**
 * Processes an image buffer with local midtone Clarity.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param clarity Amount in range [-100.0f .. 100.0f].
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_clarity_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    float clarity
);

/**
 * Processes an image buffer with Saturation and Monochrome B&W conversion.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param saturation Amount in range [-100.0f .. 100.0f].
 * @param bw_mode 1 for monochrome conversion, 0 for standard saturation.
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_monochrome_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    float saturation,
    int32_t bw_mode
);

/**
 * Processes an image buffer with radial Vignette falloff.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to vignette parameters.
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_vignette_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixVignetteParameters* params
);

/**
 * Processes an image buffer with the 8-channel HSL Color Mixer.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param dst Pointer to output image buffer (caller-owned, may point to src).
 * @param params Pointer to HSL parameters.
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_hsl_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixHslParameters* params
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
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_process_pipeline_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixPipelineParameters* params,
    const LumaFixToneCurves* curves
);

/**
 * Segments the primary human subject from an RGBA8 image buffer, outputting an 8-bit grayscale alpha mask.
 *
 * On macOS / iOS: Uses hardware-accelerated Apple Vision neural person segmentation.
 * On Android / Linux / Windows / Fallback: Uses on-device skin-tone chrominance, spatial saliency,
 * and edge-preserving boundary refinement.
 *
 * @param src Pointer to input image buffer (caller-owned).
 * @param out_mask Pointer to pre-allocated output 8-bit alpha buffer of size out_width * out_height.
 * @param out_width Width of the output mask.
 * @param out_height Height of the output mask.
 * @return LUMAFIX_SUCCESS on success, or a negative LumaFixStatus error code.
 */
LUMAFIX_API LumaFixStatus lumafix_segment_person_rgba8(
    const LumaFixImageBuffer* src,
    uint8_t* out_mask,
    int32_t out_width,
    int32_t out_height
);

#ifdef __cplusplus
}
#endif

#endif /* LUMAFIX_ENGINE_H */

