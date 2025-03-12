import 'dart:io';
import 'package:flutter/material.dart';
import 'package:take_photo/widget/document_capture_screen.widget.dart';

class CameraService {
  static Future<File?> openCameraModal(BuildContext context) async {
    return await showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DocumentCaptureScreen(),
    );
  }
}
