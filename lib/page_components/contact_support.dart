import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final double? iconSize;
  final EdgeInsets? padding;

  const ContactSupportCard({
    super.key,
    this.title,
    this.subtitle,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF8C00).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: iconSize ?? 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title ?? 'Need Help?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle ??
                'Our support team is here to assist you with any account or privacy concerns',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _showContactDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFFFF8C00),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_rounded,
                  size: 48,
                  color: Color(0xFFFF8C00),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Contact Support',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                'Send us an email at:',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              // Email Address
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  'jcml2022-2902-58530@bicol-u.edu.ph',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF8C00),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _launchSupportEmail(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF8C00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'Send Email',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchSupportEmail(BuildContext context) async {
    const email = 'jcml2022-2902-58530@bicol-u.edu.ph';

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=iTOURu Support Request&body=Hello Support Team,%0A%0A',
      );

      bool launched = false;
      String? lastError;

      // Try different launch modes
      try {
        launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        lastError = e.toString();
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            emailUri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            emailUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (e) {
          lastError = e.toString();
        }
      }

      // If all attempts failed, show error
      if (!launched && context.mounted) {
        _showErrorSnackBar(
          context,
          'Cannot open email app',
          lastError?.contains('ACTIVITY_NOT_FOUND') == true ||
                  lastError?.contains('No Activity found') == true
              ? 'Please install an email app (Gmail, Outlook, etc.) to send emails.'
              : 'Unable to open email app. Please try again later.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Error',
          'Failed to open email app: ${e.toString()}',
        );
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
