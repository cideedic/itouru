import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 4,
      ), // Minimal bottom padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top divider line
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.black.withValues(alpha: 0.2),
            margin: const EdgeInsets.only(bottom: 12), // Reduced margin
          ),
          // Logo
          Image.asset(
            'assets/images/itouru_logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8), // Reduced spacing
          // Copyright text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.copyright, size: 12, color: Colors.black87),
              const SizedBox(width: 6),
              Text(
                'Right Reserve. Capstone Group',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
