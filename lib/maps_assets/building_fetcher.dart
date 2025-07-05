import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'map_building.dart'; // Import for GeometryUtils

class OSMBuildingFetcher {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetch buildings within a defined campus boundary polygon
  static Future<List<BuildingPolygon>> fetchCampusBuildings({
    required List<LatLng> campusBoundaryPoints,
    required LatLng campusCenter,
    double radiusMeters = 500, // Smaller radius for campus-only data
  }) async {
    // Get the bounding box of the campus boundary
    final bounds = _getBoundingBox(campusBoundaryPoints);
    final query =
        '''
    [out:json][timeout:25];
    (
      way["building"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      relation["building"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
    );
    out geom;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allBuildings = _parseBuildings(data);

        // Filter buildings to only include those within the campus polygon
        return allBuildings.where((building) {
          final center = building.getCenterPoint();
          return GeometryUtils.isPointInPolygon(center, campusBoundaryPoints);
        }).toList();
      } else {
        throw Exception('Failed to fetch buildings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching buildings: $e');
    }
  }

  /// Fetch buildings by bounding box
  static Future<List<BuildingPolygon>> fetchBuildings({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final query =
        '''
    [out:json][timeout:25];
    (
      way["building"]($south,$west,$north,$east);
      relation["building"]($south,$west,$north,$east);
    );
    out geom;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseBuildings(data);
      } else {
        throw Exception('Failed to fetch buildings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching buildings: $e');
    }
  }

  /// Fetch building by name
  static Future<List<BuildingPolygon>> fetchBuildingByName({
    required String buildingName,
    required LatLng center,
    double radiusMeters = 1000,
  }) async {
    final query =
        '''
    [out:json][timeout:25];
    (
      way["building"]["name"~"$buildingName",i](around:$radiusMeters,${center.latitude},${center.longitude});
      way["building"]["building"~"$buildingName",i](around:$radiusMeters,${center.latitude},${center.longitude});
      relation["building"]["name"~"$buildingName",i](around:$radiusMeters,${center.latitude},${center.longitude});
    );
    out geom;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseBuildings(data);
      } else {
        throw Exception('Failed to fetch building: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching building: $e');
    }
  }

  /// Get bounding box from a list of points
  static _BoundingBox _getBoundingBox(List<LatLng> points) {
    double north = points.first.latitude;
    double south = points.first.latitude;
    double east = points.first.longitude;
    double west = points.first.longitude;

    for (final point in points) {
      north = math.max(north, point.latitude);
      south = math.min(south, point.latitude);
      east = math.max(east, point.longitude);
      west = math.min(west, point.longitude);
    }

    return _BoundingBox(north: north, south: south, east: east, west: west);
  }

  /// Parse buildings from OSM response
  static List<BuildingPolygon> _parseBuildings(Map<String, dynamic> data) {
    final List<BuildingPolygon> buildings = [];

    if (data['elements'] != null) {
      for (final element in data['elements']) {
        if (element['type'] == 'way' && element['geometry'] != null) {
          final List<LatLng> points = [];

          for (final node in element['geometry']) {
            if (node['lat'] != null && node['lon'] != null) {
              points.add(
                LatLng(node['lat'].toDouble(), node['lon'].toDouble()),
              );
            }
          }

          if (points.isNotEmpty) {
            final tags = element['tags'] as Map<String, dynamic>? ?? {};
            buildings.add(
              BuildingPolygon(
                points: points,
                name: tags['name'] ?? tags['building'] ?? 'Unknown Building',
                description: _getBuildingDescription(tags),
                type: _getBuildingType(tags),
                osmId: element['id']?.toString(),
                tags: tags,
              ),
            );
          }
        }
      }
    }

    return buildings;
  }

  /// Get building description from tags
  static String _getBuildingDescription(Map<String, dynamic> tags) {
    if (tags['description'] != null) return tags['description'];
    if (tags['amenity'] != null) return 'Amenity: ${tags['amenity']}';
    if (tags['building'] != null && tags['building'] != 'yes') {
      return 'Building type: ${tags['building']}';
    }
    return 'Building';
  }

  /// Determine building type from OSM tags
  static BuildingType _getBuildingType(Map<String, dynamic> tags) {
    final building = tags['building']?.toString().toLowerCase();
    final amenity = tags['amenity']?.toString().toLowerCase();

    // Academic buildings
    if (building == 'university' ||
        building == 'school' ||
        amenity == 'university' ||
        amenity == 'school') {
      return BuildingType.academic;
    }

    // Administrative buildings
    if (building == 'office' ||
        building == 'government' ||
        amenity == 'townhall' ||
        amenity == 'office') {
      return BuildingType.administrative;
    }

    // Facilities
    if (building == 'hospital' ||
        building == 'library' ||
        amenity == 'hospital' ||
        amenity == 'library') {
      return BuildingType.facility;
    }

    return BuildingType.facility; // Default
  }
}

/// Bounding box helper class
class _BoundingBox {
  final double north;
  final double south;
  final double east;
  final double west;

  _BoundingBox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

/// OSM Building polygon class
class BuildingPolygon {
  final List<LatLng> points;
  final String name;
  final String description;
  final BuildingType type;
  final String? osmId;
  final Map<String, dynamic> tags;

  BuildingPolygon({
    required this.points,
    required this.name,
    required this.description,
    required this.type,
    this.osmId,
    this.tags = const {},
  });

  LatLng getCenterPoint() => GeometryUtils.getCenterFromPoints(points);
}

enum BuildingType { academic, administrative, facility }
