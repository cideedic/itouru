import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/main_pages/featured_locations.dart';
import 'package:itouru/main_pages/maps.dart';
import 'package:itouru/main_pages/categories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itouru/login_components/guest_modal.dart';
import 'package:itouru/settings_pages/about.dart';
import 'package:itouru/main_pages/history.dart';
import 'package:itouru/main_pages/explore.dart';
import 'package:itouru/main_pages/feedback.dart';
import 'package:itouru/page_components/grid_image_gallery.dart';
import 'package:itouru/main_pages/university_officials_section.dart';
import 'package:itouru/main_pages/vmq_section.dart';
import 'package:url_launcher/url_launcher.dart';

class PolygonBackgroundPainter extends CustomPainter {
  final double animationValue;

  PolygonBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final polygons = [
      {
        'color': Colors.orange.withValues(alpha: 0.03),
        'points': [
          Offset(size.width * 0.7, -50),
          Offset(size.width * 1.2, size.height * 0.1),
          Offset(size.width * 0.9, size.height * 0.25),
        ],
      },
      {
        'color': Colors.blue.withValues(alpha: 0.03),
        'points': [
          Offset(-50, size.height * 0.1),
          Offset(size.width * 0.3, size.height * 0.05),
          Offset(size.width * 0.15, size.height * 0.3),
        ],
      },
      {
        'color': Colors.purple.withValues(alpha: 0.02),
        'points': [
          Offset(size.width * 0.85, size.height * 0.4),
          Offset(size.width * 1.1, size.height * 0.5),
          Offset(size.width * 0.95, size.height * 0.65),
        ],
      },
      {
        'color': Colors.teal.withValues(alpha: 0.025),
        'points': [
          Offset(-30, size.height * 0.7),
          Offset(size.width * 0.25, size.height * 0.75),
          Offset(size.width * 0.1, size.height * 0.9),
        ],
      },
    ];

    for (var polygon in polygons) {
      paint.color = polygon['color'] as Color;
      final path = Path();
      final points = polygon['points'] as List<Offset>;

      path.moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(PolygonBackgroundPainter oldDelegate) => false;
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late AnimationController _mapController;
  AnimationController? _officialsController;
  AnimationController? _visionController;
  AnimationController? _missionController;
  AnimationController? _qualityController;
  AnimationController? _historyController;
  AnimationController? _featuredController;
  AnimationController? _aboutController;
  AnimationController? _feedbackAnimController;
  AnimationController? _exploreController;

  late Animation<double> _mapZoomAnimation;
  Animation<Offset>? _officialsSlideAnimation;
  Animation<Offset>? _visionSlideAnimation;

  Animation<Offset>? _historySlideAnimation;
  Animation<Offset>? _featuredSlideAnimation;
  Animation<Offset>? _aboutSlideAnimation;
  Animation<Offset>? _feedbackSlideAnimation;
  Animation<Offset>? _exploreSlideAnimation;

  Animation<double>? _officialsFadeAnimation;
  Animation<double>? _visionFadeAnimation;

  Animation<double>? _historyFadeAnimation;
  Animation<double>? _featuredFadeAnimation;
  Animation<double>? _aboutFadeAnimation;
  Animation<double>? _feedbackFadeAnimation;
  Animation<double>? _exploreFadeAnimation;

  bool _officialsVisible = false;
  bool _visionVisible = false;
  bool _missionVisible = false;
  bool _qualityVisible = false;
  bool _historyVisible = false;
  bool _featuredVisible = false;
  bool _aboutVisible = false;
  bool _feedbackVisible = false;
  bool _exploreVisible = false;

  final supabase = Supabase.instance.client;

  final HistoryTimeline _historyTimeline = HistoryTimeline();
  List<Map<String, dynamic>> _timelineData = [];
  bool _isLoadingTimeline = false;

  List<String> historyImages = [];
  PageController? _historyPageController;

  @override
  void initState() {
    super.initState();

    _loadTimelineData();
    _loadHistoryImages();

    // Officials slide and fade animation
    _officialsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _officialsSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _officialsController!, curve: Curves.easeOut),
        );
    _officialsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _officialsController!, curve: Curves.easeIn),
    );
    // Vision slide and fade animation
    _visionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _visionSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _visionController!, curve: Curves.easeOut),
        );
    _visionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _visionController!, curve: Curves.easeIn),
    );

    // Mission slide and fade animation
    _missionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Quality Policy slide and fade animation
    _qualityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // History slide and fade animation
    _historyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _historySlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _historyController!, curve: Curves.easeOut),
        );
    _historyFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _historyController!, curve: Curves.easeIn),
    );

    // Featured slide and fade animation
    _featuredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _featuredSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _featuredController!, curve: Curves.easeOut),
        );
    _featuredFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _featuredController!, curve: Curves.easeIn),
    );

    // About slide and fade animation
    _aboutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _aboutSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _aboutController!, curve: Curves.easeOut),
        );
    _aboutFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _aboutController!, curve: Curves.easeIn));

    // Feedback slide and fade animation
    _feedbackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _feedbackSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _feedbackAnimController!,
            curve: Curves.easeOut,
          ),
        );
    _feedbackFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackAnimController!, curve: Curves.easeIn),
    );

    // Explore slide and fade animation
    _exploreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _exploreSlideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _exploreController!, curve: Curves.easeOut),
        );
    _exploreFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exploreController!, curve: Curves.easeIn),
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

    // Add scroll listener
    _scrollController.addListener(_onScroll);

    // Check for guest modal
    _checkAndShowGuestModal();
  }

  void _onScroll() {
    final scrollPosition = _scrollController.position.pixels;
    final screenHeight = MediaQuery.of(context).size.height;

    // Trigger officials animation (BEFORE vision section)
    if (scrollPosition > screenHeight * 0.4 && !_officialsVisible) {
      setState(() => _officialsVisible = true);
      _officialsController?.forward();
    }
    // Trigger vision animation
    if (scrollPosition > screenHeight * 0.8 && !_visionVisible) {
      setState(() => _visionVisible = true);
      _visionController?.forward();
    }

    // Trigger mission animation
    if (scrollPosition > screenHeight * 1.5 && !_missionVisible) {
      setState(() => _missionVisible = true);
      _missionController?.forward();
    }

    // Trigger quality policy animation
    if (scrollPosition > screenHeight * 2.2 && !_qualityVisible) {
      setState(() => _qualityVisible = true);
      _qualityController?.forward();
    }

    // Trigger history animation
    if (scrollPosition > screenHeight * 2.9 && !_historyVisible) {
      setState(() => _historyVisible = true);
      _historyController?.forward();
    }

    // Trigger featured animation
    if (scrollPosition > screenHeight * 3.8 && !_featuredVisible) {
      setState(() => _featuredVisible = true);
      _featuredController?.forward();
    }

    // Trigger about animation
    if (scrollPosition > screenHeight * 4.8 && !_aboutVisible) {
      setState(() => _aboutVisible = true);
      _aboutController?.forward();
    }

    // Trigger feedback animation
    if (scrollPosition > screenHeight * 5.6 && !_feedbackVisible) {
      setState(() => _feedbackVisible = true);
      _feedbackAnimController?.forward();
    }

    // Trigger explore animation
    if (scrollPosition > screenHeight * 6.4 && !_exploreVisible) {
      setState(() => _exploreVisible = true);
      _exploreController?.forward();
    }
  }

  void _navigateToCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Categories(initialCategory: category),
      ),
    );
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

  Future<void> _loadHistoryImages() async {
    try {
      final imagesResponse = await supabase
          .from('storage_objects_snapshot')
          .select('name, filename')
          .eq('bucket_id', 'history')
          .order('filename', ascending: true);

      List<String> imageUrls = [];

      for (var imageData in imagesResponse) {
        final imagePath = imageData['name'] as String;
        final filename = imageData['filename'] as String;

        if (filename == '.emptyFolderPlaceholder' ||
            imagePath.endsWith('.emptyFolderPlaceholder')) {
          continue;
        }

        // Only include image files
        if (filename.toLowerCase().endsWith('.jpg') ||
            filename.toLowerCase().endsWith('.jpeg') ||
            filename.toLowerCase().endsWith('.png') ||
            filename.toLowerCase().endsWith('.gif') ||
            filename.toLowerCase().endsWith('.webp')) {
          final publicUrl = supabase.storage
              .from('history')
              .getPublicUrl(imagePath);
          imageUrls.add(publicUrl);
        }
      }

      if (mounted) {
        setState(() {
          historyImages = imageUrls;
        });

        // Initialize page controller if we have multiple images
        if (imageUrls.length > 1) {
          _initializeHistoryPageController();
        }
      }
    } catch (e) {
      // Handle errors if necessary
      if (mounted) {
        setState(() {
          historyImages = [];
        });
      }
    }
  }

  void _initializeHistoryPageController() {
    if (historyImages.isEmpty || historyImages.length == 1) return;

    _historyPageController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );
  }

  Future<void> _loadTimelineData() async {
    setState(() {
      _isLoadingTimeline = true;
    });

    final data = await _historyTimeline.fetchTimelineData();

    if (mounted) {
      setState(() {
        _timelineData = data;
        _isLoadingTimeline = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _officialsController?.dispose();
    _visionController?.dispose();
    _missionController?.dispose();
    _qualityController?.dispose();
    _historyController?.dispose();
    _featuredController?.dispose();
    _aboutController?.dispose();
    _feedbackAnimController?.dispose();
    _exploreController?.dispose();
    _scrollController.dispose();

    if (_historyPageController != null) {
      _historyPageController!.dispose();
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

  void _showTimelineDetails() {
    _historyTimeline.showTimelineModal(context, _timelineData);
  }

  Widget _buildCategoryIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Builder with gradient box style
  Widget _buildEnhancedSection({
    required String title,
    required String subtitle,
    required String content,
    required IconData icon,
    required IconData backgroundIcon,
    required Animation<Offset>? slideAnimation,
    required Animation<double>? fadeAnimation,
    Widget? customContent,
    VoidCallback? onButtonPressed,
    String? buttonText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Title
          Stack(
            alignment: Alignment.center,
            children: [
              // Background Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    backgroundIcon,
                    size: 90,
                    color: Colors.orange.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // Title
              FadeTransition(
                opacity: fadeAnimation ?? AlwaysStoppedAnimation(0.0),
                child: SlideTransition(
                  position:
                      slideAnimation ?? AlwaysStoppedAnimation(Offset.zero),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Enhanced content card
          FadeTransition(
            opacity: fadeAnimation ?? AlwaysStoppedAnimation(0.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.orange.shade50.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Section header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subtitle,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Divider with dots
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.orange.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Content or custom widget
                  if (customContent != null)
                    customContent
                  else
                    Text(
                      content,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[700],
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  // Optional button
                  if (onButtonPressed != null && buttonText != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: onButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  buttonText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Polygon background
          Positioned.fill(
            child: CustomPaint(painter: PolygonBackgroundPainter(0)),
          ),

          // Main content
          Column(
            children: [
              ReusableHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Welcome Banner Card
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome to iTOURu',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Your Digital Campus Guide',
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
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.explore,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search Bar
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: _onSearchTap,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.grey[400],
                                  size: 22,
                                ),
                                SizedBox(width: 12),
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

                      SizedBox(height: 24),

                      // Categories Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categories',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCategoryIcon(
                                  icon: Icons.school,
                                  label: 'Colleges',
                                  color: Colors.blue,
                                  onTap: () => _navigateToCategory('College'),
                                ),
                                _buildCategoryIcon(
                                  icon: Icons.business,
                                  label: 'Buildings',
                                  color: Colors.blue,
                                  onTap: () => _navigateToCategory('Buildings'),
                                ),
                                _buildCategoryIcon(
                                  icon: Icons.place,
                                  label: 'Landmarks',
                                  color: Colors.blue,
                                  onTap: () => _navigateToCategory('Landmarks'),
                                ),
                                _buildCategoryIcon(
                                  icon: Icons.work_outline,
                                  label: 'Offices',
                                  color: Colors.blue,
                                  onTap: () => _navigateToCategory('Offices'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Discover BU West Campus Section
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.only(
                                left: 20,
                                top: 20,
                                bottom: 20,
                                right: 100,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discover BU West Campus',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Explore our state-of-the-art facilities, academic buildings, and vibrant campus life',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 15,
                              top: -10,
                              bottom: 0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/bu_torch.png',
                                  width: 105,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.orange.shade300,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Open space with BU logo background
                      SizedBox(
                        height: screenHeight * 0.5,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.5,
                                child: Image.asset(
                                  'assets/images/bu_logo.png',
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.school,
                                      size: 200,
                                      color: Colors.grey[300],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      VMQSection(
                        slideAnimation: _visionSlideAnimation,
                        fadeAnimation: _visionFadeAnimation,
                      ),

                      // University Officials Section
                      UniversityOfficialsSection(
                        slideAnimation: _officialsSlideAnimation,
                        fadeAnimation: _officialsFadeAnimation,
                      ),

                      SizedBox(height: 20),

                      // History Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 40,
                        ),
                        child: Column(
                          children: [
                            // Title with decorative elements
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background Icon with glow effect
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.orange.withValues(alpha: 0.15),
                                        Colors.orange.withValues(alpha: 0.03),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.history_edu,
                                      size: 90,
                                      color: Colors.orange.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                ),

                                // Title
                                FadeTransition(
                                  opacity:
                                      _historyFadeAnimation ??
                                      AlwaysStoppedAnimation(0.0),
                                  child: SlideTransition(
                                    position:
                                        _historySlideAnimation ??
                                        AlwaysStoppedAnimation(Offset.zero),
                                    child: Column(
                                      children: [
                                        Text(
                                          'History',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black87,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 60,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.shade400,
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            // content card
                            FadeTransition(
                              opacity:
                                  _historyFadeAnimation ??
                                  AlwaysStoppedAnimation(0.0),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.orange.shade50.withValues(
                                        alpha: 0.3,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Section header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.shade400,
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.timeline,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Journey Through Time',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                'Explore BU\'s rich heritage',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Divider with dots
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.orange.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade400,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.orange.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Timeline preview or loading
                                    _isLoadingTimeline
                                        ? SizedBox(
                                            height: 180,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 40,
                                                    height: 40,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors
                                                              .orange[400],
                                                          strokeWidth: 3,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Loading timeline...',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : _historyTimeline.buildPreviewTimeline(
                                            _timelineData,
                                            3,
                                          ),

                                    const SizedBox(height: 24),

                                    // Action button with icon
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _timelineData.isEmpty
                                            ? null
                                            : _showTimelineDetails,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: _timelineData.isEmpty
                                                ? null
                                                : LinearGradient(
                                                    colors: [
                                                      Colors.orange.shade400,
                                                      Colors.orange.shade600,
                                                    ],
                                                  ),
                                            color: _timelineData.isEmpty
                                                ? Colors.grey[300]
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.explore,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Explore Full Timeline',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (historyImages.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      GridImageGallery(
                                        imageUrls: historyImages,
                                        accentColor: Colors.orange.shade600,
                                        showGalleryText: false,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Featured Locations Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 40,
                        ),
                        child: Column(
                          children: [
                            // Title with decorative elements
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background Icon with glow effect
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.orange.withValues(alpha: 0.15),
                                        Colors.orange.withValues(alpha: 0.03),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.location_city,
                                      size: 90,
                                      color: Colors.orange.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                ),

                                // Title
                                FadeTransition(
                                  opacity:
                                      _featuredFadeAnimation ??
                                      AlwaysStoppedAnimation(0.0),
                                  child: SlideTransition(
                                    position:
                                        _featuredSlideAnimation ??
                                        AlwaysStoppedAnimation(Offset.zero),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Featured Locations',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black87,
                                            letterSpacing: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 60,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.shade400,
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            FadeTransition(
                              opacity:
                                  _featuredFadeAnimation ??
                                  AlwaysStoppedAnimation(0.0),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.orange.shade50.withValues(
                                        alpha: 0.3,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: FeaturedLocationsSection(
                                  height: isLandscape
                                      ? screenHeight * 0.6
                                      : screenHeight * 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // About iTOURu Section
                      _buildEnhancedSection(
                        title: 'About iTOURu',
                        subtitle: 'Your Digital Campus Guide',
                        content:
                            'iTOURu is an interactive campus navigation and tour application designed to help students, visitors, and staff explore Bicol University West Campus seamlessly. Discover academic facilities, buildings, amenities, and key locations all in one comprehensive digital guide.',
                        icon: Icons.info_outline,
                        backgroundIcon: Icons.info,
                        slideAnimation: _aboutSlideAnimation,
                        fadeAnimation: _aboutFadeAnimation,
                        buttonText: 'Learn More',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AboutPage(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20),

                      // Feedback Section
                      FeedbackSection(
                        slideAnimation: _feedbackSlideAnimation,
                        fadeAnimation: _feedbackFadeAnimation,
                      ),

                      SizedBox(height: 20),

                      ExploreSection(
                        slideAnimation: _exploreSlideAnimation,
                        fadeAnimation: _exploreFadeAnimation,
                        mapZoomAnimation: _mapZoomAnimation,
                        onMapTap: _onMapTap,
                      ),

                      SizedBox(height: 20),

                      // Official BU Website Section
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () async {
                            final shouldVisit = await showDialog<bool>(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Icon
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.language,
                                          size: 48,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Title
                                      Text(
                                        'Visit Official Website',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),

                                      // Message
                                      Text(
                                        'You will be redirected to the official Bicol University website at bicol-u.edu.ph',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),

                                      // Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Colors.grey[300]!,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                              ),
                                              child: Text(
                                                'Cancel',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.orange.shade600,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                'Visit',
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

                            if (shouldVisit == true) {
                              final Uri url = Uri.parse(
                                'https://bicol-u.edu.ph/',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.orange.shade400,
                                  Colors.orange.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.language,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Visit Official Website',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'For more information about Bicol University',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 0),
    );
  }
}
