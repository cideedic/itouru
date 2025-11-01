// lib/maps_assets/bottom_sheets.dart
import 'package:flutter/material.dart';
import 'map_building.dart';
import 'package:itouru/building_content_pages/content.dart';
import 'package:itouru/college_content_pages/content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/image_layout.dart';

class BottomSheets {
  static final _supabase = Supabase.instance.client;

  static void showBuildingInfo(
    BuildContext context,
    BicolBuildingPolygon building, {
    VoidCallback? onVirtualTour,
    VoidCallback? onDirections,
    bool isLoadingRoute = false,
    bool isCollege = false,
    bool isLandmark = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !isLoadingRoute,
      enableDrag: !isLoadingRoute,
      isScrollControlled: true,
      builder: (context) => _BuildingInfoContent(
        building: building,
        onVirtualTour: onVirtualTour,
        onDirections: onDirections,
        isLoadingRoute: isLoadingRoute,
        isCollege: isCollege,
        isLandmark: isLandmark,
      ),
    );
  }

  static void showRouteInfo(
    BuildContext context, {
    required String buildingName,
    required String distance,
    required String duration,
    VoidCallback? onClearRoute,
    VoidCallback? onStartNavigation,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBottomSheetHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route to',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        buildingName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.straighten, color: Colors.orange),
                      const SizedBox(height: 4),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text('Distance', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.access_time, color: Colors.orange),
                      const SizedBox(height: 4),
                      Text(
                        duration,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text('Duration', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onStartNavigation?.call();
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Start Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onClearRoute?.call();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear Route'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBottomSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BuildingInfoContent extends StatefulWidget {
  final BicolBuildingPolygon building;
  final VoidCallback? onVirtualTour;
  final VoidCallback? onDirections;
  final bool isLoadingRoute;
  final bool isCollege;
  final bool isLandmark;

  const _BuildingInfoContent({
    required this.building,
    this.onVirtualTour,
    this.onDirections,
    required this.isLoadingRoute,
    this.isCollege = false,
    this.isLandmark = false,
  });

  @override
  State<_BuildingInfoContent> createState() => _BuildingInfoContentState();
}

class _BuildingInfoContentState extends State<_BuildingInfoContent> {
  List<String> _imageUrls = [];
  bool _isLoadingImages = true;
  bool _isLoadingInfo = true;
  PageController? _pageController;

  // For buildings
  String? _buildingName;
  String? _buildingNickname;
  String? _buildingType;

  // For colleges
  String? _collegeName;
  String? _collegeAbbreviation;

  @override
  void initState() {
    super.initState();
    print(
      '🏛️ Landmark Debug - ID: ${widget.building.buildingId}, isLandmark: ${widget.isLandmark}, Name: ${widget.building.name}',
    );
    _loadData();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.isCollege) {
      await _loadCollegeData();
    } else if (widget.isLandmark) {
      await _loadLandmarkData();
    } else {
      await _loadBuildingData();
    }
  }

  Future<void> _loadCollegeData() async {
    if (widget.building.buildingId == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _isLoadingInfo = false;
      });
      return;
    }

    try {
      final response = await BottomSheets._supabase
          .from('College')
          .select('college_name, college_abbreviation')
          .eq('college_id', widget.building.buildingId!)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _isLoadingImages = false;
          _isLoadingInfo = false;
        });
        return;
      }

      setState(() {
        _collegeName = response['college_name'];
        _collegeAbbreviation = response['college_abbreviation'];
        _isLoadingInfo = false;
      });

      await _loadCollegeImages(response['college_name']);
    } catch (e) {
      print('❌ Error loading college data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _isLoadingInfo = false;
      });
    }
  }

  Future<void> _loadLandmarkData() async {
    if (widget.building.buildingId == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _isLoadingInfo = false;
      });
      return;
    }

    try {
      final response = await BottomSheets._supabase
          .from('Building')
          .select('building_name, building_nickname, building_type')
          .eq('building_id', widget.building.buildingId!)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _isLoadingImages = false;
          _isLoadingInfo = false;
        });
        return;
      }

      setState(() {
        _buildingName = response['building_name'];
        _buildingNickname = response['building_nickname'];
        _buildingType = response['building_type'];
        _isLoadingInfo = false;
      });

      await _loadBuildingImages(response['building_name']);
    } catch (e) {
      print('❌ Error loading landmark data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _isLoadingInfo = false;
      });
    }
  }

  Future<void> _loadBuildingData() async {
    if (widget.building.buildingId == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _isLoadingInfo = false;
      });
      return;
    }

    try {
      final response = await BottomSheets._supabase
          .from('Building')
          .select('building_name, building_nickname, building_type')
          .eq('building_id', widget.building.buildingId!)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _isLoadingImages = false;
          _isLoadingInfo = false;
        });
        return;
      }

      setState(() {
        _buildingName = response['building_name'];
        _buildingNickname = response['building_nickname'];
        _buildingType = response['building_type'];
        _isLoadingInfo = false;
      });

      await _loadBuildingImages(response['building_name']);
    } catch (e) {
      print('❌ Error loading building data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _isLoadingInfo = false;
      });
    }
  }

  Future<void> _loadCollegeImages(String? collegeName) async {
    if (collegeName == null && _collegeAbbreviation == null) {
      if (!mounted) return;
      setState(() => _isLoadingImages = false);
      return;
    }

    try {
      List<String> possibleFolderNames = [];

      if (collegeName != null) {
        final collegeFolderName = collegeName
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();
        possibleFolderNames.add(collegeFolderName);
      }

      if (_collegeAbbreviation != null) {
        final abbrevFolderName = _collegeAbbreviation!
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();
        if (!possibleFolderNames.contains(abbrevFolderName)) {
          possibleFolderNames.add(abbrevFolderName);
        }
      }

      List<dynamic> imagesResponse = [];

      for (var folderName in possibleFolderNames) {
        final response = await BottomSheets._supabase
            .from('storage_objects_snapshot')
            .select('name, filename')
            .eq('bucket_id', 'images')
            .eq('folder', folderName)
            .order('filename', ascending: true)
            .limit(5);

        if (response.isNotEmpty) {
          imagesResponse = response;
          break;
        }
      }

      if (!mounted) return;

      List<String> imageUrls = [];

      for (var imageData in imagesResponse) {
        final imagePath = imageData['name'] as String;
        final filename = imageData['filename'] as String;

        print('📸 Checking image: $filename'); // ← Add this

        if (filename == '.emptyFolderPlaceholder' ||
            imagePath.endsWith('.emptyFolderPlaceholder') ||
            filename.contains('_logo')) {
          print('❌ Skipping: $filename'); // ← Add this
          continue;
        }

        final publicUrl = BottomSheets._supabase.storage
            .from('images')
            .getPublicUrl(imagePath);

        imageUrls.add(publicUrl);
        print('✅ Added image: $filename'); // ← Add this
      }
      // ✅ ADD THESE 3 LINES HERE
      if (imageUrls.length > 3) {
        imageUrls = imageUrls.sublist(0, 3);
      }

      print('🎯 Total images loaded: ${imageUrls.length}'); // ← Add this
      if (!mounted) return;

      setState(() {
        _imageUrls = imageUrls;
        _isLoadingImages = false;
      });

      if (imageUrls.length > 1) {
        _pageController = PageController(); // Remove viewportFraction
      }
    } catch (e) {
      print('❌ Error loading college images: $e');
      if (!mounted) return;
      setState(() => _isLoadingImages = false);
    }
  }

  Future<void> _loadBuildingImages(String? buildingName) async {
    if (buildingName == null && _buildingNickname == null) {
      if (!mounted) return;
      setState(() => _isLoadingImages = false);
      return;
    }

    try {
      List<String> possibleFolderNames = [];

      if (buildingName != null) {
        final buildingFolderName = buildingName
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();
        possibleFolderNames.add(buildingFolderName);
      }

      if (_buildingNickname != null) {
        final nicknameFolderName = _buildingNickname!
            .toLowerCase()
            .replaceAll('.', '')
            .replaceAll(' ', '-')
            .trim();
        if (!possibleFolderNames.contains(nicknameFolderName)) {
          possibleFolderNames.add(nicknameFolderName);
        }
      }

      List<dynamic> imagesResponse = [];

      for (var folderName in possibleFolderNames) {
        final response = await BottomSheets._supabase
            .from('storage_objects_snapshot')
            .select('name, filename')
            .eq('bucket_id', 'images')
            .eq('folder', folderName)
            .order('filename', ascending: true)
            .limit(5);

        if (response.isNotEmpty) {
          imagesResponse = response;
          break;
        }
      }

      if (!mounted) return;

      List<String> imageUrls = [];

      for (var imageData in imagesResponse) {
        final imagePath = imageData['name'] as String;
        final filename = imageData['filename'] as String;

        print('📸 Checking image: $filename'); // ← Add this

        if (filename == '.emptyFolderPlaceholder' ||
            imagePath.endsWith('.emptyFolderPlaceholder') ||
            filename.contains('_logo')) {
          print('❌ Skipping: $filename'); // ← Add this
          continue;
        }

        final publicUrl = BottomSheets._supabase.storage
            .from('images')
            .getPublicUrl(imagePath);

        imageUrls.add(publicUrl);
        print('✅ Added image: $filename'); // ← Add this
      }

      print('🎯 Total images loaded: ${imageUrls.length}'); // ← Add this
      // ✅ ADD THESE 3 LINES HERE
      if (imageUrls.length > 3) {
        imageUrls = imageUrls.sublist(0, 3);
      }

      if (!mounted) return;

      setState(() {
        _imageUrls = imageUrls;
        _isLoadingImages = false;
      });

      if (imageUrls.length > 1) {
        _pageController = PageController(); // Remove viewportFraction
      }
    } catch (e) {
      print('❌ Error loading building images: $e');
      if (!mounted) return;
      setState(() => _isLoadingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomSheets._buildBottomSheetHandle(),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingInfo)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  _buildHeader(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          if (_isLoadingImages)
            _buildImageLoadingPlaceholder()
          else if (_imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ImageLayout.forMap(
                imageUrls: _imageUrls,
                pageController: _pageController,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (widget.isLoadingRoute)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Getting directions...',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (widget.isCollege) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'College',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Text(
            _collegeName ?? widget.building.name,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          if (_collegeAbbreviation != null &&
              _collegeAbbreviation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _collegeAbbreviation!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    } else if (widget.isLandmark) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  _buildingType ?? 'Landmark',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Text(
            _buildingName ?? widget.building.name,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          if (_buildingNickname != null && _buildingNickname!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _buildingNickname!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_buildingType != null && _buildingType!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Text(
                      _buildingType!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Text(
                  _buildingName ?? widget.building.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                if (_buildingNickname != null &&
                    _buildingNickname!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _buildingNickname!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons() {
    // For colleges: Use college_id to navigate to CollegeDetailsPage
    if (widget.isCollege) {
      final hasValidId = widget.building.buildingId != null;

      return Row(
        children: [
          if (hasValidId)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isLoadingRoute
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CollegeDetailsPage(
                              collegeId: widget.building.buildingId!,
                              collegeName: _collegeName ?? widget.building.name,
                              title: _collegeName ?? widget.building.name,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          if (hasValidId) const SizedBox(width: 12),

          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.isLoadingRoute
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onDirections?.call();
                    },
              icon: widget.isLoadingRoute
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : const Icon(Icons.directions, size: 18),
              label: Text(widget.isLoadingRoute ? 'Loading...' : 'Directions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // For landmarks: Show Info + Directions (landmarks use BuildingDetailsPage)
    if (widget.isLandmark) {
      final hasValidId = widget.building.buildingId != null;

      return Row(
        children: [
          if (hasValidId)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isLoadingRoute
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BuildingDetailsPage(
                              buildingId: widget.building.buildingId!,
                              buildingName:
                                  _buildingName ?? widget.building.name,
                              title: _buildingName ?? widget.building.name,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          if (hasValidId) const SizedBox(width: 12),

          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.isLoadingRoute
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onDirections?.call();
                    },
              icon: widget.isLoadingRoute
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : const Icon(Icons.directions, size: 18),
              label: Text(widget.isLoadingRoute ? 'Loading...' : 'Directions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // For buildings with detailed info: Show Info + Directions buttons
    if (widget.building.hasDetailedInfo) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.isLoadingRoute
                  ? null
                  : () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuildingDetailsPage(
                            buildingId: widget.building.buildingId!,
                            buildingName: widget.building.name,
                            title: widget.building.name,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.isLoadingRoute
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onDirections?.call();
                    },
              icon: widget.isLoadingRoute
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : const Icon(Icons.directions, size: 18),
              label: Text(widget.isLoadingRoute ? 'Loading...' : 'Directions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ✨ FIXED: For buildings without detailed info - wrap in Row with Expanded
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.isLoadingRoute
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onDirections?.call();
                  },
            icon: widget.isLoadingRoute
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : const Icon(Icons.directions, size: 18),
            label: Text(widget.isLoadingRoute ? 'Loading...' : 'Directions'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageLoadingPlaceholder() {
    return Column(
      children: [
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A31C8)),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
