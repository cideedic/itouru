import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/main_pages/maps.dart';
import 'package:itouru/main_pages/categories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itouru/login_components/guest_modal.dart';
import 'package:itouru/login_components/guest_restriction_modal.dart';
import 'dart:math';
import 'dart:ui';
import 'package:itouru/settings_pages/about.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late AnimationController _mapController;
  late AnimationController _searchCardController;
  late AnimationController _searchFieldController;
  late PageController _featuredLocationsController;

  late Animation<double> _mapZoomAnimation;
  late Animation<double> _searchCardFadeAnimation;
  late Animation<double> _searchFieldFadeAnimation;

  final List<AnimationController> _locationControllers = [];
  final List<Animation<double>> _locationFadeAnimations = [];
  final List<Animation<Offset>> _locationSlideAnimations = [];

  int _currentLocationIndex = 0;

  // Feedback state
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  final supabase = Supabase.instance.client;

  bool _isGuestUser() {
    final user = supabase.auth.currentUser;
    if (user == null) return true;

    final isAnonymous =
        user.isAnonymous ||
        user.appMetadata['provider'] == 'anonymous' ||
        user.email == null ||
        user.email!.isEmpty;

    return isAnonymous;
  }

  void _showGuestRestriction() {
    showDialog(
      context: context,
      builder: (context) => const GuestRestrictionModal(feature: 'Feedback'),
    );
  }

  final List<Map<String, dynamic>> featuredLocations = [
    {
      'id': 2,
      'name': 'College of Science',
      'description':
          'The College of Science building houses various science departments and laboratories for students pursuing scientific disciplines.',
      'image': 'assets/images/college_of_science.png',
      'category': 'College Building',
    },
    {
      'id': 3,
      'name': 'College of Engineering',
      'description':
          'Modern facilities and laboratories for engineering students with state-of-the-art equipment.',
      'image': 'assets/images/college_of_engineering.jpg',
      'category': 'College Building',
    },
    {
      'id': 4,
      'name': 'Library',
      'description':
          'The main university library with extensive collection of books, journals, and digital resources.',
      'image': 'assets/images/library.jpg',
      'category': 'Academic Facility',
    },
    {
      'id': 5,
      'name': 'Administration Building',
      'description':
          'Central administrative offices and student services are located in this building.',
      'image': 'assets/images/admin_building.jpg',
      'category': 'Administrative',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Search card animation
    _searchCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _searchCardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchCardController, curve: Curves.easeOut),
    );

    // Search field animation
    _searchFieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _searchFieldFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchFieldController, curve: Curves.easeOut),
    );

    // Map zoom animation
    _mapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _mapZoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _mapController, curve: Curves.easeInOut));

    // Featured locations page controller
    _featuredLocationsController = PageController(initialPage: 0);

    // Initialize animations for each location
    for (int i = 0; i < featuredLocations.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      );

      _locationControllers.add(controller);

      _locationFadeAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
      );

      _locationSlideAnimations.add(
        Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        ),
      );
    }

    // Start search animations
    _searchCardController.forward().then((_) {
      _searchFieldController.forward();
    });

    // Check for guest modal
    _checkAndShowGuestModal();
  }

  Future<void> _checkAndShowGuestModal() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final isAnonymous =
          user.isAnonymous ||
          user.appMetadata['provider'] == 'anonymous' ||
          user.email == null ||
          user.email!.isEmpty;

      if (isAnonymous) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenModal =
            prefs.getBool('guest_modal_shown_${user.id}') ?? false;

        if (!hasSeenModal && mounted) {
          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const GuestAccessModal(),
            );

            await prefs.setBool('guest_modal_shown_${user.id}', true);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchCardController.dispose();
    _searchFieldController.dispose();
    _scrollController.dispose();
    _feedbackController.dispose();
    _featuredLocationsController.dispose();
    for (var controller in _locationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onMapTap() async {
    await _mapController.forward();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Maps()),
      ).then((_) {
        if (mounted) {
          _mapController.reverse();
        }
      });
    }
  }

  void _onSearchTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Categories(autoFocusSearch: true),
      ),
    );
  }

  void _onLocationExplore() {
    // Navigate to Categories page with the current location
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Categories(autoFocusSearch: true),
      ),
    );
  }

  void _onLocationInfo() {
    final location = featuredLocations[_currentLocationIndex];
    // Navigate to detailed info page
    print('Info for ${location['name']}');
  }

  void _showModal({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 32),
                SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0 || _feedbackController.text.trim().isEmpty) {
      _showModal(
        message: 'Please provide a rating and feedback',
        backgroundColor: Colors.red[50]!,
        textColor: const Color.fromARGB(255, 207, 80, 80),
        icon: Icons.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userResponse = await supabase
          .from('Users')
          .select('user_id')
          .eq('email', user.email!)
          .single();

      final userId = userResponse['user_id'];
      final feedbackId = Random().nextInt(9007199254740991);

      await supabase.from('Feedback').insert({
        'feedback_id': feedbackId,
        'user_id': userId,
        'rating': _selectedRating,
        'description': _feedbackController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      _showModal(
        message: 'Thank you for your feedback!',
        backgroundColor: Colors.green[50]!,
        textColor: const Color.fromARGB(255, 91, 194, 96),
        icon: Icons.check_circle,
      );

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _selectedRating = 0;
            _feedbackController.clear();
            _isSubmitting = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      _showModal(
        message: 'Failed to submit feedback. Please try again.',
        backgroundColor: Colors.red[50]!,
        textColor: const Color.fromARGB(255, 207, 80, 80),
        icon: Icons.error,
      );

      print('Error submitting feedback: $e');
    }
  }

  void _onStarTap(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ReusableHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Welcome Banner Section
                  Container(
                    height: isLandscape
                        ? screenHeight * 0.35
                        : screenHeight * 0.78,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isLandscape ? 8 : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isLandscape ? 12 : 30,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: RadialGradient(
                              center: const Alignment(-1.0, -1.0),
                              radius: 1.5,
                              colors: [
                                const Color(
                                  0xFFFFC86C,
                                ).withValues(alpha: 0.535),
                                const Color(0xFF6ABAF4).withValues(alpha: 0.26),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/home_image.png',
                                height: isLandscape ? 120 : 200,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: isLandscape ? 100 : 150,
                                    child: Icon(
                                      Icons.home,
                                      size: isLandscape ? 50 : 80,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: isLandscape ? 8 : 16),
                              Text(
                                'Welcome to',
                                style: GoogleFonts.poppins(
                                  fontSize: isLandscape ? 16 : 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Image.asset(
                                'assets/images/itouru_logo.png',
                                height: isLandscape ? 50 : 80,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    'iTOURu',
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: isLandscape ? 36 : 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (!isLandscape) ...[
                          const SizedBox(height: 40),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeTransition(
                                  opacity: _searchCardFadeAnimation,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      'Search Location of Interest',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                FadeTransition(
                                  opacity: _searchFieldFadeAnimation,
                                  child: GestureDetector(
                                    onTap: _onSearchTap,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Search',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Featured Locations Slideshow Section
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Round the entire section
                    child: Container(
                      height: isLandscape ? screenHeight * 0.7 : screenHeight,
                      width: double.infinity,
                      color: Colors.black,
                      child: Stack(
                        children: [
                          // PageView for slideshow
                          PageView.builder(
                            controller: _featuredLocationsController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentLocationIndex = index;
                              });
                            },
                            itemCount: featuredLocations.length,
                            itemBuilder: (context, index) {
                              final location = featuredLocations[index];
                              return Stack(
                                children: [
                                  // Background Image
                                  Image.asset(
                                    location['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[400],
                                        child: Center(
                                          child: Icon(
                                            Icons.location_city,
                                            size: 80,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Gradient Overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color.fromARGB(
                                            255,
                                            0,
                                            1,
                                            46,
                                          ).withValues(alpha: 0.2),
                                          const Color.fromARGB(
                                            255,
                                            0,
                                            1,
                                            46,
                                          ).withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // Right side buttons - positioned at bottom right but not at the very bottom
                          Positioned(
                            right: 20,
                            bottom: 90, // Moved up from center to bottom area
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Info Button
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _onLocationInfo,
                                      borderRadius: BorderRadius.circular(25),
                                      child: Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Explore Button
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _onLocationExplore,
                                      borderRadius: BorderRadius.circular(25),
                                      child: Icon(
                                        Icons.explore_outlined,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Location Info at Bottom
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0),
                                    Colors.black.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        199,
                                        152,
                                        76,
                                      ).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                          255,
                                          199,
                                          152,
                                          76,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      featuredLocations[_currentLocationIndex]['category'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                          255,
                                          199,
                                          152,
                                          76,
                                        ),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    featuredLocations[_currentLocationIndex]['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Indicator Dots
                                  Row(
                                    children: List.generate(
                                      featuredLocations.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: index == _currentLocationIndex
                                            ? 24
                                            : 8,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: index == _currentLocationIndex
                                              ? Colors.cyan
                                              : Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Extra spacing before about section
                  SizedBox(height: isLandscape ? 10 : 15),

                  // About App Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange[400],
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'About iTOURu',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'iTOURu is an interactive campus navigation and tour application designed to help students, visitors, and staff explore Bicol University West Campus seamlessly. Discover academic facilities, buildings, amenities, and key locations all in one comprehensive digital guide.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // In your Home page, the Learn More button code:
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AboutPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[400],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Learn More',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              // Make sure you have this import at the top of your home.dart file:
                              // import 'package:itouru/settings_pages/about.dart';
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isLandscape ? 10 : 15),
                  // Feedback Section (Compact)
                  GestureDetector(
                    onTap: _isGuestUser() ? _showGuestRestriction : null,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 30,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Row(
                                  children: [
                                    Icon(
                                      Icons.feedback_outlined,
                                      color: Colors.orange[400],
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Rate Our App',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Share your experience with us',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Center(
                                  child: Image.asset(
                                    'assets/images/feedback_img.png',
                                    height: 150,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        child: Icon(
                                          Icons.rate_review,
                                          size: 80,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Current stars with animation on tap
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return GestureDetector(
                                      onTap: (_isSubmitting || _isGuestUser())
                                          ? null
                                          : () => _onStarTap(index + 1),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Icon(
                                          index < _selectedRating
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: index < _selectedRating
                                              ? 36
                                              : 32, // Grows when selected
                                          color: index < _selectedRating
                                              ? Colors.orange[400]
                                              : Colors.grey[300],
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                SizedBox(height: 12),

                                // Feedback text field
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _feedbackController,
                                    enabled: !_isSubmitting && !_isGuestUser(),
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _isGuestUser()
                                          ? 'Sign in to share feedback...'
                                          : 'Share your feedback...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16),

                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: (_isSubmitting || _isGuestUser())
                                        ? null
                                        : _submitFeedback,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[400],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                      disabledBackgroundColor: Colors.grey[300],
                                    ),
                                    child: _isSubmitting
                                        ? SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            _isGuestUser()
                                                ? 'Sign In Required'
                                                : 'Submit Feedback',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Blur overlay for guest users
                        if (_isGuestUser())
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 30,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 3,
                                    sigmaY: 3,
                                  ),
                                  child: Container(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            size: 48,
                                            color: Colors.orange[400],
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Sign in to access',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Tap to learn more',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Extra spacing before map section
                  SizedBox(height: isLandscape ? 20 : 20),

                  // Map Section
                  GestureDetector(
                    onTap: _onMapTap,
                    child: AnimatedBuilder(
                      animation: _mapZoomAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _mapZoomAnimation.value,
                          child: child,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/footer_map.jpg',
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.map,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.black.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Explore Campus Map',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Tap to navigate',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 0),
    );
  }
}
