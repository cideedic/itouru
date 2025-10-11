import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/login_components/login_option.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/settings_pages/privacy.dart';
import 'package:itouru/login_components/guest_restriction_modal.dart';
import 'package:itouru/settings_pages/support.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  bool _isGuestUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return true;
    return user.isAnonymous ||
        user.appMetadata['provider'] == 'anonymous' ||
        user.email == null ||
        user.email!.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Use the reusable header
          ReusableHeader(),

          // Main content for Settings page
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    AnimatedSettingItem(
                      icon: Icons.security,
                      iconColor: Colors.orange[400]!,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your privacy settings',
                      onTap: () {
                        // Check if user is a guest
                        if (_isGuestUser()) {
                          // Show restriction modal for guest users
                          showDialog(
                            context: context,
                            builder: (context) => const GuestRestrictionModal(
                              feature: 'Privacy & Security',
                            ),
                          );
                        } else {
                          // Allow access for registered users
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivacyPage(),
                            ),
                          );
                        }
                      },
                    ),
                    AnimatedSettingItem(
                      icon: Icons.help_outline,
                      iconColor: Colors.orange[400]!,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportPage(),
                          ),
                        );
                      },
                    ),
                    AnimatedSettingItem(
                      icon: Icons.info_outline,
                      iconColor: Colors.orange[400]!,
                      title: 'About iTOURu',
                      subtitle:
                          'Know more about the application and its creators',
                      onTap: () {
                        // Handle about section
                      },
                    ),
                    AnimatedSettingItem(
                      icon: Icons.logout,
                      iconColor: Colors.orange[400]!,
                      title: 'Log Out',
                      subtitle: 'Exit Application',
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      size: 48,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Title
                                  Text(
                                    'Log Out',
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
                                    'Are you sure you want to log out?',
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
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
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
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'Log Out',
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
                        if (shouldLogout == true) {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginOptionPage(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 4),
    );
  }
}

// Animated Setting Item Widget
class AnimatedSettingItem extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AnimatedSettingItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<AnimatedSettingItem> createState() => _AnimatedSettingItemState();
}

class _AnimatedSettingItemState extends State<AnimatedSettingItem> {
  bool _hovered = false;
  bool _pressed = false;

  Color get _backgroundColor {
    if (_pressed) return Colors.orange.withValues(alpha: 0.18);
    if (_hovered) return Colors.orange.withValues(alpha: 0.12);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400), // Smooth transition
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
