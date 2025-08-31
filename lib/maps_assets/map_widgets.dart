// lib/maps_assets/map_widgets.dart
import 'package:flutter/material.dart';
import 'map_building.dart';

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
        color: backgroundColor ?? _transparentBlue,
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
    return Container(
      decoration: BoxDecoration(
        color: _transparentBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderBlue, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _textColor.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, color: _iconColor),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: _iconColor),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // Build search results dropdown
  static Widget buildSearchResults({
    required List<BicolBuildingPolygon> buildings,
    required Function(BicolBuildingPolygon) onBuildingTap,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount: buildings.length,
        itemBuilder: (context, index) {
          final building = buildings[index];
          return ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue, // Use a single color for all buildings
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 16,
              ),
            ),
            title: Text(
              building.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
            subtitle: Text(
              building.description,
              style: TextStyle(
                fontSize: 12,
                color: _textColor.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onBuildingTap(building),
          );
        },
      ),
    );
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
            color: _transparentBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: _borderBlue, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: _iconColor),
            onPressed: onZoomIn,
          ),
        ),
        Container(width: 48, height: 1, color: _borderBlue),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _transparentBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: _borderBlue, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: _iconColor),
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
