// lib/maps_assets/map_widgets.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'map_building.dart';
import 'building_matcher.dart';

class MapWidgets {
  static const Color _textColor = Color.fromARGB(
    136,
    55,
    107,
    132,
  ); // Darker blue for text
  static const Color _iconColor = Color(0xFF1976D2); // Blue for icons
  static const String _hasSeenGuideKey = 'has_seen_map_guide';

  // Build legend item
  static Widget buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  // 🆕 NEW: Build location permission toggle button
  static Widget buildLocationToggle({
    required VoidCallback? onPermissionChanged,
  }) {
    return _LocationToggleButton(onPermissionChanged: onPermissionChanged);
  }

  // 🆕 NEW: Build info/guide button
  static Widget buildInfoButton({required VoidCallback onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.info_outline, color: _iconColor),
        onPressed: onPressed,
        tooltip: 'Map Guide',
      ),
    );
  }

  // 🆕 NEW: Check if user has seen the guide
  static Future<bool> hasSeenGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenGuideKey) ?? false;
  }

  // 🆕 NEW: Mark guide as seen
  static Future<void> markGuideAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGuideKey, true);
  }

  // 🆕 NEW: Show map guide modal (styled like GuestAccessModal)
  static Future<void> showMapGuideModal(
    BuildContext context, {
    bool isFirstTime = false,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo and Title
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.map,
                            size: 60,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Bicol University Maps',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Interactive Campus Navigation Guide',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Purpose Section
                      _buildSectionTitle('Purpose'),
                      _buildInfoText(
                        'Navigate Bicol University campus with interactive maps showing buildings, facilities, and landmarks with real-time location tracking.',
                      ),
                      const SizedBox(height: 16),

                      // Map Legend
                      _buildSectionTitle('Map Legend'),
                      _buildLegendItem(
                        icon: Icons.place,
                        iconColor: Colors.red,
                        title: 'Landmarks',
                        description: 'Important campus locations',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        icon: Icons.school,
                        iconColor: Colors.blue,
                        title: 'Colleges',
                        description: 'Academic colleges and departments',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        icon: Icons.work_outline,
                        iconColor: Colors.green,
                        title: 'Offices',
                        description: 'Administrative offices',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        icon: Icons.business,
                        iconColor: Color(0xFFFF8C00),
                        title: 'Buildings',
                        description: 'Academic structures',
                      ),

                      const SizedBox(height: 16),

                      // Features
                      _buildSectionTitle('Features'),
                      _buildBulletPoint(
                        'Search for buildings, offices, and landmarks',
                      ),
                      _buildBulletPoint(
                        'Get turn-by-turn navigation directions',
                      ),
                      _buildBulletPoint('Enable location to see your position'),
                      _buildBulletPoint('Tap markers for detailed information'),
                      const SizedBox(height: 16),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap the info button anytime to view this guide again. Enable location services for the best navigation experience.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.orange[900],
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

              const SizedBox(height: 20),

              // Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isFirstTime) {
                      await markGuideAsSeen();
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isFirstTime ? 'Get Started' : 'I Understand',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Build section title
  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper: Build info text
  static Widget _buildInfoText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }

  // Helper: Build bullet point
  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build legend item
  static Widget _buildLegendItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
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
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build floating action button
  static Widget buildFloatingActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    bool isLoading = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_iconColor),
                ),
              )
            : Icon(icon, color: iconColor ?? _iconColor),
        onPressed: onPressed,
      ),
    );
  }

  // Build search bar
  static Widget buildSearchBar({
    required TextEditingController controller,
    required Function(String) onChanged,
    required VoidCallback onClear,
    String hintText = 'Search',
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () {
                        controller.clear();
                        onClear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              onChanged(value);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  // Build search results dropdown
  static Widget buildSearchResults({
    required List<dynamic> results,
    required Function(dynamic) onResultTap,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No results found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];

                String name;
                String? subtitle;
                String? secondaryText;
                IconData icon;
                Color iconColor;

                if (result is BicolBuildingPolygon) {
                  name = result.databaseName ?? result.name;
                  subtitle = result.databaseNickname;
                  secondaryText = result.isFacility
                      ? _getBuildingTypeText(result)
                      : null;
                  icon = Icons.business;
                  iconColor = Color(0xFFFF8C00);
                } else if (result is BicolMarker) {
                  name = result.displayName;
                  if (result.isCollege) {
                    subtitle = result.abbreviation;
                    secondaryText = null;
                    icon = Icons.school;
                    iconColor = Colors.blue;
                  } else {
                    subtitle = 'Landmark';
                    icon = Icons.place;
                    iconColor = Colors.green;
                  }
                } else if (result is OfficeData) {
                  name = result.name;
                  subtitle = result.abbreviation;
                  secondaryText = BuildingMatcher.getBuildingNameById(
                    result.buildingId,
                  );
                  icon = Icons.work_outline;
                  iconColor = Colors.green;
                } else {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: iconColor, width: 1.5),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (secondaryText != null &&
                            secondaryText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  secondaryText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    onTap: () => onResultTap(result),
                  ),
                );
              },
            ),
    );
  }

  static String _getBuildingTypeText(BicolBuildingPolygon building) {
    if (building.isFacility) {
      if (building.isPool) return 'Swimming Pool';
      if (building.isField) return 'Sports Facility';
      return 'Facility';
    }
    return building.description;
  }

  // Build zoom controls
  static Widget buildZoomControls({
    required VoidCallback onZoomIn,
    required VoidCallback onZoomOut,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: Colors.black87),
            onPressed: onZoomIn,
          ),
        ),
        Container(width: 48, height: 1, color: Colors.grey.shade300),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: Colors.black87),
            onPressed: onZoomOut,
          ),
        ),
      ],
    );
  }
}

// 🆕 Internal widget for location toggle
class _LocationToggleButton extends StatefulWidget {
  final VoidCallback? onPermissionChanged;

  const _LocationToggleButton({this.onPermissionChanged});

  @override
  State<_LocationToggleButton> createState() => _LocationToggleButtonState();
}

class _LocationToggleButtonState extends State<_LocationToggleButton> {
  bool _isLocationEnabled = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    setState(() => _isChecking = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      setState(() {
        _isLocationEnabled =
            serviceEnabled &&
            (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always);
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _toggleLocation() async {
    if (_isLocationEnabled) {
      _showDisableDialog();
    } else {
      await _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isChecking = false);
        _showServiceDisabledDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isChecking = false);
        _showPermanentlyDeniedDialog();
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      await _checkLocationStatus();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        widget.onPermissionChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Location enabled successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isChecking = false);
    }
  }

  void _showServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Service Disabled'),
          ],
        ),
        content: const Text(
          'Please enable location services in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              await Future.delayed(const Duration(seconds: 1));
              _checkLocationStatus();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: const Text(
          'Location permission was permanently denied. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              _checkLocationStatus();
            },
            child: const Text('App Settings'),
          ),
        ],
      ),
    );
  }

  void _showDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Disable Location'),
          ],
        ),
        content: const Text(
          'To disable location, please go to app settings and revoke location permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              _checkLocationStatus();
            },
            child: const Text('App Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isChecking
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade700,
                  ),
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                _isLocationEnabled ? Icons.location_on : Icons.location_off,
                color: _isLocationEnabled ? Colors.green : Colors.grey.shade600,
              ),
              onPressed: _toggleLocation,
              tooltip: _isLocationEnabled
                  ? 'Location Enabled'
                  : 'Enable Location',
            ),
    );
  }
}
