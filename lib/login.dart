import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_email');
    final rememberFlag = prefs.getBool('remember_me') ?? false;
    setState(() {
      _rememberMe = rememberFlag;
      if (rememberFlag && rememberedEmail != null) {
        _emailController.text = rememberedEmail;
      }
    });
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guest_mode', false);
      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
      } else {
        await prefs.remove('remembered_email');
      }

      if (mounted) {
        // AuthGate will rebuild via auth subscription, but we can also navigate.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Enter a valid email to reset password.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showSnackBar('Password reset email sent. Check your inbox.');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    }
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Home()),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1133A1);
    final Color secondaryBlue = const Color(0xFF3B6BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top gradient header with logo and welcome text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [secondaryBlue, primaryBlue],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Image.asset('assets/images/itouru_logo.png',
                              fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'iTOURu',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start your tour today!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Card with form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 6),
                        _DecoratedTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'you@example.com',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text('Password',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 6),
                        _DecoratedTextField(
                          controller: _passwordController,
                          hintText: 'Your password',
                          obscureText: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Minimum 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _isSubmitting ? null : _onForgotPassword,
                              child: Text(
                                'Forgot Password',
                                style: GoogleFonts.poppins(
                                  color: secondaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Remember me',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) {
                                    setState(() => _rememberMe = v ?? false);
                                  },
                                  activeColor: Colors.orange,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                )
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 6),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onLoginPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: _isSubmitting ? null : _continueAsGuest,
                            child: Text(
                              'No Account? Continue as Guest',
                              style: GoogleFonts.poppins(
                                color: secondaryBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                '© Right Reserve. Capstone Group',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecoratedTextField extends StatelessWidget {
  const _DecoratedTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCECF7)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

