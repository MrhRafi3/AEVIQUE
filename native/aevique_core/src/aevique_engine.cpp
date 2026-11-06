#include "aevique_engine.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>

static inline float clamp_float(float val, float min_val, float max_val) {
    if (val < min_val) return min_val;
    if (val > max_val) return max_val;
    return val;
}

static inline double clamp_double(double val, double min_val, double max_val) {
    if (val < min_val) return min_val;
    if (val > max_val) return max_val;
    return val;
}

static inline uint8_t clamp_u8(int val) {
    if (val < 0) return 0;
    if (val > 255) return 255;
    return static_cast<uint8_t>(val);
}

static bool is_identity_curve(const AeviqueCurvePoint* points, int32_t count) {
    if (count == 0 || points == nullptr) return true;
    if (count != 2) return false;
    return (std::abs(points[0].x - 0.0f) < 1e-4f) &&
           (std::abs(points[0].y - 0.0f) < 1e-4f) &&
           (std::abs(points[1].x - 1.0f) < 1e-4f) &&
           (std::abs(points[1].y - 1.0f) < 1e-4f);
}

static void interpolate_curve_channel(const AeviqueCurveChannel* channel, uint8_t lut[256]) {
    if (channel == nullptr || channel->point_count == 0 || channel->points == nullptr ||
        is_identity_curve(channel->points, channel->point_count)) {
        for (int i = 0; i < 256; i++) {
            lut[i] = static_cast<uint8_t>(i);
        }
        return;
    }

    std::vector<AeviqueCurvePoint> sorted(channel->points, channel->points + channel->point_count);
    std::sort(sorted.begin(), sorted.end(), [](const AeviqueCurvePoint& a, const AeviqueCurvePoint& b) {
        return a.x < b.x;
    });

    const size_t num_points = sorted.size();

    for (int i = 0; i < 256; i++) {
        const double norm_x = static_cast<double>(i) / 255.0;

        if (norm_x <= static_cast<double>(sorted.front().x)) {
            lut[i] = clamp_u8(static_cast<int>(std::round(static_cast<double>(sorted.front().y) * 255.0)));
        } else if (norm_x >= static_cast<double>(sorted.back().x)) {
            lut[i] = clamp_u8(static_cast<int>(std::round(static_cast<double>(sorted.back().y) * 255.0)));
        } else {
            size_t idx = 0;
            while (idx < num_points - 1 && static_cast<double>(sorted[idx + 1].x) < norm_x) {
                idx++;
            }
            const double p0_x = static_cast<double>(sorted[idx].x);
            const double p0_y = static_cast<double>(sorted[idx].y);
            const double p1_x = static_cast<double>(sorted[idx + 1].x);
            const double p1_y = static_cast<double>(sorted[idx + 1].y);
            const double dx = p1_x - p0_x;
            const double t = dx > 0.0 ? (norm_x - p0_x) / dx : 0.0;
            const double interpolated_y = p0_y + (p1_y - p0_y) * t;
            lut[i] = clamp_u8(static_cast<int>(std::round(interpolated_y * 255.0)));
        }
    }
}

uint32_t aevique_get_version(void) {
    return (AEVIQUE_VERSION_MAJOR << 16) | (AEVIQUE_VERSION_MINOR << 8) | AEVIQUE_VERSION_PATCH;
}

const char* aevique_status_to_string(AeviqueStatus status) {
    switch (status) {
        case AEVIQUE_SUCCESS:
            return "Success";
        case AEVIQUE_ERROR_NULL_POINTER:
            return "Null pointer argument";
        case AEVIQUE_ERROR_INVALID_DIMENSIONS:
            return "Invalid image dimensions";
        case AEVIQUE_ERROR_INVALID_STRIDE:
            return "Invalid row stride (must be >= width * channels)";
        case AEVIQUE_ERROR_UNSUPPORTED_FORMAT:
            return "Unsupported pixel format (only RGBA8888 and RGB888 supported)";
        case AEVIQUE_ERROR_INVALID_PARAMETER:
            return "Invalid adjustment parameter (must not be NaN or infinite)";
        case AEVIQUE_ERROR_BUFFER_TOO_SMALL:
            return "Buffer capacity is smaller than required by dimensions and stride";
        default:
            return "Unknown error";
    }
}

AeviqueStatus aevique_process_pipeline_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviquePipelineParameters* params,
    const AeviqueToneCurves* curves
) {
    try {
        // 1. Validate pointers
        if (src == nullptr || dst == nullptr || params == nullptr) {
            return AEVIQUE_ERROR_NULL_POINTER;
        }
        if (src->data == nullptr || dst->data == nullptr) {
            return AEVIQUE_ERROR_NULL_POINTER;
        }

        // 2. Validate dimensions and guard against integer overflow
        if (src->width <= 0 || src->height <= 0 || dst->width <= 0 || dst->height <= 0 ||
            src->width > 65536 || src->height > 65536) {
            return AEVIQUE_ERROR_INVALID_DIMENSIONS;
        }
        if (src->width != dst->width || src->height != dst->height) {
            return AEVIQUE_ERROR_INVALID_DIMENSIONS;
        }

        // 3. Validate pixel formats
        if (src->format != dst->format) {
            return AEVIQUE_ERROR_INVALID_DIMENSIONS;
        }
        if (src->format != AEVIQUE_PIXEL_FORMAT_RGBA8888 &&
            src->format != AEVIQUE_PIXEL_FORMAT_RGB888) {
            return AEVIQUE_ERROR_UNSUPPORTED_FORMAT;
        }

        const int32_t bpp = (src->format == AEVIQUE_PIXEL_FORMAT_RGB888) ? 3 : 4;

        // 4. Validate stride with 64-bit integer overflow protection
        int64_t min_stride_64 = static_cast<int64_t>(src->width) * static_cast<int64_t>(bpp);
        if (min_stride_64 > INT32_MAX ||
            static_cast<int64_t>(src->stride_bytes) < min_stride_64 ||
            static_cast<int64_t>(dst->stride_bytes) < min_stride_64) {
            return AEVIQUE_ERROR_INVALID_STRIDE;
        }
        int32_t min_stride = static_cast<int32_t>(min_stride_64);

        // 5. Validate parameters for NaN or Infinity
        const AeviqueAdvancedToneParameters* t = &params->tone;
        if (std::isnan(t->exposure) || std::isinf(t->exposure) ||
            std::isnan(t->contrast) || std::isinf(t->contrast) ||
            std::isnan(t->saturation) || std::isinf(t->saturation) ||
            std::isnan(t->brightness) || std::isinf(t->brightness) ||
            std::isnan(t->warmth) || std::isinf(t->warmth) ||
            std::isnan(t->tint) || std::isinf(t->tint) ||
            std::isnan(t->highlights) || std::isinf(t->highlights) ||
            std::isnan(t->shadows) || std::isinf(t->shadows) ||
            std::isnan(t->whites) || std::isinf(t->whites) ||
            std::isnan(t->blacks) || std::isinf(t->blacks) ||
            std::isnan(t->ambiance) || std::isinf(t->ambiance) ||
            std::isnan(params->vibrance) || std::isinf(params->vibrance) ||
            std::isnan(params->clarity) || std::isinf(params->clarity) ||
            std::isnan(params->structure) || std::isinf(params->structure) ||
            std::isnan(params->effects.grain) || std::isinf(params->effects.grain) ||
            std::isnan(params->effects.vintage) || std::isinf(params->effects.vintage) ||
            std::isnan(params->effects.drama) || std::isinf(params->effects.drama) ||
            std::isnan(params->vignette.amount) || std::isinf(params->vignette.amount) ||
            std::isnan(params->vignette.radius) || std::isinf(params->vignette.radius) ||
            std::isnan(params->vignette.feather) || std::isinf(params->vignette.feather) ||
            std::isnan(params->vignette.center_x) || std::isinf(params->vignette.center_x) ||
            std::isnan(params->vignette.center_y) || std::isinf(params->vignette.center_y)) {
            return AEVIQUE_ERROR_INVALID_PARAMETER;
        }

        // Validate curve points for NaN or Inf if provided
        if (curves != nullptr) {
            const AeviqueCurveChannel* channels[4] = {&curves->rgb, &curves->red, &curves->green, &curves->blue};
            for (int c = 0; c < 4; c++) {
                if (channels[c] != nullptr && channels[c]->point_count > 0 && channels[c]->points != nullptr) {
                    for (int32_t p = 0; p < channels[c]->point_count; p++) {
                        if (std::isnan(channels[c]->points[p].x) || std::isinf(channels[c]->points[p].x) ||
                            std::isnan(channels[c]->points[p].y) || std::isinf(channels[c]->points[p].y)) {
                            return AEVIQUE_ERROR_INVALID_PARAMETER;
                        }
                    }
                }
            }
        }

        // Clamped parameters
        const double exposure = clamp_double(t->exposure, -100.0, 100.0);
        const double contrast = clamp_double(t->contrast, -100.0, 100.0);
        const float saturation = clamp_float(t->saturation, -100.0f, 100.0f);
        const double brightness = clamp_double(t->brightness, -100.0, 100.0);
        const double warmth = clamp_double(t->warmth, -100.0, 100.0);
        const double tint = clamp_double(t->tint, -100.0, 100.0);
        const double highlights = clamp_double(t->highlights, -100.0, 100.0);
        const double shadows = clamp_double(t->shadows, -100.0, 100.0);
        const double whites = clamp_double(t->whites, -100.0, 100.0);
        const double blacks = clamp_double(t->blacks, -100.0, 100.0);
        const double ambiance = clamp_double(t->ambiance, -100.0, 100.0);

        const float vibrance = clamp_float(params->vibrance, -100.0f, 100.0f);
        const float clarity = clamp_float(params->clarity, -100.0f, 100.0f);
        const int32_t bw_mode = params->effects.bw_mode;
        const float grain = clamp_float(params->effects.grain, 0.0f, 100.0f);
        const float vintage = clamp_float(params->effects.vintage, 0.0f, 100.0f);
        const float drama = clamp_float(params->effects.drama, 0.0f, 100.0f);
        const float structure = clamp_float(params->structure, 0.0f, 100.0f);

        const float vig_amount_param = clamp_float(params->vignette.amount, -100.0f, 100.0f);
        const float vig_radius_param = clamp_float(params->vignette.radius, 0.0f, 100.0f);
        const float vig_feather_param = clamp_float(params->vignette.feather, 0.0f, 100.0f);
        const float vig_cx_norm = clamp_float(params->vignette.center_x, 0.0f, 1.0f);
        const float vig_cy_norm = clamp_float(params->vignette.center_y, 0.0f, 1.0f);

        // Precompute channel curves
        uint8_t rgb_curve[256];
        uint8_t r_curve[256];
        uint8_t g_curve[256];
        uint8_t b_curve[256];

        if (curves != nullptr) {
            interpolate_curve_channel(&curves->rgb, rgb_curve);
            interpolate_curve_channel(&curves->red, r_curve);
            interpolate_curve_channel(&curves->green, g_curve);
            interpolate_curve_channel(&curves->blue, b_curve);
        } else {
            for (int i = 0; i < 256; i++) {
                rgb_curve[i] = static_cast<uint8_t>(i);
                r_curve[i] = static_cast<uint8_t>(i);
                g_curve[i] = static_cast<uint8_t>(i);
                b_curve[i] = static_cast<uint8_t>(i);
            }
        }

        // Exposure factor
        double exposure_factor = 1.0;
        if (exposure > 0.0) {
            exposure_factor = 1.0 + (exposure / 100.0) * 1.5;
        } else if (exposure < 0.0) {
            exposure_factor = 1.0 / (1.0 + (-exposure / 100.0) * 1.5);
        }

        // Contrast factor
        double c_val = contrast * 1.5;
        double contrast_factor = (259.0 * (c_val + 255.0)) / (255.0 * (259.0 - c_val));

        // Brightness & warmth/tint shifts
        double brightness_shift = brightness * 1.28;
        double warmth_shift = warmth * 0.45;
        double tint_shift = tint * 0.45;

        // Generate 3 composite 1D LUTs matching AEVIQUE Dart LutGenerator
        uint8_t r_lut[256];
        uint8_t g_lut[256];
        uint8_t b_lut[256];

        for (int i = 0; i < 256; i++) {
            double base = static_cast<double>(i) * exposure_factor;

            // Whites & Blacks adjustments
            if (whites != 0.0 && i > 180) {
                double weight = clamp_double((static_cast<double>(i) - 180.0) / 75.0, 0.0, 1.0);
                base += whites * 0.5 * weight;
            }
            if (blacks != 0.0 && i < 75) {
                double weight = clamp_double((75.0 - static_cast<double>(i)) / 75.0, 0.0, 1.0);
                base += blacks * 0.5 * weight;
            }

            // Highlights adjustment (values > 100)
            if (highlights != 0.0 && i > 100) {
                double weight = clamp_double((static_cast<double>(i) - 100.0) / 155.0, 0.0, 1.0);
                base += highlights * 0.6 * weight;
            }

            // Shadows adjustment (values < 155)
            if (shadows != 0.0 && i < 155) {
                double weight = clamp_double((155.0 - static_cast<double>(i)) / 155.0, 0.0, 1.0);
                base += shadows * 0.6 * weight;
            }

            // Contrast and brightness
            base = contrast_factor * (base - 128.0) + 128.0 + brightness_shift;

            // Ambiance (boosts midtone detail and contrast subtly)
            if (ambiance != 0.0) {
                double mid_weight = 1.0 - (std::abs(static_cast<double>(i) - 128.0) / 128.0);
                base += ambiance * 0.4 * mid_weight;
            }

            // Apply master RGB curve
            int clamped_base = clamp_u8(static_cast<int>(std::round(clamp_double(base, 0.0, 255.0))));
            uint8_t curved_base = rgb_curve[clamped_base];

            // Channel-specific warmth & tint
            double r_val = clamp_double(static_cast<double>(curved_base) + warmth_shift + (tint_shift * 0.6), 0.0, 255.0);
            double g_val = clamp_double(static_cast<double>(curved_base) - (tint_shift * 0.8), 0.0, 255.0);
            double b_val = clamp_double(static_cast<double>(curved_base) - warmth_shift + (tint_shift * 0.6), 0.0, 255.0);

            // Apply individual channel curves
            r_lut[i] = r_curve[clamp_u8(static_cast<int>(std::round(r_val)))];
            g_lut[i] = g_curve[clamp_u8(static_cast<int>(std::round(g_val)))];
            b_lut[i] = b_curve[clamp_u8(static_cast<int>(std::round(b_val)))];
        }

        // Check if tone LUT is identity
        bool is_neutral_lut = true;
        for (int i = 0; i < 256; i++) {
            if (r_lut[i] != i || g_lut[i] != i || b_lut[i] != i) {
                is_neutral_lut = false;
                break;
            }
        }

        const bool is_neutral_sat = (std::abs(saturation) < 1e-4f && bw_mode == 0);
        const bool is_neutral_vibrance = (std::abs(vibrance) < 1e-4f);
        const bool is_neutral_clarity = (std::abs(clarity) < 1e-4f);
        const bool is_neutral_vintage = (vintage <= 0.001f);
        const bool is_neutral_drama = (drama <= 0.001f);
        const bool is_neutral_grain = (grain <= 0.001f);
        const bool is_neutral_vignette = (std::abs(vig_amount_param) < 1e-4f);
        const bool is_neutral_structure = (structure <= 0.001f);

        // Fast-path 0: completely neutral adjustment state
        if (is_neutral_lut && is_neutral_sat && is_neutral_vibrance && is_neutral_clarity &&
            is_neutral_vintage && is_neutral_drama && is_neutral_grain && is_neutral_vignette &&
            is_neutral_structure) {
            if (src->data == dst->data) {
                return AEVIQUE_SUCCESS;
            }
            for (int32_t y = 0; y < src->height; y++) {
                const uint8_t* src_row = src->data + y * src->stride_bytes;
                uint8_t* dst_row = dst->data + y * dst->stride_bytes;
                std::memcpy(dst_row, src_row, static_cast<size_t>(min_stride));
            }
            return AEVIQUE_SUCCESS;
        }

        const int32_t width = src->width;
        const int32_t height = src->height;
        const int32_t src_stride = src->stride_bytes;
        const int32_t dst_stride = dst->stride_bytes;
        const int32_t channels = bpp;

        // Fast-path 1: Tone-only (3 1D LUT lookups per pixel, zero floating-point arithmetic)
        if (is_neutral_sat && is_neutral_vibrance && is_neutral_clarity &&
            is_neutral_vintage && is_neutral_drama && is_neutral_grain && is_neutral_vignette &&
            is_neutral_structure) {
            for (int32_t y = 0; y < height; y++) {
                const uint8_t* src_row = src->data + y * src_stride;
                uint8_t* dst_row = dst->data + y * dst_stride;

                for (int32_t x = 0; x < width; x++) {
                    const uint8_t* s = src_row + (x * channels);
                    uint8_t* d = dst_row + (x * channels);

                    d[0] = r_lut[s[0]];
                    d[1] = g_lut[s[1]];
                    d[2] = b_lut[s[2]];
                    if (channels == 4) {
                        d[3] = s[3]; // Preserve alpha
                    }
                }
            }
            return AEVIQUE_SUCCESS;
        }

        // Fast-path 2: Tone + Saturation only (no other effects active)
        if (is_neutral_vibrance && is_neutral_clarity && is_neutral_vintage &&
            is_neutral_drama && is_neutral_grain && is_neutral_vignette && is_neutral_structure) {
            const float sat_factor = bw_mode ? 0.0f : clamp_float((saturation + 100.0f) / 100.0f, 0.0f, 3.0f);
            for (int32_t y = 0; y < height; y++) {
                const uint8_t* src_row = src->data + y * src_stride;
                uint8_t* dst_row = dst->data + y * dst_stride;

                for (int32_t x = 0; x < width; x++) {
                    const uint8_t* s = src_row + (x * channels);
                    uint8_t* d = dst_row + (x * channels);

                    uint8_t r_tone = r_lut[s[0]];
                    uint8_t g_tone = g_lut[s[1]];
                    uint8_t b_tone = b_lut[s[2]];

                    float lum = 0.2126f * r_tone + 0.7152f * g_tone + 0.0722f * b_tone;
                    if (bw_mode) {
                        uint8_t gray = clamp_u8(static_cast<int>(std::round(lum)));
                        d[0] = gray;
                        d[1] = gray;
                        d[2] = gray;
                    } else {
                        d[0] = clamp_u8(static_cast<int>(std::round(lum + (r_tone - lum) * sat_factor)));
                        d[1] = clamp_u8(static_cast<int>(std::round(lum + (g_tone - lum) * sat_factor)));
                        d[2] = clamp_u8(static_cast<int>(std::round(lum + (b_tone - lum) * sat_factor)));
                    }
                    if (channels == 4) {
                        d[3] = s[3]; // Preserve alpha
                    }
                }
            }
            return AEVIQUE_SUCCESS;
        }

        // --- General Unified Native Pipeline (Pixel-level fused loop) ---
        const float sat_factor = bw_mode ? 0.0f : clamp_float((saturation + 100.0f) / 100.0f, 0.0f, 3.0f);
        const float vib_factor = vibrance / 100.0f;
        const float clarity_factor = (clarity / 100.0f) * 0.7f;
        const float vintage_factor = vintage / 100.0f;
        const float drama_factor = drama / 100.0f;
        const float grain_intensity = (grain / 100.0f) * 38.0f;

        // Vignette geometry precomputations
        const double vig_cx = static_cast<double>(vig_cx_norm) * static_cast<double>(width);
        const double vig_cy = static_cast<double>(vig_cy_norm) * static_cast<double>(height);
        const double vig_max_dist = std::sqrt(vig_cx * vig_cx + vig_cy * vig_cy);
        const double vig_rad = (static_cast<double>(vig_radius_param) / 100.0) * vig_max_dist;
        const double vig_rad2 = vig_rad * vig_rad;
        const double vig_feather = std::max(1.0, (static_cast<double>(vig_feather_param) / 100.0) * vig_max_dist);
        const double vig_intensity = static_cast<double>(vig_amount_param) / 100.0;

        uint32_t rng_seed = 1337;

        for (int32_t y = 0; y < height; y++) {
            const uint8_t* src_row = src->data + y * src_stride;
            uint8_t* dst_row = dst->data + y * dst_stride;

            const double dy = static_cast<double>(y) - vig_cy;
            const double dy2 = dy * dy;

            for (int32_t x = 0; x < width; x++) {
                const uint8_t* s = src_row + (x * channels);
                uint8_t* d = dst_row + (x * channels);

                // Stage 1: Tone LUT lookup
                uint8_t r = is_neutral_lut ? s[0] : r_lut[s[0]];
                uint8_t g = is_neutral_lut ? s[1] : g_lut[s[1]];
                uint8_t b = is_neutral_lut ? s[2] : b_lut[s[2]];

                // Stage 2: Vibrance (preserves natural skin tones)
                if (!is_neutral_vibrance) {
                    float r_f = static_cast<float>(r);
                    float g_f = static_cast<float>(g);
                    float b_f = static_cast<float>(b);
                    float max_val = std::max({r_f, g_f, b_f});
                    float min_val = std::min({r_f, g_f, b_f});
                    float sat = (max_val == 0.0f) ? 0.0f : (max_val - min_val) / max_val;
                    float sat_weight = clamp_float(1.0f - sat, 0.0f, 1.0f);
                    float amt = vib_factor * sat_weight * 1.25f;
                    float lum = 0.2126f * r_f + 0.7152f * g_f + 0.0722f * b_f;
                    r = clamp_u8(static_cast<int>(std::round(r_f + (r_f - lum) * amt)));
                    g = clamp_u8(static_cast<int>(std::round(g_f + (g_f - lum) * amt)));
                    b = clamp_u8(static_cast<int>(std::round(b_f + (b_f - lum) * amt)));
                }

                // Stage 3: Clarity (local midtone contrast)
                if (!is_neutral_clarity) {
                    float r_f = static_cast<float>(r);
                    float g_f = static_cast<float>(g);
                    float b_f = static_cast<float>(b);
                    float lum = 0.2126f * r_f + 0.7152f * g_f + 0.0722f * b_f;
                    float mid_weight = 1.0f - clamp_float(std::abs(lum - 128.0f) / 128.0f, 0.0f, 1.0f);
                    float delta = (lum - 128.0f) * clarity_factor * mid_weight;
                    r = clamp_u8(static_cast<int>(std::round(r_f + delta)));
                    g = clamp_u8(static_cast<int>(std::round(g_f + delta)));
                    b = clamp_u8(static_cast<int>(std::round(b_f + delta)));
                }

                // Stage 4: Saturation & B/W Monochrome
                if (!is_neutral_sat) {
                    float r_f = static_cast<float>(r);
                    float g_f = static_cast<float>(g);
                    float b_f = static_cast<float>(b);
                    float lum = 0.2126f * r_f + 0.7152f * g_f + 0.0722f * b_f;
                    if (bw_mode) {
                        uint8_t gray = clamp_u8(static_cast<int>(std::round(lum)));
                        r = gray;
                        g = gray;
                        b = gray;
                    } else {
                        r = clamp_u8(static_cast<int>(std::round(lum + (r_f - lum) * sat_factor)));
                        g = clamp_u8(static_cast<int>(std::round(lum + (g_f - lum) * sat_factor)));
                        b = clamp_u8(static_cast<int>(std::round(lum + (b_f - lum) * sat_factor)));
                    }
                }

                // Stage 5: Vintage (lifted blacks and retro color tone)
                if (!is_neutral_vintage) {
                    r = clamp_u8(static_cast<int>(std::round(static_cast<float>(r) * (1.0f - vintage_factor * 0.15f) + vintage_factor * 35.0f)));
                    g = clamp_u8(static_cast<int>(std::round(static_cast<float>(g) * (1.0f - vintage_factor * 0.10f) + vintage_factor * 25.0f)));
                    b = clamp_u8(static_cast<int>(std::round(static_cast<float>(b) * (1.0f - vintage_factor * 0.25f) + vintage_factor * 15.0f)));
                }

                // Stage 6: Drama (chiaroscuro contrast)
                if (!is_neutral_drama) {
                    float r_f = static_cast<float>(r);
                    float g_f = static_cast<float>(g);
                    float b_f = static_cast<float>(b);
                    float lum = 0.2126f * r_f + 0.7152f * g_f + 0.0722f * b_f;
                    float diff = lum - 128.0f;
                    float mult = 1.0f + drama_factor * 0.75f * (diff / 128.0f);
                    r = clamp_u8(static_cast<int>(std::round(r_f * mult)));
                    g = clamp_u8(static_cast<int>(std::round(g_f * mult)));
                    b = clamp_u8(static_cast<int>(std::round(b_f * mult)));
                }

                // Stage 7: Film Grain (deterministic PRNG synthesis)
                if (!is_neutral_grain) {
                    rng_seed = (rng_seed * 1664525u + 1013904223u) & 0x7FFFFFFFu;
                    int rand_byte = static_cast<int>((rng_seed >> 16) & 0xFFu);
                    float noise = ((static_cast<float>(rand_byte) - 128.0f) / 128.0f) * grain_intensity;
                    r = clamp_u8(static_cast<int>(std::round(static_cast<float>(r) + noise)));
                    g = clamp_u8(static_cast<int>(std::round(static_cast<float>(g) + noise)));
                    b = clamp_u8(static_cast<int>(std::round(static_cast<float>(b) + noise)));
                }

                // Stage 8: Vignette (radial falloff)
                if (!is_neutral_vignette) {
                    const double dx = static_cast<double>(x) - vig_cx;
                    const double dist2 = dx * dx + dy2;
                    if (dist2 > vig_rad2) {
                        const double dist = std::sqrt(dist2);
                        const double t = clamp_double((dist - vig_rad) / vig_feather, 0.0, 1.0);
                        const double factor = clamp_double(1.0 + vig_intensity * t * t, 0.0, 2.0);
                        r = clamp_u8(static_cast<int>(std::round(static_cast<double>(r) * factor)));
                        g = clamp_u8(static_cast<int>(std::round(static_cast<double>(g) * factor)));
                        b = clamp_u8(static_cast<int>(std::round(static_cast<double>(b) * factor)));
                    }
                }

                // Store to output buffer
                d[0] = r;
                d[1] = g;
                d[2] = b;
                if (channels == 4) {
                    d[3] = s[3]; // Preserve alpha channel
                }
            }
        }

        // Stage 9: Structure (local 4-neighbor micro-contrast enhancement)
        if (!is_neutral_structure && height > 2 && width > 2) {
            const float factor = (structure / 100.0f) * 0.8f;
            uint8_t* dst_data = dst->data;

            for (int32_t y = 1; y < height - 1; y++) {
                uint8_t* row_up = dst_data + (y - 1) * dst_stride;
                uint8_t* row = dst_data + y * dst_stride;
                uint8_t* row_down = dst_data + (y + 1) * dst_stride;

                for (int32_t x = 1; x < width - 1; x++) {
                    uint8_t* p = row + x * channels;
                    const uint8_t* p_left = row + (x - 1) * channels;
                    const uint8_t* p_right = row + (x + 1) * channels;
                    const uint8_t* p_up = row_up + x * channels;
                    const uint8_t* p_down = row_down + x * channels;

                    double avg_r = (static_cast<double>(p_left[0]) + static_cast<double>(p_right[0]) +
                                    static_cast<double>(p_up[0]) + static_cast<double>(p_down[0])) * 0.25;
                    double avg_g = (static_cast<double>(p_left[1]) + static_cast<double>(p_right[1]) +
                                    static_cast<double>(p_up[1]) + static_cast<double>(p_down[1])) * 0.25;
                    double avg_b = (static_cast<double>(p_left[2]) + static_cast<double>(p_right[2]) +
                                    static_cast<double>(p_up[2]) + static_cast<double>(p_down[2])) * 0.25;

                    p[0] = clamp_u8(static_cast<int>(std::round(static_cast<double>(p[0]) + (static_cast<double>(p[0]) - avg_r) * factor)));
                    p[1] = clamp_u8(static_cast<int>(std::round(static_cast<double>(p[1]) + (static_cast<double>(p[1]) - avg_g) * factor)));
                    p[2] = clamp_u8(static_cast<int>(std::round(static_cast<double>(p[2]) + (static_cast<double>(p[2]) - avg_b) * factor)));
                }
            }
        }

        return AEVIQUE_SUCCESS;
    } catch (...) {
        return AEVIQUE_ERROR_UNKNOWN;
    }
}

AeviqueStatus aevique_process_advanced_tone_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueAdvancedToneParameters* params,
    const AeviqueToneCurves* curves
) {
    if (params == nullptr) {
        return AEVIQUE_ERROR_NULL_POINTER;
    }

    AeviquePipelineParameters pipeline_params;
    std::memset(&pipeline_params, 0, sizeof(AeviquePipelineParameters));
    pipeline_params.tone = *params;
    pipeline_params.vibrance = 0.0f;
    pipeline_params.clarity = 0.0f;
    pipeline_params.effects.bw_mode = 0;
    pipeline_params.effects.grain = 0.0f;
    pipeline_params.effects.vintage = 0.0f;
    pipeline_params.effects.drama = 0.0f;
    pipeline_params.vignette.amount = 0.0f;
    pipeline_params.vignette.radius = 50.0f;
    pipeline_params.vignette.feather = 50.0f;
    pipeline_params.vignette.center_x = 0.5f;
    pipeline_params.vignette.center_y = 0.5f;
    pipeline_params.structure = 0.0f;

    return aevique_process_pipeline_rgba8(src, dst, &pipeline_params, curves);
}

AeviqueStatus aevique_process_curves_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueToneParameters* tone_params,
    const AeviqueToneCurves* curves
) {
    if (tone_params == nullptr) {
        return AEVIQUE_ERROR_NULL_POINTER;
    }

    AeviqueAdvancedToneParameters adv_params;
    std::memset(&adv_params, 0, sizeof(AeviqueAdvancedToneParameters));
    adv_params.exposure = tone_params->exposure;
    adv_params.contrast = tone_params->contrast;
    adv_params.saturation = tone_params->saturation;

    return aevique_process_advanced_tone_rgba8(src, dst, &adv_params, curves);
}

AeviqueStatus aevique_process_tone_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueToneParameters* params
) {
    return aevique_process_curves_rgba8(src, dst, params, nullptr);
}

AeviqueStatus aevique_process_vibrance_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    float vibrance
) {
    AeviquePipelineParameters p;
    std::memset(&p, 0, sizeof(AeviquePipelineParameters));
    p.vibrance = vibrance;
    p.vignette.radius = 50.0f;
    p.vignette.feather = 50.0f;
    p.vignette.center_x = 0.5f;
    p.vignette.center_y = 0.5f;
    return aevique_process_pipeline_rgba8(src, dst, &p, nullptr);
}

AeviqueStatus aevique_process_clarity_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    float clarity
) {
    AeviquePipelineParameters p;
    std::memset(&p, 0, sizeof(AeviquePipelineParameters));
    p.clarity = clarity;
    p.vignette.radius = 50.0f;
    p.vignette.feather = 50.0f;
    p.vignette.center_x = 0.5f;
    p.vignette.center_y = 0.5f;
    return aevique_process_pipeline_rgba8(src, dst, &p, nullptr);
}

AeviqueStatus aevique_process_monochrome_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    float saturation,
    int32_t bw_mode
) {
    AeviquePipelineParameters p;
    std::memset(&p, 0, sizeof(AeviquePipelineParameters));
    p.tone.saturation = saturation;
    p.effects.bw_mode = bw_mode;
    p.vignette.radius = 50.0f;
    p.vignette.feather = 50.0f;
    p.vignette.center_x = 0.5f;
    p.vignette.center_y = 0.5f;
    return aevique_process_pipeline_rgba8(src, dst, &p, nullptr);
}

AeviqueStatus aevique_process_vignette_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueVignetteParameters* params
) {
    if (params == nullptr) {
        return AEVIQUE_ERROR_NULL_POINTER;
    }
    AeviquePipelineParameters p;
    std::memset(&p, 0, sizeof(AeviquePipelineParameters));
    p.vignette = *params;
    return aevique_process_pipeline_rgba8(src, dst, &p, nullptr);
}
