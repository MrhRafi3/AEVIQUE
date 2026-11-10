import 'package:flutter_test/flutter_test.dart';
import 'package:lumafix/core/models/edit_state.dart';
import 'package:lumafix/core/models/history_manager.dart';

void main() {
  group('EditState and Sub-models', () {
    test('Initial EditState is default/identity', () {
      final state = EditState.identity();
      expect(state.isIdentity, isTrue);
      expect(state.tune.brightness, 0.0);
      expect(state.tune.contrast, 0.0);
      expect(state.tune.isIdentity, isTrue);
      expect(state.details.isIdentity, isTrue);
      expect(state.geometry.isIdentity, isTrue);
      expect(state.effects.isIdentity, isTrue);
      expect(state.portrait.isIdentity, isTrue);
      expect(state.curves.isIdentity, isTrue);
      expect(state.vignette.isIdentity, isTrue);
    });

    test(
      'PortraitAdjustments copyWith, blemishes and serialization roundtrip',
      () {
        final portrait = const PortraitAdjustments(
          skinSmooth: 35.0,
          skinBrighten: 15.0,
          blemishes: [
            BlemishSpot(x: 0.45, y: 0.55, radius: 0.025),
            BlemishSpot(x: 0.60, y: 0.70, radius: 0.03),
          ],
        );
        expect(portrait.isIdentity, isFalse);
        expect(portrait.blemishes.length, 2);

        final state = EditState.identity().copyWith(portrait: portrait);
        final json = state.toJson();
        final restored = EditState.fromJson(json);

        expect(restored.portrait.skinSmooth, 35.0);
        expect(restored.portrait.skinBrighten, 15.0);
        expect(restored.portrait.blemishes.length, 2);
        expect(restored.portrait.blemishes.first.x, 0.45);
        expect(restored.portrait.blemishes.first.y, 0.55);
        expect(restored, equals(state));
      },
    );

    test('TuneAdjustments copyWith and identity check', () {
      final tune = const TuneAdjustments().copyWith(
        brightness: 25.0,
        contrast: -10.0,
      );
      expect(tune.brightness, 25.0);
      expect(tune.contrast, -10.0);
      expect(tune.isIdentity, isFalse);

      final reset = tune.copyWith(brightness: 0.0, contrast: 0.0);
      expect(reset.isIdentity, isTrue);
    });

    test('GeometryAdjustments rotation and flip', () {
      final geom = const GeometryAdjustments().copyWith(
        rotationQuarterTurns: 1,
        flipHorizontal: true,
      );
      expect(geom.rotationQuarterTurns, 1);
      expect(geom.flipHorizontal, isTrue);
      expect(geom.isIdentity, isFalse);
    });

    test('Serialization round-trip preserves state', () {
      final original = EditState.identity().copyWith(
        tune: const TuneAdjustments(
          brightness: 15.0,
          contrast: -20.0,
          saturation: 30.0,
          warmth: 10.0,
        ),
        effects: const EffectsAdjustments(bwMode: true, grain: 40.0),
        geometry: const GeometryAdjustments(
          rotationQuarterTurns: 2,
          cropLeft: 0.1,
          cropRight: 0.9,
        ),
      );

      final json = original.toJson();
      final restored = EditState.fromJson(json);

      expect(restored.tune.brightness, 15.0);
      expect(restored.tune.contrast, -20.0);
      expect(restored.tune.saturation, 30.0);
      expect(restored.tune.warmth, 10.0);
      expect(restored.effects.bwMode, isTrue);
      expect(restored.effects.grain, 40.0);
      expect(restored.geometry.rotationQuarterTurns, 2);
      expect(restored.geometry.cropLeft, 0.1);
      expect(restored.geometry.cropRight, 0.9);
      expect(restored, equals(original));
    });

    test('HslAdjustments updateBand, resetBand, and roundtrip serialization', () {
      final initialHsl = const HslAdjustments();
      expect(initialHsl.isIdentity, isTrue);

      final updated = initialHsl
          .updateBand(HslColorBand.blue, hue: 15.0, saturation: 25.0, luminance: -10.0)
          .updateBand(HslColorBand.orange, hue: -5.0, saturation: 30.0);

      expect(updated.isIdentity, isFalse);
      expect(updated.blue.hue, 15.0);
      expect(updated.blue.saturation, 25.0);
      expect(updated.blue.luminance, -10.0);
      expect(updated.orange.hue, -5.0);
      expect(updated.orange.saturation, 30.0);
      expect(updated.red.isIdentity, isTrue);

      final resetBlue = updated.resetBand(HslColorBand.blue);
      expect(resetBlue.blue.isIdentity, isTrue);
      expect(resetBlue.orange.isIdentity, isFalse);

      final state = EditState.identity().copyWith(hsl: updated);
      final json = state.toJson();
      final restored = EditState.fromJson(json);

      expect(restored.hsl.blue.hue, 15.0);
      expect(restored.hsl.blue.saturation, 25.0);
      expect(restored.hsl.orange.saturation, 30.0);
      expect(restored.hsl, equals(updated));
    });

    test('SelectiveMask and MaskToneAdjustments serialization and equality', () {
      final mask1 = SelectiveMask(
        id: 'brush_1',
        name: 'Sky Brush',
        type: MaskType.brush,
        inverted: false,
        opacity: 0.85,
        brushPoints: const [
          MaskPoint(x: 0.2, y: 0.3, radius: 0.05, feather: 0.6),
          MaskPoint(x: 0.25, y: 0.35, radius: 0.05, feather: 0.6),
        ],
        adjustments: const MaskToneAdjustments(exposure: 15.0, clarity: 20.0),
      );

      final mask2 = SelectiveMask(
        id: 'linear_1',
        name: 'Ground Gradient',
        type: MaskType.linearGradient,
        inverted: true,
        linearData: const LinearGradientData(startX: 0.5, startY: 0.7, endX: 0.5, endY: 1.0),
        adjustments: const MaskToneAdjustments(warmth: 25.0, brightness: -10.0),
      );

      final state = EditState.identity().copyWith(
        masks: [mask1, mask2],
        showMaskOverlay: true,
      );

      expect(state.isIdentity, isFalse);
      expect(state.masks.length, 2);
      expect(state.showMaskOverlay, isTrue);

      final json = state.toJson();
      final restored = EditState.fromJson(json);

      expect(restored.masks.length, 2);
      expect(restored.masks[0].id, 'brush_1');
      expect(restored.masks[0].brushPoints.length, 2);
      expect(restored.masks[0].adjustments.exposure, 15.0);
      expect(restored.masks[1].inverted, isTrue);
      expect(restored.masks[1].adjustments.warmth, 25.0);
      expect(restored.showMaskOverlay, isTrue);
      expect(restored, equals(state));
    });

    test('EffectsAdjustments glow and lensBlur', () {
      final effects = const EffectsAdjustments(
        bloom: 20.0,
        glow: 35.0,
        lensBlur: 45.0,
        grain: 10.0,
      );
      expect(effects.isIdentity, isFalse);
      expect(effects.glow, 35.0);
      expect(effects.lensBlur, 45.0);

      final state = EditState.identity().copyWith(effects: effects);
      final json = state.toJson();
      final restored = EditState.fromJson(json);

      expect(restored.effects.glow, 35.0);
      expect(restored.effects.lensBlur, 45.0);
      expect(restored.effects, equals(effects));
    });
  });

  group('HistoryManager', () {
    test('Push, undo, and redo manage stack correctly', () {
      final initial = EditState.identity();
      final history = HistoryManager(initialState: initial);

      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.current, equals(initial));

      final step1 = initial.copyWith(
        tune: const TuneAdjustments(brightness: 20.0),
      );
      history.push(step1);

      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
      expect(history.current.tune.brightness, 20.0);

      final step2 = step1.copyWith(
        tune: const TuneAdjustments(brightness: 20.0, contrast: 15.0),
      );
      history.push(step2);

      expect(history.canUndo, isTrue);
      expect(history.historyLength, 3);

      // Undo to step 1
      final undone1 = history.undo();
      expect(undone1, isNotNull);
      expect(history.current.tune.contrast, 0.0);
      expect(history.current.tune.brightness, 20.0);
      expect(history.canRedo, isTrue);

      // Undo to initial
      final undone2 = history.undo();
      expect(undone2, isNotNull);
      expect(history.current.tune.brightness, 0.0);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);

      // Redo to step 1
      final redone1 = history.redo();
      expect(redone1, isNotNull);
      expect(history.current.tune.brightness, 20.0);
      expect(history.canUndo, isTrue);

      // Branching history by pushing new state after undo clears redo
      final step3 = history.current.copyWith(
        effects: const EffectsAdjustments(bwMode: true),
      );
      history.push(step3);
      expect(history.canRedo, isFalse);
      expect(history.current.effects.bwMode, isTrue);
    });

    test('Pushing identical state is ignored', () {
      final initial = EditState.identity();
      final history = HistoryManager(initialState: initial);

      history.push(initial);
      expect(history.historyLength, 1);
      expect(history.canUndo, isFalse);
    });

    test('Reset restores initial state', () {
      final initial = EditState.identity();
      final history = HistoryManager(initialState: initial);
      history.push(
        initial.copyWith(tune: const TuneAdjustments(brightness: 50.0)),
      );
      history.push(
        initial.copyWith(tune: const TuneAdjustments(brightness: 80.0)),
      );

      expect(history.historyLength, 3);
      history.reset();
      expect(history.historyLength, 1);
      expect(history.current.isIdentity, isTrue);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });
  });
}
