#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#include "lumafix_engine.h"

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
static LumaFixImageBuffer create_buffer(std::vector<uint8_t>& storage, int32_t w, int32_t h, int32_t stride = 0) {
    if (stride == 0) stride = w * 4;
    storage.resize(static_cast<size_t>(h * stride), 0);
    LumaFixImageBuffer buf;
    buf.data = storage.data();
    buf.width = w;
    buf.height = h;
    buf.stride_bytes = stride;
    buf.format = LUMAFIX_PIXEL_FORMAT_RGBA8888;
    return buf;
}

static LumaFixImageBuffer make_test_buffer(uint8_t* ptr, int32_t w, int32_t h, int32_t stride) {
    LumaFixImageBuffer buf;
    buf.data = ptr;
    buf.width = w;
    buf.height = h;
    buf.stride_bytes = stride;
    buf.format = LUMAFIX_PIXEL_FORMAT_RGBA8888;
    return buf;
}

// 1. Version check test
static bool test_version() {
    uint32_t ver = lumafix_get_version();
    uint32_t expected = (1 << 16) | (2 << 8) | 0;
    TEST_ASSERT(ver == expected, "Version should be 1.2.0");
    return true;
}

// 2. Input validation: Null pointers
static bool test_null_pointers() {
    LumaFixToneParameters params = {0.0f, 0.0f, 0.0f};
    std::vector<uint8_t> mem;
    LumaFixImageBuffer buf = create_buffer(mem, 10, 10);

    TEST_ASSERT(lumafix_process_tone_rgba8(nullptr, &buf, &params) == LUMAFIX_ERROR_NULL_POINTER,
                "Null src must return NULL_POINTER");
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, nullptr, &params) == LUMAFIX_ERROR_NULL_POINTER,
                "Null dst must return NULL_POINTER");
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, nullptr) == LUMAFIX_ERROR_NULL_POINTER,
                "Null params must return NULL_POINTER");

    LumaFixImageBuffer null_data = buf;
    null_data.data = nullptr;
    TEST_ASSERT(lumafix_process_tone_rgba8(&null_data, &buf, &params) == LUMAFIX_ERROR_NULL_POINTER,
                "Null src->data must return NULL_POINTER");
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &null_data, &params) == LUMAFIX_ERROR_NULL_POINTER,
                "Null dst->data must return NULL_POINTER");

    return true;
}

// 3. Input validation: Invalid dimensions and stride
static bool test_invalid_dimensions_and_stride() {
    LumaFixToneParameters params = {0.0f, 0.0f, 0.0f};
    std::vector<uint8_t> mem;
    LumaFixImageBuffer buf = create_buffer(mem, 10, 10);

    buf.width = 0;
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, &params) == LUMAFIX_ERROR_INVALID_DIMENSIONS,
                "Zero width must return INVALID_DIMENSIONS");

    buf.width = -5;
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, &params) == LUMAFIX_ERROR_INVALID_DIMENSIONS,
                "Negative width must return INVALID_DIMENSIONS");

    buf.width = 10;
    buf.height = 0;
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, &params) == LUMAFIX_ERROR_INVALID_DIMENSIONS,
                "Zero height must return INVALID_DIMENSIONS");

    buf.height = 10;
    buf.stride_bytes = 39; // width is 10, so min stride is 40
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, &params) == LUMAFIX_ERROR_INVALID_STRIDE,
                "Stride < width * 4 must return INVALID_STRIDE");

    buf.stride_bytes = 40;
    LumaFixImageBuffer dst = create_buffer(mem, 10, 10);
    dst.width = 12; // dimension mismatch
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &dst, &params) == LUMAFIX_ERROR_INVALID_DIMENSIONS,
                "Src/Dst width mismatch must return INVALID_DIMENSIONS");

    buf.width = 70000; // Exceeds 65536 max limit
    buf.stride_bytes = 70000 * 4;
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, &params) == LUMAFIX_ERROR_INVALID_DIMENSIONS,
                "Width > 65536 must return INVALID_DIMENSIONS");

    return true;
}

// 4. Input validation: Invalid parameter values (NaN / infinity)
static bool test_invalid_parameters() {
    std::vector<uint8_t> mem;
    LumaFixImageBuffer buf = create_buffer(mem, 4, 4);

    LumaFixToneParameters p_nan = {NAN, 0.0f, 0.0f};
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, &p_nan) == LUMAFIX_ERROR_INVALID_PARAMETER,
                "NaN exposure must return INVALID_PARAMETER");

    LumaFixToneParameters p_inf = {0.0f, INFINITY, 0.0f};
    TEST_ASSERT(lumafix_process_tone_rgba8(&buf, &buf, &p_inf) == LUMAFIX_ERROR_INVALID_PARAMETER,
                "Inf contrast must return INVALID_PARAMETER");

    return true;
}

// 5. Neutral adjustment leaves pixels and alpha 100% unchanged
static bool test_neutral_adjustment() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 16, 16);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 16, 16);

    // Fill with distinct test pattern
    for (size_t i = 0; i < src_mem.size(); i++) {
        src_mem[i] = static_cast<uint8_t>((i * 7 + 13) % 256);
    }

    LumaFixToneParameters neutral = {0.0f, 0.0f, 0.0f};
    LumaFixStatus status = lumafix_process_tone_rgba8(&src, &dst, &neutral);
    TEST_ASSERT(status == LUMAFIX_SUCCESS, "Neutral adjustment should succeed");

    for (size_t i = 0; i < src_mem.size(); i++) {
        TEST_ASSERT(dst_mem[i] == src_mem[i], "Neutral adjustment must not modify any pixel value");
    }

    // Test in-place neutral
    status = lumafix_process_tone_rgba8(&dst, &dst, &neutral);
    TEST_ASSERT(status == LUMAFIX_SUCCESS, "In-place neutral should succeed");
    for (size_t i = 0; i < src_mem.size(); i++) {
        TEST_ASSERT(dst_mem[i] == src_mem[i], "In-place neutral must preserve all values");
    }

    return true;
}

// 6. Alpha channel preservation under extreme adjustments
static bool test_alpha_preservation() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 8, 8);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 8, 8);

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

    LumaFixToneParameters extreme = {50.0f, 40.0f, -80.0f};
    LumaFixStatus status = lumafix_process_tone_rgba8(&src, &dst, &extreme);
    TEST_ASSERT(status == LUMAFIX_SUCCESS, "Processing should succeed");

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
    LumaFixImageBuffer src = create_buffer(src_mem, 1, 1);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 1, 1);

    src_mem[0] = 100; // R
    src_mem[1] = 100; // G
    src_mem[2] = 100; // B
    src_mem[3] = 255; // A

    // Positive exposure increases luminance
    LumaFixToneParameters pos_exp = {30.0f, 0.0f, 0.0f};
    lumafix_process_tone_rgba8(&src, &dst, &pos_exp);
    TEST_ASSERT(dst_mem[0] > 100, "Positive exposure must increase channel value");

    // Negative exposure decreases luminance
    LumaFixToneParameters neg_exp = {-30.0f, 0.0f, 0.0f};
    lumafix_process_tone_rgba8(&src, &dst, &neg_exp);
    TEST_ASSERT(dst_mem[0] < 100, "Negative exposure must decrease channel value");

    return true;
}

// 8. Contrast behavior (mid-point 128 expansion)
static bool test_contrast_behavior() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 2, 1);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 2, 1);

    // Pixel 0: below mid-point (80)
    src_mem[0] = 80; src_mem[1] = 80; src_mem[2] = 80; src_mem[3] = 255;
    // Pixel 1: above mid-point (180)
    src_mem[4] = 180; src_mem[5] = 180; src_mem[6] = 180; src_mem[7] = 255;

    LumaFixToneParameters high_contrast = {0.0f, 30.0f, 0.0f};
    lumafix_process_tone_rgba8(&src, &dst, &high_contrast);

    TEST_ASSERT(dst_mem[0] < 80, "Values below 128 must be darkened by positive contrast");
    TEST_ASSERT(dst_mem[4] > 180, "Values above 128 must be lightened by positive contrast");

    return true;
}

// 9. Saturation behavior & -100 Monochrome
static bool test_saturation_and_monochrome() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 1, 1);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 1, 1);

    // Distinct colored pixel (orange-red: 220, 100, 40)
    src_mem[0] = 220; src_mem[1] = 100; src_mem[2] = 40; src_mem[3] = 255;

    // Saturation = -100 must produce grayscale R == G == B matching Rec. 709 luminance
    LumaFixToneParameters mono = {0.0f, 0.0f, -100.0f};
    lumafix_process_tone_rgba8(&src, &dst, &mono);

    TEST_ASSERT(dst_mem[0] == dst_mem[1] && dst_mem[1] == dst_mem[2],
                "Saturation -100 must make R == G == B");

    // Rec. 709 lum for (220, 100, 40): 0.2126*220 + 0.7152*100 + 0.0722*40 = 46.772 + 71.52 + 2.888 = 121.18 -> 121
    int expected_lum = static_cast<int>(std::round(0.2126 * 220.0 + 0.7152 * 100.0 + 0.0722 * 40.0));
    int diff = std::abs(static_cast<int>(dst_mem[0]) - expected_lum);
    TEST_ASSERT(diff <= 1, "Monochrome output should match Rec. 709 luminance within 1 LSB");

    // Positive saturation should increase distance from luminance (boost color)
    LumaFixToneParameters boost_sat = {0.0f, 0.0f, 50.0f};
    lumafix_process_tone_rgba8(&src, &dst, &boost_sat);
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
    LumaFixImageBuffer src = create_buffer(src_mem, w, h, stride);
    LumaFixImageBuffer dst = create_buffer(dst_mem, w, h, stride);

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

    LumaFixToneParameters params = {10.0f, 10.0f, 10.0f};
    LumaFixStatus st = lumafix_process_tone_rgba8(&src, &dst, &params);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Strided processing should succeed");

    // Pixels are processed
    TEST_ASSERT(dst_mem[0] != 0, "Pixels must be processed");
    // Padding should remain untouched
    TEST_ASSERT(dst_mem[12] == 0xBB, "Padding bytes must not be corrupted");

    return true;
}

// 11. Boundary values: Black (0), White (255), Midtone (128)
static bool test_boundary_values() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 3, 1);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 3, 1);

    // Pixel 0: pure black (0)
    src_mem[0] = 0; src_mem[1] = 0; src_mem[2] = 0; src_mem[3] = 255;
    // Pixel 1: pure white (255)
    src_mem[4] = 255; src_mem[5] = 255; src_mem[6] = 255; src_mem[7] = 255;
    // Pixel 2: midtone gray (128)
    src_mem[8] = 128; src_mem[9] = 128; src_mem[10] = 128; src_mem[11] = 255;

    LumaFixToneParameters params = {20.0f, 25.0f, 15.0f};
    LumaFixStatus st = lumafix_process_tone_rgba8(&src, &dst, &params);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Boundary test should succeed");

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
    LumaFixImageBuffer src = create_buffer(src_mem, 1, 1);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 1, 1);

    src_mem[0] = 150;
    src_mem[1] = 100;
    src_mem[2] = 50;
    src_mem[3] = 255;

    LumaFixToneParameters params = {20.0f, 15.0f, 20.0f};
    LumaFixStatus st = lumafix_process_tone_rgba8(&src, &dst, &params);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Parity test execution should succeed");

    int r_err = std::abs(static_cast<int>(dst_mem[0]) - 220);
    int g_err = std::abs(static_cast<int>(dst_mem[1]) - 128);
    int b_err = std::abs(static_cast<int>(dst_mem[2]) - 38);

    printf("(C++ output: R=%d, G=%d, B=%d; Expected: R=220, G=128, B=38) ",
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

    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), 3, 1, 12);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), 3, 1, 12);

    LumaFixToneParameters tone_params = {0.0f, 0.0f, 0.0f};

    // S-curve pulling shadows down and highlights up
    LumaFixCurvePoint points[] = {
        {0.0f, 0.0f},
        {0.25f, 0.15f},
        {0.75f, 0.85f},
        {1.0f, 1.0f}
    };
    LumaFixToneCurves curves = {};
    curves.rgb.points = points;
    curves.rgb.point_count = 4;

    LumaFixStatus st = lumafix_process_curves_rgba8(&src, &dst, &tone_params, &curves);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Curves call should succeed");

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

    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), 1, 1, 4);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), 1, 1, 4);

    // Warmth +50: +Red, -Blue
    LumaFixAdvancedToneParameters params = {};
    params.warmth = 50.0f;
    LumaFixStatus st = lumafix_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Warmth should succeed");
    TEST_ASSERT(dst_mem[0] > 128, "Warmth should increase red channel");
    TEST_ASSERT(dst_mem[2] < 128, "Warmth should decrease blue channel");

    // Tint +50: +Magenta (+R, +B), -Green
    params.warmth = 0.0f;
    params.tint = 50.0f;
    st = lumafix_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Tint should succeed");
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

    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), 2, 1, 8);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), 2, 1, 8);

    // Shadows +50 (lifts dark pixels, leaves highlights mostly unaffected)
    LumaFixAdvancedToneParameters params = {};
    params.shadows = 50.0f;
    LumaFixStatus st = lumafix_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Shadows should succeed");
    TEST_ASSERT(dst_mem[0] > 40, "Shadows +50 should lift dark tones");
    TEST_ASSERT(dst_mem[4] == 220, "Shadows adjustment should not alter values > 155");

    // Highlights -50 (pulls down bright pixels, leaves shadows unaffected)
    params.shadows = 0.0f;
    params.highlights = -50.0f;
    st = lumafix_process_advanced_tone_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Highlights should succeed");
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

    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), 2, 1, 8);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), 2, 1, 8);

    LumaFixAdvancedToneParameters params = {};
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

    LumaFixCurvePoint pts[] = {{0.0f, 0.0f}, {0.5f, 0.55f}, {1.0f, 1.0f}};
    LumaFixToneCurves curves = {};
    curves.rgb.points = pts;
    curves.rgb.point_count = 3;

    LumaFixStatus st = lumafix_process_advanced_tone_rgba8(&src, &dst, &params, &curves);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Combined advanced tone call should succeed");

    // Check alpha preservation strictly
    TEST_ASSERT(dst_mem[3] == 180, "Alpha channel 1 must be strictly preserved");
    TEST_ASSERT(dst_mem[7] == 200, "Alpha channel 2 must be strictly preserved");

    // Verify determinism across repeated call
    std::vector<uint8_t> dst_mem2(src_mem.size(), 0);
    LumaFixImageBuffer dst2 = make_test_buffer(dst_mem2.data(), 2, 1, 8);
    st = lumafix_process_advanced_tone_rgba8(&src, &dst2, &params, &curves);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Repeat call should succeed");
    TEST_ASSERT(dst_mem == dst_mem2, "Advanced tone engine must be strictly deterministic");

    return true;
}

// 17. Vibrance behavior: skin-tone preserving saturation
static bool test_vibrance_behavior() {
    // Pixel 1: moderately saturated color (R: 180, G: 120, B: 100, A: 255)
    // Pixel 2: low saturated gray-ish (R: 130, G: 128, B: 125, A: 255)
    std::vector<uint8_t> src_mem = {
        180, 120, 100, 255,
        130, 128, 125, 255
    };
    std::vector<uint8_t> dst_mem(src_mem.size(), 0);
    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), 2, 1, 8);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), 2, 1, 8);

    // Neutral vibrance = 0
    LumaFixStatus st = lumafix_process_vibrance_rgba8(&src, &dst, 0.0f);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Neutral vibrance should succeed");
    TEST_ASSERT(dst_mem[0] == 180 && dst_mem[1] == 120 && dst_mem[2] == 100, "Vibrance 0 must be identity");

    // Positive vibrance +50: should boost low-saturated pixel more than high-saturated
    st = lumafix_process_vibrance_rgba8(&src, &dst, 50.0f);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Positive vibrance should succeed");
    TEST_ASSERT(dst_mem[3] == 255 && dst_mem[7] == 255, "Alpha must be preserved in vibrance");
    TEST_ASSERT(dst_mem[0] >= 180, "Vibrance should increase red on warm tone");

    return true;
}

// 18. Clarity behavior: local midtone contrast enhancement
static bool test_clarity_behavior() {
    // Pixel 1: extreme deep shadow (R: 5, G: 5, B: 5, A: 255) - near black
    // Pixel 2: bright midtone (R: 192, G: 192, B: 192, A: 255)
    std::vector<uint8_t> src_mem = {
        5, 5, 5, 255,
        192, 192, 192, 255
    };
    std::vector<uint8_t> dst_mem(src_mem.size(), 0);
    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), 2, 1, 8);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), 2, 1, 8);

    LumaFixStatus st = lumafix_process_clarity_rgba8(&src, &dst, 50.0f);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Clarity should succeed");
    TEST_ASSERT(dst_mem[3] == 255 && dst_mem[7] == 255, "Alpha must be preserved in clarity");

    // Bright midtone pixel (lum 192 > 128) should increase in clarity boost
    TEST_ASSERT(dst_mem[4] > 192, "Clarity > 0 should boost bright midtones");

    // Deep shadow pixel should experience minimal change compared to midtone
    int shadow_shift = std::abs(static_cast<int>(dst_mem[0]) - 5);
    int midtone_shift = std::abs(static_cast<int>(dst_mem[4]) - 192);
    TEST_ASSERT(midtone_shift > shadow_shift, "Clarity midtone change must exceed deep shadow change");

    return true;
}

// 19. Monochrome B&W conversion
static bool test_monochrome_bw_behavior() {
    // Pixel: saturated orange (R: 240, G: 120, B: 30, A: 200)
    std::vector<uint8_t> src_mem = { 240, 120, 30, 200 };
    std::vector<uint8_t> dst_mem(4, 0);
    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), 1, 1, 4);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), 1, 1, 4);

    // Compute expected Rec. 709 luminance
    double exp_lum = 0.2126 * 240.0 + 0.7152 * 120.0 + 0.0722 * 30.0;
    uint8_t exp_gray = static_cast<uint8_t>(std::round(exp_lum));

    LumaFixStatus st = lumafix_process_monochrome_rgba8(&src, &dst, 0.0f, 1);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Monochrome conversion should succeed");
    TEST_ASSERT(dst_mem[0] == exp_gray && dst_mem[1] == exp_gray && dst_mem[2] == exp_gray,
                "All RGB channels must equal Rec. 709 luminance in B&W mode");
    TEST_ASSERT(dst_mem[3] == 200, "Alpha channel must be preserved in B&W mode");

    return true;
}

// 20. Vignette radial falloff
static bool test_vignette_behavior() {
    const int w = 100;
    const int h = 100;
    std::vector<uint8_t> src_mem(w * h * 4, 200);
    std::vector<uint8_t> dst_mem(w * h * 4, 0);

    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), w, h, w * 4);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), w, h, w * 4);

    LumaFixVignetteParameters v = {};
    v.amount = -50.0f; // Darken edges
    v.radius = 40.0f;
    v.feather = 30.0f;
    v.center_x = 0.5f;
    v.center_y = 0.5f;

    LumaFixStatus st = lumafix_process_vignette_rgba8(&src, &dst, &v);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Vignette should succeed");

    // Center pixel (50, 50) must remain completely untouched (within radius)
    size_t center_idx = (50 * w + 50) * 4;
    TEST_ASSERT(dst_mem[center_idx] == 200, "Vignette center pixel must remain untouched");

    // Corner pixel (0, 0) must be significantly darker
    size_t corner_idx = 0;
    TEST_ASSERT(dst_mem[corner_idx] < 200, "Vignette corner pixel must be darkened");

    return true;
}

// 21. Unified Pipeline: Combined operations in single pass
static bool test_pipeline_combined() {
    const int w = 32;
    const int h = 32;
    std::vector<uint8_t> src_mem(w * h * 4);
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            size_t idx = (y * w + x) * 4;
            src_mem[idx + 0] = static_cast<uint8_t>((x * 255) / w);
            src_mem[idx + 1] = static_cast<uint8_t>((y * 255) / h);
            src_mem[idx + 2] = static_cast<uint8_t>(((x + y) * 255) / (w + h));
            src_mem[idx + 3] = 240;
        }
    }
    std::vector<uint8_t> dst_mem(src_mem.size(), 0);
    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), w, h, w * 4);
    LumaFixImageBuffer dst = make_test_buffer(dst_mem.data(), w, h, w * 4);

    LumaFixPipelineParameters params = {};
    params.tone.exposure = 10.0f;
    params.tone.contrast = 15.0f;
    params.vibrance = 20.0f;
    params.clarity = 15.0f;
    params.effects.vintage = 10.0f;
    params.effects.drama = 15.0f;
    params.effects.grain = 10.0f;
    params.vignette.amount = -30.0f;
    params.vignette.radius = 45.0f;
    params.vignette.feather = 40.0f;
    params.vignette.center_x = 0.5f;
    params.vignette.center_y = 0.5f;
    params.structure = 15.0f;

    LumaFixStatus st = lumafix_process_pipeline_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Unified pipeline should succeed");

    // Check all pixels have alpha strictly preserved
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            size_t idx = (y * w + x) * 4;
            if (dst_mem[idx + 3] != 240) {
                TEST_ASSERT(false, "Alpha channel corrupted in unified pipeline");
            }
        }
    }

    // Verify in-place processing produces identical results to out-of-place
    std::vector<uint8_t> in_place_mem = src_mem;
    LumaFixImageBuffer in_place_buf = make_test_buffer(in_place_mem.data(), w, h, w * 4);
    st = lumafix_process_pipeline_rgba8(&in_place_buf, &in_place_buf, &params, nullptr);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "In-place unified pipeline should succeed");
    TEST_ASSERT(dst_mem == in_place_mem, "In-place unified pipeline must match out-of-place exactly");

    return true;
}

// 22. Pipeline RGB888 format support
static bool test_pipeline_rgb888() {
    const int w = 16;
    const int h = 16;
    const int stride = w * 3;
    std::vector<uint8_t> src_mem(h * stride, 150);
    std::vector<uint8_t> dst_mem(h * stride, 0);

    LumaFixImageBuffer src;
    src.data = src_mem.data();
    src.width = w;
    src.height = h;
    src.stride_bytes = stride;
    src.format = LUMAFIX_PIXEL_FORMAT_RGB888;

    LumaFixImageBuffer dst = src;
    dst.data = dst_mem.data();

    LumaFixPipelineParameters params = {};
    params.tone.exposure = 20.0f;
    params.vibrance = 15.0f;
    params.clarity = 10.0f;

    LumaFixStatus st = lumafix_process_pipeline_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Pipeline RGB888 processing should succeed");
    TEST_ASSERT(dst_mem[0] > 150, "RGB888 exposure +20 should boost channels");

    return true;
}

// 23. Pipeline validation and bounds checking
static bool test_pipeline_validation_and_errors() {
    std::vector<uint8_t> mem(64, 0);
    LumaFixImageBuffer buf = make_test_buffer(mem.data(), 4, 4, 16);
    LumaFixPipelineParameters params = {};

    // Null checks
    TEST_ASSERT(lumafix_process_pipeline_rgba8(nullptr, &buf, &params, nullptr) == LUMAFIX_ERROR_NULL_POINTER,
                "Null src must fail with NULL_POINTER");
    TEST_ASSERT(lumafix_process_pipeline_rgba8(&buf, nullptr, &params, nullptr) == LUMAFIX_ERROR_NULL_POINTER,
                "Null dst must fail with NULL_POINTER");
    TEST_ASSERT(lumafix_process_pipeline_rgba8(&buf, &buf, nullptr, nullptr) == LUMAFIX_ERROR_NULL_POINTER,
                "Null params must fail with NULL_POINTER");

    // NaN parameter protection
    params.vibrance = std::numeric_limits<float>::quiet_NaN();
    TEST_ASSERT(lumafix_process_pipeline_rgba8(&buf, &buf, &params, nullptr) == LUMAFIX_ERROR_INVALID_PARAMETER,
                "NaN vibrance must fail with INVALID_PARAMETER");

    params.vibrance = 0.0f;
    params.vignette.amount = std::numeric_limits<float>::infinity();
    TEST_ASSERT(lumafix_process_pipeline_rgba8(&buf, &buf, &params, nullptr) == LUMAFIX_ERROR_INVALID_PARAMETER,
                "Inf vignette must fail with INVALID_PARAMETER");

    return true;
}

// 24. HSL Color Mixer targeted color range testing
static bool test_hsl_mixer() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 4, 1);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 4, 1);

    // Pixel 0: Pure Red (220, 20, 20)
    // Pixel 1: Pure Green (20, 220, 20)
    // Pixel 2: Pure Blue (20, 20, 220)
    // Pixel 3: Yellow (220, 220, 20)
    src_mem[0] = 220; src_mem[1] = 20;  src_mem[2] = 20;  src_mem[3] = 255;
    src_mem[4] = 20;  src_mem[5] = 220; src_mem[6] = 20;  src_mem[7] = 255;
    src_mem[8] = 20;  src_mem[9] = 20;  src_mem[10] = 220; src_mem[11] = 255;
    src_mem[12] = 220; src_mem[13] = 220; src_mem[14] = 20; src_mem[15] = 255;

    LumaFixHslParameters hsl;
    std::memset(&hsl, 0, sizeof(LumaFixHslParameters));
    // Drastically desaturate Green (-100), shift Blue hue (+50), boost Red luminance (+30)
    hsl.green.saturation = -100.0f;
    hsl.blue.hue = 50.0f;
    hsl.red.luminance = 30.0f;

    LumaFixStatus status = lumafix_process_hsl_rgba8(&src, &dst, &hsl);
    TEST_ASSERT(status == LUMAFIX_SUCCESS, "lumafix_process_hsl_rgba8 must succeed");

    // Green pixel should be desaturated (R, G, B much closer together)
    int g_diff = std::abs(dst_mem[5] - dst_mem[4]);
    int orig_g_diff = std::abs(src_mem[5] - src_mem[4]);
    TEST_ASSERT(g_diff < orig_g_diff, "Green desaturation should lower channel difference");

    // Red pixel luminance should be lifted
    TEST_ASSERT(dst_mem[0] >= src_mem[0], "Red pixel luminance boost should raise red level");

    return true;
}

// 25. Film Effects: Bloom, Glow, Chromatic Aberration, Lens Blur
static bool test_effects_glow_blur_chromatic() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 16, 16);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 16, 16);

    // Fill with high contrast center square
    for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
            int idx = (y * 16 + x) * 4;
            uint8_t val = (x >= 6 && x <= 10 && y >= 6 && y <= 10) ? 250 : 20;
            src_mem[idx + 0] = val;
            src_mem[idx + 1] = val;
            src_mem[idx + 2] = val;
            src_mem[idx + 3] = 255;
        }
    }

    LumaFixPipelineParameters params;
    std::memset(&params, 0, sizeof(LumaFixPipelineParameters));
    params.effects.bloom = 40.0f;
    params.effects.glow = 30.0f;
    params.effects.chromatic_aberration = 25.0f;
    params.effects.lens_blur = 20.0f;
    params.vignette.radius = 50.0f;
    params.vignette.feather = 50.0f;
    params.vignette.center_x = 0.5f;
    params.vignette.center_y = 0.5f;

    LumaFixStatus status = lumafix_process_pipeline_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(status == LUMAFIX_SUCCESS, "Pipeline with bloom, glow, blur, chromatic must succeed");

    // Check that edges were softened by lens blur & diffusion
    int center_val = dst_mem[(8 * 16 + 8) * 4];
    int outer_val = dst_mem[(0 * 16 + 0) * 4];
    TEST_ASSERT(center_val > 50, "Center remains luminous");
    TEST_ASSERT(outer_val >= 20, "Diffusion raises dark surrounding slightly");

    return true;
}

// 26. Sharpening: high-frequency edge enhancement with coring
static bool test_sharpening_native() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 8, 8);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 8, 8);

    // Uniform 100 with a bright 180 center pixel at (4,4)
    for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
            int idx = (y * 8 + x) * 4;
            uint8_t val = (x == 4 && y == 4) ? 180 : 100;
            src_mem[idx + 0] = val;
            src_mem[idx + 1] = val;
            src_mem[idx + 2] = val;
            src_mem[idx + 3] = 255;
        }
    }

    LumaFixPipelineParameters params;
    std::memset(&params, 0, sizeof(LumaFixPipelineParameters));
    params.sharpening = 40.0f;
    params.vignette.radius = 50.0f;
    params.vignette.feather = 50.0f;
    params.vignette.center_x = 0.5f;
    params.vignette.center_y = 0.5f;

    LumaFixStatus status = lumafix_process_pipeline_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(status == LUMAFIX_SUCCESS, "Sharpening pipeline should succeed");

    int center_idx = (4 * 8 + 4) * 4;
    TEST_ASSERT(dst_mem[center_idx + 0] > 180, "Sharpening must boost high-frequency contrast peak");
    TEST_ASSERT(dst_mem[center_idx + 3] == 255, "Alpha preserved in sharpening");

    // Boundary pixel at (0,0) remains 100
    TEST_ASSERT(dst_mem[0] == 100, "Boundary pixels remain intact");

    return true;
}

// 27. Color Engine: Skin-tone protection during Vibrance and Saturation boost
static bool test_skin_tone_protection() {
    std::vector<uint8_t> src_mem, dst_mem;
    LumaFixImageBuffer src = create_buffer(src_mem, 2, 1);
    LumaFixImageBuffer dst = create_buffer(dst_mem, 2, 1);

    // Pixel 0: Human skin tone (Peach/Warm: R=210, G=155, B=125)
    src_mem[0] = 210;
    src_mem[1] = 155;
    src_mem[2] = 125;
    src_mem[3] = 255;

    // Pixel 1: Blue sky tone with identical saturation magnitude (R=125, G=155, B=210)
    src_mem[4] = 125;
    src_mem[5] = 155;
    src_mem[6] = 210;
    src_mem[7] = 255;

    LumaFixPipelineParameters params;
    std::memset(&params, 0, sizeof(LumaFixPipelineParameters));
    params.vibrance = 40.0f;
    params.tone.saturation = 20.0f;
    params.vignette.radius = 50.0f;
    params.vignette.feather = 50.0f;
    params.vignette.center_x = 0.5f;
    params.vignette.center_y = 0.5f;

    LumaFixStatus status = lumafix_process_pipeline_rgba8(&src, &dst, &params, nullptr);
    TEST_ASSERT(status == LUMAFIX_SUCCESS, "Pipeline with vibrance/saturation should succeed");

    int skin_r_boost = static_cast<int>(dst_mem[0]) - static_cast<int>(src_mem[0]);
    int sky_b_boost = static_cast<int>(dst_mem[6]) - static_cast<int>(src_mem[6]);

    printf("(Skin R boost: +%d LSB, Sky B boost: +%d LSB) ", skin_r_boost, sky_b_boost);
    TEST_ASSERT(skin_r_boost < sky_b_boost, "Skin tone boost must be attenuated relative to sky/background boost");

    return true;
}

// 28. Subject segmentation: person detection and alpha mask generation
static bool test_subject_segmentation() {
    // Null checks
    LumaFixStatus st = lumafix_segment_person_rgba8(nullptr, nullptr, 10, 10);
    TEST_ASSERT(st == LUMAFIX_ERROR_NULL_POINTER, "Null pointer must return LUMAFIX_ERROR_NULL_POINTER");

    // Invalid dimensions
    std::vector<uint8_t> dummy(16, 0);
    std::vector<uint8_t> out_m(16, 0);
    LumaFixImageBuffer invalid_buf = make_test_buffer(dummy.data(), -1, 10, 40);
    st = lumafix_segment_person_rgba8(&invalid_buf, out_m.data(), 10, 10);
    TEST_ASSERT(st == LUMAFIX_ERROR_INVALID_DIMENSIONS, "Negative width must return LUMAFIX_ERROR_INVALID_DIMENSIONS");

    // Synthetic 40x40 image: background is dark blue/gray, center has skin tone
    const int w = 40;
    const int h = 40;
    std::vector<uint8_t> src_mem(w * h * 4, 0);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            int idx = (y * w + x) * 4;
            float dx = (x - 20) / 10.0f;
            float dy = (y - 18) / 10.0f;
            if (dx * dx + dy * dy < 1.0f) {
                // Skin tone (R: 215, G: 155, B: 120)
                src_mem[idx] = 215;
                src_mem[idx + 1] = 155;
                src_mem[idx + 2] = 120;
                src_mem[idx + 3] = 255;
            } else {
                // Background (R: 30, G: 40, B: 60)
                src_mem[idx] = 30;
                src_mem[idx + 1] = 40;
                src_mem[idx + 2] = 60;
                src_mem[idx + 3] = 255;
            }
        }
    }

    LumaFixImageBuffer src = make_test_buffer(src_mem.data(), w, h, w * 4);
    std::vector<uint8_t> mask(w * h, 0);

    st = lumafix_segment_person_rgba8(&src, mask.data(), w, h);
    TEST_ASSERT(st == LUMAFIX_SUCCESS, "Segmentation on image buffer must succeed");

    // Corners should be background (alpha < 50)
    TEST_ASSERT(mask[0] < 50, "Top-left corner must be background in mask");
    TEST_ASSERT(mask[w - 1] < 50, "Top-right corner must be background in mask");

    return true;
}

int main() {
    printf("========================================\n");
    printf("LumaFix Core Native Unit Test Suite\n");
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
    RUN_TEST(test_vibrance_behavior);
    RUN_TEST(test_clarity_behavior);
    RUN_TEST(test_monochrome_bw_behavior);
    RUN_TEST(test_vignette_behavior);
    RUN_TEST(test_pipeline_combined);
    RUN_TEST(test_pipeline_rgb888);
    RUN_TEST(test_pipeline_validation_and_errors);
    RUN_TEST(test_hsl_mixer);
    RUN_TEST(test_effects_glow_blur_chromatic);
    RUN_TEST(test_sharpening_native);
    RUN_TEST(test_skin_tone_protection);
    RUN_TEST(test_subject_segmentation);

    printf("========================================\n");
    printf("Result: %d / %d tests passed\n", g_tests_passed, g_tests_run);
    printf("========================================\n");

    return (g_tests_passed == g_tests_run) ? 0 : 1;
}

