// lib/maps_assets/map_widgets.dart
import 'package:flutter/material.dart';
import 'map_building.dart';
import 'building_matcher.dart';

class MapWidgets {
  // Consistent transparent blue color scheme
  static const Color _transparentBlue = Color(
    0x40E3F2FD,
  ); // Light blue with transparency
  static const Color _borderBlue = Color(
    0x60BBDEFB,
  ); // Slightly more opaque blue border
  static const Color _textColor = Color.fromARGB(
    136,
    55,
    107,
    132,
  ); // Darker blue for text
  static const Color _iconColor = Color(0xFF1976D2); // Blue for icons

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
        color:
            backgroundColor ??
            Colors.white, // ✅ Default to white instead of transparent blue

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
            color: Colors.white, // ✨ White background
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
                        setState(() {}); // Rebuild to hide clear button
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
              setState(() {}); // Rebuild to show/hide clear button
            },
          ),
        );
      },
    );
  }

  // Build search results dropdown - also make it white
  static Widget buildSearchResults({
    required List<dynamic>
    results, // ✨ CHANGED: Accept dynamic list (buildings + markers)
    required Function(dynamic) onResultTap, // ✨ CHANGED: Accept dynamic type
  }) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300,
      ), // ✨ Taller for subtitles
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
                  // Building
                  name =
                      result.databaseName ??
                      result.name; // Primary: formal name
                  subtitle = result.databaseNickname; // Secondary: nickname
                  secondaryText = result.isFacility
                      ? _getBuildingTypeText(result)
                      : null;
                  icon = Icons.business;
                  iconColor = Colors.orange;
                } else if (result is BicolMarker) {
                  // College or Landmark
                  name = result.displayName;
                  if (result.isCollege) {
                    subtitle = result.abbreviation;
                    secondaryText = null;
                    icon = Icons.school;
                    iconColor = Colors.blue;
                  } else {
                    subtitle = 'Landmark';
                    icon = Icons.place;
                    iconColor = Colors.red;
                  }
                } else if (result is OfficeData) {
                  // ✨ NEW: Office
                  name = result.name;
                  subtitle = result.abbreviation;
                  secondaryText = BuildingMatcher.getBuildingNameById(
                    result.buildingId,
                  );
                  icon = Icons.work_outline;
                  iconColor = Colors.purple;
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
                        color: iconColor.withOpacity(0.1),
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

  // ✨ NEW: Helper to get building type text
  static String _getBuildingTypeText(BicolBuildingPolygon building) {
    if (building.isFacility) {
      if (building.isPool) return 'Swimming Pool';
      if (building.isField) return 'Sports Facility';
      return 'Facility';
    }
    // You can add more logic here based on building type from database
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
            color: Colors.white, // ✅ White background
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
            color: Colors.white, // ✅ White background
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

  // Build bottom legend bar
  static Widget buildLegendBar({required bool isLocationConnected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _transparentBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderBlue, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          buildLegendItem(Colors.red, 'Academic'),
          const SizedBox(width: 16),
          buildLegendItem(Colors.blue, 'Admin'),
          const SizedBox(width: 16),
          buildLegendItem(Colors.green, 'Facilities'),
          const Spacer(),
          if (isLocationConnected)
            Icon(Icons.circle, color: Colors.green, size: 8),
          if (isLocationConnected) const SizedBox(width: 4),
          Text(
            isLocationConnected ? 'Connected' : 'Finding location...',
            style: TextStyle(
              fontSize: 12,
              color: isLocationConnected ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
