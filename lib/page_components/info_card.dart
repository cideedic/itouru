import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoCard extends StatelessWidget {
  final Map<String, dynamic>? headData;
  final String? headImageUrl;

  const InfoCard({super.key, required this.headData, this.headImageUrl});

  String _buildFullName() {
    if (headData == null) return 'No information available';

    final prefix = headData!['prefix_name']?.toString() ?? '';
    final firstName = headData!['first_name']?.toString() ?? '';
    final lastName = headData!['last_name']?.toString() ?? '';
    final middleName = headData!['middle_name']?.toString() ?? '';
    final suffix = headData!['suffix_name']?.toString() ?? '';

    String fullName = '';

    if (prefix.isNotEmpty) fullName += '$prefix ';
    if (firstName.isNotEmpty) fullName += '$firstName ';
    if (middleName.isNotEmpty) {
      fullName += '${middleName[0]}. ';
    }
    if (lastName.isNotEmpty) fullName += '$lastName ';
    if (suffix.isNotEmpty) fullName += suffix;

    return fullName.trim();
  }

  List<String> _extractEmails() {
    if (headData == null || headData!['email'] == null) return [];

    try {
      final emailString = headData!['email'].toString();

      // Split by newline, comma, or semicolon
      final emails = emailString
          .split(RegExp(r'[\n,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.contains('@'))
          .toList();

      return emails;
    } catch (e) {
      return [];
    }
  }

  Map<String, String> _extractSocials() {
    if (headData == null) return {};

    Map<String, String> socials = {};

    try {
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
    } catch (e) {
      return {};
    }

    return socials;
  }

  Future<void> _handleSocialTap(
    BuildContext context,
    String type,
    String value,
  ) async {
    if (type == 'email') {
      final emails = _extractEmails();
      if (emails.isEmpty) {
        _showErrorSnackBar(
          context,
          'No emails available',
          'No contact email addresses found for this person.',
        );
        return;
      }

      // If only one email, show confirmation modal directly
      if (emails.length == 1) {
        _showEmailConfirmationModal(context, emails[0]);
      } else {
        // If multiple emails, show selection modal first
        _showEmailSelectionModal(context, emails);
      }
    } else {
      _showLinkConfirmationModal(context, type, value);
    }
  }

  void _showEmailSelectionModal(BuildContext context, List<String> emails) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
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
                'Select Email Address',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Email List
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < emails.length; i++) ...[
                        _buildEmailSelectionItem(context, emails[i], i),
                        if (i < emails.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  ),
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

  Widget _buildEmailSelectionItem(
    BuildContext context,
    String email,
    int index,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close selection modal
        _showEmailConfirmationModal(context, email); // Show confirmation
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_extractEmails().length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Email ${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFA9D2B),
                        ),
                      ),
                    ),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showEmailConfirmationModal(BuildContext context, String email) {
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
                'Send Email',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'You\'re about to send an email to\n'),
                    TextSpan(
                      text: email,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFA9D2B),
                      ),
                    ),
                    TextSpan(text: '\n\nDo you want to continue?'),
                  ],
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
                        await _launchEmail(context, email);
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

  Future<void> _launchEmail(BuildContext context, String email) async {
    try {
      // Create mailto URL with optional subject and body
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Inquiry&body=Hello,',
      );

      bool launched = false;
      String? lastError;

      // Try to launch the email URL with different modes
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
        if (lastError != null && lastError.contains('ACTIVITY_NOT_FOUND')) {
          _showErrorSnackBar(
            context,
            'No email app available',
            'Please install an email app (Gmail, Outlook, etc.) to send emails.',
          );
        } else if (lastError != null &&
            lastError.contains('No Activity found')) {
          _showErrorSnackBar(
            context,
            'Cannot open email',
            'No compatible app found to handle email links.',
          );
        } else {
          _showErrorSnackBar(
            context,
            'Cannot open email',
            'Unable to open email app. Please try again later.',
          );
        }
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Invalid email',
          'The email format is invalid: ${e.message}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Unexpected error',
          'Failed to open email app: ${e.toString()}',
        );
      }
    }
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

      // Parse the URL
      try {
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
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(
            context,
            'Invalid URL format',
            'The ${_getDisplayName(type)} link is not properly formatted.',
          );
        }
        return;
      }

      if (uri == null) {
        if (context.mounted) {
          _showErrorSnackBar(
            context,
            'No URL available',
            'Unable to generate link for ${_getDisplayName(type)}.',
          );
        }
        return;
      }

      // Try to launch the URL with different modes
      bool launched = false;
      String? lastError;

      // Try external application mode first
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        lastError = e.toString();
      }

      // Try platform default mode
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          lastError = e.toString();
        }
      }

      // Try external non-browser mode
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (e) {
          lastError = e.toString();
        }
      }

      // If all attempts failed, show error
      if (!launched && context.mounted) {
        if (lastError != null && lastError.contains('ACTIVITY_NOT_FOUND')) {
          _showErrorSnackBar(
            context,
            'No app available',
            'Please install a browser or ${_getDisplayName(type)} app to open this link.',
          );
        } else if (lastError != null &&
            lastError.contains('No Activity found')) {
          _showErrorSnackBar(
            context,
            'Cannot open link',
            'No compatible app found to handle ${_getDisplayName(type)} links.',
          );
        } else {
          _showErrorSnackBar(
            context,
            'Cannot open link',
            'Unable to open ${_getDisplayName(type)}. Please try again later.',
          );
        }
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Invalid URL',
          'The link format is invalid: ${e.message}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Unexpected error',
          'Failed to open link: ${e.toString()}',
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

  @override
  Widget build(BuildContext context) {
    if (headData == null) {
      return SizedBox.shrink();
    }

    final name = _buildFullName();
    final position = headData!['position']?.toString() ?? '';
    final emails = _extractEmails();
    final socials = _extractSocials();

    final iconMap = {
      'email': Icons.email_rounded,
      'facebook': Icons.facebook_rounded,
      'instagram': Icons.camera_alt_rounded,
      'x': Icons.clear,
    };

    final colorMap = {
      'email': Color(0xFFFA9D2B),
      'facebook': Color(0xFFFA9D2B),
      'instagram': Color(0xFFFA9D2B),
      'x': Color(0xFFFA9D2B),
    };

    // Combine emails and socials for display
    final hasEmailOrSocials = emails.isNotEmpty || socials.isNotEmpty;

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
          // Head Image (if available)
          if (headImageUrl != null) ...[
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  headImageUrl!,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFA9D2B),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
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
          if (hasEmailOrSocials) ...[
            Divider(),
            SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                // Email icon (if emails exist)
                if (emails.isNotEmpty)
                  InkWell(
                    onTap: () => _handleSocialTap(context, 'email', ''),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorMap['email']!.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Badge(
                        label: emails.length > 1
                            ? Text(
                                '${emails.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                        backgroundColor: Colors.red,
                        isLabelVisible: emails.length > 1,
                        child: Icon(
                          iconMap['email'],
                          color: colorMap['email'],
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                // Other social icons
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
