import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:take_photo/old/CameraWidget.dart';
import 'package:take_photo/widget/cameraOverlayPainter.widget.dart';
import 'package:take_photo/widget/cropImage.service.dart';


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
      setState(() {});
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
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      final photo = await _cameraController!.takePicture();




      /**VER DIMENSIONES D EL AIMAGEN YA RECORTADA */
    

final croppedFile = await cropImage(File(photo.path));

// Obtener las dimensiones de la imagen
final image = File(croppedFile!.path);
final imageSize = await image.length(); // Esto devuelve el tamaño en bytes de la imagen

print("Tamaño de la imagen: $imageSize bytes");

// Si necesitas las dimensiones (alto y ancho de la imagen):


final imageBytes = await image.readAsBytes();
final decodedImage = img.decodeImage(imageBytes);

if (decodedImage != null) {
  print("Ancho: ${decodedImage.width}");
  print("Alto: ${decodedImage.height}");

  // Verificar si el tamaño se acerca a 8.5 x 11 pulgadas
  const double cartaWidthPx = 2550; // 8.5 pulgadas en píxeles (aproximado)
  const double cartaHeightPx = 3300; // 11 pulgadas en píxeles (aproximado)

  if (decodedImage.width == cartaWidthPx && decodedImage.height == cartaHeightPx) {
    print("La imagen tiene el tamaño de Carta.Ancho: ${decodedImage.width}-Alto: ${decodedImage.height}");
  } else {
    print("La imagen no tiene el tamaño de Carta.Ancho: ${decodedImage.width}-Alto: ${decodedImage.height}");
  }
} else {
  print("La imagen No se pudo decodificar la imagen.");
}


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
    return Size(overlayWidth, overlayHeight);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
      Widget _buildTopBar() {
    return Positioned(
      top: 10,
        left: 0, // Asegura que el widget inicie desde la izquierda
    right: 0, // Asegura que el widget termine en la derecha
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          
          Row(
            children: [
              const Icon(Icons.crop_free_outlined, color: Color.fromARGB(171, 255, 255, 255), size: 30),
              Text('Auto Capture On', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        
           IconButton(
            icon: const Icon(Icons.flash_auto_outlined, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

    Widget _buildCaptureButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.photo_library, color: Colors.white, size: 30),
          ElevatedButton(
            onPressed: _takePicture,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
            ),
            child: Container(
            width: 34.0,
            height: 34.0,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          )
          
          ),
          Container(),
        ],
      ),
    );
  }

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
    
    Widget _errorMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _cameraController != null && _cameraController!.value.isInitialized
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

  Widget _buildOverlay({required double screenWidth, required double screenHeight}) {
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








}

