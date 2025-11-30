import 'package:flutter/material.dart';
import 'package:itouru/login_components/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/main_pages/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/login_components/terms_and_privacy.dart';

class LoginOptionPage extends StatefulWidget {
  const LoginOptionPage({super.key});

  @override
  State<LoginOptionPage> createState() => _LoginOptionPageState();
}

class _LoginOptionPageState extends State<LoginOptionPage> {
  bool _isGuestLoading = false;

  Future<void> _handleUniversityLogin() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isGuestLoading = true);

    try {
      await Supabase.instance.client.auth.signInAnonymously();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Guest login failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGuestLoading = false);
      }
    }
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => const TermsOfServiceModal(),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 203, 210, 255),
                        Color(0xFF1A31C8),
                        Color(0xFF060870),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                ),
              ),
              Expanded(child: Container(color: const Color(0xFFF5F5F5))),
            ],
          ),

          // Content
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 40),

                              // Logo
                              Container(
                                width: 35,
                                height: 35,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/i_logo.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 35),

                              // Title
                              Text(
                                'Choose Login\nMethod',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Login Card
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Continue as',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // University Account Button
                                    OutlinedButton(
                                      onPressed: _handleUniversityLogin,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF2196F3,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF2196F3),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                      ),
                                      child: const Text(
                                        'Bicol University Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    Row(
                                      children: const [
                                        Expanded(
                                          child: Divider(color: Colors.grey),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            'or',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(color: Colors.grey),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Guest Button
                                    ElevatedButton(
                                      onPressed: _isGuestLoading
                                          ? null
                                          : _handleGuestLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFFA726,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          56,
                                        ),
                                      ),
                                      child: _isGuestLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Guest',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Terms and Privacy
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        const Text(
                                          'By continuing you accept our ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _showTerms,
                                          child: const Text(
                                            'Terms of Service',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2196F3),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          ' and ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _showPrivacy,
                                          child: const Text(
                                            'Privacy Concerns',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2196F3),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Footer at bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: const Text(
                        '© Right Reserve. Capstone Group',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
