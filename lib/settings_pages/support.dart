import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/contact_support.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? expandedQuestion;

  // Map to store answers for each question
  final Map<String, String> faqAnswers = {
    'How do I create an account?':
        'You can create an account using your existing Google BU email address. Once you sign up, if your account is new, you\'ll be prompted to set up your profile with your personal information.',

    'What if I forget my password?':
        'You can use the "Forgot Password" option on the login page. Enter your BU email address, and you\'ll receive a password reset link via email. Follow the link to create a new password securely.',

    'How do I update my profile information?':
        'Go to Settings > Privacy and Security page. Here you can update your name, gender, birthdate, and phone number. Note that your nationality and email cannot be changed once set. To change your password, a verification email will be sent to your registered email address for security purposes.',

    'How do I search for locations?':
        'Use the search functionality on the Categories page to look up your desired location. Simply type the name of the building, office, or landmark you\'re looking for.',

    'How do I view tour details?':
        'Each location has detailed information including descriptions, images, and directions. For colleges, you\'ll see learning outcomes, the dean\'s information with contact details, offered programs, buildings, and rooms. Buildings show their descriptions, room listings, and a direction button. Landmarks display descriptions and directions. Offices include descriptions, the head of office, location details, and a direction button.',

    'Are there guided tours available?':
        'Yes! We offer several guided tours designed for new students and visitors who want to familiarize themselves with the campus layout. Each tour includes video guides and step-by-step routes for the buildings covered in that tour.',

    'How is my data protected?':
        'We take your privacy seriously. Your data is encrypted and stored securely on our servers. We use industry-standard security protocols to protect your personal information. Your BU email credentials are handled through Google\'s secure authentication system, and we never store your password directly.',

    'What permissions does the app need?':
        'The app requires location permissions for navigation purposes to help you find your way around campus. Camera access is needed for QR code scanning functionality. These permissions can be managed through your device settings at any time.',

    'How do I report a security concern?':
        'If you discover a security vulnerability or have concerns about your account security, please contact our support team immediately at jcml2022-2902-58530@bicol-u.edu.ph with details about the issue.',

    'How do I use the app as a guest?':
        'You can browse locations, view maps, and access basic information without creating an account. Simply select "Continue as Guest" on the login page to explore the campus.',

    'How do I contact support?':
        'You can reach our support team by tapping "Contact Support" at the bottom of the Help & Support page, or email us directly at jcml2022-2902-58530@bicol-u.edu.ph. We typically respond within 24-48 hours. You can also use the feedback feature that is on Home page.',

    'Where can I report a bug?':
        'If you encounter any issues or bugs while using the app, please email us at jcml2022-2902-58530@bicol-u.edu.ph with a detailed description of the problem, including screenshots if possible. This helps us resolve issues quickly. You can also use the feedback feature that is on Home page.',
  };

  final List<HelpCategory> categories = [
    HelpCategory(
      icon: Icons.account_circle,
      iconColor: Colors.blue,
      title: 'Accounts',
      questions: [
        'How do I create an account?',
        'What if I forget my password?',
        'How do I update my profile information?',
      ],
    ),
    HelpCategory(
      icon: Icons.explore,
      iconColor: Colors.green,
      title: 'Tours & Destinations',
      questions: [
        'How do I search for locations?',
        'How do I view tour details?',
        'Are there guided tours available?',
      ],
    ),
    HelpCategory(
      icon: Icons.security,
      iconColor: Color(0xFFFF8C00),
      title: 'Privacy & Security',
      questions: [
        'How is my data protected?',
        'What permissions does the app need?',
        'How do I report a security concern?',
      ],
    ),
    HelpCategory(
      icon: Icons.help_outline,
      iconColor: Colors.red,
      title: 'General',
      questions: [
        'How do I use the app as a guest?',
        'How do I contact support?',
        'Where can I report a bug?',
      ],
    ),
  ];

  List<HelpCategory> get filteredCategories {
    if (selectedCategory == 'All' && searchQuery.isEmpty) {
      return categories;
    }

    return categories.where((category) {
      final matchesCategory =
          selectedCategory == 'All' || category.title == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty ||
          category.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          category.questions.any(
            (q) => q.toLowerCase().contains(searchQuery.toLowerCase()),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          ReusableHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
                              'Help & Support',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                              ),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category Filter Chips
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildCategoryChip('All'),
                          ...categories.map(
                            (cat) => _buildCategoryChip(cat.title),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // General Questions Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Frequently Asked Questions',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // Help Categories
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: filteredCategories.map((category) {
                        return _buildCategoryCard(category);
                      }).toList(),
                    ),
                  ),

                  // Contact Support Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ContactSupportCard(
                      title: 'Still need help?',
                      subtitle: 'Our support team is here to assist you',
                      iconSize: 48,
                      padding: const EdgeInsets.all(24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildCategoryChip(String title) {
    final isSelected = selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(title),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = title;
          });
        },
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: Color(0xFFFF8C00),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? Color(0xFFFF8C00) : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildCategoryCard(HelpCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  category.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          // Questions with Accordion
          ...category.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final isLast = index == category.questions.length - 1;
            final isExpanded = expandedQuestion == question;

            return Column(
              children: [
                _buildAccordionItem(question, isExpanded),
                if (!isLast && !isExpanded)
                  Divider(
                    height: 1,
                    color: Colors.grey[200],
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccordionItem(String question, bool isExpanded) {
    final answer =
        faqAnswers[question] ??
        'This is where the detailed answer to the question would appear.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expandedQuestion = isExpanded ? null : question;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isExpanded
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isExpanded ? Color(0xFFFF8C00) : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Answer',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                answer,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFFFF8C00,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(
                                      0xFFFF8C00,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFFFF8C00),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'For more assistance, contact our support team.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Color(0xFFFF8C00),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class HelpCategory {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> questions;

  HelpCategory({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.questions,
  });
}
