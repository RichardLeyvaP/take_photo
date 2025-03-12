import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:take_photo/camera.service.dart';

void _showImageModal(BuildContext context, File imageFile) {
 showDialog(
  context: context,
  builder: (BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        // Puedes ajustar el tamaño máximo aquí
        width: MediaQuery.of(context).size.width * 0.9, // 90% del ancho de la pantalla
        height: MediaQuery.of(context).size.height * 0.7, // 70% de la altura de la pantalla
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              imageFile, 
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height * 0.5, // Ajusta el alto si es necesario
              width: double.infinity, // Ajusta el ancho a la pantalla
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Foto tomada", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cerrar"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Guardar imagen"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);

}

void onCameraPressed(BuildContext context) async {
  await requestCameraPermission();
  await requestStoragePermission();

  var granted = await _checkPermissions();
  if (granted && context.mounted) {
     File? photo;
     photo = await CameraService.openCameraModal(context);
    if (photo != null && context.mounted) {
      _showImageModal(context, photo);
      
    }
  }
}
Future<void> requestCameraPermission() async {
  var status = await Permission.camera.request();

  if (status.isGranted) {
    print("Permiso de cámara concedido");
  } else if (status.isDenied) {
    print("Permiso de cámara denegado");
  } else if (status.isPermanentlyDenied) {
    print(
        "Permiso de cámara permanentemente denegado, abre la configuración...");
    await openAppSettings();
  }
}

Future<void> requestStoragePermission() async {
  // Detectamos qué permiso usar dependiendo de la versión de Android
  Permission storagePermission = Permission.storage;
  
  if (await Permission.photos.isRestricted || await Permission.photos.isPermanentlyDenied) {
    storagePermission = Permission.photos;
  }

  var status = await storagePermission.request();

  if (status.isGranted) {
    print("Permiso de almacenamiento concedido rlp ✅");
  } else if (status.isDenied) {
    print("Permiso de almacenamiento denegado rlp ❌");    
  } else if (status.isPermanentlyDenied) {
    print("Permiso permanentemente denegado, abriendo configuración... rlp");
    await openAppSettings(); // Abrimos la configuración manualmente
  }
}

Future<bool> _checkPermissions() async {
  PermissionStatus cameraStatus = await Permission.camera.status;
  PermissionStatus storageStatus = await Permission.storage.status;

  return cameraStatus.isGranted && storageStatus.isGranted;
}