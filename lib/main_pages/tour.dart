import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/header.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/main_pages/tour_loading_widget.dart';
import 'package:itouru/maps_assets/virtual_tour_manager.dart';
import 'package:itouru/page_components/loading_widget.dart';
import 'package:itouru/page_components/video_layout.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTours() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await supabase
          .from('Tours')
          .select('id, name, description, is_active, building_ids, total_stops')
          .eq('is_active', true)
          .order('name');

      setState(() {
        _tours = List<Map<String, dynamic>>.from(response);
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
                              hintText: 'Search tours...',
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
                                onRefresh: _fetchTours,
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
                        Text(
                          tour['name'] ?? 'Unnamed Tour',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),

                        if (tour['description'] != null &&
                            tour['description'].toString().isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            tour['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
      // Get building_ids from tour
      final buildingIds = widget.tour['building_ids'] as List?;

      if (buildingIds == null || buildingIds.isEmpty) {
        _buildings = [];
        return;
      }

      // Convert to List<int>
      final buildingIdList = buildingIds.map((id) => id as int).toList();

      // Fetch all buildings in one query
      final response = await supabase
          .from('Building')
          .select('building_id, building_name, building_nickname')
          .inFilter('building_id', buildingIdList);

      // Sort buildings by the order in building_ids array
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
                                fontSize: 14,
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
                    SizedBox(height: 24),
                  ],

                  // Buildings List Header
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

                  // Buildings List
                  _buildings.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(40),
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
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _buildings.length,
                          itemBuilder: (context, index) {
                            final building = _buildings[index];
                            final displayNumber = index + 1;

                            return _buildBuildingCard(building, displayNumber);
                          },
                        ),

                  // Buttons section
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Cancel button
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
                        SizedBox(width: 12),
                        // Start Virtual Tour button
                        Expanded(
                          flex: 2,
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
                                  'Start Virtual Tour',
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _startVirtualTour() {
    // Prepare tour stops from building_ids
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

          location: null,
        ),
      );
    }

    // Navigate to loading screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TourLoadingScreen(tourName: widget.tour['name'], tourStops: stops),
      ),
    );
  }

  Widget _buildBuildingCard(Map<String, dynamic> building, int number) {
    final buildingName = building['building_name'] ?? 'Unknown Building';
    final buildingNickname = building['building_nickname'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
        padding: EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stop number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFFF8C00),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
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
          ],
        ),
      ),
    );
  }
}
