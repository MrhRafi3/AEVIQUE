import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumafix/core/models/edit_state.dart';
import 'package:lumafix/core/image_engine/image_pipeline.dart';
import 'package:lumafix/core/image_engine/coordinate_transformer.dart';

void main() {
  group('GeometryAdjustments Continuous Rotation & Straightening', () {
    test('Default GeometryAdjustments has rotationAngle = 0.0 and isIdentity = true', () {
      const geo = GeometryAdjustments();
      expect(geo.rotationAngle, 0.0);
      expect(geo.isIdentity, isTrue);
    });

    test('copyWith properly updates rotationAngle and affects isIdentity', () {
      const geo = GeometryAdjustments();
      final rotated = geo.copyWith(rotationAngle: 3.5);
      expect(rotated.rotationAngle, 3.5);
      expect(rotated.isIdentity, isFalse);

      final reset = rotated.copyWith(rotationAngle: 0.0);
      expect(reset.isIdentity, isTrue);
    });

    test('Serialization and deserialization preserves rotationAngle', () {
      const geo = GeometryAdjustments(
        cropLeft: 0.1,
        cropTop: 0.2,
        cropRight: 0.9,
        cropBottom: 0.8,
        rotationQuarterTurns: 1,
        rotationAngle: -7.5,
        flipHorizontal: true,
      );
      final json = geo.toJson();
      expect(json['rotationAngle'], -7.5);

      final restored = GeometryAdjustments.fromJson(json);
      expect(restored.rotationAngle, -7.5);
      expect(restored.rotationQuarterTurns, 1);
      expect(restored.cropLeft, 0.1);
      expect(restored.flipHorizontal, isTrue);
    });

    test('ImagePipeline processes continuous rotation and crop correctly', () async {
      // Create a test image 200x100 (aspect 2:1)
      final testImg = img.Image(width: 200, height: 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 200; x++) {
          testImg.setPixelRgba(x, y, x.clamp(0, 255), y.clamp(0, 255), 128, 255);
        }
      }
      final pngBytes = Uint8List.fromList(img.encodePng(testImg));

      final state = const EditState().copyWith(
        geometry: const GeometryAdjustments(
          rotationAngle: 15.0,
          cropLeft: 0.1,
          cropTop: 0.1,
          cropRight: 0.9,
          cropBottom: 0.9,
        ),
      );

      final processedBytes = await ImagePipeline.processImage(pngBytes, state, outputPng: true);
      final decoded = img.decodeImage(processedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, greaterThan(0));
      expect(decoded.height, greaterThan(0));
    });
  });

  group('ImageCoordinateTransformer', () {
    test('Calculates correct display rect with letterboxing (BoxFit.contain)', () {
      const viewportSize = Size(400, 800);

      final rect = ImageCoordinateTransformer.getDisplayRect(
        viewportSize: viewportSize,
        imageAspectRatio: 2.0,
      );

      // Width should fill 400, height should be 200, centered vertically (top: 300)
      expect(rect.left, 0.0);
      expect(rect.width, 400.0);
      expect(rect.height, 200.0);
      expect(rect.top, 300.0);
    });

    test('Maps viewport coordinates to normalized [0..1] image coordinates accurately', () {
      const viewportSize = Size(400, 800);

      // Center of viewport (200, 400) should map to center of image (0.5, 0.5)
      final normCenter = ImageCoordinateTransformer.viewportToNormalized(
        viewportPos: const Offset(200, 400),
        viewportSize: viewportSize,
        imageAspectRatio: 2.0,
      );

      expect(normCenter, isNotNull);
      expect((normCenter!.dx - 0.5).abs(), lessThan(1e-4));
      expect((normCenter.dy - 0.5).abs(), lessThan(1e-4));

      // Coordinate in letterbox area (200, 50) should return null (outside image)
      final outside = ImageCoordinateTransformer.viewportToNormalized(
        viewportPos: const Offset(200, 50),
        viewportSize: viewportSize,
        imageAspectRatio: 2.0,
        clampToImage: false,
      );
      expect(outside, isNull);
    });
  });
}
