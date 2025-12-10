import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'terms_of_service.dart';
import 'privacy_policy.dart';
import 'package:itouru/page_components/contact_support.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  // Controllers for editable fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();

  // Controllers for read-only fields
  final TextEditingController _emailController = TextEditingController();

  String userEmail = "";
  String college = "";
  bool _showEmail = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Show modal when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrivacyInfoModal();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();

    _emailController.dispose();
    super.dispose();
  }

  void _navigateToTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      userEmail = user.email ?? "";

      final response = await Supabase.instance.client
          .from('Users')
          .select('''
              first_name,
              middle_name,
              last_name,
              suffix,
              email,
              college
            ''')
          .eq('email', userEmail)
          .maybeSingle();

      if (response != null) {
        setState(() {
          // Editable fields
          _firstNameController.text = response['first_name']?.toString() ?? "";
          _middleNameController.text =
              response['middle_name']?.toString() ?? "";
          _lastNameController.text = response['last_name']?.toString() ?? "";
          _suffixController.text = response['suffix']?.toString() ?? "";

          // Read-only fields
          _emailController.text = response['email']?.toString() ?? "";
          college = response['college']?.toString() ?? "N/A";

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        _showSnackBar('Failed to load profile data', isError: true);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      // Update only editable user information
      final updates = {
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'suffix': _suffixController.text.trim(),
      };

      await Supabase.instance.client
          .from('Users')
          .update(updates)
          .eq('email', userEmail);

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      if (mounted) {
        _showSnackBar('Profile updated successfully', isError: false);
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      if (mounted) {
        _showSnackBar('Failed to save changes: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset,
                  color: Color(0xFFFF8C00),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Change Password?',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Do you want to change your password? This is recommended if you haven\'t changed the default password yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _sendPasswordResetEmail();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF8C00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        'Yes',
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
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      // Send password reset email with proper deep link redirect
      await Supabase.instance.client.auth.resetPasswordForEmail(
        userEmail,
        redirectTo: 'itouru://reset-password',
      );

      if (mounted) {
        _showSnackBar(
          'Password reset link has been sent to your email',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to send password reset email', isError: true);
      }
    }
  }

  void _showPrivacyInfoModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon and Title
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF8C00).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security,
                            color: Color(0xFFFF8C00),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Privacy & Data Protection',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // User Data Protection
                      _buildSectionTitle('User Data Protection'),
                      _buildInfoText(
                        'Your data is securely stored and managed with strict access controls. We use secure protocols to protect your information.',
                      ),
                      const SizedBox(height: 16),

                      // Authentication & Authorization
                      _buildSectionTitle('Authentication & Authorization'),
                      _buildBulletPoint(
                        'Login credentials are protected using secure token-based authentication',
                      ),
                      _buildBulletPoint(
                        'Only you can access your account with proper verification',
                      ),
                      const SizedBox(height: 16),

                      // Privacy Practices
                      _buildSectionTitle('Privacy Practices'),
                      _buildBulletPoint(
                        'We collect only necessary information for app functionality',
                      ),
                      _buildBulletPoint(
                        'Your data is never shared without explicit consent',
                      ),
                      _buildBulletPoint(
                        'You can adjust your preferences anytime in-app',
                      ),
                      const SizedBox(height: 16),

                      // Security Measures
                      _buildSectionTitle('Security Measures'),
                      _buildBulletPoint(
                        'Data is encrypted during transmission and at rest',
                      ),
                      _buildBulletPoint(
                        'Regular security audits and updates are performed',
                      ),
                      _buildBulletPoint(
                        'Strict measures prevent unauthorized access',
                      ),
                      const SizedBox(height: 16),
                      // Legal Documents Section
                      Text(
                        'LEGAL DOCUMENTS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Terms of Service Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close modal first
                            _navigateToTermsOfService();
                          },
                          icon: Icon(
                            Icons.description,
                            size: 16,
                            color: Colors.blue,
                          ),
                          label: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Terms of Service',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Privacy Policy Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close modal first
                            _navigateToPrivacyPolicy();
                          },
                          icon: Icon(
                            Icons.privacy_tip,
                            size: 16,
                            color: Colors.green,
                          ),
                          label: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Privacy Policy',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.green,
                              ),
                            ],
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // User Rights & Controls
                      _buildSectionTitle('Your Rights & Controls'),
                      _buildInfoText(
                        'You may view, modify, or delete your personal data anytime by managing your account settings or contacting support.',
                      ),
                      const SizedBox(height: 16),

                      // Information Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'For any privacy concerns or questions, please contact the app administrator.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'I Understand',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const ReusableHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back Button
                          Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Privacy & Security',
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Header Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'PERSONAL INFORMATION',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  // Privacy Info Button
                                  IconButton(
                                    onPressed: _showPrivacyInfoModal,
                                    icon: const Icon(Icons.info_outline),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blue.withValues(
                                        alpha: 0.1,
                                      ),
                                      foregroundColor: Colors.blue,
                                    ),
                                    tooltip: 'Privacy Guidelines',
                                  ),
                                  const SizedBox(width: 8),
                                  // Edit Button
                                  if (!isEditing)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isEditing = true;
                                        });
                                      },
                                      icon: const Icon(Icons.edit),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Color(
                                          0xFFFF8C00,
                                        ).withValues(alpha: 0.1),
                                        foregroundColor: Color(0xFFFF8C00),
                                      ),
                                      tooltip: 'Edit Profile',
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // First Name
                          _buildTextField(
                            label: 'First Name',
                            controller: _firstNameController,
                            icon: Icons.person,
                            enabled: isEditing,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter first name';
                              }
                              // Check for numbers in name
                              if (RegExp(r'\d').hasMatch(value)) {
                                return 'Name cannot contain numbers';
                              }
                              // Check for special characters (allow spaces, periods, hyphens, and apostrophes)
                              if (!RegExp(
                                r"^[a-zA-Z\s.\-']+$",
                              ).hasMatch(value)) {
                                return 'Name contains invalid characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Middle Name and Suffix
                          Row(
                            children: [
                              Expanded(
                                flex: 7,
                                child: _buildTextField(
                                  label: 'Middle Name',
                                  controller: _middleNameController,
                                  icon: Icons.person_outline,
                                  enabled: isEditing,
                                  validator: (value) {
                                    // Middle name is optional, so only validate if not empty
                                    if (value != null && value.isNotEmpty) {
                                      // Check for numbers
                                      if (RegExp(r'\d').hasMatch(value)) {
                                        return 'Name cannot contain numbers';
                                      }
                                      // Check for special characters
                                      if (!RegExp(
                                        r"^[a-zA-Z\s.\-']+$",
                                      ).hasMatch(value)) {
                                        return 'Name contains invalid characters';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  label: 'Suffix',
                                  controller: _suffixController,
                                  icon: Icons.text_fields,
                                  enabled: isEditing,
                                  validator: (value) {
                                    // Suffix is optional, so only validate if not empty
                                    if (value != null && value.isNotEmpty) {
                                      // Allow only common suffixes: Jr., Sr., I, II, III, IV, V
                                      if (!RegExp(
                                        r'^(Jr\.?|Sr\.?|I{1,3}|IV|V)$',
                                        caseSensitive: false,
                                      ).hasMatch(value.trim())) {
                                        return 'Invalid suffix';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Last Name
                          _buildTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            icon: Icons.person,
                            enabled: isEditing,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter last name';
                              }
                              // Check for numbers
                              if (RegExp(r'\d').hasMatch(value)) {
                                return 'Name cannot contain numbers';
                              }
                              // Check for special characters (allow hyphens for compound surnames)
                              if (!RegExp(
                                r"^[a-zA-Z\s.\-']+$",
                              ).hasMatch(value)) {
                                return 'Name contains invalid characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Read-only Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'The information below cannot be edited. Contact an administrator for verification and changes.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'College',
                            controller: TextEditingController(text: college),
                            icon: Icons.school,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildMaskedEmailField(),
                          const SizedBox(height: 16),

                          // Password Management Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFFFF8C00),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Password Security',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your password is securely encrypted and cannot be viewed. For security reasons, we recommend changing your password regularly.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Change Password Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showChangePasswordDialog,
                              icon: Icon(
                                Icons.lock_reset,
                                size: 18,
                                color: Color(0xFFFF8C00),
                              ),
                              label: Text(
                                'Change Password',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF8C00),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xFFFF8C00)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Use the reusable Contact Support Card
                          ContactSupportCard(
                            title: 'Need Help?',
                            subtitle:
                                'Our support team is here to assist you with any account or privacy concerns',
                          ),

                          // Action Buttons
                          if (isEditing) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () {
                                            setState(() {
                                              isEditing = false;
                                            });
                                            _loadUserData();
                                          },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving ? null : _saveChanges,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFF8C00),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
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
                                            'Save Changes',
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
                          const SizedBox(height: 24),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Color(0xFFFF8C00),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaskedEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          readOnly: true,
          obscureText: !_showEmail,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
            letterSpacing: _showEmail ? 0 : 2,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.email, color: Colors.grey[400], size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showEmail ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: Color(0xFFFF8C00),
              ),
              onPressed: () {
                setState(() {
                  _showEmail = !_showEmail;
                });
              },
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? prefixText, // NEW parameter for +63
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: enabled ? Colors.black87 : Colors.grey[600],
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: enabled ? Color(0xFFFF8C00) : Colors.grey[400],
              size: 20,
            ),
            // NEW: Add prefix text support
            prefixText: prefixText,
            prefixStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterText: '',
          ),
          validator: validator,
        ),
      ],
    );
  }
}
