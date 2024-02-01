import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:ui' as ui;

class EyeShadowPainter extends CustomPainter {
  final ui.Image image;
  final Face face;

  EyeShadowPainter(this.image, this.face);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green;

    final leftEyePosition = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEyePosition =
        face.landmarks[FaceLandmarkType.rightEye]?.position;

    if (leftEyePosition != null && rightEyePosition != null) {
      final ovalSize = rightEyePosition.distanceTo(leftEyePosition) * 1.5;

      canvas.drawImage(image, Offset.zero, Paint());

      // Draw oval for left eye
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            leftEyePosition.x.toDouble(),
            leftEyePosition.y.toDouble(),
          ),
          width: ovalSize,
          height: ovalSize,
        ),
        paint,
      );

      // Draw oval for right eye
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            rightEyePosition.x.toDouble(),
            rightEyePosition.y.toDouble(),
          ),
          width: ovalSize,
          height: ovalSize,
        ),
        paint,
      );
    } else {
      print("Couldn't find both eyes! paintign");
      Fluttertoast.showToast(
        msg: "Couldn't find both eyes!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
    }
  }

  @override
  bool shouldRepaint(EyeShadowPainter oldDelegate) {
    return image != oldDelegate.image || face != oldDelegate.face;
  }
}