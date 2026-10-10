import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

/// Keeps compact product photos in the app's private documents directory.
class ProductImageStorage {
  const ProductImageStorage();

  Future<String> save(XFile image) async {
    final directory = await _imageDirectory();
    await directory.create(recursive: true);
    final extension = p.extension(image.path).toLowerCase();
    final safeExtension = RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension)
        ? extension
        : '.jpg';
    final nonce = Random.secure().nextInt(1 << 32).toRadixString(16);
    final destination = File(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_$nonce$safeExtension',
      ),
    );
    await File(image.path).copy(destination.path);
    return destination.path;
  }

  Future<void> delete(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    final directory = await _imageDirectory();
    if (p.equals(
      p.normalize(p.dirname(imagePath)),
      p.normalize(directory.path),
    )) {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    }
  }

  Future<Directory> _imageDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, 'product_images'));
  }
}
