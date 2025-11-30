import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuestAccessModal extends StatelessWidget {
  const GuestAccessModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and Title
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: Image.asset(
                          'assets/images/i_logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Guest Access',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Welcome to iTOURu!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Purpose Section
                    _buildSectionTitle('Purpose'),
                    _buildInfoText(
                      'This application is designed solely for navigation and providing general public information about Bicol University campus.',
                    ),
                    const SizedBox(height: 16),

                    // Guest Limitations
                    _buildSectionTitle('Guest Mode Limitations'),
                    _buildBulletPoint('Cannot submit feedback or reports'),
                    _buildBulletPoint(
                      'Session expires after 24 hours or when app closes',
                    ),
                    const SizedBox(height: 16),

                    // Guidelines
                    _buildSectionTitle('Guidelines'),
                    _buildBulletPoint(
                      'Use the app responsibly for navigation purposes',
                    ),
                    _buildBulletPoint(
                      'Information provided is for general guidance only',
                    ),
                    _buildBulletPoint(
                      'Always verify critical information with official sources',
                    ),
                    _buildBulletPoint('Respect campus rules and regulations'),
                    const SizedBox(height: 16),

                    // Data Notice
                    _buildSectionTitle('Data & Privacy'),
                    _buildInfoText(
                      'As a guest, minimal data is collected. Your session is temporary and not linked to any personal information.',
                    ),
                    const SizedBox(height: 16),

                    // Recommendation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'For full access and personalized features, sign in with your Bicol University account.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Accept Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'I Understand',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Color(0xFFFF8C00),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
