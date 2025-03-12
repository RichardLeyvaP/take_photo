
import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CaptureButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo externo (Borde separado)
          Container(
            width: 85, // Tamaño del borde externo
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(255, 253, 253, 253), // Color del borde
                width: 3, // Grosor del borde
              ),
            ),
          ),
          // Círculo interno (Botón de captura)
          Container(
            width: 70, // Tamaño del botón central
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // Color de relleno
            ),
          ),
        ],
      ),
    );
  }
}
