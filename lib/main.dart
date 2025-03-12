import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:take_photo/camera.service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
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
    print("Permiso de almacenamiento concedido ✅");
  } else if (status.isDenied) {
    print("Permiso de almacenamiento denegado ❌");    
  } else if (status.isPermanentlyDenied) {
    print("Permiso permanentemente denegado, abriendo configuración...");
    await openAppSettings(); // Abrimos la configuración manualmente
  }
}

Future<bool> _checkPermissions() async {
  PermissionStatus cameraStatus = await Permission.camera.status;
  PermissionStatus storageStatus = await Permission.storage.status;

  return cameraStatus.isGranted && storageStatus.isGranted;
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            ElevatedButton(
                onPressed: () async {
                  await requestCameraPermission();
                  await requestStoragePermission();

                  var granted = await _checkPermissions();
                  if (granted && context.mounted) {
                    CameraService.openCameraModal(context);
                  }
                },
                child: const Text("Take Photo")),
          ],
        ));
  }
}
