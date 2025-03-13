import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:take_photo/widget/cameraOverlayPainter.widget.dart';

class CameraWidget extends StatefulWidget {
  final double cropWidth;
  final double cropHeight;

  const CameraWidget({super.key, this.cropWidth = 1, this.cropHeight = 1});

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();
  }

  /// Solicita permisos de cámara y almacenamiento
  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  /// Inicializa la cámara
  Future<void> _initCamera() async {
    try {
      await _requestPermissions();
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception("No hay cámaras disponibles");

      _cameraController = CameraController(_cameras[0], ResolutionPreset.high);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      _initializeControllerFuture = Future.error(e);
    }
  }

  /// Captura una imagen y la recorta
  Future<void> _takePicture() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;

      final XFile photo = await _cameraController!.takePicture();
      File? croppedFile = await _cropImage(File(photo.path), 150, 150);

      if (croppedFile != null) {
        Navigator.pop(context, croppedFile); // Retorna la imagen recortada
      }
    } catch (e) {
      print("Error al tomar foto: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildOverlay(screenWidth: size.width, screenHeight: size.height),
          _buildTopBar(),
          _buildCaptureButton(),
        ],
      ),
    );
  }

  /// Muestra la vista previa de la cámara
  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : _errorMessage("No se pudo inicializar la cámara");
        } else if (snapshot.hasError) {
          return _errorMessage("Error al cargar la cámara");
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  /// Botón de retroceso en la parte superior
  Widget _buildTopBar() {
    return Positioned(
      top: 40,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// Botón de captura de imagen
  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: ElevatedButton(
          onPressed: _takePicture,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: const Icon(Icons.camera_alt, size: 40),
        ),
      ),
    );
  }

  /// Muestra un mensaje de error en el centro de la pantalla
  Widget _errorMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Crea el overlay con dimensiones proporcionadas
  Widget _buildOverlay({required double screenWidth, required double screenHeight}) {
    double overlayWidth = screenWidth * 0.8;
    double overlayHeight = overlayWidth * (11 / 8.5);

    if (overlayHeight > screenHeight * 0.8) {
      overlayHeight = screenHeight * 0.8;
      overlayWidth = overlayHeight * (8.5 / 11);
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: CameraOverlayPainter(overlayWidth: overlayWidth, overlayHeight: overlayHeight),
        ),
      ),
    );
  }

  /// Recorta la imagen capturada
  Future<File?> _cropImage(File imageFile, int width, int height) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    int x = (image.width - width) ~/ 2;
    int y = (image.height - height) ~/ 2;

    final cropped = img.copyCrop(image, x: x, y: y, width: width, height: height);
    final croppedBytes = Uint8List.fromList(img.encodePng(cropped));

    final tempDir = await getTemporaryDirectory();
    final outputFile = File('${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');

    await outputFile.writeAsBytes(croppedBytes);
    return outputFile;
  }
}

// /// 🔹 Dibuja el overlay de la cámara
// class CameraOverlayPainter extends CustomPainter {
//   final double overlayWidth;
//   final double overlayHeight;

//   CameraOverlayPainter({required this.overlayWidth, required this.overlayHeight});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..color = Colors.green
//       ..strokeWidth = 4
//       ..style = PaintingStyle.stroke;

//     double marginX = (size.width - overlayWidth) / 2;
//     double marginY = (size.height - overlayHeight) / 2;
//     double cornerSize = 30;

//     _drawCorner(canvas, marginX, marginY, paint, cornerSize, isTopLeft: true);
//     _drawCorner(canvas, marginX + overlayWidth, marginY, paint, cornerSize, isTopLeft: false);
//     _drawCorner(canvas, marginX, marginY + overlayHeight, paint, cornerSize, isTopLeft: false, isBottom: true);
//     _drawCorner(canvas, marginX + overlayWidth, marginY + overlayHeight, paint, cornerSize, isBottom: true);
//   }

//   void _drawCorner(Canvas canvas, double x, double y, Paint paint, double size, {bool isTopLeft = false, bool isBottom = false}) {
//     canvas.drawLine(Offset(x, y), Offset(x + (isTopLeft ? size : -size), y), paint);
//     canvas.drawLine(Offset(x, y), Offset(x, y + (isBottom ? -size : size)), paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
