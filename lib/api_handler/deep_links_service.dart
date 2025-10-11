import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:itouru/login_components/reset_password.dart';

class DeepLinkService {
  static AppLinks? _appLinks;
  static StreamSubscription<Uri>? _sub;

  static Future<void> initialize(BuildContext context) async {
    _appLinks = AppLinks();

    // Handle initial link when app is opened from link
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri, context);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Handle links while app is running
    _sub = _appLinks!.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri, context);
    }, onError: (err) {});
  }

  static void _handleDeepLink(Uri uri, BuildContext context) {
    // Check if it's a password reset link
    // Supabase sends links with #access_token or type=recovery in the fragment
    if (uri.host == 'reset-password' ||
        uri.path.contains('reset-password') ||
        uri.fragment.contains('access_token=') ||
        uri.fragment.contains('type=recovery')) {
      // Navigate to reset password page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
      );
    }
  }

  static void dispose() {
    _sub?.cancel();
  }
}
