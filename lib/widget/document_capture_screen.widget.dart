import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DocumentCaptureScreen extends StatefulWidget {
  const DocumentCaptureScreen({super.key});

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeCamera();
    if (mounted) {
      setState(() {}); // Asegura que la UI se actualice
    }
  }

  Future<void> _initializeCamera() async {
    try {
     
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('No cameras available');

      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      await _initializeControllerFuture;

      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          _initializeControllerFuture = Future.error(e);
        });
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      final photo = await _cameraController!.takePicture();
      final documentSize = _getDocumentSize();

      final croppedFile = await _cropImage(File(photo.path), documentSize.width.toInt() , documentSize.height.toInt());

      if (croppedFile != null) {
        Navigator.pop(context, croppedFile);
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Size _getDocumentSize() {
    final size = MediaQuery.of(context).size;
    var overlayWidth = size.width * 0.8;
    var overlayHeight = overlayWidth * (11 / 8.5);

    if (overlayHeight > size.height * 0.8) {
      overlayHeight = size.height * 0.8;
      overlayWidth = overlayHeight * (8.5 / 11);
    }

    return  Size(overlayWidth, overlayHeight);
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

  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _cameraController != null &&
                  _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : _errorMessage('Could not initialize camera');
        } else if (snapshot.hasError) {
          return _errorMessage('Error loading camera');
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

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

  Widget _errorMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOverlay(
      {required double screenWidth, required double screenHeight}) {
      final documentSize = _getDocumentSize();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: CameraOverlayPainter(
              overlayWidth: documentSize.width, overlayHeight: documentSize.height),
        ),
      ),
    );
  }

  Future<File?> _cropImage(File imageFile, int width, int height) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    final x = (image.width - width) ~/ 2;
    final y = (image.height - height) ~/ 2;

    final cropped =
        img.copyCrop(image, x: x, y: y, width: width, height: height);
    final croppedBytes = Uint8List.fromList(img.encodePng(cropped));

    final tempDir = await getTemporaryDirectory();
    final outputFile = File(
        '${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');

    await outputFile.writeAsBytes(croppedBytes);
    return outputFile;
  }
}

class CameraOverlayPainter extends CustomPainter {
  final double overlayWidth;
  final double overlayHeight;

  CameraOverlayPainter(
      {required this.overlayWidth, required this.overlayHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final marginX = (size.width - overlayWidth) / 2;
    final marginY = (size.height - overlayHeight) / 2;
    const cornerSize = 30.0;

    _drawCorner(canvas, marginX, marginY, paint, cornerSize, isTopLeft: true);
    _drawCorner(canvas, marginX + overlayWidth, marginY, paint, cornerSize);
    _drawCorner(canvas, marginX, marginY + overlayHeight, paint, cornerSize,
        isBottom: true);
    _drawCorner(canvas, marginX + overlayWidth, marginY + overlayHeight, paint,
        cornerSize,
        isBottom: true);
  }

  void _drawCorner(Canvas canvas, double x, double y, Paint paint, double size,
      {bool isTopLeft = false, bool isBottom = false}) {
    canvas.drawLine(
        Offset(x, y), Offset(x + (isTopLeft ? size : -size), y), paint);
    canvas.drawLine(
        Offset(x, y), Offset(x, y + (isBottom ? -size : size)), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CaptureButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(255, 253, 253, 253),
                width: 3,
              ),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
