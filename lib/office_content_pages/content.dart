// office_details.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/sticky_header.dart';
import 'package:itouru/main_pages/maps.dart';
import 'package:itouru/page_components/loading_widget.dart';
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

class _OfficeDetailsPageState extends State<OfficeDetailsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Set<String> expandedSections = {};
  Map<String, AnimationController> sectionControllers = {};

  // Data from Supabase
  Map<String, dynamic>? officeData;
  Map<String, dynamic>? headData;
  String? buildingName;
  String? roomName;
  String? headerImageUrl;
  String? logoImageUrl;
  int? buildingId;

  bool isLoading = true;

  // Scroll controller for sticky header
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;

  @override
  void initState() {
    super.initState();
    _loadOfficeData();
    _initializeSectionControllers();
    _scrollController.addListener(_onScroll);
  }

  void _initializeSectionControllers() {
    final sections = ['ABOUT'];
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

  Future<void> _loadOfficeData() async {
    try {
      setState(() => isLoading = true);

      print('🏢 Loading office data for office_id: ${widget.officeId}');

      // Fetch Office data with Head and College information using JOIN
      final response = await supabase
          .from('Office')
          .select('*, Head(*), College(*)')
          .eq('office_id', widget.officeId)
          .single();

      print('🏢 Office Data: ${response['office_name']}');
      print('🏢 Building ID from Office: ${response['building_id']}');
      print('🏢 Room ID from Office: ${response['room_id']}');

      print('🏢 College ID from Office: ${response['college_id']}');

      // Fetch Building and Room information if available
      String? fetchedBuildingName;
      String? fetchedRoomName;
      String? buildingFolderName;
      int? fetchedBuildingId;

      // PRIORITY 1: Get building from building_id in Office table
      if (response['building_id'] != null) {
        print('🏢 Fetching building from Office.building_id');
        fetchedBuildingId = response['building_id'] as int;

        final buildingResponse = await supabase
            .from('Building')
            .select('building_name')
            .eq('building_id', fetchedBuildingId)
            .maybeSingle();

        if (buildingResponse != null) {
          fetchedBuildingName = buildingResponse['building_name'];

          // Get building folder name for fetching header image
          buildingFolderName = fetchedBuildingName
              ?.toLowerCase()
              .replaceAll('.', '')
              .replaceAll(' ', '-')
              .trim();

          print('🏢 Building Name: $fetchedBuildingName');
          print('🏢 Building Folder Name: $buildingFolderName');
        }
      }
      // FALLBACK: Try to get building through room_id if building_id is null
      else if (response['room_id'] != null) {
        print('🏢 Fetching building from Room.building_id (fallback)');
        final roomResponse = await supabase
            .from('Room')
            .select('room_name, room_number, building_id')
            .eq('room_id', response['room_id'])
            .maybeSingle();

        if (roomResponse != null) {
          // Use room_number instead of room_name
          if (roomResponse['room_number'] != null) {
            fetchedRoomName = 'Room ${roomResponse['room_number']}';
          }

          // Fetch building separately if building_id exists
          if (roomResponse['building_id'] != null) {
            fetchedBuildingId = roomResponse['building_id'] as int;

            final buildingResponse = await supabase
                .from('Building')
                .select('building_name')
                .eq('building_id', fetchedBuildingId)
                .maybeSingle();

            if (buildingResponse != null) {
              fetchedBuildingName = buildingResponse['building_name'];

              // Get building folder name for fetching header image
              buildingFolderName = fetchedBuildingName
                  ?.toLowerCase()
                  .replaceAll('.', '')
                  .replaceAll(' ', '-')
                  .trim();

              print('🏢 Building Name (from room): $fetchedBuildingName');
              print('🏢 Building Folder Name (from room): $buildingFolderName');
            }
          }
        }
      }

      String? fetchedHeaderUrl;

      // Fetch header image from building folder (using building_name or building_nickname)
      if (buildingFolderName != null) {
        // ✨ NEW: Also try to fetch building data to get nickname
        String? buildingNicknameFolderName;

        if (fetchedBuildingId != null) {
          try {
            final buildingResponse = await supabase
                .from('Building')
                .select('building_name, building_nickname')
                .eq('building_id', fetchedBuildingId)
                .maybeSingle();

            if (buildingResponse != null) {
              // Update building name if needed
              if (fetchedBuildingName == null) {
                fetchedBuildingName = buildingResponse['building_name'];
              }

              // Get building nickname for folder name
              if (buildingResponse['building_nickname'] != null) {
                buildingNicknameFolderName =
                    buildingResponse['building_nickname']
                        ?.toString()
                        .toLowerCase()
                        .replaceAll('.', '')
                        .replaceAll(' ', '-')
                        .trim();
              }
            }
          } catch (e) {
            print('⚠️ Error fetching building details: $e');
          }
        }

        // Create list of possible building folder names (name and nickname)
        List<String> possibleBuildingFolderNames = [];
        possibleBuildingFolderNames.add(buildingFolderName);
        if (buildingNicknameFolderName != null &&
            buildingNicknameFolderName != buildingFolderName) {
          possibleBuildingFolderNames.add(buildingNicknameFolderName);
        }

        print(
          '🏢 Possible Building Folder Names: $possibleBuildingFolderNames',
        );

        // Try each possible folder name until we find images
        if (possibleBuildingFolderNames.isNotEmpty) {
          print(
            '🖼️ Fetching images from building folders: $possibleBuildingFolderNames',
          );
          List<dynamic> buildingImagesResponse = [];

          for (var folderName in possibleBuildingFolderNames) {
            try {
              final response = await supabase
                  .from('storage_objects_snapshot')
                  .select('name, filename')
                  .eq('bucket_id', 'images')
                  .eq('folder', folderName)
                  .order('filename', ascending: true);

              if (response.isNotEmpty) {
                buildingImagesResponse = response;
                print('✅ Found images in building folder: $folderName');
                break;
              }
            } catch (e) {
              print('⚠️ No images in building folder $folderName: $e');
            }
          }

          if (buildingImagesResponse.isNotEmpty) {
            print(
              '🏢 Building Images Response Length: ${buildingImagesResponse.length}',
            );

            // Find first non-placeholder, non-logo image
            for (var imageData in buildingImagesResponse) {
              final imagePath = imageData['name'] as String;
              final filename = imageData['filename'] as String;

              print(
                '🏢 Found building image - Path: $imagePath, Filename: $filename',
              );

              // Skip placeholder files and logo files
              if (filename == '.emptyFolderPlaceholder' ||
                  imagePath.endsWith('.emptyFolderPlaceholder') ||
                  filename.contains('_logo')) {
                print('⏭️ Skipping: $filename');
                continue;
              }

              fetchedHeaderUrl = supabase.storage
                  .from('images')
                  .getPublicUrl(imagePath);
              print('🎯 Set building image as header: $fetchedHeaderUrl');
              break; // Use first valid image
            }

            if (fetchedHeaderUrl == null) {
              print('❌ No valid building images found after filtering');
            }
          }
        }
      } else {
        print('⚠️ No building folder name available');
      }
      String? fetchedLogoUrl;

      if (response['College'] != null) {
        print('🏫 Office has college - fetching college logo');
        final collegeName = response['College']['college_name'] as String?;
        final collegeAbbreviation =
            response['College']['college_abbreviation'] as String?;

        // Create list of possible college folder names
        List<String> collegeFolderNames = [];
        if (collegeName != null) {
          collegeFolderNames.add(
            collegeName
                .toLowerCase()
                .replaceAll(' ', '-')
                .replaceAll('college of', 'college-of')
                .trim(),
          );
        }
        if (collegeAbbreviation != null && collegeAbbreviation != collegeName) {
          collegeFolderNames.add(
            collegeAbbreviation.toLowerCase().replaceAll(' ', '-').trim(),
          );
        }

        print('🏫 Possible college folder names: $collegeFolderNames');

        // Try each possible folder name until we find a logo
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
            print('⚠️ No logo in college folder $collegeFolderName: $e');
          }
        }

        if (fetchedLogoUrl == null) {
          print('❌ No college logo found in any folder');
        }
      } else {
        print('ℹ️ Office has no college_id - no logo to fetch');
      }

      setState(() {
        officeData = response;
        headData = response['Head'];
        buildingName = fetchedBuildingName;
        roomName = fetchedRoomName;
        headerImageUrl = fetchedHeaderUrl;
        logoImageUrl = fetchedLogoUrl;
        buildingId = fetchedBuildingId;
        isLoading = false;
      });

      print('✅ Office data loaded successfully');
      print('   - Building ID: $buildingId');
      print('   - Building Name: $buildingName');
    } catch (e) {
      print('❌ Error loading office data: $e');
      setState(() => isLoading = false);
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // Method for directions to be called from About tab
  void handleDirections() {
    if (buildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.title} has no building location assigned'),
          backgroundColor: Color(0xFFFF8C00),
        ),
      );
      return;
    }

    print('\n🧭 === OFFICE DIRECTIONS ===');
    print('   Office: ${widget.title}');
    print('   Building ID: $buildingId');
    print('   Building Name: $buildingName');

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Opening map...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate to Maps page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Maps(
          buildingId: buildingId!,
          destinationName: buildingName ?? widget.title,
          itemType: 'office',
        ),
      ),
    );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
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
                          buildingId: buildingId,
                          onDirectionsPressed: handleDirections,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sticky Header with conditional logo
          StickyHeader(
            isVisible: _showStickyHeader,
            title: widget.title,
            abbreviation: officeData?['office_abbreviation'],
            logoImageUrl: logoImageUrl,
            showLogo: logoImageUrl != null,
          ),
        ],
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
                        Icons.domain,
                        color: Color(0xFF203BE6),
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
                  fontSize: 20,
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
