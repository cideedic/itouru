import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'map_building.dart';

class OSMBuildingFetcher {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetch landmarks (parks, monuments, etc.)
  static Future<List<LandmarkPoint>> fetchCampusLandmarks({
    required List<LatLng> campusBoundaryPoints,
    required LatLng campusCenter,
  }) async {
    final bounds = _getBoundingBox(campusBoundaryPoints);

    // Query for parks and other landmark amenities
    final query =
        '''
    [out:json][timeout:25];
    (
      node["leisure"="park"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      way["leisure"="park"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      node["tourism"="attraction"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      node["historic"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      relation["leisure"="park"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
    );
    out body;
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
        final allLandmarks = _parseLandmarkPoints(data, campusBoundaryPoints);

        // Filter to only include landmarks within campus polygon
        return allLandmarks.where((landmark) {
          return GeometryUtils.isPointInPolygon(
            landmark.position,
            campusBoundaryPoints,
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch landmarks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching landmarks: $e');
    }
  }

  /// Fetch sports/leisure facilities including ALL pool types
  static Future<List<FacilityArea>> fetchCampusFacilities({
    required List<LatLng> campusBoundaryPoints,
    required LatLng campusCenter,
  }) async {
    final bounds = _getBoundingBox(campusBoundaryPoints);

    // Enhanced query for sports/leisure areas and ALL swimming pool variations
    final query =
        '''
    [out:json][timeout:25];
    (
      way["leisure"="pitch"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      way["leisure"="track"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      way["leisure"="stadium"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      way["leisure"="sports_centre"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      way["leisure"="swimming_pool"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      way["sport"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      way["amenity"="swimming_pool"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      node["leisure"="swimming_pool"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      node["amenity"="swimming_pool"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      node["sport"="swimming"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      relation["leisure"="pitch"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      relation["leisure"="track"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      relation["leisure"="swimming_pool"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
      relation["sport"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
    );
    out body;
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
        final allFacilities = _parseFacilities(data, campusBoundaryPoints);

        // Filter to only include facilities within campus polygon
        return allFacilities.where((facility) {
          if (facility.points.length == 1) {
            return GeometryUtils.isPointInPolygon(
              facility.points[0],
              campusBoundaryPoints,
            );
          }
          // For polygon facilities
          final center = GeometryUtils.getCenterFromPoints(facility.points);
          return GeometryUtils.isPointInPolygon(center, campusBoundaryPoints);
        }).toList();
      } else {
        throw Exception('Failed to fetch facilities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching facilities: $e');
    }
  }

  /// Fetch college ground POINTS (nodes) within campus boundary
  static Future<List<CollegeGroundPoint>> fetchCampusCollegeGrounds({
    required List<LatLng> campusBoundaryPoints,
    required LatLng campusCenter,
  }) async {
    final bounds = _getBoundingBox(campusBoundaryPoints);

    final query =
        '''
    [out:json][timeout:25];
    (
      node["amenity"="college"](${bounds.south},${bounds.west},${bounds.north},${bounds.east});
    );
    out body;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allColleges = _parseCollegeGroundPoints(data);

        return allColleges.where((college) {
          return GeometryUtils.isPointInPolygon(
            college.position,
            campusBoundaryPoints,
          );
        }).toList();
      } else {
        throw Exception(
          'Failed to fetch college grounds: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching college grounds: $e');
    }
  }

  /// Fetch buildings within a defined campus boundary polygon
  static Future<List<BuildingPolygon>> fetchCampusBuildings({
    required List<LatLng> campusBoundaryPoints,
    required LatLng campusCenter,
    double radiusMeters = 500,
  }) async {
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

  /// Parse landmarks from OSM response
  static List<LandmarkPoint> _parseLandmarkPoints(
    Map<String, dynamic> data,
    List<LatLng> campusBoundary,
  ) {
    final List<LandmarkPoint> landmarks = [];

    if (data['elements'] != null) {
      for (final element in data['elements']) {
        LatLng? position;

        // Handle nodes (points)
        if (element['type'] == 'node' &&
            element['lat'] != null &&
            element['lon'] != null) {
          position = LatLng(
            element['lat'].toDouble(),
            element['lon'].toDouble(),
          );
        }
        // Handle ways (get center point)
        else if (element['type'] == 'way' && element['geometry'] != null) {
          final List<LatLng> points = [];
          for (final node in element['geometry']) {
            if (node['lat'] != null && node['lon'] != null) {
              points.add(
                LatLng(node['lat'].toDouble(), node['lon'].toDouble()),
              );
            }
          }
          if (points.isNotEmpty) {
            position = GeometryUtils.getCenterFromPoints(points);
          }
        }

        if (position != null) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          landmarks.add(
            LandmarkPoint(
              position: position,
              name: tags['name'] ?? 'Unknown Landmark',
              osmId: element['id']?.toString(),
              tags: tags,
            ),
          );
        }
      }
    }

    return landmarks;
  }

  /// Parse facilities (including node-based pools)
  static List<FacilityArea> _parseFacilities(
    Map<String, dynamic> data,
    List<LatLng> campusBoundary,
  ) {
    final List<FacilityArea> facilities = [];

    if (data['elements'] != null) {
      for (final element in data['elements']) {
        List<LatLng> points = [];
        final tags = element['tags'] as Map<String, dynamic>? ?? {};

        // Handle ways (polygons)
        if (element['type'] == 'way' && element['geometry'] != null) {
          for (final node in element['geometry']) {
            if (node['lat'] != null && node['lon'] != null) {
              points.add(
                LatLng(node['lat'].toDouble(), node['lon'].toDouble()),
              );
            }
          }
        }
        // Handle nodes (points)
        else if (element['type'] == 'node' &&
            element['lat'] != null &&
            element['lon'] != null) {
          points = [
            LatLng(element['lat'].toDouble(), element['lon'].toDouble()),
          ];
        }
        // Handle relations
        else if (element['type'] == 'relation' && element['members'] != null) {
          // For relations, try to get geometry from members
          for (final member in element['members']) {
            if (member['geometry'] != null) {
              for (final node in member['geometry']) {
                if (node['lat'] != null && node['lon'] != null) {
                  points.add(
                    LatLng(node['lat'].toDouble(), node['lon'].toDouble()),
                  );
                }
              }
            }
          }
        }

        if (points.isNotEmpty) {
          facilities.add(
            FacilityArea(
              points: points,
              name: tags['name'] ?? _getFacilityDefaultName(tags),
              description: _getFacilityDescription(tags),
              facilityType: _getFacilityType(tags),
              osmId: element['id']?.toString(),
              tags: tags,
            ),
          );
        }
      }
    }

    return facilities;
  }

  /// Parse college ground POINTS from OSM response
  static List<CollegeGroundPoint> _parseCollegeGroundPoints(
    Map<String, dynamic> data,
  ) {
    final List<CollegeGroundPoint> colleges = [];

    if (data['elements'] != null) {
      for (final element in data['elements']) {
        if (element['type'] == 'node' &&
            element['lat'] != null &&
            element['lon'] != null) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};

          colleges.add(
            CollegeGroundPoint(
              position: LatLng(
                element['lat'].toDouble(),
                element['lon'].toDouble(),
              ),
              name: tags['name'] ?? 'Unknown College',
              osmId: element['id']?.toString(),
              tags: tags,
            ),
          );
        }
      }
    }

    return colleges;
  }

  /// Get default name for facility
  static String _getFacilityDefaultName(Map<String, dynamic> tags) {
    // Check for swimming pool first
    if (tags['leisure'] == 'swimming_pool' ||
        tags['amenity'] == 'swimming_pool' ||
        tags['sport'] == 'swimming') {
      return 'Swimming Pool';
    }

    if (tags['sport'] != null) return '${tags['sport']} Field';
    if (tags['leisure'] == 'pitch') return 'Sports Field';
    if (tags['leisure'] == 'track') return 'Running Track';
    if (tags['leisure'] == 'stadium') return 'Stadium';
    return 'Sports Facility';
  }

  /// Get facility description
  static String _getFacilityDescription(Map<String, dynamic> tags) {
    if (tags['description'] != null) return tags['description'];

    // Better description for pools
    if (tags['leisure'] == 'swimming_pool' ||
        tags['amenity'] == 'swimming_pool' ||
        tags['sport'] == 'swimming') {
      String desc = 'Swimming Pool';
      if (tags['length'] != null) desc += ' (${tags['length']}m)';
      if (tags['capacity'] != null) desc += ' - ${tags['capacity']} capacity';
      return desc;
    }

    if (tags['sport'] != null) return 'Sport: ${tags['sport']}';
    if (tags['leisure'] != null) return 'Leisure: ${tags['leisure']}';
    return 'Sports Facility';
  }

  ///Determine facility type (better pool detection)
  static FacilityType _getFacilityType(Map<String, dynamic> tags) {
    final leisure = tags['leisure']?.toString().toLowerCase();
    final amenity = tags['amenity']?.toString().toLowerCase();
    final sport = tags['sport']?.toString().toLowerCase();

    // Check all possible pool tags
    if (leisure == 'swimming_pool' ||
        amenity == 'swimming_pool' ||
        sport == 'swimming') {
      return FacilityType.swimmingPool;
    }

    if (leisure == 'track' || sport == 'athletics') return FacilityType.track;
    if (leisure == 'stadium') return FacilityType.stadium;
    if (sport != null) return FacilityType.sportsField;

    return FacilityType.other;
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

    if (building == 'university' ||
        building == 'school' ||
        amenity == 'university' ||
        amenity == 'school') {
      return BuildingType.academic;
    }

    if (building == 'office' ||
        building == 'government' ||
        amenity == 'townhall' ||
        amenity == 'office') {
      return BuildingType.administrative;
    }

    if (building == 'hospital' ||
        building == 'library' ||
        amenity == 'hospital' ||
        amenity == 'library') {
      return BuildingType.facility;
    }

    return BuildingType.facility;
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

/// College Ground point class (for markers, not polygons)
class CollegeGroundPoint {
  final LatLng position;
  final String name;
  final String? osmId;
  final Map<String, dynamic> tags;

  CollegeGroundPoint({
    required this.position,
    required this.name,
    this.osmId,
    this.tags = const {},
  });
}

/// landmark point class (for parks, monuments, etc.)
class LandmarkPoint {
  final LatLng position;
  final String name;
  final String? osmId;
  final Map<String, dynamic> tags;

  LandmarkPoint({
    required this.position,
    required this.name,
    this.osmId,
    this.tags = const {},
  });
}

/// Facility Area class (fields, pools, ovals, etc.)
class FacilityArea {
  final List<LatLng> points;
  final String name;
  final String description;
  final FacilityType facilityType;
  final String? osmId;
  final Map<String, dynamic> tags;

  FacilityArea({
    required this.points,
    required this.name,
    required this.description,
    required this.facilityType,
    this.osmId,
    this.tags = const {},
  });

  LatLng getCenterPoint() => GeometryUtils.getCenterFromPoints(points);
}

enum BuildingType { academic, administrative, facility }

enum FacilityType { sportsField, track, stadium, swimmingPool, other }
