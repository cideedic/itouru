// lib/maps_assets/map_boundary.dart
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:math';

class MapBoundary {
  // Bicol University West Campus center
  static const LatLng bicolUniversityCenter = LatLng(13.14413932, 123.72296108);

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
      const LatLng(13.14520684, 123.72113722),
      const LatLng(13.14498325, 123.72104204),
      const LatLng(13.14475900, 123.72094235),
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

  // ✅ STRICT BOUNDARY: Camera constraint that keeps view within campus
  static CameraConstraint getCameraConstraint() {
    final bounds = getCampusBounds();

    // Small padding to allow full building visibility at edges (≈50 meters)
    const double padding = 0.0005;

    final constrainedBounds = LatLngBounds(
      LatLng(bounds.south - padding, bounds.west - padding),
      LatLng(bounds.north + padding, bounds.east + padding),
    );

    // Use contain to prevent ANY part of the view from going outside bounds
    // This stops users from swiping/panning beyond the campus area
    return CameraConstraint.contain(bounds: constrainedBounds);
  }

  // ✅ FLEXIBLE BOUNDARY: For virtual tours that need to show gates/routes outside
  static CameraConstraint getFlexibleCameraConstraint() {
    final bounds = getCampusBounds();

    // Larger padding for virtual tours (≈700 meters)
    const double padding = 0.007;

    final expandedBounds = LatLngBounds(
      LatLng(bounds.south - padding, bounds.west - padding),
      LatLng(bounds.north + padding, bounds.east + padding),
    );

    return CameraConstraint.contain(bounds: expandedBounds);
  }

  // ✅ UNCONSTRAINED: For special cases (testing, debugging)
  static CameraConstraint getUnconstrainedCamera() {
    return CameraConstraint.unconstrained();
  }

  // ✅ SMART SELECTOR: Get appropriate constraint based on context
  static CameraConstraint getCameraConstraintForContext({
    bool isVirtualTour = false,
    bool allowExternal = false,
  }) {
    if (allowExternal) {
      return getUnconstrainedCamera();
    } else if (isVirtualTour) {
      return getFlexibleCameraConstraint();
    } else {
      return getCameraConstraint(); // Strict by default
    }
  }

  // ✅ STRICTER ZOOM LEVELS: More restrictive for campus-only view
  // These prevent zooming out too far or in beyond OSM tile limits
  static double getMinZoom() =>
      17.0; // Can't zoom out too far (campus fills screen)
  static double getMaxZoom() => 21.0; // Can't zoom in beyond OSM tiles
  static double getInitialZoom() => 17.45; // Good starting view

  // ✅ Check if point is reasonably close to campus (for routing)
  static bool isNearCampus(LatLng point, {double radiusKm = 1.0}) {
    return _distanceBetween(point, bicolUniversityCenter) <= radiusKm * 1000;
  }

  // ✅ Calculate distance between two points (Haversine formula)
  static double _distanceBetween(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        pow(sin(deltaLatRad / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLngRad / 2), 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // ✅ ACTIVE USE: Clamp a point to stay within campus bounds
  // Used by: Location tracking, user positioning, route calculations
  // Purpose: Ensures coordinates don't go outside valid campus area
  static LatLng clampToCampusBounds(LatLng point) {
    final bounds = getCampusBounds();

    final clampedLat = point.latitude.clamp(bounds.south, bounds.north);
    final clampedLng = point.longitude.clamp(bounds.west, bounds.east);

    return LatLng(clampedLat, clampedLng);
  }

  // ✅ ACTIVE USE: Get the closest point on campus boundary to a given point
  // Used by: Entrance/exit detection, gate finding, boundary snapping
  // Purpose: Find nearest valid campus entry point for off-campus users
  static LatLng getClosestPointOnBoundary(LatLng point) {
    final boundaryPoints = getCampusBoundaryPoints();

    LatLng closestPoint = boundaryPoints.first;
    double minDistance = _distanceBetween(point, closestPoint);

    for (final boundaryPoint in boundaryPoints) {
      final distance = _distanceBetween(point, boundaryPoint);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = boundaryPoint;
      }
    }

    return closestPoint;
  }
}
