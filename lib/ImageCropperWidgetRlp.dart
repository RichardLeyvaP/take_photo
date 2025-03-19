import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math_64.dart' as vector_math;

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;

  const ImageCropperWidget({Key? key, required this.imageFile}) : super(key: key);

  @override
  _ImageCropperWidgetState createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  final TransformationController _transformationController = TransformationController();
  final double _minScale = 1.0;
  final double _maxScale = 4.0;
  final double _cropWidth = 8.5 * 96;
  final double _cropHeight = 11 * 96;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    super.dispose();
  }

  void _onTransformationChanged() {
    final Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    final double offsetX = matrix.getTranslation().x;
    final double offsetY = matrix.getTranslation().y;
    final double maxOffsetX = (_cropWidth * scale - _cropWidth) / 2;
    final double maxOffsetY = (_cropHeight * scale - _cropHeight) / 2;
    final double safeMaxOffsetX = maxOffsetX.clamp(0, double.infinity);
    final double safeMaxOffsetY = maxOffsetY.clamp(0, double.infinity);

    if (offsetX.abs() > safeMaxOffsetX || offsetY.abs() > safeMaxOffsetY) {
      final Matrix4 newMatrix = matrix.clone();
      newMatrix.setTranslation(vector_math.Vector3(
        offsetX.clamp(-safeMaxOffsetX, safeMaxOffsetX),
        offsetY.clamp(-safeMaxOffsetY, safeMaxOffsetY),
        0,
      ));
      _transformationController.value = newMatrix;
    }
  }

//  Future<File> cropImage() async {
//   final image = img.decodeImage(await widget.imageFile.readAsBytes())!;
//   final originalWidth = image.width.toDouble();
//   final originalHeight = image.height.toDouble();

//   final Matrix4 matrix = _transformationController.value;
//   final double scale = matrix.getMaxScaleOnAxis();
//   final double offsetX = matrix.getTranslation().x;
//   final double offsetY = matrix.getTranslation().y;

//   // Asegurarse de que el área de recorte no exceda las dimensiones de la imagen
//   final double maxCropX = (originalWidth - _cropWidth).clamp(0, originalWidth);
//   final double maxCropY = (originalHeight - _cropHeight).clamp(0, originalHeight);

//   // Calcular las coordenadas de recorte en la imagen original
//   final double cropX = (-offsetX / scale).clamp(0, maxCropX);
//   final double cropY = (-offsetY / scale).clamp(0, maxCropY);

//   // Recortar la imagen
//   img.Image croppedImage = img.copyCrop(
//     image,
//     x: cropX.toInt(),
//     y: cropY.toInt(),
//     width: _cropWidth.toInt(),
//     height: _cropHeight.toInt(),
//   );

//   // Guardar la imagen recortada en un archivo temporal
//   File croppedFile = File('${Directory.systemTemp.path}/cropped_image.png');
//   croppedFile.writeAsBytesSync(img.encodePng(croppedImage));
//   return croppedFile;
// }
Future<File> cropImage() async {
  // Cargar la imagen original
  final image = img.decodeImage(await widget.imageFile.readAsBytes())!;
  final originalWidth = image.width.toDouble();
  final originalHeight = image.height.toDouble();

  // Definir las coordenadas de recorte fijas
  final double cropX = 1; // Empezar desde el borde izquierdo
  final double cropY = 1; // Empezar 20 píxeles desde la parte superior
  final double cropWidth = originalWidth - 1; // Mitad del ancho de la imagen
  final double cropHeight = originalHeight - 1 - 1; // Altura restante (20px arriba y 50px abajo)

  // Recortar la imagen
  img.Image croppedImage = img.copyCrop(
    image,
    x: cropX.toInt(),
    y: cropY.toInt(),
    width: cropWidth.toInt(),
    height: cropHeight.toInt(),
  );

  // Guardar la imagen recortada en un archivo temporal
  File croppedFile = File('${Directory.systemTemp.path}/cropped_image.png');
  croppedFile.writeAsBytesSync(img.encodePng(croppedImage));

  return croppedFile;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recortar Imagen RLP'),
        actions: [
          IconButton(
            icon: Icon(Icons.crop),
            onPressed: () async {
              File croppedFile = await cropImage();
              _showImageModal(context, croppedFile);
            },
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
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
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CropOverlayPainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showImageModal(BuildContext context, File imageFile) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                imageFile,
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Photo taken", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Save image"),
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

class _CropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const ui.Color.fromARGB(255, 15, 143, 54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double width = size.width;
    final double height = size.height;
    const double margin = 20.0;

    canvas.drawRect(
      Rect.fromLTWH(margin, margin, width - margin * 2, height - margin * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}