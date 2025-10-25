// college_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:video_player/video_player.dart';
// Import your content widgets
import 'about.dart';
import 'history.dart';
import 'programs.dart';
import 'buildings.dart';

class CollegeDetailsPage extends StatefulWidget {
  final int collegeId; // Required - primary identifier
  final String? collegeName; // Optional - fallback for display
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

  // Data from Supabase
  Map<String, dynamic>? collegeData;
  Map<String, dynamic>? headData;
  List<Map<String, dynamic>>? historyData;
  List<Map<String, dynamic>>? programsData;
  List<Map<String, dynamic>>? buildingsData;
  Map<String, List<Map<String, dynamic>>> roomsByBuilding = {};
  List<String> collegeVideos = [];
  List<String> collegeImages = [];
  String? headerImageUrl;
  String? logoImageUrl;

  bool isLoading = true;

  // Video carousel controller
  PageController? _videoPageController;
  int _currentVideoPage = 0;
  static const int _infiniteMultiplier = 10000;

  // Gallery carousel controller
  PageController? _pageController;
  int _currentPage = 0;

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

  void _onScroll() {
    // Show sticky header when scrolled past 300 pixels (approximately when card is out of view)
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showStickyHeader) {
      setState(() {
        _showStickyHeader = shouldShow;
      });
    }
  }

  void _initializeSectionControllers() {
    final sections = ['ABOUT', 'HISTORY', 'PROGRAMS', 'BUILDINGS'];
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

    final initialPage = _infiniteMultiplier * collegeImages.length;
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: initialPage,
    );

    _pageController!.addListener(() {
      int next = _pageController!.page!.round() % collegeImages.length;
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
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

      // Fetch College data with Head information using JOIN
      final response = await supabase
          .from('College')
          .select('*, Head(*)')
          .eq('college_id', widget.collegeId)
          .single();

      // Fetch History data
      final historyResponse = await supabase
          .from('History')
          .select('*')
          .eq('college_id', widget.collegeId)
          .order('date', ascending: true);

      // Fetch Programs data
      final programsResponse = await supabase
          .from('Program')
          .select('*')
          .eq('college_id', widget.collegeId)
          .order('program_type', ascending: true);

      // Fetch Buildings data
      final buildingsResponse = await supabase
          .from('Building')
          .select('*')
          .eq('college_id', widget.collegeId)
          .order('building_name', ascending: true);

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
            .order('room_number', ascending: true);

        for (var room in roomsResponse) {
          final buildingId = room['building_id'].toString();
          if (!roomsMap.containsKey(buildingId)) {
            roomsMap[buildingId] = [];
          }
          roomsMap[buildingId]!.add(room);
        }
      }

      // Determine college folder name
      final collegeFolderName =
          response['college_name']
              ?.toString()
              .toLowerCase()
              .replaceAll(' ', '-')
              .replaceAll('college of', 'college-of')
              .trim() ??
          widget.collegeName
              ?.toLowerCase()
              .replaceAll(' ', '-')
              .replaceAll('college of', 'college-of')
              .trim();

      List<String> videoUrls = [];
      List<String> imageUrls = [];
      String? fetchedHeaderUrl;
      String? fetchedLogoUrl;

      if (collegeFolderName != null) {
        // Fetch videos from 'videos' bucket
        final videosResponse = await supabase
            .from('storage_objects_snapshot')
            .select('name, filename')
            .eq('bucket_id', 'videos')
            .eq('folder', collegeFolderName)
            .order('filename', ascending: true);

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

        // Fetch images from 'images' bucket
        final imagesResponse = await supabase
            .from('storage_objects_snapshot')
            .select('name, filename')
            .eq('bucket_id', 'images')
            .eq('folder', collegeFolderName)
            .order('filename', ascending: true);

        for (var i = 0; i < imagesResponse.length; i++) {
          final imageData = imagesResponse[i];
          final imagePath = imageData['name'] as String;
          final filename = imageData['filename'] as String;

          // Skip placeholder files
          if (filename == '.emptyFolderPlaceholder' ||
              imagePath.endsWith('.emptyFolderPlaceholder')) {
            continue;
          }

          final publicUrl = supabase.storage
              .from('images')
              .getPublicUrl(imagePath);

          if (i == 0) {
            fetchedHeaderUrl = publicUrl;
          }

          imageUrls.add(publicUrl);
        }

        // Fetch logo from 'logos' bucket
        final logoResponse = await supabase
            .from('storage_objects_snapshot')
            .select('name')
            .eq('bucket_id', 'logos')
            .eq('folder', collegeFolderName)
            .maybeSingle();

        if (logoResponse != null) {
          final logoPath = logoResponse['name'] as String;
          fetchedLogoUrl = supabase.storage
              .from('logos')
              .getPublicUrl(logoPath);
        }
      }

      setState(() {
        collegeData = response;
        headData = response['Head'];
        historyData = List<Map<String, dynamic>>.from(historyResponse);
        programsData = List<Map<String, dynamic>>.from(programsResponse);
        buildingsData = List<Map<String, dynamic>>.from(buildingsResponse);
        roomsByBuilding = roomsMap;
        collegeVideos = videoUrls;
        collegeImages = imageUrls;
        headerImageUrl = fetchedHeaderUrl;
        logoImageUrl = fetchedLogoUrl;
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1A31C8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading ${widget.title}...',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A31C8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
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
                                    ? NetworkImage(headerImageUrl!)
                                          as ImageProvider
                                    : const AssetImage(
                                        'assets/images/default_college.png',
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
                          horizontal: 0,
                          vertical: 0,
                        ),
                        child: Column(
                          children: [
                            // Display college videos
                            if (collegeVideos.isNotEmpty) ...[
                              collegeVideos.length == 1
                                  ? _buildSingleVideo()
                                  : _buildVideoCarousel(),
                              const SizedBox(height: 30),
                            ],
                            // Display college images with carousel
                            if (collegeImages.isNotEmpty) ...[
                              collegeImages.length == 1
                                  ? _buildSingleImage()
                                  : _buildCarouselGallery(),
                              const SizedBox(height: 30),
                            ],
                            _buildExpandableSection(
                              'ABOUT',
                              '${collegeData?['college_name'] ?? widget.title}\'s Purpose',
                              AboutTab(
                                description:
                                    collegeData?['college_about'] ?? '',
                                vision: collegeData?['vision'] ?? '',
                                mission: collegeData?['mission'] ?? '',
                                goals: collegeData?['goals'] ?? '',
                                objectives: collegeData?['objectives'] ?? '',
                                headData: headData,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildExpandableSection(
                              'HISTORY',
                              '${collegeData?['college_name'] ?? widget.title}\'s Timeline',
                              HistoryTab(historyEntries: historyData ?? []),
                            ),
                            const SizedBox(height: 30),
                            _buildExpandableSection(
                              'PROGRAMS',
                              '${collegeData?['college_name'] ?? widget.title}\'s Offered Programs',
                              ProgramsTab(programs: programsData ?? []),
                            ),
                            const SizedBox(height: 30),
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
                        ),
                      ),
                    ],
                  ),
                ),
          // Sticky Header
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            top: _showStickyHeader ? 0 : -135,
            left: 0,
            right: 0,
            child: _buildStickyHeader(),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: EdgeInsets.only(top: 12, bottom: 14, left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.42, 0.85],
          colors: [
            Color(0xFF203BE6).withValues(alpha: 0.95),
            Color(0xFF1A31C8).withValues(alpha: 0.95),
            Color(0xFF060870).withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: logoImageUrl != null
                      ? Image.network(
                          logoImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.school,
                              color: Colors.blue,
                              size: 25,
                            );
                          },
                        )
                      : Icon(Icons.school, color: Colors.blue, size: 25),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
                fontSize: 20,
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

  Widget _buildSingleVideo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VIDEO',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A31C8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showVideoDialog(collegeVideos[0]),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoThumbnail(videoUrl: collegeVideos[0]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GALLERY',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A31C8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showImageDialog(collegeImages[0]),
            child: Container(
              height: 325,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      collegeImages[0],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF1A31C8),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
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
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
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

  Widget _buildVideoCarousel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VIDEOS',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A31C8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _videoPageController,
              scrollDirection: Axis.horizontal,
              itemCount: null,
              itemBuilder: (context, index) {
                final actualIndex = index % collegeVideos.length;
                return _buildVideoCarouselItem(actualIndex, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCarouselItem(int actualIndex, int virtualIndex) {
    return AnimatedBuilder(
      animation: _videoPageController!,
      builder: (context, child) {
        double scale = 1.0;
        double opacity = 1.0;

        if (_videoPageController!.position.haveDimensions) {
          double page = _videoPageController!.page ?? virtualIndex.toDouble();
          double distance = (page - virtualIndex).abs();

          if (distance < 1.0) {
            scale = 1.0 - (distance * 0.15);
            opacity = 1.0 - (distance * 0.6);
          } else {
            scale = 0.85;
            opacity = 0.4;
          }
        }

        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: child,
              ),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showVideoDialog(collegeVideos[actualIndex]),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VideoThumbnail(videoUrl: collegeVideos[actualIndex]),
          ),
        ),
      ),
    );
  }

  void _showVideoDialog(String videoUrl) {
    final int initialIndex = collegeVideos.indexOf(videoUrl);
    showDialog(
      context: context,
      builder: (context) => VideoPlayerCarouselDialog(
        videoUrls: collegeVideos,
        initialIndex: initialIndex,
      ),
    );
  }

  Widget _buildCarouselGallery() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GALLERY',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A31C8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 325,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: null,
              itemBuilder: (context, index) {
                final actualIndex = index % collegeImages.length;
                return _buildCarouselItem(actualIndex, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(int actualIndex, int virtualIndex) {
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (context, child) {
        double scale = 1.0;
        double opacity = 1.0;

        if (_pageController!.position.haveDimensions) {
          double page = _pageController!.page ?? virtualIndex.toDouble();
          double distance = (page - virtualIndex).abs();

          if (distance < 1.0) {
            scale = 1.0 - (distance * 0.15);
            opacity = 1.0 - (distance * 0.6);
          } else {
            scale = 0.85;
            opacity = 0.4;
          }
        }

        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: child,
              ),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showImageDialog(collegeImages[actualIndex]),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  collegeImages[actualIndex],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF1A31C8),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
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
                        Colors.black.withValues(alpha: 0.5),
                      ],
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

  void _showImageDialog(String imageUrl) {
    final int initialIndex = collegeImages.indexOf(imageUrl);
    showDialog(
      context: context,
      builder: (context) => ImageCarouselDialog(
        imageUrls: collegeImages,
        initialIndex: initialIndex,
      ),
    );
  }
}

// Image Carousel Dialog Widget
class ImageCarouselDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageCarouselDialog({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<ImageCarouselDialog> createState() => _ImageCarouselDialogState();
}

class _ImageCarouselDialogState extends State<ImageCarouselDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF1A31C8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          // Previous button
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _previousImage,
                  ),
                ),
              ),
            ),
          // Next button
          if (_currentIndex < widget.imageUrls.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _nextImage,
                  ),
                ),
              ),
            ),
          // Close button
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Page indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Video Thumbnail Widget
class VideoThumbnail extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnail({super.key, required this.videoUrl});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeThumbnail();
  }

  Future<void> _initializeThumbnail() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      await _controller.seekTo(const Duration(seconds: 1));
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_hasError)
          Container(
            color: Colors.black,
            child: Center(
              child: Icon(
                Icons.video_library,
                size: 80,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          )
        else if (!_isInitialized)
          Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: const Color(0xFF1A31C8)),
            ),
          )
        else
          VideoPlayer(_controller),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 80,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// Video Player Dialog Widget (for single video)
class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _hasError
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading video',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : !_isInitialized
                    ? Container(
                        padding: const EdgeInsets.all(60),
                        child: CircularProgressIndicator(
                          color: const Color(0xFF1A31C8),
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                  }
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: AnimatedOpacity(
                                    opacity: _controller.value.isPlaying
                                        ? 0.0
                                        : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _controller.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: const Color(0xFF1A31C8),
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.3,
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
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Video Player Carousel Dialog Widget (for multiple videos)
class VideoPlayerCarouselDialog extends StatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;

  const VideoPlayerCarouselDialog({
    super.key,
    required this.videoUrls,
    required this.initialIndex,
  });

  @override
  State<VideoPlayerCarouselDialog> createState() =>
      _VideoPlayerCarouselDialogState();
}

class _VideoPlayerCarouselDialogState extends State<VideoPlayerCarouselDialog> {
  late PageController _pageController;
  late int _currentIndex;
  Map<int, VideoPlayerController> _controllers = {};
  Map<int, bool> _initialized = {};
  Map<int, bool> _errors = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideo(_currentIndex);
  }

  Future<void> _initializeVideo(int index) async {
    if (_controllers.containsKey(index)) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrls[index]),
      );
      _controllers[index] = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _initialized[index] = true;
          _errors[index] = false;
        });

        if (index == _currentIndex) {
          controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errors[index] = true;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextVideo() {
    if (_currentIndex < widget.videoUrls.length - 1) {
      _controllers[_currentIndex]?.pause();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousVideo() {
    if (_currentIndex > 0) {
      _controllers[_currentIndex]?.pause();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _controllers[_currentIndex]?.pause();
                _currentIndex = index;
                _initializeVideo(index);
                _controllers[index]?.play();
              });
            },
            itemCount: widget.videoUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildVideoPlayer(index),
                  ),
                ),
              );
            },
          ),
          // Previous button
          if (_currentIndex > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _previousVideo,
                  ),
                ),
              ),
            ),
          // Next button
          if (_currentIndex < widget.videoUrls.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _nextVideo,
                  ),
                ),
              ),
            ),
          // Close button
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Page indicator
          if (widget.videoUrls.length > 1)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.videoUrls.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _controllers[index];
    final isInitialized = _initialized[index] ?? false;
    final hasError = _errors[index] ?? false;

    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (!isInitialized || controller == null) {
      return Container(
        padding: const EdgeInsets.all(60),
        child: CircularProgressIndicator(color: const Color(0xFF1A31C8)),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),
          GestureDetector(
            onTap: () {
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: const Color(0xFF1A31C8),
                bufferedColor: Colors.grey,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
