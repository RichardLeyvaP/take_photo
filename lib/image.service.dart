import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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
}
