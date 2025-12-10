import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:itouru/page_components/bottom_nav_bar.dart';
import 'package:itouru/page_components/sticky_header.dart';
import 'package:itouru/main_pages/maps.dart';
import 'package:itouru/page_components/loading_widget.dart';
import 'about.dart';

class OfficeDetailsPage extends StatefulWidget {
  final int officeId;
  final String? officeName;
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
  int? floorLevel; // NEW: Floor level
  String? headerImageUrl;
  String? logoImageUrl;
  String? headImageUrl;
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

  // Helper function to normalize folder names
  String normalizeFolderName(String name) {
    return name
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll("'", '')
        .replaceAll(' ', '-')
        .trim();
  }

  Future<void> _loadOfficeData() async {
    try {
      setState(() => isLoading = true);

      // Fetch Office data with Head and College information using JOIN
      final response = await supabase
          .from('Office')
          .select('*, Head(*), College(*)')
          .eq('office_id', widget.officeId)
          .single();

      // Fetch Building and Room information if available
      String? fetchedBuildingName;
      String? fetchedRoomName;
      int? fetchedBuildingId;
      int? fetchedFloorLevel;

      // Priority 1: Get building from building_id in Office table
      if (response['building_id'] != null) {
        fetchedBuildingId = response['building_id'] as int;

        final buildingResponse = await supabase
            .from('Building')
            .select('building_name, building_nickname')
            .eq('building_id', fetchedBuildingId)
            .maybeSingle();

        if (buildingResponse != null) {
          fetchedBuildingName = buildingResponse['building_name'];
        }
      }

      // Priority 2: Get room information if room_id exists
      if (response['room_id'] != null) {
        final roomResponse = await supabase
            .from('Room')
            .select('room_name, room_number, building_id, floor_level')
            .eq('room_id', response['room_id'])
            .maybeSingle();

        if (roomResponse != null) {
          // Prefer room_name, fallback to room_number
          if (roomResponse['room_name'] != null &&
              (roomResponse['room_name'] as String).isNotEmpty) {
            fetchedRoomName = roomResponse['room_name'] as String;
          } else if (roomResponse['room_number'] != null) {
            fetchedRoomName = 'Room ${roomResponse['room_number']}';
          }

          // Get floor level
          if (roomResponse['floor_level'] != null) {
            fetchedFloorLevel = roomResponse['floor_level'] as int;
          }

          // If building_id wasn't set from Office table, get it from Room
          if (fetchedBuildingId == null &&
              roomResponse['building_id'] != null) {
            fetchedBuildingId = roomResponse['building_id'] as int;

            final buildingResponse = await supabase
                .from('Building')
                .select('building_name, building_nickname')
                .eq('building_id', fetchedBuildingId)
                .maybeSingle();

            if (buildingResponse != null) {
              fetchedBuildingName = buildingResponse['building_name'];
              print('✓ Building Name from Room: $fetchedBuildingName');
            }
          }
        }
      }

      String? fetchedHeaderUrl;
      String? fetchedLogoUrl;

      // Fetch header image and logo from building folder
      if (fetchedBuildingId != null) {
        try {
          final buildingResponse = await supabase
              .from('Building')
              .select('building_name, building_nickname')
              .eq('building_id', fetchedBuildingId)
              .maybeSingle();

          if (buildingResponse != null) {
            final buildingName = buildingResponse['building_name']?.toString();
            final nickname = buildingResponse['building_nickname']?.toString();

            // Create list of possible folder names to check
            List<String> possibleFolderNames = [];

            if (buildingName != null) {
              final fullName = normalizeFolderName(buildingName);
              possibleFolderNames.add(fullName);

              if (fullName.startsWith('bicol-university-')) {
                final withoutPrefix = fullName.replaceFirst(
                  'bicol-university-',
                  '',
                );
                if (withoutPrefix.isNotEmpty &&
                    !possibleFolderNames.contains(withoutPrefix)) {
                  possibleFolderNames.add(withoutPrefix);
                }
              }
            }

            if (nickname != null) {
              final normalizedNickname = normalizeFolderName(nickname);
              if (!possibleFolderNames.contains(normalizedNickname)) {
                possibleFolderNames.add(normalizedNickname);
              }
            }

            // Try each possible folder name until we find images
            if (possibleFolderNames.isNotEmpty) {
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

              // Find first non-placeholder, non-logo image for header
              for (var imageData in imagesResponse) {
                final imagePath = imageData['name'] as String;
                final filename = imageData['filename'] as String;

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
                break;
              }

              // Try to fetch building logo
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
                    break;
                  }
                } catch (e) {
                  // No logo found in this folder, continue to next
                }
              }
            }
          }
        } catch (e) {
          // Error fetching building images
        }
      }

      // If no building logo found, try to fetch college logo as fallback
      if (fetchedLogoUrl == null && response['College'] != null) {
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
              break; // Stop searching once logo is found
            }
          } catch (e) {
            // No logo found in this folder, continue to next
          }
        }
      }

      //Fetch head official image
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
        officeData = response;
        headData = response['Head'];
        buildingName = fetchedBuildingName;
        roomName = fetchedRoomName;
        floorLevel = fetchedFloorLevel;
        headerImageUrl = fetchedHeaderUrl;
        logoImageUrl = fetchedLogoUrl;
        headImageUrl = fetchedHeadImageUrl;
        buildingId = fetchedBuildingId;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      // User-friendly error handling
      if (mounted) {
        String errorMsg = 'Unable to load office information.';

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
              onPressed: () => _loadOfficeData(),
            ),
          ),
        );
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
                          floorLevel: floorLevel, // NEW
                          headData: headData,
                          headImageUrl: headImageUrl,
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
            color: Colors.black.withValues(alpha: 0.3),
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
