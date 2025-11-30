import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Cone-shaped field of view marker showing user's direction
class ConeMarkerWidget extends StatelessWidget {
  final double heading; // User's compass heading (0-360°)
  final double coneAngle; // Width of cone in degrees (default: 45°)
  final double coneLength; // Length of cone in pixels (default: 50)
  final Color coneColor;
  final Color circleColor;

  const ConeMarkerWidget({
    super.key,
    required this.heading,
    this.coneAngle = 45.0,
    this.coneLength = 50.0,
    this.coneColor = const Color(0x4D2196F3),
    this.circleColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: coneLength * 2,
      height: coneLength * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cone (field of view)
          CustomPaint(
            size: Size(coneLength * 2, coneLength * 2),
            painter: ConePainter(
              heading: heading,
              coneAngle: coneAngle,
              coneLength: coneLength,
              coneColor: coneColor,
            ),
          ),

          // User position circle
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 6,
                ),
              ],
            ),
          ),

          // Direction indicator dot
          Positioned(
            top: (coneLength * 2) / 2 - coneLength * 0.5,
            left: (coneLength * 2) / 2 - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConePainter extends CustomPainter {
  final double heading;
  final double coneAngle;
  final double coneLength;
  final Color coneColor;

  ConePainter({
    required this.heading,
    required this.coneAngle,
    required this.coneLength,
    required this.coneColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final headingRad = (heading - 90) * math.pi / 180;

    // Calculate cone edges
    final halfConeAngle = (coneAngle / 2) * math.pi / 180;
    final leftAngle = headingRad - halfConeAngle;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        coneColor.withValues(alpha: coneColor.a * 1.0),
        coneColor.withValues(alpha: coneColor.a * 0.6), //
        coneColor.withValues(alpha: coneColor.a * 0.2),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    // Create cone path
    final path = Path();
    path.moveTo(center.dx, center.dy);

    // Left edge of cone
    path.lineTo(
      center.dx + coneLength * math.cos(leftAngle),
      center.dy + coneLength * math.sin(leftAngle),
    );

    final arcRect = Rect.fromCircle(center: center, radius: coneLength);
    path.arcTo(arcRect, leftAngle, halfConeAngle * 2, false);

    path.lineTo(center.dx, center.dy);
    path.close();

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: coneLength),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = coneColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(ConePainter oldDelegate) {
    return heading != oldDelegate.heading ||
        coneAngle != oldDelegate.coneAngle ||
        coneLength != oldDelegate.coneLength ||
        coneColor != oldDelegate.coneColor;
  }
}
