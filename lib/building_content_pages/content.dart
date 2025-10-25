// building_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
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

class _BuildingDetailsPageState extends State<BuildingDetailsPage> {
  final supabase = Supabase.instance.client;
  String? expandedSection;

  // Data from Supabase
  Map<String, dynamic>? buildingData;
  List<Map<String, dynamic>>? roomsData;
  String? headerImageUrl;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuildingData();
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

  Future<void> _loadBuildingData() async {
    try {
      setState(() => isLoading = true);

      // Fetch Building data
      final response = await supabase
          .from('Building')
          .select('*')
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

      // Fetch building image from storage
      String? fetchedHeaderUrl;
      final buildingFolderName =
          response['building_name']
              ?.toString()
              .toLowerCase()
              .replaceAll(' ', '-')
              .trim() ??
          widget.buildingName?.toLowerCase().replaceAll(' ', '-').trim();

      if (buildingFolderName != null) {
        try {
          final imagesResponse = await supabase
              .from('storage_objects_snapshot')
              .select('name')
              .eq('bucket_id', 'images')
              .eq('folder', buildingFolderName)
              .order('filename', ascending: true)
              .limit(1);

          if (imagesResponse.isNotEmpty) {
            final imagePath = imagesResponse[0]['name'] as String;
            fetchedHeaderUrl = supabase.storage
                .from('images')
                .getPublicUrl(imagePath);
          }
        } catch (e) {
          print('Error loading building image: $e');
        }
      }

      setState(() {
        buildingData = response;
        roomsData = fetchedRooms;
        headerImageUrl = fetchedHeaderUrl;
        // Store calculated max floor in buildingData for easy access
        if (maxFloor != null) {
          buildingData!['calculated_floors'] = maxFloor;
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error loading building data: $e');
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
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated loading circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
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
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                children: [
                  _buildExpandableSection(
                    'ABOUT',
                    '${buildingData?['building_name'] ?? widget.title}\'s Information',
                    BuildingAboutTab(
                      description: buildingData?['description'],
                      location: buildingData?['address'],
                      numberOfFloors: buildingData?['calculated_floors'],
                      numberOfRooms: roomsData?.length ?? 0,
                      hasRooms: _hasRooms,
                    ),
                  ),
                  // Only show ROOMS section if building has rooms
                  if (_hasRooms) ...[
                    const SizedBox(height: 30),
                    _buildExpandableSection(
                      'ROOMS',
                      '${buildingData?['building_name'] ?? widget.title}\'s Rooms',
                      BuildingRoomsTab(rooms: roomsData ?? []),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
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
        children: [
          // Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.business, color: Colors.blue[900], size: 35),
          ),
          SizedBox(width: 20),
          // Title
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
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    String title,
    String subtitle,
    Widget content,
  ) {
    bool isExpanded = expandedSection == title;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                expandedSection = isExpanded ? null : title;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      isExpanded ? 'Tap to collapse' : 'Tap to expand',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
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
