import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/main_pages/tour_loading_widget.dart';
import 'package:itouru/maps_assets/virtual_tour_manager.dart';
import 'package:itouru/page_components/loading_widget.dart';
import 'package:itouru/page_components/video_layout.dart';
import 'package:itouru/main_pages/maps.dart';
import 'package:itouru/maps_assets/location_service.dart';
import 'package:itouru/maps_assets/map_boundary.dart';
import 'package:geolocator/geolocator.dart';

class Tours extends StatefulWidget {
  const Tours({super.key});

  @override
  ToursState createState() => ToursState();
}

class ToursState extends State<Tours> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tours = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserType; // Store current user type

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserType();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch current user's type from the database
  Future<void> _fetchCurrentUserType() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        // Guest user - no user type
        setState(() {
          _currentUserType = null;
        });
        _fetchTours();
        return;
      }

      final response = await supabase
          .from('Users')
          .select('user_type')
          .eq('email', user.email ?? '')
          .maybeSingle();

      setState(() {
        _currentUserType = response?['user_type']?.toString();
      });

      _fetchTours();
    } catch (e) {
      // If error, treat as guest
      setState(() {
        _currentUserType = null;
      });
      _fetchTours();
    }
  }

  Future<void> _fetchTours() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await supabase
          .from('Tours')
          .select(
            'id, name, description, is_active, building_ids, total_stops, target_audience',
          )
          .eq('is_active', true)
          .order('name');

      // Filter tours based on target_audience and current user type
      final filteredTours = (response as List).where((tour) {
        final targetAudience = tour['target_audience']
            ?.toString()
            .toLowerCase();

        // If target_audience is null or 'general', show to everyone
        if (targetAudience == null || targetAudience == 'general') {
          return true;
        }

        // If user is not logged in (guest), only show 'general' tours
        if (_currentUserType == null) {
          return false;
        }

        final userType = _currentUserType!.toLowerCase();

        // Match specific audiences
        if (targetAudience == 'student' && userType == 'student') {
          return true;
        }

        if (targetAudience == 'accreditor' && userType == 'accreditor') {
          return true;
        }

        if (targetAudience == 'faculty' &&
            (userType == 'faculty' || userType == 'staff')) {
          return true;
        }

        return false;
      }).toList();

      setState(() {
        _tours = List<Map<String, dynamic>>.from(filteredTours);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredTours() {
    if (_searchQuery.isEmpty) {
      return _tours;
    }

    return _tours.where((tour) {
      final name = tour['name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query);
    }).toList();
  }

  void _onTourTap(Map<String, dynamic> tour) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TourBuildingsPage(tour: tour)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTours = _getFilteredTours();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ReusableHeader(),
          Expanded(
            child: _isLoading
                ? LoadingScreen.dots(
                    title: 'Loading Tours',
                    subtitle: 'Please Wait',
                  )
                : Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search tours',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      // Tours List
                      Expanded(
                        child: filteredTours.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off
                                          : Icons.tour_outlined,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No tours found'
                                          : 'No tours available',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_searchQuery.isNotEmpty) ...[
                                      SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your search',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await _fetchCurrentUserType();
                                },
                                color: Color(0xFFFF8C00),
                                child: ListView.builder(
                                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  itemCount: filteredTours.length,
                                  itemBuilder: (context, index) {
                                    final tour = filteredTours[index];
                                    return _buildTourCard(tour);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildTourCard(Map<String, dynamic> tour) {
    final targetAudience = tour['target_audience']?.toString() ?? 'general';

    // Helper function to get badge label
    String _getAudienceLabel(String audience) {
      switch (audience.toLowerCase()) {
        case 'student':
          return 'Student';
        case 'faculty':
          return 'Faculty';
        case 'accreditor':
          return 'Accreditor';
        default:
          return 'General';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTourTap(tour),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFFF8C00),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  // Tour details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Target Audience Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF8C00).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 11,
                                color: Color(0xFFFF8C00),
                              ),
                              SizedBox(width: 4),
                              Text(
                                _getAudienceLabel(targetAudience),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Color(0xFFFF8C00),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6),

                        Text(
                          tour['name'] ?? 'Unnamed Tour',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (tour['description'] != null &&
                            tour['description'].toString().isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            tour['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tour Buildings Page with Single Table Support
class TourBuildingsPage extends StatefulWidget {
  final Map<String, dynamic> tour;

  const TourBuildingsPage({super.key, required this.tour});

  @override
  TourBuildingsPageState createState() => TourBuildingsPageState();
}

class TourBuildingsPageState extends State<TourBuildingsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _buildings = [];
  bool _isLoading = true;
  List<String> tourVideos = [];
  PageController? _videoPageController;
  int _currentVideoPage = 0;
  static const int _infiniteMultiplier = 10000;
  bool _audioGuideEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchTourData();
  }

  @override
  void dispose() {
    if (_videoPageController != null) {
      _videoPageController!.dispose();
    }
    super.dispose();
  }

  void _initializeVideoPageController() {
    if (tourVideos.isEmpty || tourVideos.length == 1) return;

    final initialPage = _infiniteMultiplier * tourVideos.length;
    _videoPageController = PageController(
      viewportFraction: 0.8,
      initialPage: initialPage,
    );

    _videoPageController!.addListener(() {
      int next = _videoPageController!.page!.round() % tourVideos.length;
      if (_currentVideoPage != next) {
        setState(() {
          _currentVideoPage = next;
        });
      }
    });
  }

  Future<void> _fetchTourData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch buildings based on building_ids array
      await _fetchBuildings();

      // Fetch videos
      await _fetchTourVideos();

      setState(() {
        _isLoading = false;
      });

      // Initialize video controller after data is loaded
      if (tourVideos.length > 1) {
        _initializeVideoPageController();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBuildings() async {
    try {
      final buildingIds = widget.tour['building_ids'] as List?;

      if (buildingIds == null || buildingIds.isEmpty) {
        _buildings = [];
        return;
      }

      final buildingIdList = buildingIds.map((id) => id as int).toList();

      final response = await supabase
          .from('Building')
          .select('building_id, building_name, building_nickname, description')
          .inFilter('building_id', buildingIdList);

      final buildingsMap = {
        for (var building in response) building['building_id']: building,
      };

      _buildings = buildingIdList
          .where((id) => buildingsMap.containsKey(id))
          .map((id) => buildingsMap[id]!)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchTourVideos() async {
    try {
      // Create folder name from tour name
      final tourFolderName = widget.tour['name']
          ?.toString()
          .toLowerCase()
          .replaceAll(' ', '-')
          .trim();

      if (tourFolderName == null || tourFolderName.isEmpty) {
        return;
      }

      final videosResponse = await supabase
          .from('storage_objects_snapshot')
          .select('name, filename')
          .eq('bucket_id', 'tours')
          .eq('folder', tourFolderName)
          .order('filename', ascending: true);

      List<String> videoUrls = [];
      for (var videoData in videosResponse) {
        final videoPath = videoData['name'] as String;
        final filename = videoData['filename'] as String;

        // Skip placeholder files
        if (filename == '.emptyFolderPlaceholder' ||
            videoPath.endsWith('.emptyFolderPlaceholder')) {
          continue;
        }

        final publicUrl = supabase.storage
            .from('tours')
            .getPublicUrl(videoPath);
        videoUrls.add(publicUrl);
      }

      tourVideos = videoUrls;
    } catch (e) {
      // No videos found or error occurred
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.tour['name'] ?? 'Tour Details',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? LoadingScreen.dots(
              title: 'Loading Tour',
              subtitle: 'Preparing your tour',
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tour Description
                  if (widget.tour['description'] != null &&
                      widget.tour['description'].toString().isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFFF8C00),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'About this tour',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Color(0xFFFF8C00),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.tour['description'],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Display tour videos
                  if (tourVideos.isNotEmpty) ...[
                    VideoLayout(
                      videoUrls: tourVideos,
                      pageController: _videoPageController,
                    ),
                    SizedBox(height: 20),
                  ],
                  // Start Virtual Tour and Cancel buttons side by side
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _buildings.isNotEmpty
                                ? _startVirtualTour
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF8C00),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Start Tour',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tour Stops Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.apartment,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tour Stops',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF8C00).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_buildings.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Color(0xFFFF8C00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Tour Stops Card with Limited Preview
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _buildings.isEmpty
                        ? Container(
                            padding: EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.apartment_outlined,
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No buildings in this tour',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            constraints: BoxConstraints(
                              maxHeight: _buildings.length > 4
                                  ? 345
                                  : double.infinity,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.all(12),
                              itemCount: _buildings.length,
                              itemBuilder: (context, index) {
                                final building = _buildings[index];
                                final displayNumber = index + 1;
                                final isLastItem =
                                    index == _buildings.length - 1;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLastItem ? 0 : 12,
                                  ),
                                  child: _buildBuildingCard(
                                    building,
                                    displayNumber,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  SizedBox(height: 20),

                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Future<void> _startVirtualTour() async {
    if (_buildings.isEmpty) return;

    try {
      // Check if user has location permission
      final locationResult = await LocationService.getCurrentLocation();

      if (!locationResult.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_off, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    locationResult.error ??
                        'Location permission required to start tour',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          ),
        );
        return;
      }

      // Check if user is within campus bounds
      final isOnCampus = MapBoundary.isWithinCampusBounds(
        locationResult.location!,
      );

      bool? startFromCurrentLocation;

      if (isOnCampus) {
        // Show modal to choose starting point (current location vs gate)
        startFromCurrentLocation = await _showStartingPointModal();

        if (startFromCurrentLocation == null) {
          // User cancelled
          return;
        }
      } else {
        // User is off campus - gate selection will happen in loading screen
        startFromCurrentLocation = false;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are off campus. You will select a starting gate.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue[700],
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Proceed with tour - gate selection happens in loading screen if needed
      _proceedWithTour(startFromCurrentLocation: startFromCurrentLocation);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting tour: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool?> _showStartingPointModal() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - More compact
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tour,
                          size: 28,
                          color: Color(0xFFFF8C00),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Choose Starting Point',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'You are on campus',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content with Audio Guide Toggle
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Audio Guide Toggle - Compact version
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _audioGuideEnabled = !_audioGuideEnabled;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _audioGuideEnabled
                                ? Colors.orange[50]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _audioGuideEnabled
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _audioGuideEnabled
                                      ? Colors.orange[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _audioGuideEnabled
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: _audioGuideEnabled
                                      ? Colors.orange
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Audio Guide',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _audioGuideEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _audioGuideEnabled = value;
                                  });
                                },
                                activeColor: Colors.orange,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Starting point question
                      Text(
                        'Where would you like to start?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Current Location Option
                      _buildStartingPointOption(
                        icon: Icons.my_location,
                        iconColor: Colors.blue,
                        iconBgColor: Colors.blue[50]!,
                        title: 'Current Location',
                        description: 'Start from where you are now',
                        onTap: () => Navigator.pop(context, true),
                      ),

                      SizedBox(height: 10),

                      // Nearest Gate Option
                      _buildStartingPointOption(
                        icon: Icons.door_sliding,
                        iconColor: Colors.green,
                        iconBgColor: Colors.green[50]!,
                        title: 'Nearest Campus Gate',
                        description: 'Start from the closest entrance',
                        onTap: () => Navigator.pop(context, false),
                      ),

                      SizedBox(height: 16),

                      // Info box - more compact
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your choice determines the route',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartingPointOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedWithTour({required bool startFromCurrentLocation}) {
    List<VirtualTourStop> stops = [];

    for (int i = 0; i < _buildings.length; i++) {
      final building = _buildings[i];
      final buildingId = building['building_id'] as int;
      final stopNumber = i + 1;

      stops.add(
        VirtualTourStop(
          stopNumber: stopNumber,
          buildingId: buildingId,
          buildingName: building['building_name'] ?? 'Unknown Building',
          buildingNickname: building['building_nickname'] ?? '',
          buildingDescription: building['description'],
          location: null,
        ),
      );
    }

    // Show loading message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  startFromCurrentLocation
                      ? 'Starting tour from your location...'
                      : 'Finding nearest campus gate...',
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFFF8C00),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Navigate to loading screen with starting point preference
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourLoadingScreen(
          tourName: widget.tour['name'],
          tourStops: stops,
          startFromCurrentLocation: startFromCurrentLocation,
          audioGuideEnabled: _audioGuideEnabled,
        ),
      ),
    );
  }

  Widget _buildBuildingCard(Map<String, dynamic> building, int number) {
    final buildingName = building['building_name'] ?? 'Unknown Building';
    final buildingNickname = building['building_nickname'] ?? '';

    return GestureDetector(
      onTap: () => _onStopTap(building, number), // Add tap handler
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stop number
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Building details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buildingName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (buildingNickname.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        buildingNickname,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Add arrow indicator
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new method to handle stop tap
  void _onStopTap(Map<String, dynamic> building, int stopNumber) {
    final buildingName = building['building_name'] ?? 'Unknown Building';
    final buildingNickname = building['building_nickname'] ?? '';
    final displayName = buildingNickname.isNotEmpty
        ? buildingNickname
        : buildingName;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stop Number Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF8C00).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'STOP',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '$stopNumber',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Navigate to This Stop?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Building Name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.apartment, size: 18, color: Color(0xFFFF8C00)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Start navigation directly to this location?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToSpecificStop(stopNumber);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF8C00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.navigation, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Navigate',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

  // Add this method to handle navigation
  void _navigateToSpecificStop(int stopNumber) {
    // Prepare tour stops
    List<VirtualTourStop> stops = [];

    for (int i = 0; i < _buildings.length; i++) {
      final building = _buildings[i];
      final buildingId = building['building_id'] as int;
      final currentStopNumber = i + 1;

      stops.add(
        VirtualTourStop(
          stopNumber: currentStopNumber,
          buildingId: buildingId,
          buildingName: building['building_name'] ?? 'Unknown Building',
          buildingNickname: building['building_nickname'] ?? '',
          location: null,
        ),
      );
    }

    // Navigate to Maps with specific stop index
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Maps(
          startVirtualTour: true,
          tourName: widget.tour['name'],
          tourStops: stops,
          skipToStopIndex: stopNumber - 1,
          audioGuideEnabled: _audioGuideEnabled,
        ),
      ),
    );
  }
}
