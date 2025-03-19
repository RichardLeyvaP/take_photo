
import 'dart:io';

import 'package:flutter/material.dart';

void showImageModal(BuildContext context, File imageFile) {
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
              const Padding(
                padding: EdgeInsets.all(8.0),
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
