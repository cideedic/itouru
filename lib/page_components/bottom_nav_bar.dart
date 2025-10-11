import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/main_pages/feedback.dart';
import 'package:itouru/main_pages/settings.dart';
import 'package:itouru/main_pages/maps.dart';
import 'package:itouru/main_pages/categories.dart';
import 'package:itouru/main_pages/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/login_components/guest_restriction_modal.dart';

class ReusableBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const ReusableBottomNavBar({super.key, this.currentIndex = 0, this.onTap});

  bool _isGuestUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return true;
    return user.isAnonymous ||
        user.appMetadata['provider'] == 'anonymous' ||
        user.email == null ||
        user.email!.isEmpty;
  }

  void _onItemTapped(BuildContext context, int index) {
    // Call the provided onTap function if available
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Check if trying to access Feedback (index 3) as guest
    if (index == 3 && _isGuestUser()) {
      showDialog(
        context: context,
        builder: (context) => const GuestRestrictionModal(feature: 'Feedback'),
      );
      return;
    }

    // Default navigation behavior
    switch (index) {
      case 0: // Home
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
        break;
      case 1: // Categories
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Categories()),
        );
        break;
      case 2: // Navigation/Map
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Maps()),
        );
        break;
      case 3: // Feedback
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Feedbacks()),
        );
        break;
      case 4: // Settings
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Settings()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(context, index),
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1A31C8),
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A31C8),
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
            fontSize: 11,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.home_outlined,
                  size: 24,
                  shadows: currentIndex == 0
                      ? [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)]
                      : null,
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.home,
                  size: 24,
                  shadows: [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)],
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.grid_view_outlined,
                  size: 24,
                  shadows: currentIndex == 1
                      ? [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)]
                      : null,
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.grid_view,
                  size: 24,
                  shadows: [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)],
                ),
              ),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.navigation_outlined,
                  size: 24,
                  shadows: currentIndex == 2
                      ? [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)]
                      : null,
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.navigation,
                  size: 24,
                  shadows: [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)],
                ),
              ),
              label: 'Navigation',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.feedback_outlined,
                  size: 24,
                  shadows: currentIndex == 3
                      ? [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)]
                      : null,
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.feedback,
                  size: 24,
                  shadows: [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)],
                ),
              ),
              label: 'Feedback',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.settings_outlined,
                  size: 24,
                  shadows: currentIndex == 4
                      ? [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)]
                      : null,
                ),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.settings,
                  size: 24,
                  shadows: [Shadow(color: Color(0xFF87CEEB), blurRadius: 8)],
                ),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
