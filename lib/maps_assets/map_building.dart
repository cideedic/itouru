import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'building_fetcher.dart'; // Your OSM fetcher

class MapBuildings {
  static List<BicolBuildingPolygon> _campusBuildings = [];
  static bool _isInitialized = false;
  static bool _isLoading = false;

  // Initialize with known campus boundary
  static Future<void> initializeWithBoundary({
    required List<LatLng> campusBoundaryPoints,
  }) async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;

    try {
      // Use campus center from boundary points
      final campusCenter = GeometryUtils.getCenterFromPoints(
        campusBoundaryPoints,
      );

      final osmBuildings = await OSMBuildingFetcher.fetchCampusBuildings(
        campusBoundaryPoints: campusBoundaryPoints,
        campusCenter: campusCenter,
      );

      _campusBuildings = osmBuildings
          .map(
            (osm) => BicolBuildingPolygon(
              points: osm.points,
              name: osm.name,
              description: osm.description,
              osmId: osm.osmId,
              osmTags: osm.tags,
            ),
          )
          .toList();

      _isInitialized = true;
      debugPrint('Loaded ${_campusBuildings.length} campus buildings from OSM');
    } catch (e) {
      debugPrint('Error loading campus buildings: $e');
      _campusBuildings = [];
    }

    _isLoading = false;
  }

  // Getters
  static List<BicolBuildingPolygon> get campusBuildings => _campusBuildings;
  static bool get isInitialized => _isInitialized;
  static bool get isLoading => _isLoading;

  static List<BicolBuildingPolygon> getFilteredBuildings(String query) {
    if (query.isEmpty) return _campusBuildings;

    return _campusBuildings.where((building) {
      return building.name.toLowerCase().contains(query.toLowerCase()) ||
          building.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  static BicolBuildingPolygon? findBuildingAtPoint(LatLng point) {
    for (final building in _campusBuildings) {
      if (GeometryUtils.isPointInPolygon(point, building.points)) {
        return building;
      }
    }
    return null;
  }
}

// Building class without type
class BicolBuildingPolygon {
  final List<LatLng> points;
  final String name;
  final String description;
  final String? osmId;
  final Map<String, dynamic> osmTags;

  BicolBuildingPolygon({
    required this.points,
    required this.name,
    required this.description,
    this.osmId,
    this.osmTags = const {},
  });

  LatLng getCenterPoint() => GeometryUtils.getCenterFromPoints(points);
}

// Utility class for shared geometry functions
class GeometryUtils {
  // Shared point-in-polygon algorithm
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    final double x = point.latitude;
    final double y = point.longitude;

    for (int i = 0; i < polygon.length; i++) {
      final LatLng vertex1 = polygon[i];
      final LatLng vertex2 = polygon[(i + 1) % polygon.length];

      if (((vertex1.longitude > y) != (vertex2.longitude > y)) &&
          (x <
              (vertex2.latitude - vertex1.latitude) *
                      (y - vertex1.longitude) /
                      (vertex2.longitude - vertex1.longitude) +
                  vertex1.latitude)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }

  // Shared center point calculation
  static LatLng getCenterFromPoints(List<LatLng> points) {
    double sumLat = 0;
    double sumLng = 0;

    for (LatLng point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / points.length, sumLng / points.length);
  }
}
