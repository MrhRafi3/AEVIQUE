#ifdef __APPLE__

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#include "lumafix_vision.h"
#include <vector>

int lumafix_apple_vision_segment_person(
    const uint8_t* rgba_data,
    int32_t width,
    int32_t height,
    int32_t stride_bytes,
    uint8_t* out_mask,
    int32_t out_w,
    int32_t out_h
) {
    if (!rgba_data || !out_mask || width <= 0 || height <= 0 || out_w <= 0 || out_h <= 0) {
        return -1;
    }

    @autoreleasepool {
        if (@available(macOS 12.0, iOS 15.0, *)) {
            // CoreVideo requires 32BGRA format for CVPixelBuffer
            size_t totalPixels = (size_t)width * height;
            std::vector<uint8_t> bgra(totalPixels * 4);
            uint8_t* dstPtr = bgra.data();
            const int effective_stride = stride_bytes > 0 ? stride_bytes : width * 4;

            for (int y = 0; y < height; ++y) {
                const uint8_t* row = rgba_data + y * effective_stride;
                for (int x = 0; x < width; ++x) {
                    dstPtr[(y * width + x) * 4 + 0] = row[x * 4 + 2]; // B
                    dstPtr[(y * width + x) * 4 + 1] = row[x * 4 + 1]; // G
                    dstPtr[(y * width + x) * 4 + 2] = row[x * 4 + 0]; // R
                    dstPtr[(y * width + x) * 4 + 3] = row[x * 4 + 3]; // A
                }
            }

            CVPixelBufferRef pixelBuffer = NULL;
            CVReturn cvRet = CVPixelBufferCreateWithBytes(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_32BGRA,
                (void*)bgra.data(),
                width * 4,
                NULL,
                NULL,
                NULL,
                &pixelBuffer
            );

            if (cvRet != kCVReturnSuccess || !pixelBuffer) {
                return -2;
            }

            VNGeneratePersonSegmentationRequest* request = [[VNGeneratePersonSegmentationRequest alloc] init];
            request.qualityLevel = VNGeneratePersonSegmentationRequestQualityLevelBalanced;
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8;

            VNImageRequestHandler* handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer options:@{}];
            NSError* error = nil;
            BOOL success = [handler performRequests:@[request] error:&error];
            CVPixelBufferRelease(pixelBuffer);

            if (!success || error) {
                return -3;
            }

            VNPixelBufferObservation* observation = [request.results firstObject];
            if (!observation) {
                return -4;
            }

            CVPixelBufferRef maskBuf = observation.pixelBuffer;
            size_t maskW = CVPixelBufferGetWidth(maskBuf);
            size_t maskH = CVPixelBufferGetHeight(maskBuf);

            CVPixelBufferLockBaseAddress(maskBuf, kCVPixelBufferLock_ReadOnly);
            const uint8_t* base = (const uint8_t*)CVPixelBufferGetBaseAddress(maskBuf);
            size_t bpr = CVPixelBufferGetBytesPerRow(maskBuf);

            // Bilinear resize to output resolution
            for (int32_t y = 0; y < out_h; y++) {
                float v = ((float)y / (float)(out_h > 1 ? out_h - 1 : 1)) * (maskH - 1);
                int32_t y0 = (int32_t)v;
                int32_t y1 = (y0 + 1 < (int32_t)maskH) ? y0 + 1 : y0;
                float fy = v - y0;

                const uint8_t* row0 = base + y0 * bpr;
                const uint8_t* row1 = base + y1 * bpr;
                uint8_t* dstRow = out_mask + y * out_w;

                for (int32_t x = 0; x < out_w; x++) {
                    float u = ((float)x / (float)(out_w > 1 ? out_w - 1 : 1)) * (maskW - 1);
                    int32_t x0 = (int32_t)u;
                    int32_t x1 = (x0 + 1 < (int32_t)maskW) ? x0 + 1 : x0;
                    float fx = u - x0;

                    float top = row0[x0] * (1.0f - fx) + row0[x1] * fx;
                    float bot = row1[x0] * (1.0f - fx) + row1[x1] * fx;
                    float val = top * (1.0f - fy) + bot * fy;

                    dstRow[x] = (uint8_t)(val > 255.0f ? 255 : (val < 0.0f ? 0 : (uint8_t)(val + 0.5f)));
                }
            }

            CVPixelBufferUnlockBaseAddress(maskBuf, kCVPixelBufferLock_ReadOnly);
            return 0;
        } else {
            return -5; // Unsupported macOS version
        }
    }
}

#endif // __APPLE__
