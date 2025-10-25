// office_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
// Import tab widget
import 'about.dart';

class OfficeDetailsPage extends StatefulWidget {
  final int officeId; // Required - primary identifier
  final String? officeName; // Optional - fallback for display
  final String title;

  const OfficeDetailsPage({
    super.key,
    required this.officeId,
    this.officeName,
    required this.title,
  });

  @override
  State<OfficeDetailsPage> createState() => _OfficeDetailsPageState();
}

class _OfficeDetailsPageState extends State<OfficeDetailsPage> {
  final supabase = Supabase.instance.client;
  String? expandedSection;

  // Data from Supabase
  Map<String, dynamic>? officeData;
  Map<String, dynamic>? headData;
  String? buildingName;
  String? roomName;
  String? headerImageUrl;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfficeData();
  }

  Future<void> _loadOfficeData() async {
    try {
      setState(() => isLoading = true);

      // Fetch Office data with Head information using JOIN
      final response = await supabase
          .from('Office')
          .select('*, Head(*)')
          .eq('office_id', widget.officeId)
          .single();

      // Fetch Building and Room information if available
      String? fetchedBuildingName;
      String? fetchedRoomName;

      if (response['room_id'] != null) {
        final roomResponse = await supabase
            .from('Room')
            .select('room_name, room_number, building_id')
            .eq('room_id', response['room_id'])
            .single();

        // Use room_number instead of room_name
        fetchedRoomName = roomResponse['room_number'] != null
            ? 'Room ${roomResponse['room_number']}'
            : null;

        // Fetch building separately if building_id exists
        if (roomResponse['building_id'] != null) {
          final buildingResponse = await supabase
              .from('Building')
              .select('building_name')
              .eq('building_id', roomResponse['building_id'])
              .single();

          fetchedBuildingName = buildingResponse['building_name'];
        }
      }

      // Fetch office image from storage
      String? fetchedHeaderUrl;
      final officeFolderName =
          response['office_name']
              ?.toString()
              .toLowerCase()
              .replaceAll(' ', '-')
              .trim() ??
          widget.officeName?.toLowerCase().replaceAll(' ', '-').trim();

      if (officeFolderName != null) {
        try {
          final imagesResponse = await supabase
              .from('storage_objects_snapshot')
              .select('name')
              .eq('bucket_id', 'images')
              .eq('folder', officeFolderName)
              .order('filename', ascending: true)
              .limit(1);

          if (imagesResponse.isNotEmpty) {
            final imagePath = imagesResponse[0]['name'] as String;
            fetchedHeaderUrl = supabase.storage
                .from('images')
                .getPublicUrl(imagePath);
          }
        } catch (e) {
          print('Error loading office image: $e');
        }
      }

      setState(() {
        officeData = response;
        headData = response['Head'];
        buildingName = fetchedBuildingName;
        roomName = fetchedRoomName;
        headerImageUrl = fetchedHeaderUrl;
        isLoading = false;
      });
    } catch (e) {
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
                              'assets/images/default_office.png',
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
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 150,
                  child: _buildOfficeCard(),
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
                    '${officeData?['office_name'] ?? widget.title}\'s Information',
                    OfficeAboutTab(
                      officeServices:
                          officeData?['office_services']?.toString() ?? '',
                      buildingName: buildingName,
                      roomName: roomName,
                      headData: headData,
                    ),
                  ),
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

  Widget _buildOfficeCard() {
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
            child: Icon(Icons.domain, color: Color(0xFF203BE6), size: 35),
          ),
          SizedBox(width: 20),
          // Title
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
        tooltip: 'Back',
      ),
    );
  }
}
