// lib/maps_assets/map_building.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum BuildingType { academic, administrative, facility }

class BicolBuildingPolygon {
  final List<LatLng> points;
  final String name;
  final String description;
  final BuildingType type;

  BicolBuildingPolygon({
    required this.points,
    required this.name,
    required this.description,
    required this.type,
  });

  // Get the center point of the polygon for map navigation
  LatLng getCenterPoint() {
    double sumLat = 0;
    double sumLng = 0;

    for (LatLng point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / points.length, sumLng / points.length);
  }
}

class MapBuildings {
  // Sample building polygons for Bicol University
  static final List<BicolBuildingPolygon> campusBuildings = [
    BicolBuildingPolygon(
      points: [
        const LatLng(13.14300, 123.72430),
        const LatLng(13.14305, 123.72440),
        const LatLng(13.14290, 123.72445),
        const LatLng(13.14285, 123.72435),
      ],
      name: "College of Science - Building 1",
      description: "Main administrative offices and registrar",
      type: BuildingType.administrative,
    ),
    BicolBuildingPolygon(
      points: [
        const LatLng(13.14275, 123.72415),
        const LatLng(13.14282, 123.72425),
        const LatLng(13.14275, 123.72430),
        const LatLng(13.14268, 123.72420),
      ],
      name: "College of Science - Building 2",
      description: "Engineering programs and laboratories",
      type: BuildingType.academic,
    ),
    BicolBuildingPolygon(
      points: [
        const LatLng(13.14258, 123.72390),
        const LatLng(13.14265, 123.72400),
        const LatLng(13.14255, 123.72405),
        const LatLng(13.14248, 123.72395),
      ],
      name: "College of Science - Building 3",
      description: "Humanities and liberal arts programs",
      type: BuildingType.academic,
    ),
    BicolBuildingPolygon(
      points: [
        const LatLng(13.14210, 123.72370),
        const LatLng(13.14218, 123.72380),
        const LatLng(13.14208, 123.72385),
        const LatLng(13.14200, 123.72375),
      ],
      name: "College of Science - Building 4",
      description: "University library and study areas",
      type: BuildingType.facility,
    ),
    BicolBuildingPolygon(
      points: [
        const LatLng(13.14245, 123.72440),
        const LatLng(13.14252, 123.72450),
        const LatLng(13.14242, 123.72455),
        const LatLng(13.14235, 123.72445),
      ],
      name: "College of Nursing",
      description: "Student services and activities",
      type: BuildingType.facility,
    ),
  ];

  // Get building color based on type
  static Color getBuildingColor(BuildingType type) {
    switch (type) {
      case BuildingType.academic:
        return Colors.red;
      case BuildingType.administrative:
        return Colors.blue;
      case BuildingType.facility:
        return Colors.green;
    }
  }

  // Get filtered buildings based on search query
  static List<BicolBuildingPolygon> getFilteredBuildings([
    String searchQuery = '',
  ]) {
    if (searchQuery.isEmpty) return campusBuildings;

    return campusBuildings.where((building) {
      return building.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          building.description.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
    }).toList();
  }

  // Check if a point is inside a polygon using ray casting algorithm
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  // Find building at a specific point
  static BicolBuildingPolygon? findBuildingAtPoint(LatLng point) {
    for (final building in campusBuildings) {
      if (isPointInPolygon(point, building.points)) {
        return building;
      }
    }
    return null;
  }
}
