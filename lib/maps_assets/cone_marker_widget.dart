// lib/maps_assets/cone_marker_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Cone-shaped field of view marker showing user's direction
class ConeMarkerWidget extends StatelessWidget {
  final double heading; // User's compass heading (0-360°)
  final double coneAngle; // Width of cone in degrees (default: 60°)
  final double coneLength; // Length of cone in pixels
  final Color coneColor;
  final Color circleColor;
  final bool showPulse; // Optional pulsing animation

  const ConeMarkerWidget({
    super.key,
    required this.heading,
    this.coneAngle = 60.0,
    this.coneLength = 80.0,
    this.coneColor = const Color(0x4D2196F3), // Semi-transparent blue
    this.circleColor = Colors.blue,
    this.showPulse = false,
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

          // Optional: Direction indicator dot
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

/// Custom painter for the cone shape
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
    final paint = Paint()
      ..color = coneColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Convert heading to radians (0° = North, clockwise)
    // Adjust for Flutter's coordinate system (0° = East, counterclockwise)
    final headingRad = (heading - 90) * math.pi / 180;

    // Calculate cone edges
    final halfConeAngle = (coneAngle / 2) * math.pi / 180;
    final leftAngle = headingRad - halfConeAngle;
    final rightAngle = headingRad + halfConeAngle;

    // Create cone path
    final path = Path();
    path.moveTo(center.dx, center.dy); // Start at center

    // Left edge of cone
    path.lineTo(
      center.dx + coneLength * math.cos(leftAngle),
      center.dy + coneLength * math.sin(leftAngle),
    );

    // Arc at the end of cone (rounded edge)
    final arcRect = Rect.fromCircle(center: center, radius: coneLength);
    path.arcTo(arcRect, leftAngle, halfConeAngle * 2, false);

    // Right edge of cone (back to center)
    path.lineTo(center.dx, center.dy);
    path.close();

    canvas.drawPath(path, paint);

    // Optional: Draw border for better visibility
    final borderPaint = Paint()
      ..color = coneColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

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

/// Pulsing cone marker (animated version)
class PulsingConeMarker extends StatefulWidget {
  final double heading;
  final double coneAngle;
  final double coneLength;
  final Color coneColor;
  final Color circleColor;

  const PulsingConeMarker({
    super.key,
    required this.heading,
    this.coneAngle = 60.0,
    this.coneLength = 80.0,
    this.coneColor = const Color(0x4D2196F3),
    this.circleColor = Colors.blue,
  });

  @override
  State<PulsingConeMarker> createState() => _PulsingConeMarkerState();
}

class _PulsingConeMarkerState extends State<PulsingConeMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ConeMarkerWidget(
            heading: widget.heading,
            coneAngle: widget.coneAngle,
            coneLength: widget.coneLength,
            coneColor: widget.coneColor.withValues(
              alpha: widget.coneColor.opacity * _scaleAnimation.value * 0.9,
            ),
            circleColor: widget.circleColor,
          ),
        );
      },
    );
  }
}
