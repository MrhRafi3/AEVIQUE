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
            return "Invalid row stride (must be >= width * 4)";
        case AEVIQUE_ERROR_UNSUPPORTED_FORMAT:
            return "Unsupported pixel format (only RGBA8888 supported)";
        case AEVIQUE_ERROR_INVALID_PARAMETER:
            return "Invalid adjustment parameter (must not be NaN or infinite)";
        case AEVIQUE_ERROR_BUFFER_TOO_SMALL:
            return "Buffer capacity is smaller than required by dimensions and stride";
        default:
            return "Unknown error";
    }
}

AeviqueStatus aevique_process_advanced_tone_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueAdvancedToneParameters* params,
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

        // 2. Validate dimensions
        if (src->width <= 0 || src->height <= 0 || dst->width <= 0 || dst->height <= 0) {
            return AEVIQUE_ERROR_INVALID_DIMENSIONS;
        }
        if (src->width != dst->width || src->height != dst->height) {
            return AEVIQUE_ERROR_INVALID_DIMENSIONS;
        }

        // 3. Validate stride
        int32_t min_stride = src->width * 4;
        if (src->stride_bytes < min_stride || dst->stride_bytes < min_stride) {
            return AEVIQUE_ERROR_INVALID_STRIDE;
        }

        // 4. Validate pixel formats
        if (src->format != AEVIQUE_PIXEL_FORMAT_RGBA8888 || dst->format != AEVIQUE_PIXEL_FORMAT_RGBA8888) {
            return AEVIQUE_ERROR_UNSUPPORTED_FORMAT;
        }

        // 5. Validate parameters for NaN or Infinity
        if (std::isnan(params->exposure) || std::isinf(params->exposure) ||
            std::isnan(params->contrast) || std::isinf(params->contrast) ||
            std::isnan(params->saturation) || std::isinf(params->saturation) ||
            std::isnan(params->brightness) || std::isinf(params->brightness) ||
            std::isnan(params->warmth) || std::isinf(params->warmth) ||
            std::isnan(params->tint) || std::isinf(params->tint) ||
            std::isnan(params->highlights) || std::isinf(params->highlights) ||
            std::isnan(params->shadows) || std::isinf(params->shadows) ||
            std::isnan(params->whites) || std::isinf(params->whites) ||
            std::isnan(params->blacks) || std::isinf(params->blacks) ||
            std::isnan(params->ambiance) || std::isinf(params->ambiance)) {
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

        const double exposure = clamp_double(params->exposure, -100.0, 100.0);
        const double contrast = clamp_double(params->contrast, -100.0, 100.0);
        const float saturation = clamp_float(params->saturation, -100.0f, 100.0f);
        const double brightness = clamp_double(params->brightness, -100.0, 100.0);
        const double warmth = clamp_double(params->warmth, -100.0, 100.0);
        const double tint = clamp_double(params->tint, -100.0, 100.0);
        const double highlights = clamp_double(params->highlights, -100.0, 100.0);
        const double shadows = clamp_double(params->shadows, -100.0, 100.0);
        const double whites = clamp_double(params->whites, -100.0, 100.0);
        const double blacks = clamp_double(params->blacks, -100.0, 100.0);
        const double ambiance = clamp_double(params->ambiance, -100.0, 100.0);

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

        // Check if all LUTs are identity
        bool is_neutral_lut = true;
        for (int i = 0; i < 256; i++) {
            if (r_lut[i] != i || g_lut[i] != i || b_lut[i] != i) {
                is_neutral_lut = false;
                break;
            }
        }
        const bool is_neutral_sat = (std::abs(saturation) < 1e-4f);

        // Fast-path: completely neutral adjustments
        if (is_neutral_lut && is_neutral_sat) {
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

        const float sat_factor = clamp_float((saturation + 100.0f) / 100.0f, 0.0f, 3.0f);
        const int32_t width = src->width;
        const int32_t height = src->height;
        const int32_t src_stride = src->stride_bytes;
        const int32_t dst_stride = dst->stride_bytes;

        if (is_neutral_sat) {
            // Tone-only fast loop (3 1D LUT lookups per pixel, zero floating-point arithmetic)
            for (int32_t y = 0; y < height; y++) {
                const uint8_t* src_row = src->data + y * src_stride;
                uint8_t* dst_row = dst->data + y * dst_stride;

                for (int32_t x = 0; x < width; x++) {
                    const uint8_t* s = src_row + (x * 4);
                    uint8_t* d = dst_row + (x * 4);

                    d[0] = r_lut[s[0]];
                    d[1] = g_lut[s[1]];
                    d[2] = b_lut[s[2]];
                    d[3] = s[3]; // Preserve alpha
                }
            }
        } else {
            // Fused Tone + Saturation loop
            for (int32_t y = 0; y < height; y++) {
                const uint8_t* src_row = src->data + y * src_stride;
                uint8_t* dst_row = dst->data + y * dst_stride;

                for (int32_t x = 0; x < width; x++) {
                    const uint8_t* s = src_row + (x * 4);
                    uint8_t* d = dst_row + (x * 4);

                    uint8_t r_tone = r_lut[s[0]];
                    uint8_t g_tone = g_lut[s[1]];
                    uint8_t b_tone = b_lut[s[2]];

                    float lum = 0.2126f * r_tone + 0.7152f * g_tone + 0.0722f * b_tone;
                    int r_out = static_cast<int>(std::round(lum + (r_tone - lum) * sat_factor));
                    int g_out = static_cast<int>(std::round(lum + (g_tone - lum) * sat_factor));
                    int b_out = static_cast<int>(std::round(lum + (b_tone - lum) * sat_factor));

                    d[0] = clamp_u8(r_out);
                    d[1] = clamp_u8(g_out);
                    d[2] = clamp_u8(b_out);
                    d[3] = s[3]; // Preserve alpha
                }
            }
        }

        return AEVIQUE_SUCCESS;
    } catch (...) {
        return AEVIQUE_ERROR_UNKNOWN;
    }
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
    adv_params.exposure = tone_params->exposure;
    adv_params.contrast = tone_params->contrast;
    adv_params.saturation = tone_params->saturation;
    adv_params.brightness = 0.0f;
    adv_params.warmth = 0.0f;
    adv_params.tint = 0.0f;
    adv_params.highlights = 0.0f;
    adv_params.shadows = 0.0f;
    adv_params.whites = 0.0f;
    adv_params.blacks = 0.0f;
    adv_params.ambiance = 0.0f;

    return aevique_process_advanced_tone_rgba8(src, dst, &adv_params, curves);
}

AeviqueStatus aevique_process_tone_rgba8(
    const AeviqueImageBuffer* src,
    AeviqueImageBuffer* dst,
    const AeviqueToneParameters* params
) {
    return aevique_process_curves_rgba8(src, dst, params, nullptr);
}
