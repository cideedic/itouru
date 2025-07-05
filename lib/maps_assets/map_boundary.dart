// lib/maps_assets/map_boundary.dart
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';

class MapBoundary {
  // Bicol University West Campus center
  static const LatLng bicolUniversityCenter = LatLng(13.1441, 123.7241);

  // Exact boundary points from GeoJSON export
  static List<LatLng> getCampusBoundaryPoints() {
    return [
      const LatLng(13.146022, 123.7232959),
      const LatLng(13.1464046, 123.7227903),
      const LatLng(13.1464687, 123.7226864),
      const LatLng(13.1463677, 123.7225648),
      const LatLng(13.1462729, 123.722453),
      const LatLng(13.1462079, 123.7223757),
      const LatLng(13.1461957, 123.7223612),
      const LatLng(13.1461209, 123.7222796),
      const LatLng(13.1460985, 123.7222534),
      const LatLng(13.145675, 123.7218247),
      const LatLng(13.1456025, 123.7217525),
      const LatLng(13.1449527, 123.7214289),
      const LatLng(13.144593, 123.7214354),
      const LatLng(13.1444454, 123.7208822),
      const LatLng(13.1443412, 123.7201676),
      const LatLng(13.143907, 123.7196946),
      const LatLng(13.143252, 123.7189132),
      const LatLng(13.1429334, 123.7193155),
      const LatLng(13.1426643, 123.7195194),
      const LatLng(13.1424528, 123.7197205),
      const LatLng(13.142546, 123.7202223),
      const LatLng(13.1426135, 123.7206329),
      const LatLng(13.1422757, 123.7209031),
      const LatLng(13.1420372, 123.7210789),
      const LatLng(13.1416417, 123.7214981),
      const LatLng(13.1419598, 123.7221865),
      const LatLng(13.1424028, 123.7224282),
      const LatLng(13.1424304, 123.7230819),
      const LatLng(13.142227, 123.7231538),
      const LatLng(13.1420598, 123.7232408),
      const LatLng(13.1419777, 123.7235596),
      const LatLng(13.1418561, 123.7239785),
      const LatLng(13.1437163, 123.7261525),
      const LatLng(13.1437614, 123.7261545),
      const LatLng(13.1442145, 123.7255704),
      const LatLng(13.146022, 123.7232959),
    ];
  }

  // Calculate bounding box from the exact campus boundary
  static LatLngBounds getCampusBounds() {
    final points = getCampusBoundaryPoints();

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng), // Southwest
      LatLng(maxLat, maxLng), // Northeast
    );
  }

  // Check if a point is within the exact campus boundary using ray casting
  static bool isWithinCampusBounds(LatLng point) {
    return _isPointInPolygon(point, getCampusBoundaryPoints());
  }

  // Ray casting algorithm to check if point is inside polygon
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
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

  // Get camera constraint with padding to prevent going outside campus
  static CameraConstraint getCameraConstraint() {
    final bounds = getCampusBounds();

    // Add small padding to prevent edge cases
    const double padding = 0.0005;

    final paddedBounds = LatLngBounds(
      LatLng(bounds.south - padding, bounds.west - padding),
      LatLng(bounds.north + padding, bounds.east + padding),
    );

    return CameraConstraint.contain(bounds: paddedBounds);
  }

  // Get minimum and maximum zoom levels appropriate for campus
  static double getMinZoom() => 16.0; // Prevent zooming out too far
  static double getMaxZoom() => 22.0; // Allow detailed view
  static double getInitialZoom() => 18.0; // Good overview of campus

  // Parse GeoJSON data if you want to load it dynamically
  static List<LatLng> parseGeoJsonBoundary(String geoJsonString) {
    final Map<String, dynamic> geoJson = json.decode(geoJsonString);
    final List<LatLng> points = [];

    if (geoJson['features'] != null && geoJson['features'].isNotEmpty) {
      final feature = geoJson['features'][0];
      if (feature['geometry'] != null &&
          feature['geometry']['type'] == 'Polygon' &&
          feature['geometry']['coordinates'] != null) {
        final coordinates = feature['geometry']['coordinates'][0];

        for (final coord in coordinates) {
          if (coord is List && coord.length >= 2) {
            // GeoJSON format is [longitude, latitude]
            points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
          }
        }
      }
    }

    return points;
  }
}
