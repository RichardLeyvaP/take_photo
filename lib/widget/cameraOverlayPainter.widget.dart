
import 'package:flutter/material.dart';

class CameraOverlayPainter extends CustomPainter {
  final double overlayWidth;
  final double overlayHeight;

  CameraOverlayPainter({required this.overlayWidth, required this.overlayHeight});

  @override
  void paint(Canvas canvas, Size size) {
    void _drawCorner(Canvas canvas, double x, double y, Paint paint, double size,
        {bool isTopLeft = false, bool isBottom = false}) {
      canvas.drawLine(
          Offset(x, y), Offset(x + (isTopLeft ? size : -size), y), paint);
      canvas.drawLine(
          Offset(x, y), Offset(x, y + (isBottom ? -size : size)), paint);
    }

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Obtener las proporciones de la pantalla en relación al área de recorte
    final scaleX = size.width / 2550;
    final scaleY = size.height / 3300;
    final scaleFactor = scaleX < scaleY ? scaleX : scaleY; // Mantener relación

    final scaledWidth = 2550 * scaleFactor;
    final scaledHeight = 3300 * scaleFactor;

    final marginX = (size.width - scaledWidth) / 2;
    final marginY = (size.height - scaledHeight) / 2;
    const cornerSize = 30.0;

    // Pintar las franjas negras (arriba, abajo, izquierda, derecha)
    final blackPaint = Paint()..color = Colors.black;

    // Pintar franja negra en la parte superior (40px)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, marginY-2), blackPaint);

    // Pintar franja negra en la parte inferior (40px)
    canvas.drawRect(Rect.fromLTWH(0, size.height - marginY+2, size.width, marginY+2 ), blackPaint);

    // Pintar franja negra en la parte izquierda (20px)
    canvas.drawRect(Rect.fromLTWH(0, 0, (marginX-2), size.height), blackPaint);

    // Pintar franja negra en la parte derecha (20px)
    canvas.drawRect(Rect.fromLTWH(size.width - (marginX-2), 0, marginX-2, size.height), blackPaint);

    // Pintar el área transparente dentro del recuadro donde estará la cámara
    final transparentPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(
      Rect.fromLTWH(marginX, marginY, scaledWidth, scaledHeight),
      transparentPaint,
    );

    // Dibujar las esquinas del recuadro verde
    _drawCorner(canvas, marginX, marginY, paint, cornerSize, isTopLeft: true);
    _drawCorner(canvas, marginX + scaledWidth, marginY, paint, cornerSize);
    _drawCorner(canvas, marginX, marginY + scaledHeight, paint, cornerSize, isTopLeft: true, isBottom: true);
    _drawCorner(canvas, marginX + scaledWidth, marginY + scaledHeight, paint, cornerSize, isBottom: true);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
