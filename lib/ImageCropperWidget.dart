import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:take_photo/image.service.dart';

class ImageCropperWidgetROYBER extends StatefulWidget {
  final File imageFile;

  const ImageCropperWidgetROYBER({Key? key, required this.imageFile}) : super(key: key);

  @override
  _ImageCropperWidgetROYBERState createState() => _ImageCropperWidgetROYBERState();
}

class _ImageCropperWidgetROYBERState extends State<ImageCropperWidgetROYBER> {
  ImageService imageService = ImageService();
  late double top, left, width, height;
  img.Image? originalImage;
  Uint8List? croppedImageBytes;
  GlobalKey imageKey = GlobalKey();
  TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  bool _isLoading = true; // Indicador de carga

Offset _currentTranslation = Offset(0, 0); // Para la traslación de la imagen

  @override
  void initState() {
    super.initState();
    top = 50;
    left = 50;
  }

  @override
  void didChangeDependencies() {
      super.didChangeDependencies();
  _transformationController.addListener(() {
    setState(() {
      _currentScale = _transformationController.value.getMaxScaleOnAxis();
      _currentTranslation = Offset(
        _transformationController.value.getTranslation().x,
        _transformationController.value.getTranslation().y,
      );
    });
  });

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double aspectRatio = 595 / 842;

    
    width = screenWidth * 0.8; 
    height = width / aspectRatio; 

    if (height > screenHeight * 0.8) {
      height = screenHeight * 0.8; // 80% de la altura de la pantalla
      width = height * aspectRatio; // Recalcular el ancho en base a la nueva altura
    }

    _loadImage();
  }
void onDragUpdate(DragUpdateDetails details) {
  double dx = details.localPosition.dx; // Coordenada x del drag
  double dy = details.localPosition.dy; // Coordenada y del drag

  // Ajustar las coordenadas según el zoom
  double adjustedDx = dx / _currentScale - _currentTranslation.dx;
  double adjustedDy = dy / _currentScale - _currentTranslation.dy;

  setState(() {
    // Actualizamos la posición del cuadro de corte según las coordenadas ajustadas
    left = adjustedDx;
    top = adjustedDy;
  });

  // Mostrar las coordenadas ajustadas en el log
  print('Adjusted coordinates: ($adjustedDx, $adjustedDy)');
}


  Future<void> _loadImage() async {
  final bytes = await widget.imageFile.readAsBytes();
  final decodedImage = await compute(_decodeAndResizeImage, bytes);

  setState(() {
    originalImage = decodedImage;
    _isLoading = false;
  });
}

 

  // Método para decodificar y redimensionar la imagen.
static img.Image _decodeAndResizeImage(Uint8List bytes) {
  img.Image image = img.decodeImage(bytes)!;

  // Redimensionar solo si es necesario
  if (image.width > 1000 || image.height > 1000) {
    image = img.copyResize(image, width: 1000);
  }

  return image;
}

Future<void> cropImage() async {
  // Calculamos el recorte de la imagen en función de las coordenadas ajustadas
  final int cropWidth = (width * _currentScale).toInt();
  final int cropHeight = (height * _currentScale).toInt();
  
  // Calcular el área a cortar (cuidado con los límites de la imagen)
  final double cropLeft = left * _currentScale;
  final double cropTop = top * _currentScale;

  // Asegurarse de que el recorte no se salga de los límites de la imagen
  final double cropRight = cropLeft + cropWidth;
  final double cropBottom = cropTop + cropHeight;

  // Asegurarse de que las coordenadas no se salgan de los límites de la imagen
  final int safeLeft = cropLeft < 0 ? 0 : cropLeft.toInt();
  final int safeTop = cropTop < 0 ? 0 : cropTop.toInt();

  // Ajustar el tamaño del recorte para que no se salga de los límites de la imagen
  final int safeWidth = cropRight > originalImage!.width
      ? originalImage!.width - safeLeft
      : cropWidth;
  final int safeHeight = cropBottom > originalImage!.height
      ? originalImage!.height - safeTop
      : cropHeight;

  // Aquí utilizamos un paquete como `image` para recortar la imagen
  img.Image? croppedImage = img.copyCrop(
    originalImage!,
    x: safeLeft,
    y: safeTop,
    width: safeWidth,
    height: safeHeight,
  );

  // Si no se recorta correctamente, revisa la escala o las coordenadas de entrada
  if (croppedImage == null) {
    print("Error al recortar la imagen. Asegúrate de que las coordenadas sean correctas.");
    return;
  }

  // Convertir la imagen recortada a un archivo
  File croppedImageFile = await imageService.convertToFile(croppedImage);
  
  // Mostrar la imagen recortada
  _showImageModal(context, croppedImageFile);

  // Ahora puedes mostrar el recorte o hacer lo que desees con la imagen recortada
}




  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recortar Imagen')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Muestra un indicador mientras carga
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          onInteractionUpdate: (ScaleUpdateDetails details) {
                            setState(() {
                              _currentScale = details.scale.clamp(1.0, 4.0);
                            });
                          },
                          child: Image.file(
                            widget.imageFile,
                            key: imageKey,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: top,
                        left: left,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            print('details: ${details}, dx: ${details.delta.dx}, dy: ${details.delta.dy}');
                            setState(() {
                              left += details.delta.dx;
                              top += details.delta.dy;
                            });
                          },
                          child: Container(
                            width: width,
                            height: height,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 2),
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: cropImage,
                  child: Text('Recortar'),
                ),
                if (croppedImageBytes != null)
                  Image.memory(croppedImageBytes!, height: 200),
              ],
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