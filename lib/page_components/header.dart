import 'package:flutter/material.dart';
import 'package:itouru/main_pages/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/login_components/guest_restriction_modal.dart';
import 'package:itouru/main_pages/qr_scan.dart';

class ReusableHeader extends StatefulWidget {
  final String? pageTitle;
  final bool showBackButton;

  const ReusableHeader({
    super.key,
    this.pageTitle,
    this.showBackButton = false,
  });

  @override
  ReusableHeaderState createState() => ReusableHeaderState();
}

class ReusableHeaderState extends State<ReusableHeader> {
  String _displayName = 'Hi Student!';
  bool _isLoading = true;
  String? _userAvatar;

  // Avatar bucket and default avatar - same as ProfilePage
  static const String avatarBucket = 'avatars';
  static const String defaultAvatar = 'avatar_1.webp';

  String _getAvatarUrl(String filename) {
    return Supabase.instance.client.storage
        .from(avatarBucket)
        .getPublicUrl(filename);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  bool _isGuestUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return true;
    return user.isAnonymous ||
        user.appMetadata['provider'] == 'anonymous' ||
        user.email == null ||
        user.email!.isEmpty;
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        setState(() {
          _displayName = 'Hi Guest!';
          _userAvatar = null;
          _isLoading = false;
        });
        return;
      }

      // Check if user is a guest
      if (_isGuestUser()) {
        setState(() {
          _displayName = 'Hi Guest!';
          _userAvatar = null;
          _isLoading = false;
        });
        return;
      }

      // Check if email exists
      if (user.email == null || user.email!.isEmpty) {
        setState(() {
          _displayName = 'Hi Student!';
          _userAvatar = null;
          _isLoading = false;
        });
        return;
      }

      // Fetch first_name and avatar from database using email
      final response = await Supabase.instance.client
          .from('Users')
          .select('first_name, avatar')
          .eq('email', user.email!)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _displayName = response['first_name'] != null
              ? 'Hi ${response['first_name']}!'
              : 'Hi Student!';
          _userAvatar = response['avatar']?.toString() ?? defaultAvatar;
          _isLoading = false;
        });
      } else {
        setState(() {
          _displayName = 'Hi Student!';
          _userAvatar = defaultAvatar;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _displayName = 'Hi Student!';
        _userAvatar = defaultAvatar;
        _isLoading = false;
      });
    }
  }

  void _handleProfileTap() {
    if (widget.showBackButton) {
      Navigator.pop(context);
      return;
    }

    // Check if user is a guest
    if (_isGuestUser()) {
      showDialog(
        context: context,
        builder: (context) => const GuestRestrictionModal(feature: 'Profile'),
      );
      return;
    }

    // If not a guest, navigate to profile
    final user = Supabase.instance.client.auth.currentUser;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(email: user?.email ?? ""),
      ),
    ).then((_) {
      // Refresh avatar when returning from profile
      _fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.0,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 117, 135, 248),
            Color(0xFF1A31C8),
            Color(0xFF060870),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _handleProfileTap,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        backgroundImage:
                            !widget.showBackButton &&
                                _userAvatar != null &&
                                !_isLoading
                            ? NetworkImage(_getAvatarUrl(_userAvatar!))
                            : null,
                        child: widget.showBackButton || _isLoading
                            ? Icon(
                                widget.showBackButton
                                    ? Icons.arrow_back
                                    : Icons.person,
                                color: Colors.white,
                                size: 28,
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isLoading
                          ? SizedBox(
                              width: 100,
                              height: 18,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            )
                          : Text(
                              widget.pageTitle ?? _displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  // Navigate to QR scanner (available for all users including guests)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRScannerPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
