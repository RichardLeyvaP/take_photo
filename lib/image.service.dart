import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:take_photo/ImageCropperWidget.dart';
import 'package:image/image.dart' as img;
import 'package:take_photo/ImageCropperWidgetRlp.dart';


class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Método para seleccionar una imagen de la galería y recortarla al tamaño de hoja carta
  Future<File?> pickAndCropImage() async {
    // Abrir galería para seleccionar la imagen
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return null; // Si el usuario cancela, retorna null

    // Recortar la imagen con tamaño de hoja carta (8.5 x 11 pulgadas en píxeles)
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 8.5, ratioY: 11), // Relación hoja carta
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop image',
          toolbarColor: const Color(0xFF6200EE),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true, // Mantiene el tamaño de hoja carta
        ),
        IOSUiSettings(
          title: 'Crop image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return null; // Si el usuario cancela el recorte

    return File(croppedFile.path); // Retorna el archivo recortado
  }
  
  /// Método para seleccionar una imagen de la galería y recortarla al tamaño de hoja carta
void pickAndCropImageNew(context) async {
  try {
    // Abrir galería para seleccionar la imagen
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return; // Si el usuario cancela, retorna

    // Navegar a la pantalla de recorte de imagen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCropperWidget(imageFile: File(pickedFile.path)),
      ),
    );
  } catch (e) {
    print('Error al cargar la foto');
  }
}



Future<File> convertToFile(img.Image? croppedImage) async {
  // Asegúrate de que la imagen no sea nula
  if (croppedImage == null) {
    throw ArgumentError('La imagen no puede ser nula');
  }

  // Obtén el directorio temporal de la aplicación
  Directory tempDir = await getTemporaryDirectory();
  
  // Genera un path único para el archivo
  String tempPath = '${tempDir.path}/cropped_image.jpg';

  // Convierte la imagen a bytes
  List<int> bytes = img.encodeJpg(croppedImage);

  // Crea un archivo y guarda los bytes
  File file = File(tempPath);
  await file.writeAsBytes(bytes);

  return file;
}



img.Image cropImage({
  required img.Image image, 
  required int x, 
  required int y, 
  required int width, 
  required int height, 
  double zoomFactor = 1.0,  // Si no se pasa, se asume que no hay zoom
}) {
  // Ajustar coordenadas si hay zoom
  int adjustedX = (x / zoomFactor).toInt();
  int adjustedY = (y / zoomFactor).toInt();
  int adjustedWidth = (width / zoomFactor).toInt();
  int adjustedHeight = (height / zoomFactor).toInt();

  print('Adjusted coordinates: $adjustedX, $adjustedY, $adjustedWidth, $adjustedHeight');

  // Evitar valores fuera del rango de la imagen
  adjustedX = adjustedX.clamp(0, image.width - 1);
  adjustedY = adjustedY.clamp(0, image.height - 1);
  adjustedWidth = adjustedWidth.clamp(1, image.width - adjustedX);
  adjustedHeight = adjustedHeight.clamp(1, image.height - adjustedY);
  print('Adjusted coordinates-2: $adjustedX, $adjustedY, $adjustedWidth, $adjustedHeight');

  // Recortar imagen
  return img.copyCrop(
    image, 
    x: adjustedX, 
    y: adjustedY, 
    width: adjustedWidth, 
    height: adjustedHeight
  );
}


Future<img.Image> decodeAndResizeImage(File imageFile, {int maxWidth = 1024}) async {
  final imageBytes = await imageFile.readAsBytes();
  final image = img.decodeImage(imageBytes)!;

  // // Reducir la resolución de la imagen si es necesario
  // if (image.width > maxWidth) {
  //   final aspectRatio = image.height / image.width;
  //   final newHeight = (maxWidth * aspectRatio).toInt();
  //   return img.copyResize(image, width: maxWidth, height: newHeight);
  // }

  return image;
}

 /* Future<File?> captureAndSaveImage(ScreenshotController screenshotController) async {
    try {
      // Capturar toda la pantalla
      final image = await screenshotController.capture();

      // Guardar la imagen en el almacenamiento
      if (image == null) {
      return null;
      }
      else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/screenshot.png');
        await file.writeAsBytes(image);
        print("Imagen guardada en: ${file.path}");
        return file;
      }
      
    } catch (e) {
      
      print("Error al capturar la imagen: $e");
      return null;
    }
   
  }*/




}
