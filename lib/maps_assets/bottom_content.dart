import 'package:flutter/material.dart';
import 'map_building.dart';
import 'package:itouru/building_content_pages/content.dart';
import 'package:itouru/college_content_pages/content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:itouru/page_components/image_layout.dart';
import 'package:itouru/maps_assets/building_matcher.dart';

const kPrimaryOrange = Color(0xFFFF8C00);
const kPrimaryBlue = Color(0xFF2196F3);

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

  static void showOfficeInfo(
    BuildContext context,
    OfficeData office, {
    required String buildingName,
    VoidCallback? onViewDetails,
    VoidCallback? onDirections,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OfficeInfoContent(
        office: office,
        buildingName: buildingName,
        onViewDetails: onViewDetails,
        onDirections: onDirections,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBottomSheetHandle(),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryOrange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route to',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        buildingName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryOrange.withValues(alpha: 0.08),
                    kPrimaryOrange.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kPrimaryOrange.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryOrange.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.straighten,
                            color: kPrimaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          distance,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Changed from 18
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Distance',
                          style: GoogleFonts.poppins(
                            fontSize: 11, // Changed from 12
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: kPrimaryOrange.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryOrange.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: kPrimaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          duration,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Est. Duration',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onStartNavigation?.call();
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: Text(
                      'Start Navigation',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                    label: Text(
                      'Clear Route',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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

        if (filename == '.emptyFolderPlaceholder' ||
            imagePath.endsWith('.emptyFolderPlaceholder') ||
            filename.contains('_logo')) {
          continue;
        }

        final publicUrl = BottomSheets._supabase.storage
            .from('images')
            .getPublicUrl(imagePath);

        imageUrls.add(publicUrl);
      }

      if (imageUrls.length > 3) {
        imageUrls = imageUrls.sublist(0, 3);
      }

      if (!mounted) return;

      setState(() {
        _imageUrls = imageUrls;
        _isLoadingImages = false;
      });

      if (imageUrls.length > 1) {
        _pageController = PageController();
      }
    } catch (e) {
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

        if (filename == '.emptyFolderPlaceholder' ||
            imagePath.endsWith('.emptyFolderPlaceholder') ||
            filename.contains('_logo')) {
          continue;
        }

        final publicUrl = BottomSheets._supabase.storage
            .from('images')
            .getPublicUrl(imagePath);

        imageUrls.add(publicUrl);
      }

      if (imageUrls.length > 3) {
        imageUrls = imageUrls.sublist(0, 3);
      }

      if (!mounted) return;

      setState(() {
        _imageUrls = imageUrls;
        _isLoadingImages = false;
      });

      if (imageUrls.length > 1) {
        _pageController = PageController();
      }
    } catch (e) {
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomSheets._buildBottomSheetHandle(),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingInfo)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: kPrimaryOrange),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (widget.isLoadingRoute)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryBlue.withValues(alpha: 0.1),
                          kPrimaryBlue.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: kPrimaryBlue.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              kPrimaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Getting directions...',
                          style: GoogleFonts.poppins(
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimaryBlue.withValues(alpha: 0.1),
                  kPrimaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: kPrimaryBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school,
                  size: 12,
                  color: kPrimaryBlue,
                ), // Changed from 14
                const SizedBox(width: 4),
                Text(
                  'College',
                  style: GoogleFonts.poppins(
                    fontSize: 10, // Changed from 12
                    fontWeight: FontWeight.w600,
                    color: kPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Text(
            _collegeName ?? widget.building.name,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
            ),
          ),

          if (_collegeAbbreviation != null &&
              _collegeAbbreviation!.isNotEmpty) ...[
            const SizedBox(height: 6),
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
              gradient: LinearGradient(
                colors: [
                  kPrimaryBlue.withValues(alpha: 0.1),
                  kPrimaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kPrimaryBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, size: 14, color: kPrimaryBlue),
                const SizedBox(width: 4),
                Text(
                  _buildingType ?? 'Landmark',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Text(
            _buildingName ?? widget.building.name,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
            ),
          ),

          if (_buildingNickname != null && _buildingNickname!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _buildingNickname!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryBlue.withValues(alpha: 0.1),
                          kPrimaryBlue.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: kPrimaryBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _buildingType!,
                      style: GoogleFonts.poppins(
                        fontSize: 10, // Changed from 12
                        fontWeight: FontWeight.w600,
                        color: kPrimaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                Text(
                  _buildingName ?? widget.building.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),

                if (_buildingNickname != null &&
                    _buildingNickname!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _buildingNickname!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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
                label: Text(
                  'Info',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          if (hasValidId) const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.isLoadingRoute
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onDirections?.call();
                    },
              icon: widget.isLoadingRoute
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.directions, size: 18),
              label: Text(
                widget.isLoadingRoute ? 'Loading...' : 'Directions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
                icon: const Icon(Icons.info_outline, size: 20),
                label: Text(
                  'Info',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (hasValidId) const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton.icon(
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.directions, size: 20),
              label: Text(
                widget.isLoadingRoute ? 'Loading...' : 'Directions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
              icon: const Icon(Icons.info_outline, size: 20),
              label: Text(
                'Info',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton.icon(
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.directions, size: 20),
              label: Text(
                widget.isLoadingRoute ? 'Loading...' : 'Directions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // For buildings without detailed info - wrap in Row with Expanded
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.directions, size: 20),
            label: Text(
              widget.isLoadingRoute ? 'Loading...' : 'Directions',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[200]!, Colors.grey[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryOrange),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OfficeInfoContent extends StatelessWidget {
  final OfficeData office;
  final String buildingName;
  final VoidCallback? onViewDetails;
  final VoidCallback? onDirections;

  const _OfficeInfoContent({
    required this.office,
    required this.buildingName,
    this.onViewDetails,
    this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomSheets._buildBottomSheetHandle(),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Office Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.1),
                        Colors.green.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.work_outline,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Office',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Office Name
                Text(
                  office.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),

                // Office Abbreviation
                Text(
                  office.abbreviation!,
                  style: GoogleFonts.poppins(
                    fontSize: 12, // Changed from 14
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // Location Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryOrange.withValues(alpha: 0.08),
                        kPrimaryOrange.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPrimaryOrange.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: kPrimaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Location',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Building Name
                      Row(
                        children: [
                          Icon(
                            Icons.apartment,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              buildingName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Room and Floor Info
                      if (office.roomName != null &&
                          office.roomName!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.meeting_room,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                office.roomName!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.info_outline, size: 20),
                        label: Text(
                          'View Details',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDirections,
                        icon: const Icon(Icons.directions, size: 20),
                        label: Text(
                          'Directions',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
