// building_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/video_layout.dart';
import 'package:itouru/page_components/image_layout.dart';
import 'package:itouru/page_components/sticky_header.dart';
import 'package:itouru/page_components/loading_widget.dart';
// Import tab widgets
import 'about.dart';
import 'rooms.dart';

class BuildingDetailsPage extends StatefulWidget {
  final int buildingId; // Required - primary identifier
  final String? buildingName; // Optional - fallback for display
  final String title;

  const BuildingDetailsPage({
    super.key,
    required this.buildingId,
    this.buildingName,
    required this.title,
  });

  @override
  State<BuildingDetailsPage> createState() => _BuildingDetailsPageState();
}

class _BuildingDetailsPageState extends State<BuildingDetailsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Set<String> expandedSections = {};
  Map<String, AnimationController> sectionControllers = {};

  // Data from Supabase
  Map<String, dynamic>? buildingData;
  List<Map<String, dynamic>>? roomsData;
  List<String> buildingVideos = [];
  List<String> buildingImages = [];
  String? headerImageUrl;
  String? logoImageUrl;

  bool isLoading = true;

  // Video carousel controller
  PageController? _videoPageController;
  int _currentVideoPage = 0;
  static const int _infiniteMultiplier = 10000;

  // Gallery carousel controller (no longer infinite)
  PageController? _pageController;

  // Scroll controller for sticky header
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;

  @override
  void initState() {
    super.initState();
    _loadBuildingData();
    _initializeSectionControllers();
    _scrollController.addListener(_onScroll);
  }

  void _initializeSectionControllers() {
    final sections = ['ABOUT', 'ROOMS'];
    for (var section in sections) {
      sectionControllers[section] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
        value: 0.0,
      );
    }
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

  void _onScroll() {
    // Show sticky header when scrolled past 300 pixels
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showStickyHeader) {
      setState(() {
        _showStickyHeader = shouldShow;
      });
    }
  }

  void _initializeVideoPageController() {
    if (buildingVideos.isEmpty || buildingVideos.length == 1) return;

    final initialPage = _infiniteMultiplier * buildingVideos.length;
    _videoPageController = PageController(
      viewportFraction: 0.8,
      initialPage: initialPage,
    );

    _videoPageController!.addListener(() {
      int next = _videoPageController!.page!.round() % buildingVideos.length;
      if (_currentVideoPage != next) {
        setState(() {
          _currentVideoPage = next;
        });
      }
    });
  }

  void _initializePageController() {
    if (buildingImages.isEmpty || buildingImages.length == 1) return;

    // No longer using infinite scrolling
    _pageController = PageController(viewportFraction: 0.8, initialPage: 0);
  }

  // Helper to check if building has rooms
  bool get _hasRooms {
    final buildingType = buildingData?['building_type']
        ?.toString()
        .toLowerCase();
    return buildingType == 'academic' ||
        buildingType == 'non-academic' ||
        buildingType == 'academic and non-academic';
  }

  // Helper to check if ABOUT section has any data
  bool _hasAboutData() {
    final hasDescription =
        buildingData?['description'] != null &&
        buildingData!['description'].toString().trim().isNotEmpty;
    final hasType = buildingData?['building_type'] != null;
    final hasFloors = buildingData?['calculated_floors'] != null;
    final hasRoomsCount = roomsData != null && roomsData!.isNotEmpty;

    return hasDescription || hasType || hasFloors || hasRoomsCount;
  }

  Future<void> _loadBuildingData() async {
    try {
      setState(() => isLoading = true);

      // Fetch Building data with College information using JOIN
      final response = await supabase
          .from('Building')
          .select('*, College(*)')
          .eq('building_id', widget.buildingId)
          .single();

      // Only fetch rooms if building type is academic, non-academic, or both
      List<Map<String, dynamic>> fetchedRooms = [];
      int? maxFloor;

      final buildingType = response['building_type']?.toString().toLowerCase();
      final shouldFetchRooms =
          buildingType == 'academic' ||
          buildingType == 'non-academic' ||
          buildingType == 'academic and non-academic';

      if (shouldFetchRooms) {
        // Fetch Rooms data - ordered by floor_level and room_number
        final roomsResponse = await supabase
            .from('Room')
            .select('*')
            .eq('building_id', widget.buildingId)
            .order('floor_level', ascending: true)
            .order('room_number', ascending: true);

        fetchedRooms = List<Map<String, dynamic>>.from(roomsResponse);

        // Calculate max floor level from rooms data
        if (roomsResponse.isNotEmpty) {
          maxFloor = roomsResponse
              .map((room) => room['floor_level'] as int?)
              .where((floor) => floor != null)
              .fold<int?>(
                null,
                (max, floor) =>
                    max == null ? floor : (floor! > max ? floor : max),
              );
        }
      }

      // Determine building folder names (try both building_name and nickname)
      final buildingFolderName = response['building_name']
          ?.toString()
          .toLowerCase()
          .replaceAll('.', '')
          .replaceAll(' ', '-')
          .trim();

      final nicknameFolderName = response['building_nickname']
          ?.toString()
          .toLowerCase()
          .replaceAll('.', '')
          .replaceAll(' ', '-')
          .trim();

      // Create list of possible folder names to check
      List<String> possibleFolderNames = [];
      if (buildingFolderName != null)
        possibleFolderNames.add(buildingFolderName);
      if (nicknameFolderName != null &&
          nicknameFolderName != buildingFolderName) {
        possibleFolderNames.add(nicknameFolderName);
      }
      // Fallback to widget.buildingName if both are null
      if (possibleFolderNames.isEmpty && widget.buildingName != null) {
        possibleFolderNames.add(
          widget.buildingName!
              .toLowerCase()
              .replaceAll('.', '')
              .replaceAll(' ', '-')
              .trim(),
        );
      }

      print('🏢 Possible Building Folder Names: $possibleFolderNames');

      List<String> videoUrls = [];
      List<String> imageUrls = [];
      String? fetchedHeaderUrl;
      String? fetchedLogoUrl;

      if (possibleFolderNames.isNotEmpty) {
        // Try each possible folder name until we find videos
        print('📹 Fetching videos from folders: $possibleFolderNames');
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
            print('✅ Found videos in folder: $folderName');
            break;
          }
        }

        print('📹 Videos Response Length: ${videosResponse.length}');
        for (var videoData in videosResponse) {
          final videoPath = videoData['name'] as String;
          final filename = videoData['filename'] as String;

          print('📹 Found video - Path: $videoPath, Filename: $filename');

          // Skip placeholder files
          if (filename == '.emptyFolderPlaceholder' ||
              videoPath.endsWith('.emptyFolderPlaceholder')) {
            print('⏭️ Skipping placeholder video: $filename');
            continue;
          }

          final publicUrl = supabase.storage
              .from('videos')
              .getPublicUrl(videoPath);
          print('✅ Added video URL: $publicUrl');
          videoUrls.add(publicUrl);
        }
        print('📹 Total videos added: ${videoUrls.length}');

        // Try each possible folder name until we find images
        print('🖼️ Fetching images from folders: $possibleFolderNames');
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
            print('✅ Found images in folder: $folderName');
            break;
          }
        }

        print('🖼️ Images Response Length: ${imagesResponse.length}');
        for (var i = 0; i < imagesResponse.length; i++) {
          final imageData = imagesResponse[i];
          final imagePath = imageData['name'] as String;
          final filename = imageData['filename'] as String;

          print('🖼️ Found image - Path: $imagePath, Filename: $filename');

          // Skip placeholder files and logo files
          if (filename == '.emptyFolderPlaceholder' ||
              imagePath.endsWith('.emptyFolderPlaceholder') ||
              filename.contains('_logo')) {
            print('⏭️ Skipping: $filename');
            continue;
          }

          final publicUrl = supabase.storage
              .from('images')
              .getPublicUrl(imagePath);

          // Set the first image as header
          if (fetchedHeaderUrl == null) {
            fetchedHeaderUrl = publicUrl;
            print('🎯 Set as header image: $publicUrl');
          }

          print('✅ Added image URL: $publicUrl');
          imageUrls.add(publicUrl);
        }
        print('🖼️ Total images added: ${imageUrls.length}');

        // Try each possible folder name until we find a building logo
        print('🏷️ Fetching building logo from folders: $possibleFolderNames');
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
              print(
                '✅ Building logo found in folder $folderName: $fetchedLogoUrl',
              );
              break; // Stop searching once logo is found
            }
          } catch (e) {
            print('⚠️ No logo in folder $folderName: $e');
          }
        }

        if (fetchedLogoUrl == null) {
          print('❌ No building logo found in any folder');
        }

        // If no building logo found, try to fetch college logo as fallback
        if (fetchedLogoUrl == null && response['College'] != null) {
          print('🏫 No building logo - Checking for college logo');
          final collegeName = response['College']['college_name'] as String?;
          final collegeAbbr =
              response['College']['college_abbreviation'] as String?;

          // Create list of possible college folder names
          List<String> collegeFolderNames = [];

          if (collegeName != null) {
            final nameFolderName = collegeName
                .toLowerCase()
                .replaceAll(' ', '-')
                .replaceAll('college of', 'college-of')
                .trim();
            collegeFolderNames.add(nameFolderName);
          }

          if (collegeAbbr != null) {
            final abbrFolderName = collegeAbbr
                .toLowerCase()
                .replaceAll(' ', '-')
                .trim();
            if (!collegeFolderNames.contains(abbrFolderName)) {
              collegeFolderNames.add(abbrFolderName);
            }
          }

          print('🏫 Possible college folder names: $collegeFolderNames');

          // Try each possible college folder name
          for (var collegeFolderName in collegeFolderNames) {
            try {
              final collegeLogoResponse = await supabase
                  .from('storage_objects_snapshot')
                  .select('name, filename')
                  .eq('bucket_id', 'images')
                  .eq('folder', collegeFolderName)
                  .like('filename', '%_logo%')
                  .maybeSingle();

              if (collegeLogoResponse != null) {
                final collegeLogoPath = collegeLogoResponse['name'] as String;
                fetchedLogoUrl = supabase.storage
                    .from('images')
                    .getPublicUrl(collegeLogoPath);
                print(
                  '✅ College logo found in folder $collegeFolderName: $fetchedLogoUrl',
                );
                break; // Stop searching once logo is found
              }
            } catch (e) {
              print('⚠️ No college logo in folder $collegeFolderName: $e');
            }
          }

          if (fetchedLogoUrl == null) {
            print('❌ No college logo found in any folder');
          }
        }
      }

      setState(() {
        buildingData = response;
        roomsData = fetchedRooms;
        buildingVideos = videoUrls;
        buildingImages = imageUrls;
        headerImageUrl = fetchedHeaderUrl;
        logoImageUrl = fetchedLogoUrl;
        // Store calculated max floor in buildingData for easy access
        if (maxFloor != null) {
          buildingData!['calculated_floors'] = maxFloor;
        }
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
      print('❌ Error loading building data: $e');
      setState(() => isLoading = false);
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show full screen loading animation
    if (isLoading) {
      return LoadingScreen.dots(
        title: ' ${widget.title}',
        subtitle: 'Please wait',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Background image + card
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 450,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        image: DecorationImage(
                          image: headerImageUrl != null
                              ? NetworkImage(headerImageUrl!) as ImageProvider
                              : const AssetImage(
                                  'assets/images/default_building.png',
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
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 150,
                      child: _buildBuildingCard(),
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
                      // Display building videos
                      if (buildingVideos.isNotEmpty) ...[
                        VideoLayout(
                          videoUrls: buildingVideos,
                          pageController: _videoPageController,
                        ),
                        const SizedBox(height: 30),
                      ],
                      // Display building images with carousel
                      if (buildingImages.isNotEmpty) ...[
                        ImageLayout(
                          imageUrls: buildingImages,
                          pageController: _pageController,
                        ),
                        const SizedBox(height: 30),
                      ],
                      // Only show ABOUT section if there's data
                      if (_hasAboutData()) ...[
                        _buildExpandableSection(
                          'ABOUT',
                          '${buildingData?['building_name'] ?? widget.title}\'s Information',
                          BuildingAboutTab(
                            buildingId: widget.buildingId,
                            buildingName: widget.title,
                            buildingType: buildingData?['building_type'],
                            description: buildingData?['description'],
                            numberOfFloors: buildingData?['calculated_floors'],
                            numberOfRooms: roomsData?.length ?? 0,
                            hasRooms: _hasRooms,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                      // Only show ROOMS section if building has rooms
                      if (_hasRooms &&
                          roomsData != null &&
                          roomsData!.isNotEmpty) ...[
                        _buildExpandableSection(
                          'ROOMS',
                          '${buildingData?['building_name'] ?? widget.title}\'s Rooms',
                          BuildingRoomsTab(rooms: roomsData ?? []),
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
            abbreviation: buildingData?['building_nickname'],
            logoImageUrl: logoImageUrl,
            showLogo: logoImageUrl != null,
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBuildingCard() {
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
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: logoImageUrl != null
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          // Only show icon/logo if logoImageUrl exists
          if (logoImageUrl != null) ...[
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
                  child: Image.network(
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
                        Icons.business,
                        color: Colors.blue[900],
                        size: 35,
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ] else
            Flexible(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
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
                            fontSize: 36,
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
        color: Colors.black.withOpacity(0.5),
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
