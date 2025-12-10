import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'map_building.dart';
import 'building_matcher.dart';
import 'map_utils.dart';

class MapWidgets {
  static const Color _textColor = Color.fromARGB(136, 55, 107, 132);
  static const Color _iconColor = Color(0xFF1976D2);
  static const String _hasSeenGuideKey = 'has_seen_map_guide';

  /// Build map tile switcher button
  static Widget buildMapTileButton({
    required BuildContext context,
    required MapTileType currentTileType,
    required Function(MapTileType) onTileTypeChanged,
  }) {
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
        icon: Icon(
          currentTileType == MapTileType.satellite
              ? Icons.map
              : Icons.satellite_alt,
          color: _iconColor,
        ),
        onPressed: () => _showTileTypeModal(
          context: context,
          onTileTypeChanged: onTileTypeChanged,
          currentTileType: currentTileType,
        ),
        tooltip: 'Change Map Style',
      ),
    );
  }

  /// Show map tile type selection modal
  static void _showTileTypeModal({
    required BuildContext context,
    required Function(MapTileType) onTileTypeChanged,
    required MapTileType currentTileType,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.layers, color: Colors.blue[700]),
                SizedBox(width: 12),
                Text(
                  'Map Style',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
            Text(
              'Choose your preferred map view',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),

            // Standard Map Option
            _buildTileOption(
              context: modalContext,
              icon: Icons.map,
              iconColor: Colors.green,
              title: 'Standard Map',
              description: 'Default OpenStreetMap view with labels',
              isSelected: currentTileType == MapTileType.standard,
              onTap: () {
                onTileTypeChanged(MapTileType.standard);
                Navigator.pop(modalContext);
              },
            ),
            SizedBox(height: 12),

            // Satellite Map Option
            _buildTileOption(
              context: modalContext,
              icon: Icons.satellite_alt,
              iconColor: Colors.blue,
              title: 'Satellite View',
              description: 'High-resolution satellite imagery',
              isSelected: currentTileType == MapTileType.satellite,
              onTap: () {
                onTileTypeChanged(MapTileType.satellite);
                Navigator.pop(modalContext);
              },
            ),

            SizedBox(height: 24 + MediaQuery.of(modalContext).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Build tile type option
  static Widget _buildTileOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.orange, size: 24),
          ],
        ),
      ),
    );
  }

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

  static Widget buildLocationToggle({
    required VoidCallback? onPermissionChanged,
  }) {
    return _LocationToggleButton(onPermissionChanged: onPermissionChanged);
  }

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

  // Check if user has seen the guide
  static Future<bool> hasSeenGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenGuideKey) ?? false;
  }

  //  Mark guide as seen
  static Future<void> markGuideAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGuideKey, true);
  }

  // Show map guide modal
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
                        icon: Icons.circle,
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
                      const SizedBox(height: 8),
                      _buildLegendItemWithBorder(
                        icon: Icons.door_sliding,
                        iconColor: Colors.green.shade500,
                        title: 'Campus Gates',
                        description: 'Entry and exit points to the campus',
                      ),

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

  //  Build section title
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

  // Build info text
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

  // Build map legend
  static Widget buildMapLegend({
    bool showColleges = true,
    bool showLandmarks = true,
    bool showGates = true,
  }) {
    // Filter legend items based on visibility
    final List<Widget> legendItems = [];

    if (showColleges) {
      legendItems.add(
        _buildCompactLegendItem(
          icon: Icons.school,
          iconColor: Colors.blue,
          label: 'Colleges',
        ),
      );
    }

    if (showLandmarks) {
      legendItems.add(
        _buildCompactLegendItem(
          icon: Icons.circle,
          iconColor: Colors.red,
          label: 'Landmarks',
        ),
      );
    }

    if (showGates) {
      legendItems.add(
        _buildCompactLegendItemWithBorder(
          icon: Icons.door_sliding,
          iconColor: Colors.green.shade700,
          label: 'Gates',
        ),
      );
    }

    // If all filters are off, show nothing
    if (legendItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: legendItems.map((item) {
          final isLast = item == legendItems.last;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 16),
            child: item,
          );
        }).toList(),
      ),
    );
  }

  // Helper: Build compact legend item with circular background
  static Widget _buildCompactLegendItem({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 1.5),
          ),
          child: Icon(icon, color: iconColor, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Helper: Build compact legend item with border (for gates)
  static Widget _buildCompactLegendItemWithBorder({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
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

  static Widget _buildLegendItemWithBorder({
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
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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

  static Widget buildFilterButton({required VoidCallback onPressed}) {
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
        icon: Icon(Icons.filter_list, color: _iconColor),
        onPressed: onPressed,
        tooltip: 'Map Filters',
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
                    icon = Icons.circle;
                    iconColor = Colors.red;
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

// Location toggle with permission modal
class _LocationToggleButton extends StatefulWidget {
  final VoidCallback? onPermissionChanged;

  const _LocationToggleButton({this.onPermissionChanged});

  @override
  State<_LocationToggleButton> createState() => _LocationToggleButtonState();
}

class _LocationToggleButtonState extends State<_LocationToggleButton> {
  bool _isLocationEnabled = false;
  bool _isChecking = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _checkLocationStatus();
      }
    });
  }

  Future<void> _checkLocationStatus() async {
    if (!mounted || _isDisposed) return;

    setState(() => _isChecking = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isLocationEnabled = false;
            _isChecking = false;
          });
        }
        return;
      }

      final permission = await Geolocator.checkPermission();

      if (mounted && !_isDisposed) {
        setState(() {
          _isLocationEnabled =
              permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('Location check error: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLocationEnabled = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _toggleLocation() async {
    if (_isDisposed) return;

    if (_isLocationEnabled) {
      _showDisableDialog();
    } else {
      final shouldRequest = await _showLocationAccessModal();
      if (shouldRequest == true && !_isDisposed) {
        await _requestPermission();
      }
    }
  }

  Future<bool?> _showLocationAccessModal() async {
    if (_isDisposed || !mounted) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: Color(0xFFFF8C00),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enable Location Access',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'iTOURu needs access to your location to provide accurate navigation and show your position on the campus map.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildBenefitItem(Icons.navigation, 'Real-time navigation'),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      Icons.my_location,
                      'Show your current position',
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      Icons.directions_walk,
                      'Turn-by-turn directions',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF8C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Enable',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your location data is only used for navigation and is not stored.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFFFF8C00).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Color(0xFFFF8C00)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Future<void> _requestPermission() async {
    if (_isDisposed || !mounted) return;

    // ✅ Show checking state immediately
    if (mounted && !_isDisposed) {
      setState(() => _isChecking = true);
    }

    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!_isDisposed && mounted) {
          setState(() => _isChecking = false);
          _showServiceDisabledDialog();
        }
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        if (!_isDisposed && mounted) {
          setState(() => _isChecking = false);
          _showPermanentlyDeniedDialog();
        }
        return;
      }

      // ✅ Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // ✅ Check the result and update UI
      if (!_isDisposed && mounted) {
        // Update location status after permission request
        await _checkLocationStatus();

        // Show success message if permission was granted
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          // Call the callback to refresh location in parent
          widget.onPermissionChanged?.call();

          if (context.mounted) {
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
        } else {
          // Permission was denied
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Location permission denied'),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      if (!_isDisposed && mounted) {
        setState(() => _isChecking = false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showServiceDisabledDialog() {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Location Service Disabled',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Please enable location services in your device settings.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              await Future.delayed(const Duration(seconds: 1));
              if (!_isDisposed) {
                _checkLocationStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8C00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Permission Required',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Location permission was permanently denied. Please enable it in app settings.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              if (!_isDisposed) {
                _checkLocationStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8C00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'App Settings',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisableDialog() {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Disable Location', style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
        content: Text(
          'To disable location, please go to app settings and revoke location permission.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              if (!_isDisposed) {
                _checkLocationStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8C00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'App Settings',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
