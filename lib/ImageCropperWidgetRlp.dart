import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:screenshot/screenshot.dart';
import 'package:take_photo/image.service.dart';
import 'package:take_photo/widget/ImageCropperW.widget.dart';
import 'package:take_photo/widget/showImageModal.widget.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

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
  ImageService imageService = ImageService();
  final double _minScale = 1.0;
  final double _maxScale = 4.0;
  final double _cropWidth = 8.5 * 96;
  final double _cropHeight = 11 * 96;

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
      transformationController.value = newMatrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double dpi = MediaQuery.of(context).devicePixelRatio;

    return Scaffold(
      appBar: AppBar(
        title: Text('Recortar Imagen RLP'),
        actions: [
          IconButton(
            icon: Icon(Icons.crop),
            onPressed: () async {
              File? croppedFile =
                  await imageService.captureAndSaveImage(screenshotController);
              if (croppedFile != null) {
                showImageModal(context, croppedFile);
              }
            },
          ),
        ],
      ),
      body: ImageCropperW(
          screenshotController: screenshotController,
          transformationController: transformationController,
          minScale: _minScale,
          maxScale: _maxScale,
          widget: widget,
          cropOverlayKey: _cropOverlayKey,
          screenSize: screenSize,
          dpi: dpi),
    );
  }
}
