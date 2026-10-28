#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#include "aevique_engine.h"

// Simple, dependency-free test runner for cross-platform execution
static int g_tests_run = 0;
static int g_tests_passed = 0;

#define TEST_ASSERT(cond, msg)                                                \
    do {                                                                       \
        if (!(cond)) {                                                         \
            fprintf(stderr, "FAIL: %s:%d: %s (%s)\n", __FILE__, __LINE__,    \
                    #cond, msg);                                               \
            return false;                                                      \
        }                                                                      \
    } while (0)

#define RUN_TEST(fn)                                                           \
    do {                                                                       \
        g_tests_run++;                                                         \
        printf("Running %s... ", #fn);                                         \
        if (fn()) {                                                            \
            g_tests_passed++;                                                  \
            printf("PASSED\n");                                                \
        } else {                                                               \
            printf("FAILED\n");                                                \
        }                                                                      \
    } while (0)

// Helper to create test buffer
static AeviqueImageBuffer create_buffer(std::vector<uint8_t>& storage, int32_t w, int32_t h, int32_t stride = 0) {
    if (stride == 0) stride = w * 4;
    storage.resize(static_cast<size_t>(h * stride), 0);
    AeviqueImageBuffer buf;
    buf.data = storage.data();
    buf.width = w;
    buf.height = h;
    buf.stride_bytes = stride;
    buf.format = AEVIQUE_PIXEL_FORMAT_RGBA8888;
    return buf;
}

static AeviqueImageBuffer make_test_buffer(uint8_t* ptr, int32_t w, int32_t h, int32_t stride) {
    AeviqueImageBuffer buf;
    buf.data = ptr;
    buf.width = w;
    buf.height = h;
    buf.stride_bytes = stride;
    buf.format = AEVIQUE_PIXEL_FORMAT_RGBA8888;
    return buf;
}

// 1. Version check test
static bool test_version() {
    uint32_t ver = aevique_get_version();
    uint32_t expected = (1 << 16) | (1 << 8) | 0;
    TEST_ASSERT(ver == expected, "Version should be 1.1.0");
    return true;
}

// 2. Input validation: Null pointers
static bool test_null_pointers() {
    AeviqueToneParameters params = {0.0f, 0.0f, 0.0f};
    std::vector<uint8_t> mem;
    AeviqueImageBuffer buf = create_buffer(mem, 10, 10);

    TEST_ASSERT(aevique_process_tone_rgba8(nullptr, &buf, &params) == AEVIQUE_ERROR_NULL_POINTER,
                "Null src must return NULL_POINTER");
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, nullptr, &params) == AEVIQUE_ERROR_NULL_POINTER,
                "Null dst must return NULL_POINTER");
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &buf, nullptr) == AEVIQUE_ERROR_NULL_POINTER,
                "Null params must return NULL_POINTER");

    AeviqueImageBuffer null_data = buf;
    null_data.data = nullptr;
    TEST_ASSERT(aevique_process_tone_rgba8(&null_data, &buf, &params) == AEVIQUE_ERROR_NULL_POINTER,
                "Null src->data must return NULL_POINTER");
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &null_data, &params) == AEVIQUE_ERROR_NULL_POINTER,
                "Null dst->data must return NULL_POINTER");

    return true;
}

// 3. Input validation: Invalid dimensions and stride
static bool test_invalid_dimensions_and_stride() {
    AeviqueToneParameters params = {0.0f, 0.0f, 0.0f};
    std::vector<uint8_t> mem;
    AeviqueImageBuffer buf = create_buffer(mem, 10, 10);

    buf.width = 0;
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &buf, &params) == AEVIQUE_ERROR_INVALID_DIMENSIONS,
                "Zero width must return INVALID_DIMENSIONS");

    buf.width = -5;
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &buf, &params) == AEVIQUE_ERROR_INVALID_DIMENSIONS,
                "Negative width must return INVALID_DIMENSIONS");

    buf.width = 10;
    buf.height = 0;
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &buf, &params) == AEVIQUE_ERROR_INVALID_DIMENSIONS,
                "Zero height must return INVALID_DIMENSIONS");

    buf.height = 10;
    buf.stride_bytes = 39; // width is 10, so min stride is 40
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &buf, &params) == AEVIQUE_ERROR_INVALID_STRIDE,
                "Stride < width * 4 must return INVALID_STRIDE");

    buf.stride_bytes = 40;
    AeviqueImageBuffer dst = create_buffer(mem, 10, 10);
    dst.width = 12; // dimension mismatch
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &dst, &params) == AEVIQUE_ERROR_INVALID_DIMENSIONS,
                "Src/Dst width mismatch must return INVALID_DIMENSIONS");

    return true;
}

// 4. Input validation: Invalid parameter values (NaN / infinity)
static bool test_invalid_parameters() {
    std::vector<uint8_t> mem;
    AeviqueImageBuffer buf = create_buffer(mem, 4, 4);

    AeviqueToneParameters p_nan = {NAN, 0.0f, 0.0f};
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &buf, &p_nan) == AEVIQUE_ERROR_INVALID_PARAMETER,
                "NaN exposure must return INVALID_PARAMETER");

    AeviqueToneParameters p_inf = {0.0f, INFINITY, 0.0f};
    TEST_ASSERT(aevique_process_tone_rgba8(&buf, &buf, &p_inf) == AEVIQUE_ERROR_INVALID_PARAMETER,
                "Inf contrast must return INVALID_PARAMETER");

    return true;
}

// 5. Neutral adjustment leaves pixels and alpha 100% unchanged
static bool test_neutral_adjustment() {
    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, 16, 16);
    AeviqueImageBuffer dst = create_buffer(dst_mem, 16, 16);

    // Fill with distinct test pattern
    for (size_t i = 0; i < src_mem.size(); i++) {
        src_mem[i] = static_cast<uint8_t>((i * 7 + 13) % 256);
    }

    AeviqueToneParameters neutral = {0.0f, 0.0f, 0.0f};
    AeviqueStatus status = aevique_process_tone_rgba8(&src, &dst, &neutral);
    TEST_ASSERT(status == AEVIQUE_SUCCESS, "Neutral adjustment should succeed");

    for (size_t i = 0; i < src_mem.size(); i++) {
        TEST_ASSERT(dst_mem[i] == src_mem[i], "Neutral adjustment must not modify any pixel value");
    }

    // Test in-place neutral
    status = aevique_process_tone_rgba8(&dst, &dst, &neutral);
    TEST_ASSERT(status == AEVIQUE_SUCCESS, "In-place neutral should succeed");
    for (size_t i = 0; i < src_mem.size(); i++) {
        TEST_ASSERT(dst_mem[i] == src_mem[i], "In-place neutral must preserve all values");
    }

    return true;
}

// 6. Alpha channel preservation under extreme adjustments
static bool test_alpha_preservation() {
    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, 8, 8);
    AeviqueImageBuffer dst = create_buffer(dst_mem, 8, 8);

    // Specific varied alpha values
    for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
            size_t idx = static_cast<size_t>(y * 32 + x * 4);
            src_mem[idx + 0] = 120;
            src_mem[idx + 1] = 150;
            src_mem[idx + 2] = 180;
            src_mem[idx + 3] = static_cast<uint8_t>((x * 30 + y * 5) % 256); // varied alpha
        }
    }

    AeviqueToneParameters extreme = {50.0f, 40.0f, -80.0f};
    AeviqueStatus status = aevique_process_tone_rgba8(&src, &dst, &extreme);
    TEST_ASSERT(status == AEVIQUE_SUCCESS, "Processing should succeed");

    for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
            size_t idx = static_cast<size_t>(y * 32 + x * 4);
            uint8_t orig_a = static_cast<uint8_t>((x * 30 + y * 5) % 256);
            TEST_ASSERT(dst_mem[idx + 3] == orig_a, "Alpha channel must be strictly preserved");
        }
    }

    return true;
}

// 7. Exposure behavior
static bool test_exposure_behavior() {
    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, 1, 1);
    AeviqueImageBuffer dst = create_buffer(dst_mem, 1, 1);

    src_mem[0] = 100; // R
    src_mem[1] = 100; // G
    src_mem[2] = 100; // B
    src_mem[3] = 255; // A

    // Positive exposure increases luminance
    AeviqueToneParameters pos_exp = {30.0f, 0.0f, 0.0f};
    aevique_process_tone_rgba8(&src, &dst, &pos_exp);
    TEST_ASSERT(dst_mem[0] > 100, "Positive exposure must increase channel value");

    // Negative exposure decreases luminance
    AeviqueToneParameters neg_exp = {-30.0f, 0.0f, 0.0f};
    aevique_process_tone_rgba8(&src, &dst, &neg_exp);
    TEST_ASSERT(dst_mem[0] < 100, "Negative exposure must decrease channel value");

    return true;
}

// 8. Contrast behavior (mid-point 128 expansion)
static bool test_contrast_behavior() {
    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, 2, 1);
    AeviqueImageBuffer dst = create_buffer(dst_mem, 2, 1);

    // Pixel 0: below mid-point (80)
    src_mem[0] = 80; src_mem[1] = 80; src_mem[2] = 80; src_mem[3] = 255;
    // Pixel 1: above mid-point (180)
    src_mem[4] = 180; src_mem[5] = 180; src_mem[6] = 180; src_mem[7] = 255;

    AeviqueToneParameters high_contrast = {0.0f, 30.0f, 0.0f};
    aevique_process_tone_rgba8(&src, &dst, &high_contrast);

    TEST_ASSERT(dst_mem[0] < 80, "Values below 128 must be darkened by positive contrast");
    TEST_ASSERT(dst_mem[4] > 180, "Values above 128 must be lightened by positive contrast");

    return true;
}

// 9. Saturation behavior & -100 Monochrome
static bool test_saturation_and_monochrome() {
    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, 1, 1);
    AeviqueImageBuffer dst = create_buffer(dst_mem, 1, 1);

    // Distinct colored pixel (orange-red: 220, 100, 40)
    src_mem[0] = 220; src_mem[1] = 100; src_mem[2] = 40; src_mem[3] = 255;

    // Saturation = -100 must produce grayscale R == G == B matching Rec. 709 luminance
    AeviqueToneParameters mono = {0.0f, 0.0f, -100.0f};
    aevique_process_tone_rgba8(&src, &dst, &mono);

    TEST_ASSERT(dst_mem[0] == dst_mem[1] && dst_mem[1] == dst_mem[2],
                "Saturation -100 must make R == G == B");

    // Rec. 709 lum for (220, 100, 40): 0.2126*220 + 0.7152*100 + 0.0722*40 = 46.772 + 71.52 + 2.888 = 121.18 -> 121
    int expected_lum = static_cast<int>(std::round(0.2126 * 220.0 + 0.7152 * 100.0 + 0.0722 * 40.0));
    int diff = std::abs(static_cast<int>(dst_mem[0]) - expected_lum);
    TEST_ASSERT(diff <= 1, "Monochrome output should match Rec. 709 luminance within 1 LSB");

    // Positive saturation should increase distance from luminance (boost color)
    AeviqueToneParameters boost_sat = {0.0f, 0.0f, 50.0f};
    aevique_process_tone_rgba8(&src, &dst, &boost_sat);
    TEST_ASSERT(dst_mem[0] > 220, "Positive saturation must boost dominant red channel");
    TEST_ASSERT(dst_mem[2] < 40, "Positive saturation must suppress sub-dominant blue channel");

    return true;
}

// 10. Strided image buffer with row padding
static bool test_strided_buffer() {
    int32_t w = 3;
    int32_t h = 2;
    int32_t stride = 20; // 3 * 4 = 12 bytes image + 8 bytes padding
    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, w, h, stride);
    AeviqueImageBuffer dst = create_buffer(dst_mem, w, h, stride);

    // Write sentinel byte in padding
    src_mem[12] = 0xAA;
    dst_mem[12] = 0xBB;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            size_t idx = static_cast<size_t>(y * stride + x * 4);
            src_mem[idx + 0] = 100;
            src_mem[idx + 1] = 150;
            src_mem[idx + 2] = 200;
            src_mem[idx + 3] = 255;
        }
    }

    AeviqueToneParameters params = {10.0f, 10.0f, 10.0f};
    AeviqueStatus st = aevique_process_tone_rgba8(&src, &dst, &params);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Strided processing should succeed");

    // Pixels are processed
    TEST_ASSERT(dst_mem[0] != 0, "Pixels must be processed");
    // Padding should remain untouched
    TEST_ASSERT(dst_mem[12] == 0xBB, "Padding bytes must not be corrupted");

    return true;
}

// 11. Boundary values: Black (0), White (255), Midtone (128)
static bool test_boundary_values() {
    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, 3, 1);
    AeviqueImageBuffer dst = create_buffer(dst_mem, 3, 1);

    // Pixel 0: pure black (0)
    src_mem[0] = 0; src_mem[1] = 0; src_mem[2] = 0; src_mem[3] = 255;
    // Pixel 1: pure white (255)
    src_mem[4] = 255; src_mem[5] = 255; src_mem[6] = 255; src_mem[7] = 255;
    // Pixel 2: midtone gray (128)
    src_mem[8] = 128; src_mem[9] = 128; src_mem[10] = 128; src_mem[11] = 255;

    AeviqueToneParameters params = {20.0f, 25.0f, 15.0f};
    AeviqueStatus st = aevique_process_tone_rgba8(&src, &dst, &params);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Boundary test should succeed");

    // Pure black with contrast + exposure:
    // Dart LutGenerator:
    // base = 0 * 1.30 = 0.
    // contrastFactor for +25 contrast: cVal = 37.5, contrastFactor = (259 * 292.5) / (255 * 221.5) = 1.3415
    // base = 1.3415 * (0 - 128) + 128 = -171.7 + 128 = -43.7 -> clamped to 0!
    TEST_ASSERT(dst_mem[0] == 0 && dst_mem[1] == 0 && dst_mem[2] == 0,
                "Black clamped at 0 under contrast expansion");

    // Pure white with contrast + exposure:
    // Clamped to 255
    TEST_ASSERT(dst_mem[4] == 255 && dst_mem[5] == 255 && dst_mem[6] == 255,
                "White clamped at 255");

    return true;
}

// 12. Numerical parity against Dart reference calculations (tolerance <= 1 in 8-bit channel units)
static bool test_numerical_parity_with_dart_reference() {
    // Reference test vector computed directly from Dart's LutGenerator & FilterKernels:
    // Input: R=150, G=100, B=50, A=255
    // Exposure = +20.0, Contrast = +15.0, Saturation = +20.0
    //
    // Dart Step 1: Exposure factor:
    // exposureFactor = 1.0 + (20.0 / 100.0) * 1.5 = 1.30
    // Dart Step 2: Contrast factor:
    // cVal = 15.0 * 1.5 = 22.5
    // contrastFactor = (259.0 * 277.5) / (255.0 * 236.5) = 71872.5 / 60307.5 = 1.191767
    //
    // Channel R=150:
    // baseR = 150 * 1.30 = 195.0
    // baseR = 1.191767 * (195.0 - 128.0) + 128.0 = 1.191767 * 67.0 + 128.0 = 79.848 + 128.0 = 207.848 -> 208
    //
    // Channel G=100:
    // baseG = 100 * 1.30 = 130.0
    // baseG = 1.191767 * (130.0 - 128.0) + 128.0 = 1.191767 * 2.0 + 128.0 = 2.3835 + 128.0 = 130.38 -> 130
    //
    // Channel B=50:
    // baseB = 50 * 1.30 = 65.0
    // baseB = 1.191767 * (65.0 - 128.0) + 128.0 = 1.191767 * (-63.0) + 128.0 = -75.081 + 128.0 = 52.919 -> 53
    //
    // Tone output: R=208, G=130, B=53
    //
    // Dart Step 3: Saturation = +20.0:
    // satFactor = (20.0 + 100.0) / 100.0 = 1.20
    // lum = 0.2126 * 208 + 0.7152 * 130 + 0.0722 * 53 = 44.2208 + 92.976 + 3.8266 = 141.0234
    // R_final = round(141.0234 + (208 - 141.0234) * 1.20) = round(141.0234 + 80.3719) = round(221.395) = 221
    // G_final = round(141.0234 + (130 - 141.0234) * 1.20) = round(141.0234 - 13.2281) = round(127.795) = 128
    // B_final = round(141.0234 + (53 - 141.0234) * 1.20) = round(141.0234 - 105.6281) = round(35.395) = 35

    std::vector<uint8_t> src_mem, dst_mem;
    AeviqueImageBuffer src = create_buffer(src_mem, 1, 1);
    AeviqueImageBuffer dst = create_buffer(dst_mem, 1, 1);

    src_mem[0] = 150;
    src_mem[1] = 100;
    src_mem[2] = 50;
    src_mem[3] = 255;

    AeviqueToneParameters params = {20.0f, 15.0f, 20.0f};
    AeviqueStatus st = aevique_process_tone_rgba8(&src, &dst, &params);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Parity test execution should succeed");

    int r_err = std::abs(static_cast<int>(dst_mem[0]) - 221);
    int g_err = std::abs(static_cast<int>(dst_mem[1]) - 128);
    int b_err = std::abs(static_cast<int>(dst_mem[2]) - 35);

    printf("(C++ output: R=%d, G=%d, B=%d; Expected: R=221, G=128, B=35) ",
           dst_mem[0], dst_mem[1], dst_mem[2]);

    TEST_ASSERT(r_err <= 1, "R channel numerical error must be <= 1 LSB");
    TEST_ASSERT(g_err <= 1, "G channel numerical error must be <= 1 LSB");
    TEST_ASSERT(b_err <= 1, "B channel numerical error must be <= 1 LSB");
    TEST_ASSERT(dst_mem[3] == 255, "Alpha must be 255");

    return true;
}

// 13. Advanced Tone: Tone Curves (S-curve contrast)
static bool test_tone_curves() {
    std::vector<uint8_t> src_mem = {
        50, 50, 50, 255,   // Dark shadow
        128, 128, 128, 255, // Midtone
        200, 200, 200, 255  // Highlight
    };
    std::vector<uint8_t> dst_mem(src_mem.size(), 0);

    AeviqueImageBuffer src = make_test_buffer(src_mem.data(), 3, 1, 12);
    AeviqueImageBuffer dst = make_test_buffer(dst_mem.data(), 3, 1, 12);

    AeviqueToneParameters tone_params = {0.0f, 0.0f, 0.0f};

    // S-curve pulling shadows down and highlights up
    AeviqueCurvePoint points[] = {
        {0.0f, 0.0f},
        {0.25f, 0.15f},
        {0.75f, 0.85f},
        {1.0f, 1.0f}
    };
    AeviqueToneCurves curves = {};
    curves.rgb.points = points;
    curves.rgb.point_count = 4;

    AeviqueStatus st = aevique_process_curves_rgba8(&src, &dst, &tone_params, &curves);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Curves call should succeed");

    // Shadow at 50 (50/255 = 0.196) should be pulled down below 50
    TEST_ASSERT(dst_mem[0] < 50, "S-curve should lower dark tones");
    // Midtone around 128 should stay near 128
    TEST_ASSERT(std::abs(static_cast<int>(dst_mem[4]) - 128) < 5, "S-curve center should remain near 128");
    // Highlight at 200 (200/255 = 0.784) should be boosted above 200
    TEST_ASSERT(dst_mem[8] > 200, "S-curve should lift bright tones");
    // Alpha preserved
    TEST_ASSERT(dst_mem[3] == 255 && dst_mem[7] == 255 && dst_mem[11] == 255, "Alpha preserved");

    return true;
}

// 14. Advanced Tone: Warmth and Tint
static bool test_warmth_and_tint() {
    std::vector<uint8_t> src_mem = {128, 128, 128, 255};
    std::vector<uint8_t> dst_mem(4, 0);

    AeviqueImageBuffer src = make_test_buffer(src_mem.data(), 1, 1, 4);
    AeviqueImageBuffer dst = make_test_buffer(dst_mem.data(), 1, 1, 4);

    // Warmth +50: +Red, -Blue
    AeviqueAdvancedToneParameters params = {};
    params.warmth = 50.0f;
    AeviqueStatus st = aevique_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Warmth should succeed");
    TEST_ASSERT(dst_mem[0] > 128, "Warmth should increase red channel");
    TEST_ASSERT(dst_mem[2] < 128, "Warmth should decrease blue channel");

    // Tint +50: +Magenta (+R, +B), -Green
    params.warmth = 0.0f;
    params.tint = 50.0f;
    st = aevique_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Tint should succeed");
    TEST_ASSERT(dst_mem[0] > 128, "Tint +50 should increase red channel");
    TEST_ASSERT(dst_mem[1] < 128, "Tint +50 should decrease green channel");
    TEST_ASSERT(dst_mem[2] > 128, "Tint +50 should increase blue channel");

    return true;
}

// 15. Advanced Tone: Highlights and Shadows
static bool test_highlights_and_shadows() {
    std::vector<uint8_t> src_mem = {
        40, 40, 40, 255,    // Dark shadow (< 155)
        220, 220, 220, 255  // Bright highlight (> 100)
    };
    std::vector<uint8_t> dst_mem(src_mem.size(), 0);

    AeviqueImageBuffer src = make_test_buffer(src_mem.data(), 2, 1, 8);
    AeviqueImageBuffer dst = make_test_buffer(dst_mem.data(), 2, 1, 8);

    // Shadows +50 (lifts dark pixels, leaves highlights mostly unaffected)
    AeviqueAdvancedToneParameters params = {};
    params.shadows = 50.0f;
    AeviqueStatus st = aevique_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Shadows should succeed");
    TEST_ASSERT(dst_mem[0] > 40, "Shadows +50 should lift dark tones");
    TEST_ASSERT(dst_mem[4] == 220, "Shadows adjustment should not alter values > 155");

    // Highlights -50 (pulls down bright pixels, leaves shadows unaffected)
    params.shadows = 0.0f;
    params.highlights = -50.0f;
    st = aevique_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Highlights should succeed");
    TEST_ASSERT(dst_mem[0] == 40, "Highlights adjustment should not alter values < 100");
    TEST_ASSERT(dst_mem[4] < 220, "Highlights -50 should recover/lower bright tones");

    return true;
}

// 16. Advanced Tone: Combined Adjustments
static bool test_combined_advanced_tone() {
    std::vector<uint8_t> src_mem = {
        50, 100, 150, 180,
        200, 120, 80, 200
    };
    std::vector<uint8_t> dst_mem(src_mem.size(), 0);

    AeviqueImageBuffer src = make_test_buffer(src_mem.data(), 2, 1, 8);
    AeviqueImageBuffer dst = make_test_buffer(dst_mem.data(), 2, 1, 8);

    AeviqueAdvancedToneParameters params = {};
    params.exposure = 15.0f;
    params.contrast = 10.0f;
    params.saturation = 20.0f;
    params.brightness = 5.0f;
    params.warmth = 25.0f;
    params.tint = -15.0f;
    params.highlights = -20.0f;
    params.shadows = 30.0f;
    params.whites = 10.0f;
    params.blacks = -10.0f;
    params.ambiance = 15.0f;

    AeviqueCurvePoint pts[] = {{0.0f, 0.0f}, {0.5f, 0.55f}, {1.0f, 1.0f}};
    AeviqueToneCurves curves = {};
    curves.rgb.points = pts;
    curves.rgb.point_count = 3;

    AeviqueStatus st = aevique_process_advanced_tone_rgba8(&src, &dst, &params, &curves);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Combined advanced tone call should succeed");

    // Check alpha preservation strictly
    TEST_ASSERT(dst_mem[3] == 180, "Alpha channel 1 must be strictly preserved");
    TEST_ASSERT(dst_mem[7] == 200, "Alpha channel 2 must be strictly preserved");

    // Verify determinism across repeated call
    std::vector<uint8_t> dst_mem2(src_mem.size(), 0);
    AeviqueImageBuffer dst2 = make_test_buffer(dst_mem2.data(), 2, 1, 8);
    st = aevique_process_advanced_tone_rgba8(&src, &dst2, &params, &curves);
    TEST_ASSERT(st == AEVIQUE_SUCCESS, "Repeat call should succeed");
    TEST_ASSERT(dst_mem == dst_mem2, "Advanced tone engine must be strictly deterministic");

    return true;
}

int main() {
    printf("========================================\n");
    printf("AEVIQUE Core Native Unit Test Suite\n");
    printf("========================================\n");

    RUN_TEST(test_version);
    RUN_TEST(test_null_pointers);
    RUN_TEST(test_invalid_dimensions_and_stride);
    RUN_TEST(test_invalid_parameters);
    RUN_TEST(test_neutral_adjustment);
    RUN_TEST(test_alpha_preservation);
    RUN_TEST(test_exposure_behavior);
    RUN_TEST(test_contrast_behavior);
    RUN_TEST(test_saturation_and_monochrome);
    RUN_TEST(test_strided_buffer);
    RUN_TEST(test_boundary_values);
    RUN_TEST(test_numerical_parity_with_dart_reference);
    RUN_TEST(test_tone_curves);
    RUN_TEST(test_warmth_and_tint);
    RUN_TEST(test_highlights_and_shadows);
    RUN_TEST(test_combined_advanced_tone);

    printf("========================================\n");
    printf("Result: %d / %d tests passed\n", g_tests_passed, g_tests_run);
    printf("========================================\n");

    return (g_tests_passed == g_tests_run) ? 0 : 1;
}

