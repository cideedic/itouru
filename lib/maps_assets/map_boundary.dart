// lib/maps_assets/map_boundary.dart
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MapBoundary {
  // Bicol University Main Campus coordinates (approximate)
  static const LatLng bicolUniversityCenter = LatLng(13.144378, 123.724111);

  // Define campus boundary with more restrictive bounds
  static const LatLng northEast = LatLng(13.146509, 123.726021);
  static const LatLng southWest = LatLng(13.141452, 123.720839);

  // Create bounds for the campus area
  static final LatLngBounds campusBounds = LatLngBounds(southWest, northEast);

  // Get detailed campus boundary points for polygon visualization
  static List<LatLng> getCampusBoundaryPoints() {
    return [
      const LatLng(13.146747, 123.722934), // North
      const LatLng(13.145363, 123.724613), // Northeast
      const LatLng(13.143788, 123.726284), // East
      const LatLng(13.142411, 123.725232), // Southeast
      const LatLng(13.141588, 123.723409), // South
      const LatLng(13.141669, 123.720579), // Southwest
      const LatLng(13.144075, 123.721241), // West
      const LatLng(13.146196, 123.722263), // Northwest
    ];
  }

  // Check if a point is within campus bounds
  static bool isWithinCampusBounds(LatLng point) {
    return campusBounds.contains(point);
  }

  // Get camera constraint for map
  static CameraConstraint getCameraConstraint() {
    return CameraConstraint.contain(bounds: campusBounds);
  }
}
