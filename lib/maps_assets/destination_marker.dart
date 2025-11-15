import 'package:flutter/material.dart';

/// Animated pulsing marker for virtual tour destinations
/// Shows the stop number with a pulsing orange circle effect
class PulsingDestinationMarker extends StatefulWidget {
  final int stopNumber;
  final Color color;
  final Color borderColor;
  final double size;

  const PulsingDestinationMarker({
    super.key,
    required this.stopNumber,
    this.color = const Color(0xFFFF8C00), // Orange
    this.borderColor = Colors.white,
    this.size = 50.0,
  });

  @override
  State<PulsingDestinationMarker> createState() =>
      _PulsingDestinationMarkerState();
}

class _PulsingDestinationMarkerState extends State<PulsingDestinationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: widget.borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  spreadRadius: 3,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${widget.stopNumber}',
                style: TextStyle(
                  color: widget.borderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size * 0.32, // Proportional font size
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
