import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;


Future<File?> cropImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // final x = (image.width - width) ~/ 2;
    // final y = (image.height - height) ~/ 2;
 const width = 2550;  // Ancho de una hoja Carta en píxeles (Aprox. 2550px)
const height = 3300; // Alto de una hoja Carta en píxeles (Aprox. 3300px)

final x = (image.width - width) ~/ 2;  // Centrar en X  
final y = (image.height - height) ~/ 2;  // Centrar en Y  


    final cropped =
        img.copyCrop(image, x: x, y: y, width: width, height: height);
    final croppedBytes = Uint8List.fromList(img.encodePng(cropped));

    final tempDir = await getTemporaryDirectory();
    final outputFile = File(
        '${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');

    await outputFile.writeAsBytes(croppedBytes);
    
    return outputFile;
  }