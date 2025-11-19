import 'package:flutter/material.dart';
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

  // 🆕 Check internet connection before initializing Supabase
  final connectivityService = ConnectivityService();
  final hasInternet = await connectivityService.hasConnection();

  print('🌐 Initial internet check: $hasInternet'); // Debug

  if (!hasInternet) {
    // No internet - show error screen
    runApp(const NoInternetApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: 'https://mgkmorkhbabqeejotfxl.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1na21vcmtoYmFicWVlam90ZnhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1Mzg1NDcsImV4cCI6MjA3NjExNDU0N30.LDm9z2hTW9wL9SxBAOdMZU2JnYcN47G-n_7xhjTABcs',
    );

    runApp(const MyApp());
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    runApp(const NoInternetApp());
  }
}

// 🆕 No Internet App - shown when app starts without internet
class NoInternetApp extends StatelessWidget {
  const NoInternetApp({Key? key}) : super(key: key);

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
                    // Check connection and restart
                    final hasInternet = await ConnectivityService()
                        .hasConnection();
                    if (hasInternet) {
                      // Restart the app
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

  // 🆕 Connectivity monitoring
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _hasShownNoInternetDialog = false;

  @override
  void initState() {
    super.initState();
    print('🚀 App initializing...');
    _initConnectivityMonitoring(); // 🆕 Initialize connectivity first
    _checkSession();
    _initDeepLinks();
    _initAuthListener();
  }

  // 🆕 Initialize connectivity monitoring
  void _initConnectivityMonitoring() {
    print('📡 Setting up connectivity monitoring...');
    _connectivityService.initialize();
    _connectivityService.onConnectivityChanged = (isConnected) {
      print('📡 Connectivity changed: $isConnected');
      print('📡 Dialog shown before: $_hasShownNoInternetDialog');

      if (!isConnected && !_hasShownNoInternetDialog) {
        print('⚠️ No internet detected - showing dialog');
        _hasShownNoInternetDialog = true;

        // Use a slight delay to ensure context is ready
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_navigatorKey.currentContext != null) {
            print('✅ Showing no internet dialog');
            ConnectivityService.showNoInternetDialog(
              _navigatorKey.currentContext!,
              onRetry: () {
                print('🔄 Retry pressed');
                _hasShownNoInternetDialog = false;
              },
            );
          } else {
            print('❌ No context available for dialog');
          }
        });
      } else if (isConnected) {
        print('✅ Internet restored');
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
    // 🆕 Check internet before checking session
    final hasInternet = await _connectivityService.hasConnection();
    print('🔍 Session check - Has internet: $hasInternet');

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
        // Check if current session is anonymous
        final isAnonymous =
            session.user.isAnonymous ||
            session.user.appMetadata['provider'] == 'anonymous' ||
            session.user.email == null ||
            session.user.email!.isEmpty;

        if (isAnonymous) {
          // Guest user - go directly to Home
          setState(() {
            _initialPage = const Home();
            _isCheckingSession = false;
          });
        } else {
          // Check if email domain is @bicol-u.edu.ph
          if (!session.user.email!.endsWith('@bicol-u.edu.ph')) {
            await Supabase.instance.client.auth.signOut();
            setState(() {
              _initialPage = const LoginOptionPage();
              _isCheckingSession = false;
            });
            return;
          }

          // Non-anonymous user with valid domain - check if registered
          try {
            final existingUser = await Supabase.instance.client
                .from('Users')
                .select()
                .eq('email', session.user.email!)
                .maybeSingle();

            if (existingUser != null) {
              // User is registered - go to Home
              setState(() {
                _initialPage = const Home();
                _isCheckingSession = false;
              });
            } else {
              // User not registered - go to registration page
              setState(() {
                _initialPage = NewUserPanels(email: session.user.email!);
                _isCheckingSession = false;
              });
            }
          } catch (e) {
            // Error checking registration - sign out and go to login
            print('Error checking user registration: $e');
            await Supabase.instance.client.auth.signOut();
            setState(() {
              _initialPage = const LoginOptionPage();
              _isCheckingSession = false;
            });
          }
        }
      } else {
        // No session - go to login
        setState(() {
          _initialPage = const LoginOptionPage();
          _isCheckingSession = false;
        });
      }
    } catch (e) {
      // Any error during session check - go to login
      print('Error in _checkSession: $e');
      setState(() {
        _initialPage = const LoginOptionPage();
        _isCheckingSession = false;
      });
    }
  }

  void _initAuthListener() {
    // Listen to auth state changes globally
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final user = session.user;

        // Check if user is anonymous - check multiple ways
        final isAnonymous =
            user.isAnonymous ||
            user.appMetadata['provider'] == 'anonymous' ||
            user.email == null ||
            user.email!.isEmpty;

        if (isAnonymous) {
          // Allow guest users to stay logged in
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

        // Check if email domain is @bicol-u.edu.ph
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

        // For non-anonymous users with valid domain, check if registered
        try {
          final existingUser = await Supabase.instance.client
              .from('Users')
              .select()
              .eq('email', user.email!)
              .maybeSingle();

          if (existingUser == null) {
            // User not registered, navigate to registration page
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
            // User is registered, navigate to home
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
    } catch (e) {}

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {});
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.host == 'reset-password' ||
        uri.path.contains('reset-password') ||
        uri.fragment.contains('type=recovery')) {
      scheduleMicrotask(() {
        if (_navigatorKey.currentState != null) {
          _navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
          );
        }
      });
    } else if (uri.host == 'login-callback' ||
        uri.fragment.contains('access_token')) {
      // Parse the OAuth tokens from the deep link fragment
      if (uri.fragment.isNotEmpty) {
        try {
          // Supabase will automatically handle the OAuth callback
          // through the auth state listener
          // Add a timeout in case auth listener doesn't fire
          Future.delayed(Duration(seconds: 10), () {
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
          });
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

  @override
  void dispose() {
    print('🛑 App disposing...');
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    _connectivityService.dispose(); // 🆕 Dispose connectivity service
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
