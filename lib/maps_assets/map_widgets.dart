// lib/maps_assets/map_widgets.dart
import 'package:flutter/material.dart';
import 'map_building.dart';

class MapWidgets {
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : Icon(icon, color: iconColor ?? Colors.grey[600]),
        onPressed: onPressed,
      ),
    );
  }

  // Build search bar
  static Widget buildSearchBar({
    required TextEditingController controller,
    required Function(String) onChanged,
    required VoidCallback onClear,
    String hintText = 'Search buildings, locations...',
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                color: MapBuildings.getBuildingColor(building.type),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              building.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: Colors.grey[700]),
            onPressed: onZoomIn,
          ),
        ),
        Container(width: 48, height: 1, color: Colors.grey[300]),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: Colors.grey[700]),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
