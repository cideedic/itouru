// college_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/video_layout.dart';
import 'package:itouru/page_components/image_layout.dart';
import 'package:itouru/page_components/sticky_header.dart';
import 'package:itouru/page_components/loading_widget.dart';
// Import your content widgets
import 'about.dart';
import 'programs.dart';
import 'buildings.dart';

class CollegeDetailsPage extends StatefulWidget {
  final int collegeId;
  final String? collegeName;
  final String title;

  const CollegeDetailsPage({
    super.key,
    required this.collegeId,
    this.collegeName,
    required this.title,
  });

  @override
  State<CollegeDetailsPage> createState() => _CollegeDetailsPageState();
}

class _CollegeDetailsPageState extends State<CollegeDetailsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Set<String> expandedSections = {};
  Map<String, AnimationController> sectionControllers = {};

  Map<String, dynamic>? collegeData;
  Map<String, dynamic>? headData;
  List<Map<String, dynamic>>? programsData;
  List<Map<String, dynamic>>? buildingsData;
  Map<String, List<Map<String, dynamic>>> roomsByBuilding = {};
  List<String> collegeVideos = [];
  List<String> collegeImages = [];
  String? headerImageUrl;
  String? logoImageUrl;
  String? headImageUrl;

  bool isLoading = true;

  // Video carousel controller
  PageController? _videoPageController;
  int _currentVideoPage = 0;
  static const int _infiniteMultiplier = 10000;

  // Gallery carousel controller
  PageController? _pageController;

  // Scroll controller for sticky header
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;

  @override
  void initState() {
    super.initState();
    _loadCollegeData();
    _initializeSectionControllers();
    _scrollController.addListener(_onScroll);
  }

  // Add this helper method to check if ABOUT section has any data
  bool _hasAboutData() {
    final hasDescription =
        collegeData?['college_about'] != null &&
        collegeData!['college_about'].toString().trim().isNotEmpty;
    final hasLearningOutcomes =
        collegeData?['learning_outcome'] != null &&
        collegeData!['learning_outcome'].toString().trim().isNotEmpty;
    final hasObjectives =
        collegeData?['objectives'] != null &&
        collegeData!['objectives'].toString().trim().isNotEmpty;
    final hasHeadData = headData != null && headData!.isNotEmpty;

    return hasDescription ||
        hasLearningOutcomes ||
        hasObjectives ||
        hasHeadData;
  }

  void _onScroll() {
    // Show sticky header when scrolled past 300 pixels
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showStickyHeader) {
      setState(() {
        _showStickyHeader = shouldShow;
      });
    }
  }

  void _initializeSectionControllers() {
    final sections = ['ABOUT', 'PROGRAMS', 'BUILDINGS'];
    for (var section in sections) {
      sectionControllers[section] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
        value: 0.0,
      );
    }
  }

  void _initializeVideoPageController() {
    if (collegeVideos.isEmpty || collegeVideos.length == 1) return;

    final initialPage = _infiniteMultiplier * collegeVideos.length;
    _videoPageController = PageController(
      viewportFraction: 0.8,
      initialPage: initialPage,
    );

    _videoPageController!.addListener(() {
      int next = _videoPageController!.page!.round() % collegeVideos.length;
      if (_currentVideoPage != next) {
        setState(() {
          _currentVideoPage = next;
        });
      }
    });
  }

  void _initializePageController() {
    if (collegeImages.isEmpty || collegeImages.length == 1) return;

    // No longer using infinite scrolling
    _pageController = PageController(viewportFraction: 0.8, initialPage: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_videoPageController != null) {
      _videoPageController!.dispose();
    }
    if (_pageController != null) {
      _pageController!.dispose();
    }
    for (var controller in sectionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCollegeData() async {
    try {
      setState(() => isLoading = true);

      final response = await supabase
          .from('College')
          .select('*, Head(*)')
          .eq('college_id', widget.collegeId)
          .single()
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      // Fetch Programs data
      final programsResponse = await supabase
          .from('Program')
          .select('*')
          .eq('college_id', widget.collegeId)
          .order('program_type', ascending: true)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      // Fetch Buildings data
      final buildingsResponse = await supabase
          .from('Building')
          .select('*')
          .eq('college_id', widget.collegeId)
          .order('building_name', ascending: true)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      // Fetch Rooms data for all buildings
      Map<String, List<Map<String, dynamic>>> roomsMap = {};
      if (buildingsResponse.isNotEmpty) {
        final roomsResponse = await supabase
            .from('Room')
            .select('*')
            .inFilter(
              'building_id',
              buildingsResponse.map((b) => b['building_id']).toList(),
            )
            .order('floor_level', ascending: true)
            .order('room_number', ascending: true)
            .timeout(
              Duration(seconds: 15),
              onTimeout: () => throw Exception('Connection timeout'),
            );

        for (var room in roomsResponse) {
          final buildingId = room['building_id'].toString();
          if (!roomsMap.containsKey(buildingId)) {
            roomsMap[buildingId] = [];
          }
          roomsMap[buildingId]!.add(room);
        }
      }

      // Determine college folder names
      final collegeFolderName = response['college_name']
          ?.toString()
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll('college of', 'college-of')
          .trim();

      final abbreviationFolderName = response['college_abbreviation']
          ?.toString()
          .toLowerCase()
          .replaceAll(' ', '-')
          .trim();

      // Create list of possible folder names to check
      List<String> possibleFolderNames = [];
      if (collegeFolderName != null) possibleFolderNames.add(collegeFolderName);
      if (abbreviationFolderName != null &&
          abbreviationFolderName != collegeFolderName) {
        possibleFolderNames.add(abbreviationFolderName);
      }
      // Fallback to widget.collegeName if both are null
      if (possibleFolderNames.isEmpty && widget.collegeName != null) {
        possibleFolderNames.add(
          widget.collegeName!
              .toLowerCase()
              .replaceAll(' ', '-')
              .replaceAll('college of', 'college-of')
              .trim(),
        );
      }

      List<String> videoUrls = [];
      List<String> imageUrls = [];
      String? fetchedHeaderUrl;
      String? fetchedLogoUrl;

      if (possibleFolderNames.isNotEmpty) {
        // Try each possible folder name until we find videos
        List<dynamic> videosResponse = [];

        for (var folderName in possibleFolderNames) {
          final response = await supabase
              .from('storage_objects_snapshot')
              .select('name, filename')
              .eq('bucket_id', 'videos')
              .eq('folder', folderName)
              .order('filename', ascending: true);

          if (response.isNotEmpty) {
            videosResponse = response;
            break;
          }
        }

        for (var videoData in videosResponse) {
          final videoPath = videoData['name'] as String;
          final filename = videoData['filename'] as String;

          // Skip placeholder files
          if (filename == '.emptyFolderPlaceholder' ||
              videoPath.endsWith('.emptyFolderPlaceholder')) {
            continue;
          }

          final publicUrl = supabase.storage
              .from('videos')
              .getPublicUrl(videoPath);
          videoUrls.add(publicUrl);
        }

        // Try each possible folder name until we find images
        List<dynamic> imagesResponse = [];

        for (var folderName in possibleFolderNames) {
          final response = await supabase
              .from('storage_objects_snapshot')
              .select('name, filename')
              .eq('bucket_id', 'images')
              .eq('folder', folderName)
              .order('filename', ascending: true);

          if (response.isNotEmpty) {
            imagesResponse = response;
            break;
          }
        }
        for (var i = 0; i < imagesResponse.length; i++) {
          final imageData = imagesResponse[i];
          final imagePath = imageData['name'] as String;
          final filename = imageData['filename'] as String;

          // Skip placeholder files and logo files
          if (filename == '.emptyFolderPlaceholder' ||
              imagePath.endsWith('.emptyFolderPlaceholder') ||
              filename.contains('_logo')) {
            continue;
          }

          final publicUrl = supabase.storage
              .from('images')
              .getPublicUrl(imagePath);

          // Set the first image as header
          fetchedHeaderUrl ??= publicUrl;

          imageUrls.add(publicUrl);
        }

        // Try each possible folder name until we find a logo
        for (var folderName in possibleFolderNames) {
          try {
            final logoResponse = await supabase
                .from('storage_objects_snapshot')
                .select('name, filename')
                .eq('bucket_id', 'images')
                .eq('folder', folderName)
                .like('filename', '%_logo%')
                .maybeSingle();

            if (logoResponse != null) {
              final logoPath = logoResponse['name'] as String;
              fetchedLogoUrl = supabase.storage
                  .from('images')
                  .getPublicUrl(logoPath);

              break; // Stop searching once logo is found
            }
          } catch (e) {
            // No logo found in this folder, continue to next
          }
        }
      }

      // Fetch head official image
      String? fetchedHeadImageUrl;
      if (response['Head'] != null) {
        final headId = response['Head']['head_id'];
        final firstName = response['Head']['first_name']
            ?.toString()
            .toLowerCase();
        final lastName = response['Head']['last_name']
            ?.toString()
            .toLowerCase();

        if (headId != null || (firstName != null && lastName != null)) {
          try {
            // Build list of possible naming patterns
            final possiblePatterns = <String>[];

            // Add head_id patterns
            if (headId != null) {
              possiblePatterns.addAll([
                'heads/head_$headId',
                'heads/head_${headId}_profile',
                'heads/$headId',
              ]);
            }

            // Add firstname-lastname patterns
            if (firstName != null && lastName != null) {
              // Normalize names: replace ñ with n, replace spaces with hyphens
              final firstNormalized = firstName
                  .replaceAll('ñ', 'n')
                  .replaceAll(' ', '-')
                  .trim();
              final firstNoSpaces = firstName
                  .replaceAll('ñ', 'n')
                  .replaceAll(' ', '')
                  .trim();
              final lastNormalized = lastName
                  .replaceAll('ñ', 'n')
                  .replaceAll(' ', '-')
                  .trim();
              final lastNoSpaces = lastName
                  .replaceAll('ñ', 'n')
                  .replaceAll(' ', '')
                  .trim();

              possiblePatterns.addAll([
                // With hyphens between words
                'heads/$firstNormalized-$lastNormalized',
                'heads/$lastNormalized-$firstNormalized',
                // Without spaces (johncedrick-doe)
                'heads/$firstNoSpaces-$lastNormalized',
                'heads/$lastNormalized-$firstNoSpaces',
                // With underscores
                'heads/${firstNormalized}_$lastNormalized',
                'heads/${lastNormalized}_$firstNormalized',
                'heads/${firstNoSpaces}_$lastNormalized',
                'heads/${lastNormalized}_$firstNoSpaces',
                // All no spaces
                'heads/$firstNoSpaces-$lastNoSpaces',
                'heads/$lastNoSpaces-$firstNoSpaces',
              ]);
            }

            for (var pattern in possiblePatterns) {
              try {
                final headImageResponse = await supabase
                    .from('storage_objects_snapshot')
                    .select('name')
                    .eq('bucket_id', 'images')
                    .like('name', '$pattern%')
                    .maybeSingle();

                if (headImageResponse != null) {
                  final headImagePath = headImageResponse['name'] as String;
                  fetchedHeadImageUrl = supabase.storage
                      .from('images')
                      .getPublicUrl(headImagePath);
                  break; // Stop searching once found
                }
              } catch (e) {
                // Continue to next pattern
              }
            }
          } catch (e) {
            // Error fetching head image, will use default
          }
        }
      }

      setState(() {
        collegeData = response;
        headData = response['Head'];
        programsData = List<Map<String, dynamic>>.from(programsResponse);
        buildingsData = List<Map<String, dynamic>>.from(buildingsResponse);
        roomsByBuilding = roomsMap;
        collegeVideos = videoUrls;
        collegeImages = imageUrls;
        headerImageUrl = fetchedHeaderUrl;
        logoImageUrl = fetchedLogoUrl;
        headImageUrl = fetchedHeadImageUrl;
        isLoading = false;
      });

      // Initialize controllers after data is loaded
      if (videoUrls.length > 1) {
        _initializeVideoPageController();
      }
      if (imageUrls.length > 1) {
        _initializePageController();
      }
    } catch (e) {
      setState(() => isLoading = false);
      // User-friendly error handling
      if (mounted) {
        String errorMsg = 'Unable to load college information.';

        if (e.toString().contains('timeout') ||
            e.toString().contains('Connection timeout')) {
          errorMsg =
              'Connection is taking too long. Please check your internet.';
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('network')) {
          errorMsg = 'No internet connection. Please check your network.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadCollegeData(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? LoadingScreen.dots(title: ' ${widget.title}', subtitle: 'Please wait')
        : Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 480,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              image: DecorationImage(
                                image: headerImageUrl != null
                                    ? NetworkImage(headerImageUrl!)
                                          as ImageProvider
                                    : const AssetImage(
                                        'assets/images/default_college.jpg',
                                      ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.black.withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: 150,
                            child: _buildCollegeCard(),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 0,
                            left: 16,
                            child: SafeArea(child: _buildBackButton(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        child: Column(
                          children: [
                            // Display college videos
                            if (collegeVideos.isNotEmpty) ...[
                              VideoLayout(
                                videoUrls: collegeVideos,
                                pageController: _videoPageController,
                              ),
                              const SizedBox(height: 30),
                            ],
                            // Display college images with carousel
                            if (collegeImages.isNotEmpty) ...[
                              ImageLayout(
                                imageUrls: collegeImages,
                                pageController: _pageController,
                              ),
                              const SizedBox(height: 30),
                            ],

                            // Only show ABOUT section if there's data
                            if (_hasAboutData()) ...[
                              _buildExpandableSection(
                                'ABOUT',
                                '${collegeData?['college_name'] ?? widget.title}\'s Purpose',
                                AboutTab(
                                  description:
                                      collegeData?['college_about'] ?? '',
                                  learningOutcomes:
                                      collegeData?['learning_outcome'] ?? '',
                                  objectives: collegeData?['objectives'] ?? '',
                                  headData: headData,
                                  headImageUrl: headImageUrl,
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],

                            // Only show PROGRAMS section if there's data
                            if (programsData != null &&
                                programsData!.isNotEmpty) ...[
                              _buildExpandableSection(
                                'PROGRAMS',
                                '${collegeData?['college_name'] ?? widget.title}\'s Offered Programs',
                                ProgramsTab(programs: programsData ?? []),
                              ),
                              const SizedBox(height: 30),
                            ],

                            // Only show BUILDINGS section if there's data
                            if (buildingsData != null &&
                                buildingsData!.isNotEmpty) ...[
                              _buildExpandableSection(
                                'BUILDINGS',
                                '${collegeData?['college_name'] ?? widget.title}\'s Buildings',
                                BuildingsTab(
                                  buildings: buildingsData ?? [],
                                  roomsByBuilding: roomsByBuilding,
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                StickyHeader(
                  isVisible: _showStickyHeader,
                  title: widget.title,
                  abbreviation: collegeData?['college_abbreviation'],
                  logoImageUrl: logoImageUrl,
                ),
              ],
            ),
            bottomNavigationBar: ReusableBottomNavBar(currentIndex: 1),
          );
  }

  Widget _buildCollegeCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.42, 0.85],
          colors: [
            Color(0xFF203BE6).withValues(alpha: 0.45),
            Color(0xFF1A31C8).withValues(alpha: 0.8),
            Color(0xFF060870).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: logoImageUrl != null
                    ? Image.network(
                        logoImageUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1A31C8),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.school,
                            color: Colors.blue,
                            size: 35,
                          );
                        },
                      )
                    : Icon(Icons.school, color: Colors.blue, size: 35),
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Text(
              widget.title,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    String title,
    String subtitle,
    Widget content,
  ) {
    bool isExpanded = expandedSections.contains(title);
    final controller = sectionControllers[title];

    if (controller != null) {
      if (isExpanded) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedSections.remove(title);
                } else {
                  expandedSections.add(title);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (controller != null)
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: controller,
                curve: Curves.easeOutCubic,
              ),
              child: FadeTransition(
                opacity: controller,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCEEDB),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        },
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
      ),
    );
  }
}
