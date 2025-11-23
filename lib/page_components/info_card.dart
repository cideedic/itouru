import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoCard extends StatelessWidget {
  final Map<String, dynamic>? headData;

  const InfoCard({super.key, required this.headData});

  String _buildFullName() {
    if (headData == null) return 'No information available';

    final prefix = headData!['prefix_name']?.toString() ?? '';
    final firstName = headData!['first_name']?.toString() ?? '';
    final lastName = headData!['last_name']?.toString() ?? '';
    final middleName = headData!['middle_name']?.toString() ?? '';
    final suffix = headData!['suffix_name']?.toString() ?? '';

    // Build name: Prefix FirstName LastName MiddleInitial. Suffix
    String fullName = '';

    if (prefix.isNotEmpty) fullName += '$prefix ';
    if (firstName.isNotEmpty) fullName += '$firstName ';
    if (lastName.isNotEmpty) fullName += '$lastName ';
    if (middleName.isNotEmpty) {
      fullName += '${middleName[0]}. ';
    }
    if (suffix.isNotEmpty) fullName += suffix;

    return fullName.trim();
  }

  Map<String, String> _extractSocials() {
    if (headData == null) return {};

    Map<String, String> socials = {};

    if (headData!['email'] != null &&
        headData!['email'].toString().isNotEmpty) {
      socials['email'] = headData!['email'].toString();
    }
    if (headData!['facebook'] != null &&
        headData!['facebook'].toString().isNotEmpty) {
      socials['facebook'] = headData!['facebook'].toString();
    }
    if (headData!['instagram'] != null &&
        headData!['instagram'].toString().isNotEmpty) {
      socials['instagram'] = headData!['instagram'].toString();
    }
    if (headData!['x'] != null && headData!['x'].toString().isNotEmpty) {
      socials['x'] = headData!['x'].toString();
    }

    return socials;
  }

  Future<void> _handleSocialTap(
    BuildContext context,
    String type,
    String value,
  ) async {
    if (type == 'email') {
      // Show email modal
      _showEmailModal(context, value);
    } else {
      // Show confirmation modal for external links
      _showLinkConfirmationModal(context, type, value);
    }
  }

  void _showEmailModal(BuildContext context, String email) {
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
                  color: Color(0xFFFA9D2B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_rounded,
                  size: 48,
                  color: Color(0xFFFA9D2B),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Send Your Concerns Here',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Email
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFA9D2B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close',
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
        ),
      ),
    );
  }

  void _showLinkConfirmationModal(
    BuildContext context,
    String type,
    String value,
  ) {
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
                  color: Color(0xFFFA9D2B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 48,
                  color: Color(0xFFFA9D2B),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Open External Link',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'You\'re about to visit ${_getDisplayName(type)}. Do you want to continue?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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
                        'Cancel',
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
                        await _launchUrl(context, type, value);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFA9D2B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
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

  String _getDisplayName(String type) {
    switch (type) {
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'x':
        return 'X (Twitter)';
      default:
        return 'this link';
    }
  }

  Future<void> _launchUrl(
    BuildContext context,
    String type,
    String value,
  ) async {
    try {
      Uri? uri;

      switch (type) {
        case 'facebook':
          if (value.startsWith('http')) {
            uri = Uri.parse(value);
          } else {
            uri = Uri.parse('https://www.facebook.com/$value');
          }
          break;
        case 'instagram':
          if (value.startsWith('http')) {
            uri = Uri.parse(value);
          } else {
            uri = Uri.parse('https://www.instagram.com/$value');
          }
          break;
        case 'x':
          if (value.startsWith('http')) {
            uri = Uri.parse(value);
          } else {
            uri = Uri.parse('https://www.x.com/$value');
          }
          break;
      }

      if (uri != null) {
        bool launched = false;

        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          // External application mode failed, try next mode
        }

        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (e) {
            // Platform default mode failed, try next mode
          }
        }

        if (!launched) {
          try {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
          } catch (e) {
            // External non-browser mode failed, show error below
          }
        }

        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot open $type link. Please install a browser app.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (headData == null) {
      return SizedBox.shrink();
    }

    final name = _buildFullName();
    final position = headData!['position']?.toString() ?? '';
    final socials = _extractSocials();

    final iconMap = {
      'email': Icons.email_rounded,
      'facebook': Icons.facebook_rounded,
      'instagram': Icons.camera_alt_rounded,
      'x': Icons.clear, // or use a custom X icon
    };

    final colorMap = {
      'email': Color(0xFFFA9D2B),
      'facebook': Color(0xFFFA9D2B),
      'instagram': Color(0xFFFA9D2B),
      'x': Color(0xFFFA9D2B),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          if (position.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              position,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
          ],
          if (socials.isNotEmpty) ...[
            Divider(),
            SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var entry in socials.entries)
                  if (iconMap.containsKey(entry.key))
                    InkWell(
                      onTap: () =>
                          _handleSocialTap(context, entry.key, entry.value),
                      borderRadius: BorderRadius.circular(8),
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
              ],
            ),
          ],
        ],
      ),
    );
  }
}
