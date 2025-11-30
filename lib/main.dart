import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/login_components/login_option.dart';
import 'package:itouru/login_components/reset_password.dart';
import 'package:itouru/login_components/new_registration.dart';
import 'package:itouru/main_pages/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:itouru/page_components/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final connectivityService = ConnectivityService();
  final hasInternet = await connectivityService.hasConnection();

  if (!hasInternet) {
    runApp(const NoInternetApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: 'https://mgkmorkhbabqeejotfxl.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1na21vcmtoYmFicWVlam90ZnhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1Mzg1NDcsImV4cCI6MjA3NjExNDU0N30.LDm9z2hTW9wL9SxBAOdMZU2JnYcN47G-n_7xhjTABcs',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit, // Changed from PKCE to implicit
        autoRefreshToken: true,
      ),
    );

    runApp(const MyApp());
  } catch (e) {
    runApp(const NoInternetApp());
  }
}

class NoInternetApp extends StatelessWidget {
  const NoInternetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off,
                    size: 60,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please check your internet connection and restart the app.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    final hasInternet = await ConnectivityService()
                        .hasConnection();
                    if (hasInternet) {
                      main();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  StreamSubscription<AuthState>? _authSubscription;
  bool _isCheckingSession = true;
  Widget _initialPage = const LoginOptionPage();

  final ConnectivityService _connectivityService = ConnectivityService();
  bool _hasShownNoInternetDialog = false;

  @override
  void initState() {
    super.initState();
    _initConnectivityMonitoring();
    _checkSession();
    _initDeepLinks();
    _initAuthListener();
  }

  void _initConnectivityMonitoring() {
    _connectivityService.initialize();
    bool isFirstConnectivityCheck = true;

    _connectivityService.onConnectivityChanged = (isConnected) {
      if (isFirstConnectivityCheck) {
        isFirstConnectivityCheck = false;
        return;
      }

      if (!isConnected && !_hasShownNoInternetDialog) {
        _hasShownNoInternetDialog = true;

        Future.delayed(const Duration(milliseconds: 300), () {
          if (_navigatorKey.currentContext != null) {
            ConnectivityService.showNoInternetDialog(
              _navigatorKey.currentContext!,
              onRetry: () {
                _hasShownNoInternetDialog = false;
              },
            );
          }
        });
      } else if (isConnected && _hasShownNoInternetDialog) {
        // Only show if dialog was shown before
        _hasShownNoInternetDialog = false;

        Future.delayed(const Duration(milliseconds: 300), () {
          if (_navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Back online!'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    };
  }

  Future<void> _checkSession() async {
    final hasInternet = await _connectivityService.hasConnection();

    if (!hasInternet) {
      setState(() {
        _initialPage = const LoginOptionPage();
        _isCheckingSession = false;
      });
      return;
    }

    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        final isAnonymous =
            session.user.isAnonymous ||
            session.user.appMetadata['provider'] == 'anonymous' ||
            session.user.email == null ||
            session.user.email!.isEmpty;

        if (isAnonymous) {
          setState(() {
            _initialPage = const Home();
            _isCheckingSession = false;
          });
        } else {
          if (!session.user.email!.endsWith('@bicol-u.edu.ph')) {
            await Supabase.instance.client.auth.signOut();
            setState(() {
              _initialPage = const LoginOptionPage();
              _isCheckingSession = false;
            });
            return;
          }

          try {
            final existingUser = await Supabase.instance.client
                .from('Users')
                .select()
                .eq('email', session.user.email!)
                .maybeSingle();

            if (existingUser != null) {
              // User is registered, go to Home
              setState(() {
                _initialPage = const Home();
                _isCheckingSession = false;
              });
            } else {
              // User NOT registered - sign them out and go to login
              await Supabase.instance.client.auth.signOut();
              setState(() {
                _initialPage = const LoginOptionPage();
                _isCheckingSession = false;
              });
            }
          } catch (e) {
            await Supabase.instance.client.auth.signOut();
            setState(() {
              _initialPage = const LoginOptionPage();
              _isCheckingSession = false;
            });
          }
        }
      } else {
        setState(() {
          _initialPage = const LoginOptionPage();
          _isCheckingSession = false;
        });
      }
    } catch (e) {
      setState(() {
        _initialPage = const LoginOptionPage();
        _isCheckingSession = false;
      });
    }
  }

  void _initAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;

      // Handle password recovery event
      if (event == AuthChangeEvent.passwordRecovery) {
        await Future.delayed(const Duration(milliseconds: 500));

        scheduleMicrotask(() {
          if (_navigatorKey.currentState != null) {
            _navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const ResetPasswordPage(),
              ),
            );
          }
        });
        return;
      }

      if (event == AuthChangeEvent.signedIn && session != null) {
        final user = session.user;

        final isAnonymous =
            user.isAnonymous ||
            user.appMetadata['provider'] == 'anonymous' ||
            user.email == null ||
            user.email!.isEmpty;

        if (isAnonymous) {
          scheduleMicrotask(() {
            if (_navigatorKey.currentState != null) {
              _navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Home()),
                (route) => false,
              );
            }
          });
          return;
        }

        if (!user.email!.endsWith('@bicol-u.edu.ph')) {
          await Supabase.instance.client.auth.signOut();

          scheduleMicrotask(() {
            if (_navigatorKey.currentState != null) {
              _navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginOptionPage(),
                ),
                (route) => false,
              );

              ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Only @bicol-u.edu.ph email addresses are allowed.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          });
          return;
        }

        try {
          final existingUser = await Supabase.instance.client
              .from('Users')
              .select()
              .eq('email', user.email!)
              .maybeSingle();

          if (existingUser == null) {
            scheduleMicrotask(() {
              if (_navigatorKey.currentState != null) {
                _navigatorKey.currentState!.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => NewUserPanels(email: user.email!),
                  ),
                  (route) => false,
                );
              }
            });
          } else {
            scheduleMicrotask(() {
              if (_navigatorKey.currentState != null) {
                _navigatorKey.currentState!.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Home()),
                  (route) => false,
                );
              }
            });
          }
        } catch (e) {
          await Supabase.instance.client.auth.signOut();

          scheduleMicrotask(() {
            if (_navigatorKey.currentState != null) {
              _navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginOptionPage(),
                ),
                (route) => false,
              );

              ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                const SnackBar(
                  content: Text('An error occurred. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        }
      }
    });
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      // Handle initial link error if necessary
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {});
  }

  Future<void> _handleDeepLink(Uri uri) async {
    // Password reset links
    if (uri.host == 'reset-password' ||
        uri.path.contains('reset-password') ||
        uri.fragment.contains('type=recovery')) {
      // Check for errors in the URL
      if (uri.queryParameters.containsKey('error') ||
          uri.fragment.contains('error=')) {
        final errorCode =
            uri.queryParameters['error_code'] ??
            Uri.splitQueryString(uri.fragment)['error_code'] ??
            '';
        final errorDesc =
            uri.queryParameters['error_description'] ??
            Uri.splitQueryString(uri.fragment)['error_description'] ??
            'Link is invalid or expired';

        scheduleMicrotask(() {
          if (_navigatorKey.currentContext != null) {
            _showPasswordResetErrorDialog(
              _navigatorKey.currentContext!,
              errorCode,
              errorDesc,
            );
          }
        });
        return;
      }

      // Wait for auth event
      bool passwordRecoveryFired = false;

      final tempSub = Supabase.instance.client.auth.onAuthStateChange.listen((
        data,
      ) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          passwordRecoveryFired = true;
        }
      });

      // Wait up to 5 seconds
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (passwordRecoveryFired) break;
      }

      tempSub.cancel();

      if (passwordRecoveryFired) {
      } else {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          scheduleMicrotask(() {
            if (_navigatorKey.currentState != null) {
              _navigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (context) => const ResetPasswordPage(),
                ),
              );
            }
          });
        } else {
          scheduleMicrotask(() {
            if (_navigatorKey.currentContext != null) {
              _showPasswordResetErrorDialog(
                _navigatorKey.currentContext!,
                'expired',
                'The password reset link has expired or has already been used.',
              );
            }
          });
        }
      }
    }
    // OAuth callback links
    else if (uri.host == 'login-callback' ||
        uri.fragment.contains('access_token')) {
      if (uri.fragment.isNotEmpty) {
        try {
          await Future.delayed(const Duration(seconds: 10));
          final session = Supabase.instance.client.auth.currentSession;

          if (session == null) {
            scheduleMicrotask(() {
              if (_navigatorKey.currentContext != null) {
                ScaffoldMessenger.of(
                  _navigatorKey.currentContext!,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Authentication timed out. Please try again.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            });
          }
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                const SnackBar(
                  content: Text('Authentication failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        }
      }
    }
  }

  void _showPasswordResetErrorDialog(
    BuildContext context,
    String errorCode,
    String errorDescription,
  ) {
    String title = 'Link Expired';
    String message = errorDescription.replaceAll('+', ' ');
    IconData icon = Icons.access_time_filled;
    Color iconColor = Colors.orange;

    // Customize message based on error code
    if (errorCode.contains('expired') || errorDescription.contains('expired')) {
      title = 'Link Expired';
      message =
          'This password reset link has expired. Password reset links expire after 1 hour.\n\nPlease request a new link.';
      icon = Icons.access_time_filled;
      iconColor = Colors.orange;
    } else if (errorCode.contains('code') ||
        errorDescription.contains('code')) {
      title = 'Link Already Used';
      message =
          'This password reset link has already been used. For security reasons, each link can only be used once.\n\nPlease request a new password reset link.';
      icon = Icons.lock_clock;
      iconColor = Colors.orange;
    } else {
      title = 'Invalid Link';
      message =
          'This password reset link is invalid or cannot be processed.\n\n$message';
      icon = Icons.error_outline;
      iconColor = Colors.red;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    _connectivityService.dispose();
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
