import 'package:flutter/material.dart';
import 'package:itouru/login_components/login_option.dart';
import 'package:itouru/login_components/reset_password.dart';
import 'package:itouru/main_pages/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dlzlnebdpxrmqnelrbfm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsemxuZWJkcHhybXFuZWxyYmZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMTExNDksImV4cCI6MjA3MzU4NzE0OX0.GUUpkHK5pGBxPgUNdU3OlzKXmpIoskxEofFG7jUYSuw',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isCheckingSession = true;
  Widget _initialPage = const LoginOptionPage();

  @override
  void initState() {
    super.initState();
    _checkSession();
    _initDeepLinks();
  }

  Future<void> _checkSession() async {
    try {
      // Check if there's an active session
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // User is logged in, go to home
        setState(() {
          _initialPage = const Home();
          _isCheckingSession = false;
        });
      } else {
        // No session, go to login
        setState(() {
          _initialPage = const LoginOptionPage();
          _isCheckingSession = false;
        });
      }
    } catch (e) {
      print('Error checking session: $e');
      setState(() {
        _initialPage = const LoginOptionPage();
        _isCheckingSession = false;
      });
    }
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Error listening to link stream: $err');
      },
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    print('Deep link received: $uri');

    if (uri.host == 'reset-password' ||
        uri.path.contains('reset-password') ||
        uri.fragment.contains('type=recovery')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
        );
      });
    } else if (uri.host == 'login-callback' ||
        uri.fragment.contains('access_token')) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        final user = session?.user;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginOptionPage()),
            );

            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Authentication failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return;
        }

        // Check if user exists in your allowed users table
        final existingUser = await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', user.email!)
            .maybeSingle();

        if (existingUser == null) {
          await Supabase.instance.client.auth.signOut();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginOptionPage()),
            );

            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text(
                  'This account is not authorized. Please contact an administrator.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) => const Home()),
            );
          });
        }
      } catch (e) {
        print('Error checking user: $e');
        await Supabase.instance.client.auth.signOut();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginOptionPage()),
          );

          ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('An error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.orange)),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: _initialPage,
      debugShowCheckedModeBanner: false,
    );
  }
}
