import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SampleImageItem {
  final String title;
  final String assetPath;
  final String description;

  const SampleImageItem({
    required this.title,
    required this.assetPath,
    required this.description,
  });
}

abstract class ImageRepository {
  Future<Uint8List?> pickImageFromGallery();
  Future<Uint8List?> pickImageFromCamera();
  Future<Uint8List?> loadSampleAsset(String path);
  List<SampleImageItem> getSampleImages();
}

class DefaultImageRepository implements ImageRepository {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> pickImageFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
      );
      if (xFile == null) return null;
      return await xFile.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List?> pickImageFromCamera() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 4096,
        maxHeight: 4096,
      );
      if (xFile == null) return null;
      return await xFile.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List?> loadSampleAsset(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  List<SampleImageItem> getSampleImages() {
    return const [
      SampleImageItem(
        title: 'Sunset Landscape',
        assetPath: 'assets/images/sample_landscape.jpg',
        description: 'Dynamic range golden sunset over lake',
      ),
      SampleImageItem(
        title: 'Studio Portrait',
        assetPath: 'assets/images/sample_portrait.jpg',
        description: 'Warm skin tones and studio lighting',
      ),
      SampleImageItem(
        title: 'Nature & Greenery',
        assetPath: 'assets/images/sample_nature.jpg',
        description: 'Rich emerald foliage and outdoor morning light',
      ),
      SampleImageItem(
        title: 'Modern Architecture',
        assetPath: 'assets/images/sample_architecture.jpg',
        description: 'Geometric perspective and structural lines',
      ),
      SampleImageItem(
        title: 'Artisan Food & Cafe',
        assetPath: 'assets/images/sample_food.jpg',
        description: 'Warm tones and still-life textures',
      ),
    ];
  }
}
