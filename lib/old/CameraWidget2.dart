import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class CameraWidget2 extends StatefulWidget {
  final double cropWidthRatio;
  final double cropHeightRatio;

  const CameraWidget2({super.key, this.cropWidthRatio = 1, this.cropHeightRatio = 1});

  @override
  _CameraWidget2State createState() => _CameraWidget2State();
}

class _CameraWidget2State extends State<CameraWidget2> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        throw Exception("No hay cámaras disponibles");
      }

      _cameraController = CameraController(cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error al inicializar la cámara: $e");
      _initializeControllerFuture = Future.error(e);
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_initializeControllerFuture == null) {
        print("Cámara aún no inicializada.");
        return;
      }

      await _initializeControllerFuture;

      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        print("La cámara no está lista.");
        return;
      }

      final XFile photo = await _cameraController!.takePicture();
      File croppedFile = await _cropImage(File(photo.path));

      print("Imagen guardada: ${croppedFile.path}");
    } catch (e) {
      print("Error al tomar foto: $e");
    }
  }

  Future<File> _cropImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image originalImage = img.decodeImage(bytes)!;

    int width = originalImage.width;
    int height = originalImage.height;

    int cropWidth = (width * widget.cropWidthRatio).toInt();
    int cropHeight = (height * widget.cropHeightRatio).toInt();
    int offsetX = (width - cropWidth) ~/ 2;
    int offsetY = (height - cropHeight) ~/ 2;

    img.Image croppedImage = img.copyCrop(originalImage, x: offsetX, y: offsetY, width: cropWidth, height: cropHeight);

    final directory = await getApplicationDocumentsDirectory();
    final croppedFile = File("${directory.path}/cropped_image.jpg");

    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

    return croppedFile;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_cameraController == null || !_cameraController!.value.isInitialized) {
                  return const Center(
                    child: Text("No se pudo inicializar la cámara", style: TextStyle(color: Colors.white)),
                  );
                }
                return CameraPreview(_cameraController!);
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text("Error al cargar la cámara", style: TextStyle(color: Colors.white)),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _takePicture,
                child: const Icon(Icons.camera, color: Colors.black, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
