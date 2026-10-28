#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <numeric>
#include <vector>

#include "aevique_engine.h"

struct BenchmarkStats {
    double min_ms;
    double max_ms;
    double mean_ms;
    double median_ms;
    double p95_ms;
};

static BenchmarkStats compute_stats(std::vector<double>& times) {
    std::sort(times.begin(), times.end());
    size_t n = times.size();
    double sum = std::accumulate(times.begin(), times.end(), 0.0);
    BenchmarkStats s;
    s.min_ms = times.front();
    s.max_ms = times.back();
    s.mean_ms = sum / static_cast<double>(n);
    s.median_ms = times[n / 2];
    size_t p95_idx = static_cast<size_t>(std::ceil(0.95 * static_cast<double>(n))) - 1;
    if (p95_idx >= n) p95_idx = n - 1;
    s.p95_ms = times[p95_idx];
    return s;
}

static void print_benchmark_row(const char* name, const BenchmarkStats& s) {
    printf("%-35s | Median: %6.2f ms | P95: %6.2f ms | Mean: %6.2f ms | Min: %6.2f ms | Max: %6.2f ms\n",
           name, s.median_ms, s.p95_ms, s.mean_ms, s.min_ms, s.max_ms);
}

int main() {
    const int32_t width = 1200;
    const int32_t height = 670;
    const int32_t stride = width * 4;
    const size_t total_bytes = static_cast<size_t>(height * stride);
    const int total_pixels = width * height;

    printf("========================================================================================\n");
    printf("AEVIQUE Core Standalone Native Benchmark\n");
    printf("========================================================================================\n");
    printf("Resolution:       %d x %d (%d pixels, %.2f MB RGBA8)\n",
           width, height, total_pixels, static_cast<double>(total_bytes) / (1024.0 * 1024.0));
    printf("Compiler:         AppleClang (C++17, Release / -O3)\n");
    printf("Target Arch:      Apple Silicon ARM64 (darwin-arm64)\n");
    printf("Iterations:       50 measured runs (after 5 warm-up runs)\n");
    printf("========================================================================================\n\n");

    // Allocate test buffers
    std::vector<uint8_t> src_mem(total_bytes);
    std::vector<uint8_t> dst_mem(total_bytes);

    // Initialize with realistic image gradient
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            size_t idx = static_cast<size_t>(y * stride + x * 4);
            src_mem[idx + 0] = static_cast<uint8_t>((x * 255) / width);
            src_mem[idx + 1] = static_cast<uint8_t>((y * 255) / height);
            src_mem[idx + 2] = static_cast<uint8_t>(((x + y) * 255) / (width + height));
            src_mem[idx + 3] = 255;
        }
    }

    AeviqueImageBuffer src;
    src.data = src_mem.data();
    src.width = width;
    src.height = height;
    src.stride_bytes = stride;
    src.format = AEVIQUE_PIXEL_FORMAT_RGBA8888;

    AeviqueImageBuffer dst;
    dst.data = dst_mem.data();
    dst.width = width;
    dst.height = height;
    dst.stride_bytes = stride;
    dst.format = AEVIQUE_PIXEL_FORMAT_RGBA8888;

    const int warm_up = 5;
    const int iterations = 50;

    // Test cases
    struct TestCase {
        const char* name;
        AeviqueToneParameters params;
        bool in_place;
    };

    TestCase cases[] = {
        {"1. Neutral (Zero-op Copy)", {0.0f, 0.0f, 0.0f}, false},
        {"2. Neutral (In-Place Fast-path)", {0.0f, 0.0f, 0.0f}, true},
        {"3. Tone Only (Exp +20, Con +25)", {20.0f, 25.0f, 0.0f}, false},
        {"4. Tone Only In-Place (Exp +20)", {20.0f, 25.0f, 0.0f}, true},
        {"5. Saturation Only (Sat +25)", {0.0f, 0.0f, 25.0f}, false},
        {"6. Fused Tone+Sat Out-of-Place", {20.0f, 25.0f, 25.0f}, false},
        {"7. Fused Tone+Sat In-Place", {20.0f, 25.0f, 25.0f}, true},
        {"8. Full Monochrome (Sat -100)", {0.0f, 0.0f, -100.0f}, false},
    };

    for (const auto& tc : cases) {
        AeviqueImageBuffer* target_dst = tc.in_place ? &src : &dst;

        // Warm-up
        for (int i = 0; i < warm_up; i++) {
            aevique_process_tone_rgba8(&src, target_dst, &tc.params);
        }

        // Measure
        std::vector<double> times;
        times.reserve(iterations);

        for (int i = 0; i < iterations; i++) {
            auto start = std::chrono::high_resolution_clock::now();
            aevique_process_tone_rgba8(&src, target_dst, &tc.params);
            auto end = std::chrono::high_resolution_clock::now();

            std::chrono::duration<double, std::milli> elapsed = end - start;
            times.push_back(elapsed.count());
        }

        BenchmarkStats s = compute_stats(times);
        print_benchmark_row(tc.name, s);
    }

    // Phase 3: Advanced Tone Engine Benchmark (1200x670)
    printf("\n--- Phase 3 Advanced Tone Engine (1200x670) ---\n");
    AeviqueAdvancedToneParameters adv_params{};
    adv_params.exposure = 20.0f;
    adv_params.contrast = 15.0f;
    adv_params.saturation = 25.0f;
    adv_params.highlights = -30.0f;
    adv_params.shadows = 20.0f;
    adv_params.whites = 10.0f;
    adv_params.blacks = -10.0f;
    adv_params.warmth = 20.0f;
    adv_params.tint = -10.0f;

    AeviqueCurvePoint rgb_pts[] = {{0.0f, 0.0f}, {0.25f, 0.20f}, {0.75f, 0.85f}, {1.0f, 1.0f}};
    AeviqueToneCurves curves{};
    curves.rgb.points = rgb_pts;
    curves.rgb.point_count = 4;

    {
        for (int i = 0; i < warm_up; i++) {
            aevique_process_advanced_tone_rgba8(&src, &dst, &adv_params, &curves);
        }
        std::vector<double> times;
        times.reserve(iterations);
        for (int i = 0; i < iterations; i++) {
            auto start = std::chrono::high_resolution_clock::now();
            aevique_process_advanced_tone_rgba8(&src, &dst, &adv_params, &curves);
            auto end = std::chrono::high_resolution_clock::now();
            std::chrono::duration<double, std::milli> elapsed = end - start;
            times.push_back(elapsed.count());
        }
        BenchmarkStats s = compute_stats(times);
        print_benchmark_row("Phase 3 Full Tone (Curves+Color+Sat)", s);
    }

    // Full-resolution benchmark (4000x3000 = 12 MP)
    printf("\n--- Full Resolution 12 MP (4000x3000 RGBA8) ---\n");
    const int32_t full_w = 4000;
    const int32_t full_h = 3000;
    const int32_t full_stride = full_w * 4;
    const size_t full_bytes = static_cast<size_t>(full_h * full_stride);

    std::vector<uint8_t> full_src_mem(full_bytes, 128);
    std::vector<uint8_t> full_dst_mem(full_bytes, 0);

    AeviqueImageBuffer full_src;
    full_src.data = full_src_mem.data();
    full_src.width = full_w;
    full_src.height = full_h;
    full_src.stride_bytes = full_stride;
    full_src.format = AEVIQUE_PIXEL_FORMAT_RGBA8888;

    AeviqueImageBuffer full_dst;
    full_dst.data = full_dst_mem.data();
    full_dst.width = full_w;
    full_dst.height = full_h;
    full_dst.stride_bytes = full_stride;
    full_dst.format = AEVIQUE_PIXEL_FORMAT_RGBA8888;

    {
        for (int i = 0; i < 3; i++) {
            aevique_process_advanced_tone_rgba8(&full_src, &full_dst, &adv_params, &curves);
        }
        std::vector<double> times;
        times.reserve(15);
        for (int i = 0; i < 15; i++) {
            auto start = std::chrono::high_resolution_clock::now();
            aevique_process_advanced_tone_rgba8(&full_src, &full_dst, &adv_params, &curves);
            auto end = std::chrono::high_resolution_clock::now();
            std::chrono::duration<double, std::milli> elapsed = end - start;
            times.push_back(elapsed.count());
        }
        BenchmarkStats s = compute_stats(times);
        print_benchmark_row("12 MP Full Tone (Curves+Tone+Sat)", s);
    }

    printf("\n========================================================================================\n");
    printf("Benchmark Complete.\n");
    printf("========================================================================================\n");

    return 0;
}

