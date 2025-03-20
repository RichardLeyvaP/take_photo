import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:take_photo/widget/showImageModal.widget.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;

  const ImageCropperWidget({Key? key, required this.imageFile})
      : super(key: key);

  @override
  _ImageCropperWidgetState createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  final ScreenshotController screenshotController = ScreenshotController();
  final GlobalKey _cropOverlayKey = GlobalKey();
  final TransformationController transformationController =
      TransformationController();
  final double _minScale = 1.0;
  final double _maxScale = 4.0;

  @override
  void initState() {
    super.initState();
    transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    transformationController.removeListener(_onTransformationChanged);
    super.dispose();
  }
  void _onTransformationChanged() {
  final Matrix4 matrix = transformationController.value;
  final double offsetX = matrix.getTranslation().x;
  final double offsetY = matrix.getTranslation().y;

  

  final Matrix4 newMatrix = Matrix4.identity()
  ..setFrom(matrix)
  ..setTranslationRaw(offsetX, offsetY, 0);

transformationController.value = newMatrix;
}


  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double dpi = MediaQuery.of(context).devicePixelRatio;

    return  Scaffold(
      appBar: AppBar(
        title: Text('Recortar Imagen'),
        actions: [
          IconButton(
            icon: Icon(Icons.crop),
            onPressed: () async {
              File? croppedFile =
                  await captureAndSaveImage(screenshotController,Size(screenSize.width, screenSize.height));
              if (croppedFile != null) {
                Navigator.pop(context, croppedFile);
                showImageModal(context, croppedFile);
              }
            },
          ),
        ],
      ),
      body:  SizedBox.expand(
      child: Stack(
        children: [
          Screenshot(
            controller: screenshotController,
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              boundaryMargin: EdgeInsets.all(double.infinity),
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: _cropOverlayKey,
                size: screenSize,
                painter: MyPainter(screenSize: screenSize, dpi: dpi),
              ),
            ),
          ),
        ],
      ),
    ),
    );
    
    
    
   
    
  }
}
Future<File?> captureAndSaveImage(ScreenshotController screenshotController,Size screenSize) async {
  try {
    final Uint8List? image = await screenshotController.capture();

    if (image != null) {
      final img.Image originalImage = img.decodeImage(image)!;

      // Obtener el tamaño de la imagen capturada
      final int imageWidth = originalImage.width;
      final int imageHeight = originalImage.height;

      // Dimensiones del rectángulo verde (ajustadas a la imagen capturada)
      final double scaleX = imageWidth / screenSize.width;
      final double scaleY = imageHeight / screenSize.height;
      final double scale = scaleX < scaleY ? scaleX : scaleY;

      final double scaledWidth = 8.5 * 96 * scale;
      final double scaledHeight = 11 * 96 * scale;

      final int cropWidth = scaledWidth.toInt();
      final int cropHeight = scaledHeight.toInt();

      // Posición del recorte (centrado en la imagen capturada)
      final int offsetX = ((imageWidth - cropWidth) / 2).toInt();
      final int offsetY = ((imageHeight - cropHeight) / 2).toInt();

      // Recortar la imagen
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: offsetX,
        y: offsetY,
        width: cropWidth,
        height: cropHeight,
      );

      // Guardar la imagen recortada
      final Uint8List croppedBytes = Uint8List.fromList(img.encodePng(croppedImage));
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(croppedBytes);

      return file;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}


 /*Future<File?> captureAndSaveImage(ScreenshotController screenshotController) async {
    try {
      // Capturar toda la pantalla
      final Uint8List? image = await screenshotController.capture();

      if (image != null) {
        final img.Image originalImage = img.decodeImage(image)!;
       
        final Uint8List croppedBytes = Uint8List.fromList(img.encodePng(originalImage));
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(croppedBytes);

        return file;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  } */
  
class MyPainter extends CustomPainter {
  final Size screenSize; // Tamaño de la pantalla del teléfono
  final double dpi; // Densidad de píxeles del dispositivo

  MyPainter({required this.screenSize, required this.dpi});

  @override
  void paint(Canvas canvas, Size size) {
    // Convertir pulgadas a píxeles
    const double inchesToPixels = 96; // 96 DPI (estándar para impresión)
    const double widthInPixels = 8.5 * inchesToPixels; // Ancho en píxeles (8.5 pulgadas)
    const double heightInPixels = 11 * inchesToPixels; // Alto en píxeles (11 pulgadas)

    // Calcular la escala para ajustar el rectángulo al tamaño de la pantalla
    final double scaleX = screenSize.width / widthInPixels;
    final double scaleY = screenSize.height / heightInPixels;
    final double scale = scaleX < scaleY ? scaleX : scaleY; // Usar la escala más pequeña

    // Dimensiones escaladas del rectángulo
    final double scaledWidth = widthInPixels * scale;
    final double scaledHeight = heightInPixels * scale;

    // Calcular la posición para centrar el rectángulo en la pantalla
    final double offsetX = (screenSize.width - scaledWidth) / 2;
    final double offsetY = ((screenSize.height - 98) - scaledHeight) / 2;
// Pintar las franjas negras (arriba, abajo, izquierda, derecha)
    final blackPaint = Paint()..color = const ui.Color.fromARGB(150, 0, 0, 0);

    // Pintar franja negra en la parte superior (40px)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, offsetY-2), blackPaint);

    // Pintar franja negra en la parte inferior (40px)
    canvas.drawRect(Rect.fromLTWH(0,  scaledHeight+offsetY+2, size.width, offsetY+2 ), blackPaint);

    // Pintar franja negra en la parte izquierda (20px)
    canvas.drawRect(Rect.fromLTWH(0, 0, (offsetX-2), size.height), blackPaint);

    // Pintar franja negra en la parte derecha (20px)
    canvas.drawRect(Rect.fromLTWH(size.width - (offsetX-2), 0, offsetX-2, size.height), blackPaint);
    // Configurar el Paint
    final Paint paint = Paint()
            ..color = const ui.Color.fromARGB(255, 15, 143, 54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Dibujar el rectángulo centrado y escalado
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight),//offsetY = 120
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}