import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:google_ml_kit/google_ml_kit.dart';

class MousePainter extends CustomPainter {
 final ui.Image image;
 final Face face;

 MousePainter(this.image, this.face);

 @override
 void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green;

    final mousePosition = face.landmarks[FaceLandmarkType.leftMouth]?.position;

    if (mousePosition != null) {
      final ovalSize = mousePosition.distanceTo(mousePosition) * 1.5;

      canvas.drawImage(image, Offset.zero, Paint());

      // Draw oval for mouse
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            mousePosition.x.toDouble(),
            mousePosition.y.toDouble(),
          ),
          width: ovalSize,
          height: ovalSize,
        ),
        paint,
      );
    } else {
      print("Couldn't find mouse! painting");
    }
 }

 @override
 bool shouldRepaint(MousePainter oldDelegate) {
    return image != oldDelegate.image || face != oldDelegate.face;
 }
}
