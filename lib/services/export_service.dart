import 'dart:io';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract class ExportService {
  Future<bool> saveToGallery(
    Uint8List imageBytes, {
    String name = 'lumaforge_edit',
  });
  Future<bool> shareImage(
    Uint8List imageBytes, {
    String name = 'lumaforge_edit',
  });
}

class DefaultExportService implements ExportService {
  @override
  Future<bool> saveToGallery(
    Uint8List imageBytes, {
    String name = 'lumaforge_edit',
  }) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final requested = await Gal.requestAccess();
        if (!requested) return false;
      }
      await Gal.putImageBytes(imageBytes, name: name);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> shareImage(
    Uint8List imageBytes, {
    String name = 'lumaforge_edit',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$name.jpg';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: 'Edited with LumaForge'),
      );
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      return false;
    }
  }
}
