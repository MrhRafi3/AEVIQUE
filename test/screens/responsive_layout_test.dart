import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/core/models/edit_state.dart';
import 'package:lumaforge/screens/editor_screen.dart';
import 'package:lumaforge/screens/export_screen.dart';
import 'package:lumaforge/screens/home_screen.dart';
import 'package:lumaforge/screens/presets_screen.dart';
import 'package:lumaforge/screens/settings_screen.dart';
import 'package:lumaforge/services/export_service.dart';
import 'package:lumaforge/services/image_repository.dart';
import 'package:lumaforge/theme/aevique_theme.dart';

class _FakeRepo implements ImageRepository {
  final Uint8List bytes;
  _FakeRepo(this.bytes);

  @override
  Future<Uint8List?> pickImageFromGallery() async => bytes;

  @override
  Future<Uint8List?> pickImageFromCamera() async => bytes;

  @override
  Future<Uint8List?> loadSampleAsset(String path) async => bytes;

  @override
  List<SampleImageItem> getSampleImages() => [];
}

class _FakeExportService implements ExportService {
  @override
  Future<bool> saveToGallery(Uint8List imageBytes, {String name = ''}) async =>
      true;

  @override
  Future<bool> shareImage(Uint8List imageBytes, {String name = ''}) async =>
      true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Uint8List sampleBytes;
  late _FakeRepo fakeRepo;
  late _FakeExportService fakeExport;

  setUp(() {
    final image = img.Image(width: 60, height: 40);
    img.fill(image, color: img.ColorRgb8(100, 150, 200));
    sampleBytes = Uint8List.fromList(img.encodeJpg(image));
    fakeRepo = _FakeRepo(sampleBytes);
    fakeExport = _FakeExportService();
  });

  final testDeviceSizes = [
    const Size(320, 640), // Compact / Small Android
    const Size(390, 844), // Standard iPhone / Modern Android
    const Size(428, 926), // Large Pro Max
    const Size(768, 1024), // Tablet Portrait
  ];

  for (final size in testDeviceSizes) {
    group('Responsive verification at ${size.width}x${size.height}', () {
      testWidgets('HomeScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        FlutterErrorDetails? caughtError;
        final prevHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            caughtError = details;
          }
          prevHandler?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AeviqueTheme.darkTheme,
            home: HomeScreen(imageRepository: fakeRepo),
          ),
        );
        await tester.pump();

        FlutterError.onError = prevHandler;
        expect(caughtError, isNull, reason: caughtError?.toString());
      });

      testWidgets('PresetsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        FlutterErrorDetails? caughtError;
        final prevHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            caughtError = details;
          }
          prevHandler?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AeviqueTheme.darkTheme,
            home: PresetsScreen(imageRepository: fakeRepo),
          ),
        );
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 250));
        });
        await tester.pump();

        FlutterError.onError = prevHandler;
        expect(caughtError, isNull, reason: caughtError?.toString());
      });

      testWidgets('EditorScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        FlutterErrorDetails? caughtError;
        final prevHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            caughtError = details;
          }
          prevHandler?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AeviqueTheme.darkTheme,
            home: EditorScreen(
              initialImageBytes: sampleBytes,
              imageName: 'Resp Test',
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 250));
        });
        await tester.pump();

        FlutterError.onError = prevHandler;
        expect(caughtError, isNull, reason: caughtError?.toString());
      });

      testWidgets('ExportScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        FlutterErrorDetails? caughtError;
        final prevHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            caughtError = details;
          }
          prevHandler?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AeviqueTheme.darkTheme,
            home: ExportScreen(
              sourceBytes: sampleBytes,
              state: EditState.identity(),
              exportService: fakeExport,
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 250));
        });
        await tester.pump();

        FlutterError.onError = prevHandler;
        expect(caughtError, isNull, reason: caughtError?.toString());
      });

      testWidgets('SettingsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        FlutterErrorDetails? caughtError;
        final prevHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            caughtError = details;
          }
          prevHandler?.call(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AeviqueTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        );
        await tester.pump();

        FlutterError.onError = prevHandler;
        expect(caughtError, isNull, reason: caughtError?.toString());
      });
    });
  }
}
