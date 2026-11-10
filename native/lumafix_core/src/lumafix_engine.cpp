#include "lumafix_engine.h"

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

static bool is_identity_curve(const LumaFixCurvePoint* points, int32_t count) {
    if (count == 0 || points == nullptr) return true;
    if (count != 2) return false;
    return (std::abs(points[0].x - 0.0f) < 1e-4f) &&
           (std::abs(points[0].y - 0.0f) < 1e-4f) &&
           (std::abs(points[1].x - 1.0f) < 1e-4f) &&
           (std::abs(points[1].y - 1.0f) < 1e-4f);
}

static void interpolate_curve_channel(const LumaFixCurveChannel* channel, uint8_t lut[256]) {
    if (channel == nullptr || channel->point_count == 0 || channel->points == nullptr ||
        is_identity_curve(channel->points, channel->point_count)) {
        for (int i = 0; i < 256; i++) {
            lut[i] = static_cast<uint8_t>(i);
        }
        return;
    }

    std::vector<LumaFixCurvePoint> sorted(channel->points, channel->points + channel->point_count);
    std::sort(sorted.begin(), sorted.end(), [](const LumaFixCurvePoint& a, const LumaFixCurvePoint& b) {
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
            if (dx <= 1e-6) {
                lut[i] = clamp_u8(static_cast<int>(std::round(p0_y * 255.0)));
            } else if (num_points == 2) {
                const double t = (norm_x - p0_x) / dx;
                const double interpolated_y = p0_y + (p1_y - p0_y) * t;
                lut[i] = clamp_u8(static_cast<int>(std::round(interpolated_y * 255.0)));
            } else {
                const double t = (norm_x - p0_x) / dx;
                double m0 = p1_y - p0_y;
                double m1 = m0;
                if (idx > 0) {
                    double prev_dx = p0_x - static_cast<double>(sorted[idx - 1].x);
                    if (prev_dx > 1e-6) {
                        m0 = 0.5 * ((p1_y - p0_y) + (p0_y - static_cast<double>(sorted[idx - 1].y)));
                    }
                }
                if (idx + 2 < num_points) {
                    double next_dx = static_cast<double>(sorted[idx + 2].x) - p1_x;
                    if (next_dx > 1e-6) {
                        m1 = 0.5 * ((static_cast<double>(sorted[idx + 2].y) - p1_y) + (p1_y - p0_y));
                    }
                }
                const double h00 = (1.0 + 2.0 * t) * (1.0 - t) * (1.0 - t);
                const double h10 = t * (1.0 - t) * (1.0 - t);
                const double h01 = t * t * (3.0 - 2.0 * t);
                const double h11 = t * t * (t - 1.0);
                const double interpolated_y = h00 * p0_y + h10 * m0 + h01 * p1_y + h11 * m1;
                lut[i] = clamp_u8(static_cast<int>(std::round(clamp_double(interpolated_y, 0.0, 1.0) * 255.0)));
            }
        }
    }
}

static inline void rgb_to_hsl(float r, float g, float b, float& h, float& s, float& l) {
    float max_c = std::max({r, g, b});
    float min_c = std::min({r, g, b});
    float delta = max_c - min_c;

    l = (max_c + min_c) * 0.5f;

    if (delta < 1e-5f) {
        h = 0.0f;
        s = 0.0f;
    } else {
        s = (l > 0.5f) ? (delta / (2.0f - max_c - min_c)) : (delta / (max_c + min_c));

        if (max_c == r) {
            h = (g - b) / delta + (g < b ? 6.0f : 0.0f);
        } else if (max_c == g) {
            h = (b - r) / delta + 2.0f;
        } else {
            h = (r - g) / delta + 4.0f;
        }
        h *= 60.0f;
    }
}

static inline float hue_to_rgb(float p, float q, float t) {
    if (t < 0.0f) t += 1.0f;
    if (t > 1.0f) t -= 1.0f;
    if (t < 1.0f / 6.0f) return p + (q - p) * 6.0f * t;
    if (t < 1.0f / 2.0f) return q;
    if (t < 2.0f / 3.0f) return p + (q - p) * (2.0f / 3.0f - t) * 6.0f;
    return p;
}

static inline void hsl_to_rgb(float h, float s, float l, float& r, float& g, float& b) {
    if (s < 1e-5f) {
        r = g = b = l;
    } else {
        h = h / 360.0f;
        if (h < 0.0f) h += 1.0f;
        if (h >= 1.0f) h -= 1.0f;

        float q = (l < 0.5f) ? (l * (1.0f + s)) : (l + s - l * s);
        float p = 2.0f * l - q;

        r = hue_to_rgb(p, q, h + 1.0f / 3.0f);
        g = hue_to_rgb(p, q, h);
        b = hue_to_rgb(p, q, h - 1.0f / 3.0f);
    }
}

// Returns skin tone probability in [0.0f, 1.0f] for normalized RGB inputs
static inline float compute_skin_probability(float r, float g, float b) {
    if (r <= g || g <= b || r < 0.15f || r > 0.98f) {
        return 0.0f;
    }

    float h, s, l;
    rgb_to_hsl(r, g, b, h, s, l);

    if (h < 10.0f || h > 50.0f) {
        return 0.0f;
    }
    if (s < 0.12f || s > 0.72f) {
        return 0.0f;
    }
    if (l < 0.15f || l > 0.92f) {
        return 0.0f;
    }

    float hue_dist = std::abs(h - 28.0f);
    float hue_weight = clamp_float(1.0f - (hue_dist / 22.0f), 0.0f, 1.0f);

    float sat_dist = std::abs(s - 0.38f);
    float sat_weight = clamp_float(1.0f - (sat_dist / 0.34f), 0.0f, 1.0f);

    float lum_dist = std::abs(l - 0.55f);
    float lum_weight = clamp_float(1.0f - (lum_dist / 0.40f), 0.0f, 1.0f);

    return hue_weight * sat_weight * lum_weight;
}

static inline bool is_hsl_neutral(const LumaFixHslParameters* hsl) {
    if (hsl == nullptr) return true;
    const LumaFixHslBand* bands[8] = {
        &hsl->red, &hsl->orange, &hsl->yellow, &hsl->green,
        &hsl->aqua, &hsl->blue, &hsl->purple, &hsl->magenta
    };
    for (int i = 0; i < 8; i++) {
        if (std::abs(bands[i]->hue) > 1e-4f ||
            std::abs(bands[i]->saturation) > 1e-4f ||
            std::abs(bands[i]->luminance) > 1e-4f) {
            return false;
        }
    }
    return true;
}

static inline void apply_hsl_pixel(
    uint8_t& r_u8, uint8_t& g_u8, uint8_t& b_u8,
    const LumaFixHslParameters& hsl
) {
    float r = static_cast<float>(r_u8) / 255.0f;
    float g = static_cast<float>(g_u8) / 255.0f;
    float b = static_cast<float>(b_u8) / 255.0f;

    float h, s, l;
    rgb_to_hsl(r, g, b, h, s, l);

    if (s < 0.02f) {
        return; // Grayscale or near-grayscale is neutral
    }

    static const float center_hues[8] = {
        0.0f,   // Red
        30.0f,  // Orange
        60.0f,  // Yellow
        120.0f, // Green
        180.0f, // Aqua
        240.0f, // Blue
        280.0f, // Purple
        320.0f  // Magenta
    };

    static const float half_widths[8] = {
        35.0f,  // Red
        28.0f,  // Orange
        38.0f,  // Yellow
        48.0f,  // Green
        42.0f,  // Aqua
        42.0f,  // Blue
        32.0f,  // Purple
        32.0f   // Magenta
    };

    const LumaFixHslBand* bands[8] = {
        &hsl.red, &hsl.orange, &hsl.yellow, &hsl.green,
        &hsl.aqua, &hsl.blue, &hsl.purple, &hsl.magenta
    };

    float total_weight = 0.0f;
    float delta_h = 0.0f;
    float delta_s = 0.0f;
    float delta_l = 0.0f;

    for (int i = 0; i < 8; i++) {
        float center = center_hues[i];
        float width = half_widths[i];
        float d = std::abs(h - center);
        if (d > 180.0f) d = 360.0f - d;

        if (d < width) {
            float weight = 0.5f * (1.0f + std::cos(3.141592653589793f * d / width));
            total_weight += weight;
            delta_h += weight * (bands[i]->hue * 0.45f);
            delta_s += weight * (bands[i]->saturation / 100.0f);
            delta_l += weight * (bands[i]->luminance / 100.0f * 0.5f);
        }
    }

    if (total_weight > 1e-4f) {
        float norm = 1.0f / std::max(1.0f, total_weight);
        h = std::fmod(h + delta_h * norm + 360.0f, 360.0f);
        s = clamp_float(s * (1.0f + delta_s * norm), 0.0f, 1.0f);
        l = clamp_float(l + delta_l * norm, 0.0f, 1.0f);
    }

    float out_r, out_g, out_b;
    hsl_to_rgb(h, s, l, out_r, out_g, out_b);

    r_u8 = clamp_u8(static_cast<int>(std::round(out_r * 255.0f)));
    g_u8 = clamp_u8(static_cast<int>(std::round(out_g * 255.0f)));
    b_u8 = clamp_u8(static_cast<int>(std::round(out_b * 255.0f)));
}

// Separable fast box / gaussian approximation on an image buffer
static void apply_fast_diffusion(
    uint8_t* data, int32_t width, int32_t height, int32_t stride, int32_t channels,
    float factor, bool highlight_only
) {
    if (factor <= 0.001f || width < 4 || height < 4) return;

    float blend_weight = factor * 0.5f;
    int32_t dw = std::max(4, width / 4);
    int32_t dh = std::max(4, height / 4);
    std::vector<uint8_t> down(static_cast<size_t>(dw * dh * channels));

    for (int32_t dy = 0; dy < dh; dy++) {
        int32_t sy = (dy * height) / dh;
        const uint8_t* srow = data + sy * stride;
        uint8_t* drow = down.data() + dy * (dw * channels);
        for (int32_t dx = 0; dx < dw; dx++) {
            int32_t sx = (dx * width) / dw;
            const uint8_t* sp = srow + sx * channels;
            uint8_t* dp = drow + dx * channels;

            float lum = 0.2126f * sp[0] + 0.7152f * sp[1] + 0.0722f * sp[2];
            if (highlight_only && lum < 155.0f) {
                dp[0] = 0;
                dp[1] = 0;
                dp[2] = 0;
            } else {
                dp[0] = sp[0];
                dp[1] = sp[1];
                dp[2] = sp[2];
            }
            if (channels == 4) dp[3] = sp[3];
        }
    }

    std::vector<uint8_t> blurred = down;
    for (int32_t y = 1; y < dh - 1; y++) {
        for (int32_t x = 1; x < dw - 1; x++) {
            for (int32_t c = 0; c < 3; c++) {
                int sum = 0;
                for (int ky = -1; ky <= 1; ky++) {
                    for (int kx = -1; kx <= 1; kx++) {
                        sum += down[static_cast<size_t>(((y + ky) * dw + (x + kx)) * channels + c)];
                    }
                }
                blurred[static_cast<size_t>((y * dw + x) * channels + c)] = static_cast<uint8_t>(sum / 9);
            }
        }
    }

    for (int32_t y = 0; y < height; y++) {
        int32_t dy = (y * dh) / height;
        uint8_t* row = data + y * stride;
        const uint8_t* brow = blurred.data() + dy * (dw * channels);
        for (int32_t x = 0; x < width; x++) {
            int32_t dx = (x * dw) / width;
            uint8_t* p = row + x * channels;
            const uint8_t* bp = brow + dx * channels;

            p[0] = clamp_u8(static_cast<int>(p[0] + bp[0] * blend_weight));
            p[1] = clamp_u8(static_cast<int>(p[1] + bp[1] * blend_weight));
            p[2] = clamp_u8(static_cast<int>(p[2] + bp[2] * blend_weight));
        }
    }
}

static void apply_chromatic_aberration_native(
    uint8_t* data, int32_t width, int32_t height, int32_t stride, int32_t channels,
    float strength
) {
    if (strength <= 0.001f || width < 8) return;
    int offset = std::max(1, static_cast<int>(std::round((strength / 100.0f) * 12.0f)));
    std::vector<uint8_t> temp_row(static_cast<size_t>(width * channels));

    for (int32_t y = 0; y < height; y++) {
        uint8_t* row = data + y * stride;
        std::memcpy(temp_row.data(), row, static_cast<size_t>(width * channels));

        for (int32_t x = 0; x < width; x++) {
            int rx = std::max(0, x - offset);
            int bx = std::min(width - 1, x + offset);
            row[x * channels + 0] = temp_row[static_cast<size_t>(rx * channels + 0)];
            row[x * channels + 2] = temp_row[static_cast<size_t>(bx * channels + 2)];
        }
    }
}

static void apply_lens_blur_native(
    uint8_t* data, int32_t width, int32_t height, int32_t stride, int32_t channels,
    float strength
) {
    if (strength <= 0.001f || width < 4 || height < 4) return;
    int radius = std::max(1, static_cast<int>(std::round((strength / 100.0f) * 8.0f)));

    std::vector<uint8_t> temp(static_cast<size_t>(height * stride));
    for (int32_t y = 0; y < height; y++) {
        const uint8_t* src_row = data + y * stride;
        uint8_t* dst_row = temp.data() + y * stride;

        for (int32_t x = 0; x < width; x++) {
            int32_t sum_r = 0, sum_g = 0, sum_b = 0, count = 0;
            int32_t start_x = std::max(0, x - radius);
            int32_t end_x = std::min(width - 1, x + radius);
            for (int32_t kx = start_x; kx <= end_x; kx++) {
                const uint8_t* p = src_row + kx * channels;
                sum_r += p[0];
                sum_g += p[1];
                sum_b += p[2];
                count++;
            }
            dst_row[x * channels + 0] = static_cast<uint8_t>(sum_r / count);
            dst_row[x * channels + 1] = static_cast<uint8_t>(sum_g / count);
            dst_row[x * channels + 2] = static_cast<uint8_t>(sum_b / count);
            if (channels == 4) dst_row[x * channels + 3] = src_row[x * channels + 3];
        }
    }

    for (int32_t x = 0; x < width; x++) {
        for (int32_t y = 0; y < height; y++) {
            int32_t sum_r = 0, sum_g = 0, sum_b = 0, count = 0;
            int32_t start_y = std::max(0, y - radius);
            int32_t end_y = std::min(height - 1, y + radius);
            for (int32_t ky = start_y; ky <= end_y; ky++) {
                const uint8_t* p = temp.data() + ky * stride + x * channels;
                sum_r += p[0];
                sum_g += p[1];
                sum_b += p[2];
                count++;
            }
            uint8_t* out_p = data + y * stride + x * channels;
            out_p[0] = static_cast<uint8_t>(sum_r / count);
            out_p[1] = static_cast<uint8_t>(sum_g / count);
            out_p[2] = static_cast<uint8_t>(sum_b / count);
        }
    }
}

static void apply_native_sharpening(
    uint8_t* data, int32_t width, int32_t height, int32_t stride, int32_t channels,
    float strength
) {
    if (strength <= 0.001f || width < 3 || height < 3) return;

    // Map 0..100 to factor 0..0.75
    const float factor = (strength / 100.0f) * 0.75f;
    const size_t row_bytes = static_cast<size_t>(width * channels);

    std::vector<uint8_t> prev_row(row_bytes);
    std::vector<uint8_t> curr_row(row_bytes);

    std::memcpy(curr_row.data(), data, row_bytes);

    for (int32_t y = 1; y < height - 1; y++) {
        std::memcpy(prev_row.data(), curr_row.data(), row_bytes);
        uint8_t* actual_curr_row = data + static_cast<size_t>(y) * static_cast<size_t>(stride);
        std::memcpy(curr_row.data(), actual_curr_row, row_bytes);
        const uint8_t* next_row = data + static_cast<size_t>(y + 1) * static_cast<size_t>(stride);

        for (int32_t x = 1; x < width - 1; x++) {
            const uint8_t* center = curr_row.data() + x * channels;
            const uint8_t* left = curr_row.data() + (x - 1) * channels;
            const uint8_t* right = curr_row.data() + (x + 1) * channels;
            const uint8_t* up = prev_row.data() + x * channels;
            const uint8_t* down = next_row + x * channels;

            uint8_t* out = actual_curr_row + x * channels;

            // Skin protection: preserve smooth skin texture while sharpening edges
            float skin_prob = 0.0f;
            if (channels >= 3) {
                skin_prob = compute_skin_probability(
                    static_cast<float>(center[0]) / 255.0f,
                    static_cast<float>(center[1]) / 255.0f,
                    static_cast<float>(center[2]) / 255.0f
                );
            }
            const float effective_factor = factor * (1.0f - 0.45f * skin_prob);

            for (int32_t c = 0; c < 3; c++) {
                int c_val = center[c];
                int laplacian = (c_val * 4) - (left[c] + right[c] + up[c] + down[c]);
                // Coring: ignore microscopic noise fluctuation
                if (std::abs(laplacian) <= 2) {
                    continue;
                }
                int sharpened = static_cast<int>(std::round(static_cast<float>(c_val) + static_cast<float>(laplacian) * effective_factor));
                out[c] = clamp_u8(sharpened);
            }
        }
    }
}

uint32_t lumafix_get_version(void) {
    return (LUMAFIX_VERSION_MAJOR << 16) | (LUMAFIX_VERSION_MINOR << 8) | LUMAFIX_VERSION_PATCH;
}

const char* lumafix_status_to_string(LumaFixStatus status) {
    switch (status) {
        case LUMAFIX_SUCCESS:
            return "Success";
        case LUMAFIX_ERROR_NULL_POINTER:
            return "Null pointer argument";
        case LUMAFIX_ERROR_INVALID_DIMENSIONS:
            return "Invalid image dimensions";
        case LUMAFIX_ERROR_INVALID_STRIDE:
            return "Invalid row stride (must be >= width * channels)";
        case LUMAFIX_ERROR_UNSUPPORTED_FORMAT:
            return "Unsupported pixel format (only RGBA8888 and RGB888 supported)";
        case LUMAFIX_ERROR_INVALID_PARAMETER:
            return "Invalid adjustment parameter (must not be NaN or infinite)";
        case LUMAFIX_ERROR_BUFFER_TOO_SMALL:
            return "Buffer capacity is smaller than required by dimensions and stride";
        default:
            return "Unknown error";
    }
}

LumaFixStatus lumafix_process_pipeline_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixPipelineParameters* params,
    const LumaFixToneCurves* curves
) {
    try {
        // 1. Validate pointers
        if (src == nullptr || dst == nullptr || params == nullptr) {
            return LUMAFIX_ERROR_NULL_POINTER;
        }
        if (src->data == nullptr || dst->data == nullptr) {
            return LUMAFIX_ERROR_NULL_POINTER;
        }

        // 2. Validate dimensions and guard against integer overflow
        if (src->width <= 0 || src->height <= 0 || dst->width <= 0 || dst->height <= 0 ||
            src->width > 65536 || src->height > 65536) {
            return LUMAFIX_ERROR_INVALID_DIMENSIONS;
        }
        if (src->width != dst->width || src->height != dst->height) {
            return LUMAFIX_ERROR_INVALID_DIMENSIONS;
        }

        // 3. Validate pixel formats
        if (src->format != dst->format) {
            return LUMAFIX_ERROR_INVALID_DIMENSIONS;
        }
        if (src->format != LUMAFIX_PIXEL_FORMAT_RGBA8888 &&
            src->format != LUMAFIX_PIXEL_FORMAT_RGB888) {
            return LUMAFIX_ERROR_UNSUPPORTED_FORMAT;
        }

        const int32_t bpp = (src->format == LUMAFIX_PIXEL_FORMAT_RGB888) ? 3 : 4;

        // 4. Validate stride with 64-bit integer overflow protection
        int64_t min_stride_64 = static_cast<int64_t>(src->width) * static_cast<int64_t>(bpp);
        if (min_stride_64 > INT32_MAX ||
            static_cast<int64_t>(src->stride_bytes) < min_stride_64 ||
            static_cast<int64_t>(dst->stride_bytes) < min_stride_64) {
            return LUMAFIX_ERROR_INVALID_STRIDE;
        }
        int32_t min_stride = static_cast<int32_t>(min_stride_64);

        // 5. Validate parameters for NaN or Infinity
        const LumaFixAdvancedToneParameters* t = &params->tone;
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
            std::isnan(params->sharpening) || std::isinf(params->sharpening) ||
            std::isnan(params->effects.grain) || std::isinf(params->effects.grain) ||
            std::isnan(params->effects.vintage) || std::isinf(params->effects.vintage) ||
            std::isnan(params->effects.drama) || std::isinf(params->effects.drama) ||
            std::isnan(params->effects.bloom) || std::isinf(params->effects.bloom) ||
            std::isnan(params->effects.glow) || std::isinf(params->effects.glow) ||
            std::isnan(params->effects.chromatic_aberration) || std::isinf(params->effects.chromatic_aberration) ||
            std::isnan(params->effects.lens_blur) || std::isinf(params->effects.lens_blur) ||
            std::isnan(params->vignette.amount) || std::isinf(params->vignette.amount) ||
            std::isnan(params->vignette.radius) || std::isinf(params->vignette.radius) ||
            std::isnan(params->vignette.feather) || std::isinf(params->vignette.feather) ||
            std::isnan(params->vignette.center_x) || std::isinf(params->vignette.center_x) ||
            std::isnan(params->vignette.center_y) || std::isinf(params->vignette.center_y)) {
            return LUMAFIX_ERROR_INVALID_PARAMETER;
        }

        // Validate HSL parameters for NaN or Inf
        const LumaFixHslBand* hsl_bands_check[8] = {
            &params->hsl.red, &params->hsl.orange, &params->hsl.yellow, &params->hsl.green,
            &params->hsl.aqua, &params->hsl.blue, &params->hsl.purple, &params->hsl.magenta
        };
        for (int i = 0; i < 8; i++) {
            if (std::isnan(hsl_bands_check[i]->hue) || std::isinf(hsl_bands_check[i]->hue) ||
                std::isnan(hsl_bands_check[i]->saturation) || std::isinf(hsl_bands_check[i]->saturation) ||
                std::isnan(hsl_bands_check[i]->luminance) || std::isinf(hsl_bands_check[i]->luminance)) {
                return LUMAFIX_ERROR_INVALID_PARAMETER;
            }
        }

        // Validate curve points for NaN or Inf if provided
        if (curves != nullptr) {
            const LumaFixCurveChannel* channels[4] = {&curves->rgb, &curves->red, &curves->green, &curves->blue};
            for (int c = 0; c < 4; c++) {
                if (channels[c] != nullptr && channels[c]->point_count > 0 && channels[c]->points != nullptr) {
                    for (int32_t p = 0; p < channels[c]->point_count; p++) {
                        if (std::isnan(channels[c]->points[p].x) || std::isinf(channels[c]->points[p].x) ||
                            std::isnan(channels[c]->points[p].y) || std::isinf(channels[c]->points[p].y)) {
                            return LUMAFIX_ERROR_INVALID_PARAMETER;
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
        const float sharpening = clamp_float(params->sharpening, 0.0f, 100.0f);

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

        // Generate 3 composite 1D LUTs matching LumaFix Dart LutGenerator
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

            // Highlights adjustment (values > 100) with smooth Hermite roll-off
            if (highlights != 0.0 && i > 100) {
                double t_h = (static_cast<double>(i) - 100.0) / 155.0;
                double smooth_h = t_h * t_h * (3.0 - 2.0 * t_h);
                base += highlights * 0.6 * smooth_h;
            }

            // Shadows adjustment (values < 155) with black floor protection
            if (shadows != 0.0 && i < 155) {
                double t_s = (155.0 - static_cast<double>(i)) / 155.0;
                double smooth_s = t_s * t_s * (3.0 - 2.0 * t_s);
                double t_black = clamp_double(static_cast<double>(i) / 16.0, 0.0, 1.0);
                double black_taper = t_black * t_black * (3.0 - 2.0 * t_black);
                base += shadows * 0.6 * smooth_s * black_taper;
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
        const bool is_neutral_hsl = is_hsl_neutral(&params->hsl);
        const bool is_neutral_vintage = (vintage <= 0.001f);
        const bool is_neutral_drama = (drama <= 0.001f);
        const bool is_neutral_grain = (grain <= 0.001f);
        const bool is_neutral_bloom = (params->effects.bloom <= 0.001f);
        const bool is_neutral_glow = (params->effects.glow <= 0.001f);
        const bool is_neutral_chromatic = (params->effects.chromatic_aberration <= 0.001f);
        const bool is_neutral_lens_blur = (params->effects.lens_blur <= 0.001f);
        const bool is_neutral_vignette = (std::abs(vig_amount_param) < 1e-4f);
        const bool is_neutral_structure = (structure <= 0.001f);
        const bool is_neutral_sharpening = (sharpening <= 0.001f);

        // Fast-path 0: completely neutral adjustment state
        if (is_neutral_lut && is_neutral_sat && is_neutral_vibrance && is_neutral_clarity &&
            is_neutral_hsl && is_neutral_vintage && is_neutral_drama && is_neutral_grain &&
            is_neutral_bloom && is_neutral_glow && is_neutral_chromatic && is_neutral_lens_blur &&
            is_neutral_vignette && is_neutral_structure && is_neutral_sharpening) {
            if (src->data == dst->data) {
                return LUMAFIX_SUCCESS;
            }
            for (int32_t y = 0; y < src->height; y++) {
                const uint8_t* src_row = src->data + y * src->stride_bytes;
                uint8_t* dst_row = dst->data + y * dst->stride_bytes;
                std::memcpy(dst_row, src_row, static_cast<size_t>(min_stride));
            }
            return LUMAFIX_SUCCESS;
        }

        const int32_t width = src->width;
        const int32_t height = src->height;
        const int32_t src_stride = src->stride_bytes;
        const int32_t dst_stride = dst->stride_bytes;
        const int32_t channels = bpp;

        // Fast-path 1: Tone-only (3 1D LUT lookups per pixel, zero floating-point arithmetic)
        if (is_neutral_sat && is_neutral_vibrance && is_neutral_clarity && is_neutral_hsl &&
            is_neutral_vintage && is_neutral_drama && is_neutral_grain &&
            is_neutral_bloom && is_neutral_glow && is_neutral_chromatic && is_neutral_lens_blur &&
            is_neutral_vignette && is_neutral_structure && is_neutral_sharpening) {
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
            return LUMAFIX_SUCCESS;
        }

        // Fast-path 2: Tone + Saturation only (no other effects active)
        if (is_neutral_vibrance && is_neutral_clarity && is_neutral_hsl &&
            is_neutral_vintage && is_neutral_drama && is_neutral_grain &&
            is_neutral_bloom && is_neutral_glow && is_neutral_chromatic && is_neutral_lens_blur &&
            is_neutral_vignette && is_neutral_structure && is_neutral_sharpening) {
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
                        float effective_sat = sat_factor;
                        if (sat_factor > 1.0f) {
                            float skin_prob = compute_skin_probability(
                                static_cast<float>(r_tone) / 255.0f,
                                static_cast<float>(g_tone) / 255.0f,
                                static_cast<float>(b_tone) / 255.0f
                            );
                            effective_sat = 1.0f + (sat_factor - 1.0f) * (1.0f - 0.55f * skin_prob);
                        }
                        d[0] = clamp_u8(static_cast<int>(std::round(lum + (r_tone - lum) * effective_sat)));
                        d[1] = clamp_u8(static_cast<int>(std::round(lum + (g_tone - lum) * effective_sat)));
                        d[2] = clamp_u8(static_cast<int>(std::round(lum + (b_tone - lum) * effective_sat)));
                    }
                    if (channels == 4) {
                        d[3] = s[3]; // Preserve alpha
                    }
                }
            }
            return LUMAFIX_SUCCESS;
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

                    float skin_prob = compute_skin_probability(r_f / 255.0f, g_f / 255.0f, b_f / 255.0f);
                    float skin_protection = (vib_factor > 0.0f) ? (1.0f - 0.65f * skin_prob) : 1.0f;

                    float amt = vib_factor * sat_weight * 1.25f * skin_protection;
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

                // Stage 3.5: HSL Color Mixer (8-band targeted color adjustments)
                if (!is_neutral_hsl) {
                    apply_hsl_pixel(r, g, b, params->hsl);
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
                        float effective_sat = sat_factor;
                        if (sat_factor > 1.0f) {
                            float skin_prob = compute_skin_probability(r_f / 255.0f, g_f / 255.0f, b_f / 255.0f);
                            effective_sat = 1.0f + (sat_factor - 1.0f) * (1.0f - 0.55f * skin_prob);
                        }
                        r = clamp_u8(static_cast<int>(std::round(lum + (r_f - lum) * effective_sat)));
                        g = clamp_u8(static_cast<int>(std::round(lum + (g_f - lum) * effective_sat)));
                        b = clamp_u8(static_cast<int>(std::round(lum + (b_f - lum) * effective_sat)));
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

        // Stage 9.5: Sharpening (edge-preserving high-frequency unsharp mask)
        if (!is_neutral_sharpening && height > 2 && width > 2) {
            apply_native_sharpening(dst->data, width, height, dst_stride, channels, sharpening);
        }

        // Stage 10: Highlight Bloom
        if (!is_neutral_bloom) {
            apply_fast_diffusion(dst->data, width, height, dst_stride, channels,
                                 clamp_float(params->effects.bloom, 0.0f, 100.0f) / 100.0f, true);
        }

        // Stage 11: Soft Diffusion Glow
        if (!is_neutral_glow) {
            apply_fast_diffusion(dst->data, width, height, dst_stride, channels,
                                 clamp_float(params->effects.glow, 0.0f, 100.0f) / 100.0f, false);
        }

        // Stage 12: Chromatic Aberration
        if (!is_neutral_chromatic) {
            apply_chromatic_aberration_native(dst->data, width, height, dst_stride, channels,
                                              clamp_float(params->effects.chromatic_aberration, 0.0f, 100.0f));
        }

        // Stage 13: Lens Blur
        if (!is_neutral_lens_blur) {
            apply_lens_blur_native(dst->data, width, height, dst_stride, channels,
                                   clamp_float(params->effects.lens_blur, 0.0f, 100.0f));
        }

        return LUMAFIX_SUCCESS;
    } catch (...) {
        return LUMAFIX_ERROR_UNKNOWN;
    }
}

LumaFixStatus lumafix_process_advanced_tone_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixAdvancedToneParameters* params,
    const LumaFixToneCurves* curves
) {
    if (params == nullptr) {
        return LUMAFIX_ERROR_NULL_POINTER;
    }

    LumaFixPipelineParameters pipeline_params;
    std::memset(&pipeline_params, 0, sizeof(LumaFixPipelineParameters));
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
    pipeline_params.sharpening = 0.0f;

    return lumafix_process_pipeline_rgba8(src, dst, &pipeline_params, curves);
}

LumaFixStatus lumafix_process_curves_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixToneParameters* tone_params,
    const LumaFixToneCurves* curves
) {
    if (tone_params == nullptr) {
        return LUMAFIX_ERROR_NULL_POINTER;
    }

    LumaFixAdvancedToneParameters adv_params;
    std::memset(&adv_params, 0, sizeof(LumaFixAdvancedToneParameters));
    adv_params.exposure = tone_params->exposure;
    adv_params.contrast = tone_params->contrast;
    adv_params.saturation = tone_params->saturation;

    return lumafix_process_advanced_tone_rgba8(src, dst, &adv_params, curves);
}

LumaFixStatus lumafix_process_tone_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixToneParameters* params
) {
    return lumafix_process_curves_rgba8(src, dst, params, nullptr);
}

LumaFixStatus lumafix_process_vibrance_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    float vibrance
) {
    LumaFixPipelineParameters p;
    std::memset(&p, 0, sizeof(LumaFixPipelineParameters));
    p.vibrance = vibrance;
    p.vignette.radius = 50.0f;
    p.vignette.feather = 50.0f;
    p.vignette.center_x = 0.5f;
    p.vignette.center_y = 0.5f;
    return lumafix_process_pipeline_rgba8(src, dst, &p, nullptr);
}

LumaFixStatus lumafix_process_clarity_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    float clarity
) {
    LumaFixPipelineParameters p;
    std::memset(&p, 0, sizeof(LumaFixPipelineParameters));
    p.clarity = clarity;
    p.vignette.radius = 50.0f;
    p.vignette.feather = 50.0f;
    p.vignette.center_x = 0.5f;
    p.vignette.center_y = 0.5f;
    return lumafix_process_pipeline_rgba8(src, dst, &p, nullptr);
}

LumaFixStatus lumafix_process_monochrome_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    float saturation,
    int32_t bw_mode
) {
    LumaFixPipelineParameters p;
    std::memset(&p, 0, sizeof(LumaFixPipelineParameters));
    p.tone.saturation = saturation;
    p.effects.bw_mode = bw_mode;
    p.vignette.radius = 50.0f;
    p.vignette.feather = 50.0f;
    p.vignette.center_x = 0.5f;
    p.vignette.center_y = 0.5f;
    return lumafix_process_pipeline_rgba8(src, dst, &p, nullptr);
}

LumaFixStatus lumafix_process_vignette_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixVignetteParameters* params
) {
    if (params == nullptr) {
        return LUMAFIX_ERROR_NULL_POINTER;
    }
    LumaFixPipelineParameters p;
    std::memset(&p, 0, sizeof(LumaFixPipelineParameters));
    p.vignette = *params;
    return lumafix_process_pipeline_rgba8(src, dst, &p, nullptr);
}

LumaFixStatus lumafix_process_hsl_rgba8(
    const LumaFixImageBuffer* src,
    LumaFixImageBuffer* dst,
    const LumaFixHslParameters* params
) {
    if (params == nullptr) {
        return LUMAFIX_ERROR_NULL_POINTER;
    }
    LumaFixPipelineParameters p;
    std::memset(&p, 0, sizeof(LumaFixPipelineParameters));
    p.hsl = *params;
    p.vignette.radius = 50.0f;
    p.vignette.feather = 50.0f;
    p.vignette.center_x = 0.5f;
    p.vignette.center_y = 0.5f;
    return lumafix_process_pipeline_rgba8(src, dst, &p, nullptr);
}
