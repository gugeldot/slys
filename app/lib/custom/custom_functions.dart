import 'package:flutter/material.dart';



class TrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.15, 0);             // Punto superior izquierdo
    path.lineTo(size.width * 0.85, 0);             // Punto superior derecho
    path.lineTo(size.width, size.height);          // Punto inferior derecho
    path.lineTo(0, size.height);                   // Punto inferior izquierdo
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
