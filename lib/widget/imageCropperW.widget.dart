
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:take_photo/ImageCropperWidgetRlp.dart';
import 'package:take_photo/widget/myPainter.widget.dart';

class ImageCropperW extends StatelessWidget {
  const ImageCropperW({
    super.key,
    required this.screenshotController,
    required this.transformationController,
    required double minScale,
    required double maxScale,
    required this.widget,
    required GlobalKey<State<StatefulWidget>> cropOverlayKey,
    required this.screenSize,
    required this.dpi,
  }) : _minScale = minScale, _maxScale = maxScale, _cropOverlayKey = cropOverlayKey;

  final ScreenshotController screenshotController;
  final TransformationController transformationController;
  final double _minScale;
  final double _maxScale;
  final ImageCropperWidget widget;
  final GlobalKey<State<StatefulWidget>> _cropOverlayKey;
  final Size screenSize;
  final double dpi;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
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
    );
  }
}
