import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color? primaryColor;
  final Color? backgroundColor;
  final LoadingStyle style;

  const LoadingWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.primaryColor,
    this.backgroundColor,
    this.style = LoadingStyle.circular,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF1A31C8);
    final backgroundColor = widget.backgroundColor ?? const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildLoadingIndicator(primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              widget.subtitle ?? 'Please wait',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color primaryColor) {
    switch (widget.style) {
      case LoadingStyle.circular:
        return _buildCircularLoading(primaryColor);
      case LoadingStyle.dots:
        return _buildDotsLoading(primaryColor);
    }
  }

  Widget _buildCircularLoading(Color primaryColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      ),
    );
  }

  Widget _buildDotsLoading(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_controller.value - delay).clamp(0.0, 1.0);
              final scale = 1.0 + (0.5 * (1 - (value - 0.5).abs() * 2));

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

enum LoadingStyle {
  circular, // Default spinning circle
  dots, // Three animated dots
}

// Convenience builder for full-screen loading
class LoadingScreen {
  static Widget circular({
    required String title,
    String? subtitle,
    Color? primaryColor,
    Color? backgroundColor,
  }) {
    return LoadingWidget(
      title: title,
      subtitle: subtitle,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      style: LoadingStyle.circular,
    );
  }

  static Widget dots({
    required String title,
    String? subtitle,
    Color? primaryColor,
    Color? backgroundColor,
  }) {
    return LoadingWidget(
      title: title,
      subtitle: subtitle,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      style: LoadingStyle.dots,
    );
  }
}
