import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
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


}
