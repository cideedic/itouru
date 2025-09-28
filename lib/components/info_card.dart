import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoCard extends StatelessWidget {
  final String name;
  final String title;
  final Map<String, String> socials; // key: type, value: url or email

  const InfoCard({
    super.key,
    required this.name,
    required this.title,
    required this.socials,
  });

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      'email': Icons.email_rounded,
      'facebook': Icons.facebook_rounded,
      'instagram': Icons.camera_alt_rounded,
      'x': Icons.clear, // Replace with a suitable X icon if available
    };

    final colorMap = {
      'email': Colors.orange,
      'facebook': Colors.orange,
      'instagram': Colors.orange,
      'x': Colors.orange,
    };

    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var entry in socials.entries)
                if (iconMap.containsKey(entry.key))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InkWell(
                      onTap: () {
                        // Handle tap for each social here
                        // For email, use mailto:; for others, launch URL
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorMap[entry.key]!.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          iconMap[entry.key],
                          color: colorMap[entry.key],
                          size: 28,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
