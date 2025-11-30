import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/main_pages/home.dart';
import 'package:itouru/login_components/terms_and_privacy.dart';
import 'dart:async';
import 'package:itouru/login_components/login_option.dart';
import 'package:itouru/login_components/login.dart';

class NewUserPanels extends StatefulWidget {
  final String email;

  const NewUserPanels({super.key, required this.email});

  @override
  State<NewUserPanels> createState() => _NewUserPanelsState();
}

class _NewUserPanelsState extends State<NewUserPanels>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final _scrollController = ScrollController();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  String? _selectedUserType;
  String? _selectedCollegeAbbreviation;
  String? _selectedNationality;
  String? _selectedSex;
  DateTime? _selectedBirthday;
  bool _isSubmitting = false;
  bool _isLoadingColleges = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _hasReadTerms = false;
  bool _hasReadPrivacy = false;
  bool _registrationComplete = false;

  StreamSubscription<AuthState>? _authSubscription;

  final List<String> _userTypes = ['Student', 'Faculty', 'Staff'];

  List<Map<String, dynamic>> _colleges = [];
  Map<String, String> _collegeAbbreviationToName = {};

  final List<String> _nationalities = ['Filipino', 'Other'];
  final List<String> _sexOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadColleges();
    _passwordController.addListener(_validatePassword);

    // Listen to auth state changes
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      // If user logs out or session expires, redirect to login options
      if (event == AuthChangeEvent.signedOut || data.session == null) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginOptionPage()),
            (route) => false,
          );
        }
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasDigit &&
      _hasSpecialChar;

  Future<void> _loadColleges() async {
    try {
      final response = await supabase
          .from('College')
          .select('college_abbreviation, college_name')
          .order('college_abbreviation');

      if (mounted) {
        setState(() {
          _colleges = List<Map<String, dynamic>>.from(response);
          _collegeAbbreviationToName = {
            for (var college in _colleges)
              '${college['college_name']} (${college['college_abbreviation']})':
                  college['college_name'] as String,
          };
          _isLoadingColleges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingColleges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load colleges',
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _pageController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!_registrationComplete) {
        supabase.auth.signOut();
      }
    }
  }

  String _getDefaultAvatar(String? sex) {
    if (sex == 'Male') {
      return 'avatar_1.png';
    } else if (sex == 'Female') {
      return 'avatar_3.png';
    }
    return 'avatar_1.png';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFFF8C00),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Check password validity
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please meet all password requirements',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Passwords do not match',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Check if terms and privacy are accepted
    if (!_acceptedTerms || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please accept Terms of Service and Privacy Policy',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get the current authenticated user
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Update the password in Supabase Auth
      final authResponse = await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (authResponse.user == null) {
        throw Exception('Failed to set password');
      }

      final response = await supabase
          .from('Users')
          .select('user_id')
          .order('user_id', ascending: false)
          .limit(1);

      int nextUserId = 1;

      if (response.isNotEmpty) {
        final maxId = response.first['user_id'] as int;
        nextUserId = maxId + 1;
      }

      final collegeFullName = _selectedCollegeAbbreviation != null
          ? _collegeAbbreviationToName[_selectedCollegeAbbreviation]
          : null;

      final insertData = {
        'user_id': nextUserId,
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'suffix': _suffixController.text.trim().isEmpty
            ? null
            : _suffixController.text.trim(),
        'email': widget.email,
        'user_type': _selectedUserType,
        'college': collegeFullName,
        'birthday': _selectedBirthday?.toIso8601String().split('T')[0],
        'nationality': _selectedNationality,
        'sex': _selectedSex,
        'phone_number': _phoneController.text.trim(),
        'avatar': _getDefaultAvatar(_selectedSex),
      };

      await supabase.from('Users').insert(insertData);
      _registrationComplete = true;

      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e.toString().contains('duplicate') ||
          e.toString().contains('unique')) {
        errorMessage = 'An account with this email already exists.';
      } else {
        errorMessage = 'Registration failed: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.montserrat(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showTerms() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TermsOfServiceModal(),
    );

    if (result == true && mounted) {
      setState(() {
        _hasReadTerms = true;
        _acceptedTerms = true;
      });
    }
  }

  void _showPrivacy() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PrivacyPolicyModal(),
    );

    if (result == true && mounted) {
      setState(() {
        _hasReadPrivacy = true;
        _acceptedPrivacy = true;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.montserrat(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFFF8C00), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator:
              validator ??
              (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return 'This field is required';
                }
                return null;
              },
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? Colors.green : Colors.grey[300],
            ),
            child: Icon(
              isMet ? Icons.check : Icons.close,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isMet ? Colors.green : Colors.grey[600],
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalSelector({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = true,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLoading
              ? null
              : () => _showSelectionModal(
                  context: context,
                  title: label,
                  items: items,
                  currentValue: value,
                  onSelected: onChanged,
                ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isLoading ? 'Loading...' : value ?? hint,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: value == null ? Colors.grey[400] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Method to show the modal with radio buttons
  Future<void> _showSelectionModal({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String? currentValue,
    required Function(String?) onSelected,
  }) async {
    String? tempSelected = currentValue;

    final sortedItems = List<String>.from(items)..sort();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select $title',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  // Options list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: sortedItems.length,
                      itemBuilder: (context, index) {
                        final item = sortedItems[index];
                        final isSelected = tempSelected == item;

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              tempSelected = item;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFFFF8C00).withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                // Radio button
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Color(0xFFFF8C00)
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFFF8C00),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Item text
                                Expanded(
                                  child: Text(
                                    item,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      color: isSelected
                                          ? Color(0xFFFF8C00)
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Confirm button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          onSelected(tempSelected);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF8C00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final halfHeight = constraints.maxHeight / 2;
          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: halfHeight,
                    width: double.infinity,
                    color: Color(0xFFF5F5F5),
                  ),
                  Container(
                    height: halfHeight,
                    width: double.infinity,
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
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              SafeArea(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildIntroPanel(),
                    _buildRegistrationPanel(),
                    _buildSuccessRegistrationPanel(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Panel 1: Introduction
  Widget _buildIntroPanel() {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  onPressed: () async {
                    // Sign out and go back to login
                    await supabase.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  tooltip: 'Back to Login',
                ),
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF8C00),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 60),
          // Image
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 60),
                  child: Image.asset(
                    'assets/images/registration_img.png',
                    height: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(flex: 20),
                Text(
                  'Welcome to',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'iTOURu',
                  style: GoogleFonts.montserrat(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Your Bicol University - West Campus Tour Guide',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: SizedBox(
              width: 80,
              height: 80,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C00),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  elevation: 8,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '© Right Reserve. Capstone Group',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Panel 2: Registration Form
  Widget _buildRegistrationPanel() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          Container(
            color: Color(0xFFF5F5F5),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Back button and Page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 28,
                        ),
                      ),
                      // Page indicators
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF8C00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF8C00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Illustration
                Image.asset(
                  'assets/images/registration_img2.png',
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Icon(
                        Icons.people_alt,
                        size: 80,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          // Blue section with avatar, title, and form card
          Container(
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
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Avatar logo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/i_logo.png',
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.location_on,
                            size: 35,
                            color: Color(0xFFFF8C00),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Complete Personal\nInformation',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                // Form Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hint: 'Enter your first name',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    controller: _middleNameController,
                                    label: 'Middle Name',
                                    hint: 'Enter middle name',
                                    required: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _suffixController,
                                    label: 'Suffix',
                                    hint: 'Jr., Sr.',
                                    required: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hint: 'Enter your last name',
                            ),
                            const SizedBox(height: 16),
                            _buildModalSelector(
                              label: 'User Type',
                              hint: 'Select',
                              value: _selectedUserType,
                              items: _userTypes,
                              onChanged: (value) =>
                                  setState(() => _selectedUserType = value),
                            ),
                            const SizedBox(height: 16),
                            _buildModalSelector(
                              label: 'College',
                              hint: 'Select your college',
                              value: _selectedCollegeAbbreviation,
                              items: _collegeAbbreviationToName.keys.toList(),
                              onChanged: (value) => setState(
                                () => _selectedCollegeAbbreviation = value,
                              ),
                              isLoading: _isLoadingColleges,
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Birthday',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: ' *',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _birthdayController,
                                  readOnly: true,
                                  onTap: _selectDate,
                                  style: GoogleFonts.montserrat(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Select your birthday',
                                    hintStyle: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Color(0xFFFF8C00),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select your birthday';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildModalSelector(
                              label: 'Nationality',
                              hint: 'Select nationality',
                              value: _selectedNationality,
                              items: _nationalities,
                              onChanged: (value) =>
                                  setState(() => _selectedNationality = value),
                            ),

                            const SizedBox(height: 16),
                            _buildModalSelector(
                              label: 'Sex',
                              hint: 'Select sex',
                              value: _selectedSex,
                              items: _sexOptions,
                              onChanged: (value) =>
                                  setState(() => _selectedSex = value),
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'e.g., 09123456789',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'This field is required';
                                }
                                if (!RegExp(
                                  r'^09\d{9}$',
                                ).hasMatch(value.trim())) {
                                  return 'Invalid phone number format';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isPasswordValid
                                    ? Colors.green[50]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isPasswordValid
                                      ? Colors.green
                                      : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isPasswordValid
                                            ? Icons.check_circle
                                            : Icons.info_outline,
                                        color: _isPasswordValid
                                            ? Colors.green
                                            : Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isPasswordValid
                                            ? 'All requirements met!'
                                            : 'Password must contain:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _isPasswordValid
                                              ? Colors.green
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRequirementItem(
                                    'At least 8 characters',
                                    _hasMinLength,
                                  ),
                                  _buildRequirementItem(
                                    'One uppercase letter (A-Z)',
                                    _hasUppercase,
                                  ),
                                  _buildRequirementItem(
                                    'One lowercase letter (a-z)',
                                    _hasLowercase,
                                  ),
                                  _buildRequirementItem(
                                    'One number (0-9)',
                                    _hasDigit,
                                  ),
                                  _buildRequirementItem(
                                    'One special character (!@#\$%^&*)',
                                    _hasSpecialChar,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Password',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: ' *',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.montserrat(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Color(0xFFFF8C00),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (!_isPasswordValid) {
                                      return 'Password does not meet requirements';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Confirm Password Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Confirm Password',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: ' *',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: GoogleFonts.montserrat(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Confirm your password',
                                    hintStyle: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Color(0xFFFF8C00),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  // Terms of Service
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: _showTerms,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: _acceptedTerms
                                                ? Color(0xFFFF8C00)
                                                : Colors.white,
                                            border: Border.all(
                                              color: _acceptedTerms
                                                  ? Color(0xFFFF8C00)
                                                  : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: _acceptedTerms
                                              ? Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  'I accept the ',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: _showTerms,
                                                  child: Text(
                                                    'Terms of Service',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Color(0xFF2196F3),
                                                      decoration: TextDecoration
                                                          .underline,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (!_hasReadTerms)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  'Please read and accept in the document',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: Colors.orange[700],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Privacy Policy
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: _showPrivacy,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: _acceptedPrivacy
                                                ? Color(0xFFFF8C00)
                                                : Colors.white,
                                            border: Border.all(
                                              color: _acceptedPrivacy
                                                  ? Color(0xFFFF8C00)
                                                  : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: _acceptedPrivacy
                                              ? Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  'I accept the ',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: _showPrivacy,
                                                  child: Text(
                                                    'Privacy Policy',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Color(0xFF2196F3),
                                                      decoration: TextDecoration
                                                          .underline,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (!_hasReadPrivacy)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  'Please read and accept in the document',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: Colors.orange[700],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _submitRegistration,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF8C00),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isSubmitting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Panel 3: Success Registration
  Widget _buildSuccessRegistrationPanel() {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 70),
                  child: Image.asset(
                    'assets/images/registration_img3.png',
                    height: 210,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  'Nice!',
                  style: GoogleFonts.montserrat(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'You are now registered. Please proceed to explore Bicol University.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: SizedBox(
              width: 80,
              height: 80,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C00),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  elevation: 8,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '© Right Reserve. Capstone Group',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
