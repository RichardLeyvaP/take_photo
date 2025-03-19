
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

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