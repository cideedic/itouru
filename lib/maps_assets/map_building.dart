import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'building_fetcher.dart';
import 'building_matcher.dart';

class MapBuildings {
  static List<BicolBuildingPolygon> _campusBuildings = [];
  static List<BicolMarker> _campusMarkers = [];
  static bool _isInitialized = false;
  static bool _isLoading = false;

  // Store database names for search
  static List<DatabaseSearchItem> _databaseSearchItems = [];

  // Track processed landmarks to avoid duplicates
  static Set<int> _processedLandmarkIds = {};

  static Future<void> initializeWithBoundary({
    required List<LatLng> campusBoundaryPoints,
  }) async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;

    try {
      // Load data from Supabase
      await BuildingMatcher.loadBuildings();
      await BuildingMatcher.loadColleges();
      await BuildingMatcher.loadOffices();

      final campusCenter = GeometryUtils.getCenterFromPoints(
        campusBoundaryPoints,
      );

      // Fetch buildings, colleges, facilities, AND landmarks
      final osmBuildings = await OSMBuildingFetcher.fetchCampusBuildings(
        campusBoundaryPoints: campusBoundaryPoints,
        campusCenter: campusCenter,
      );

      final osmCollegeGrounds =
          await OSMBuildingFetcher.fetchCampusCollegeGrounds(
            campusBoundaryPoints: campusBoundaryPoints,
            campusCenter: campusCenter,
          );

      final osmFacilities = await OSMBuildingFetcher.fetchCampusFacilities(
        campusBoundaryPoints: campusBoundaryPoints,
        campusCenter: campusCenter,
      );

      // Fetch landmarks
      final osmLandmarks = await OSMBuildingFetcher.fetchCampusLandmarks(
        campusBoundaryPoints: campusBoundaryPoints,
        campusCenter: campusCenter,
      );

      _campusBuildings = [];
      _campusMarkers = [];
      _databaseSearchItems = [];
      _processedLandmarkIds = {}; // Reset processed landmarks

      // Process buildings
      debugPrint('\n🏢 Processing ${osmBuildings.length} buildings from OSM');
      for (var osm in osmBuildings) {
        final buildingMatch = BuildingMatcher.matchBuilding(osm.name);

        if (buildingMatch != null && !buildingMatch.isLandmark) {
          final building = BicolBuildingPolygon(
            points: osm.points,
            name: osm.name,
            description: osm.description,
            osmId: osm.osmId,
            osmTags: osm.tags,
            buildingId: buildingMatch.id,
            databaseName: buildingMatch.databaseName,
            databaseNickname: buildingMatch.databaseNickname,
          );
          _campusBuildings.add(building);
          debugPrint(
            '🏢 Building: ${building.databaseName} | Nickname: ${building.databaseNickname}',
          );

          // Add to searchable items with database name
          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: buildingMatch.databaseName ?? osm.name,
              nickname: buildingMatch.databaseNickname,
              type: 'building',
              reference: building,
            ),
          );
        } else if (buildingMatch != null && buildingMatch.isLandmark) {
          // LANDMARK BUILDING - Create marker instead of polygon
          final center = GeometryUtils.getCenterFromPoints(osm.points);
          final marker = BicolMarker(
            position: center,
            name: osm.name,
            type: 'landmark',
            itemId: buildingMatch.id,
            buildingId: buildingMatch.id,
            databaseName: buildingMatch.databaseName,
          );
          _campusMarkers.add(marker);
          _processedLandmarkIds.add(buildingMatch.id); // Track this landmark

          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: buildingMatch.databaseName ?? osm.name,
              type: 'landmark',
              reference: marker,
            ),
          );

          debugPrint(
            '🏛️ Landmark from building: ${buildingMatch.databaseName} (ID: ${buildingMatch.id})',
          );
        } else if (buildingMatch == null) {
          final building = BicolBuildingPolygon(
            points: osm.points,
            name: osm.name,
            description: osm.description,
            osmId: osm.osmId,
            osmTags: osm.tags,
            buildingId: null,
            databaseName: null,
            databaseNickname: null,
          );
          _campusBuildings.add(building);

          // Still searchable by OSM name
          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: osm.name,
              type: 'building',
              reference: building,
            ),
          );
        }
      }

      // Process facilities
      debugPrint('\n⚽ Processing ${osmFacilities.length} facilities from OSM');
      for (var facility in osmFacilities) {
        debugPrint(
          '   OSM Facility: "${facility.name}" (${facility.facilityType})',
        );

        final facilityMatch = BuildingMatcher.matchFacility(facility.name);

        if (facilityMatch != null) {
          final building = BicolBuildingPolygon(
            points: facility.points,
            name: facility.name,
            description: facility.description,
            osmId: facility.osmId,
            osmTags: facility.tags,
            buildingId: facilityMatch.id,
            facilityType: facility.facilityType,
            databaseName: facilityMatch.databaseName,
            databaseNickname: facilityMatch.databaseNickname,
          );
          _campusBuildings.add(building);

          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: facilityMatch.databaseName ?? facility.name,
              nickname: facilityMatch.databaseNickname,
              type: 'facility',
              reference: building,
            ),
          );

          debugPrint(
            '✅ Matched facility: ${facility.name} (ID: ${facilityMatch.id})',
          );
        } else {
          final building = BicolBuildingPolygon(
            points: facility.points,
            name: facility.name,
            description: facility.description,
            osmId: facility.osmId,
            osmTags: facility.tags,
            buildingId: null,
            facilityType: facility.facilityType,
            databaseName: null,
            databaseNickname: null,
          );
          _campusBuildings.add(building);

          // Still searchable by OSM name
          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: facility.name,
              type: 'facility',
              reference: building,
            ),
          );

          debugPrint('⚠️  No match for facility: "${facility.name}"');
        }
      }

      // Process college ground points
      debugPrint(
        '\n🎓 Processing ${osmCollegeGrounds.length} college grounds from OSM',
      );
      for (var collegeGround in osmCollegeGrounds) {
        debugPrint(
          '   OSM College: "${collegeGround.name}" at ${collegeGround.position}',
        );

        final collegeMatch = BuildingMatcher.matchCollegeGround(
          collegeGround.name,
        );

        if (collegeMatch != null) {
          final marker = BicolMarker(
            position: collegeGround.position,
            name: collegeMatch.name,
            abbreviation: collegeMatch.abbreviation,
            type: 'college',
            itemId: collegeMatch.id,
            buildingId: null,
            databaseName: collegeMatch.name,
          );
          _campusMarkers.add(marker);

          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: collegeMatch.name,
              abbreviation: collegeMatch.abbreviation,
              type: 'college',
              reference: marker,
            ),
          );

          debugPrint(
            '✅ Created college marker: ${collegeMatch.name} (ID: ${collegeMatch.id})',
          );
        } else {
          debugPrint(
            '⚠️  No match for college ground: "${collegeGround.name}"',
          );
        }
      }

      // Process landmarks
      debugPrint('\n🏛️ Processing ${osmLandmarks.length} landmarks from OSM');
      for (var landmark in osmLandmarks) {
        debugPrint(
          '   OSM Landmark: "${landmark.name}" at ${landmark.position}',
        );

        // Try to match with Supabase building database
        final buildingMatch = BuildingMatcher.matchBuilding(landmark.name);

        debugPrint('    Trying to match: "${landmark.name}"');
        debugPrint(
          '    Match result: ${buildingMatch?.id} (isLandmark: ${buildingMatch?.isLandmark})',
        );

        if (buildingMatch != null && buildingMatch.isLandmark) {
          // Check if already processed from buildings
          if (_processedLandmarkIds.contains(buildingMatch.id)) {
            debugPrint(
              'Skipping duplicate landmark: ${buildingMatch.databaseName} (already added from building)',
            );
            continue;
          }

          // Matched landmark
          final marker = BicolMarker(
            position: landmark.position,
            name: landmark.name,
            type: 'landmark',
            itemId: buildingMatch.id,
            buildingId: buildingMatch.id,
            databaseName: buildingMatch.databaseName,
          );
          _campusMarkers.add(marker);
          _processedLandmarkIds.add(buildingMatch.id); // Track this landmark

          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: buildingMatch.databaseName ?? landmark.name,
              type: 'landmark',
              reference: marker,
            ),
          );

          debugPrint(
            'W Created landmark marker with ID: ${buildingMatch.id} for ${landmark.name}',
          );
        } else {
          // Unmatched landmar
          final marker = BicolMarker(
            position: landmark.position,
            name: landmark.name,
            type: 'Landmark',
            itemId: 0, // Use 0 for unmatched landmarks
            buildingId: null,
            databaseName: null,
          );
          _campusMarkers.add(marker);

          // Still searchable by OSM name
          _databaseSearchItems.add(
            DatabaseSearchItem(
              name: landmark.name,
              type: 'landmark',
              reference: marker,
            ),
          );

          debugPrint(
            '⚠️  Created unmatched landmark marker: "${landmark.name}" (no building_id)',
          );
        }
      }

      _isInitialized = true;

      // Show statistics
      debugPrint('\n📊 === LOADING SUMMARY ===');
      debugPrint(
        '🏢 Loaded ${_campusBuildings.length} campus polygons from OSM',
      );
      debugPrint(
        '✅ Matched ${_campusBuildings.where((b) => b.buildingId != null).length} to Supabase',
      );
      debugPrint('📍 Created ${_campusMarkers.length} markers:');
      debugPrint(
        '    🎓 ${_campusMarkers.where((m) => m.type == 'college').length} colleges',
      );
      debugPrint(
        '    🏛️ ${_campusMarkers.where((m) => m.type == 'landmark').length} landmarks',
      );
      debugPrint(
        '⚽ Facilities: ${_campusBuildings.where((b) => b.isFacility).length}',
      );
      debugPrint(
        '    🏊 Pools: ${_campusBuildings.where((b) => b.isPool).length}',
      );
      debugPrint(
        '    🏟️ Fields: ${_campusBuildings.where((b) => b.isField).length}',
      );
      debugPrint('🔍 Searchable items: ${_databaseSearchItems.length}');
      debugPrint('📊 === END SUMMARY ===\n');
    } catch (e) {
      debugPrint('❌ Error loading campus buildings: $e');
      _campusBuildings = [];
      _campusMarkers = [];
      _databaseSearchItems = [];
      _processedLandmarkIds = {};
    }

    final allOffices = BuildingMatcher.getAllOffices();
    for (var office in allOffices) {
      final buildingName = BuildingMatcher.getBuildingNameById(
        office.buildingId,
      );
      if (buildingName != null) {
        _databaseSearchItems.add(
          DatabaseSearchItem(
            name: office.name,
            abbreviation: office.abbreviation,
            subtitle: buildingName,
            type: 'office',
            reference: office,
          ),
        );
      }
    }

    _isLoading = false;
  }

  // Getters
  static List<BicolBuildingPolygon> get campusBuildings => _campusBuildings;
  static List<BicolMarker> get campusMarkers => _campusMarkers;
  static bool get isInitialized => _isInitialized;
  static bool get isLoading => _isLoading;

  static List<BicolMarker> get colleges =>
      _campusMarkers.where((m) => m.type == 'college').toList();

  static List<BicolMarker> get landmarks =>
      _campusMarkers.where((m) => m.type == 'landmark').toList();

  static List<BicolBuildingPolygon> getFilteredBuildings(String query) {
    if (query.isEmpty) return _campusBuildings;

    return _campusBuildings.where((building) {
      final dbName = building.databaseName?.toLowerCase() ?? '';
      final osmName = building.name.toLowerCase();
      final desc = building.description.toLowerCase();
      final q = query.toLowerCase();

      return dbName.contains(q) || osmName.contains(q) || desc.contains(q);
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

  static BicolMarker? findMarkerNearPoint(
    LatLng point, {
    double radiusMeters = 50,
  }) {
    const Distance distance = Distance();

    for (final marker in _campusMarkers) {
      final distanceToMarker = distance.as(
        LengthUnit.Meter,
        point,
        marker.position,
      );

      if (distanceToMarker <= radiusMeters) {
        return marker;
      }
    }
    return null;
  }

  // Search function
  static List<dynamic> searchAll(String query) {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();
    final spacelessQuery = normalizedQuery.replaceAll(' ', '');

    List<dynamic> results = [];
    Set<dynamic> addedReferences = {};

    // Search through database items with  matching
    final matchedItems = _databaseSearchItems.where((item) {
      final nameMatch = item.name.toLowerCase().contains(normalizedQuery);

      final abbreviationMatch =
          item.abbreviation != null &&
          item.abbreviation!.toLowerCase().contains(normalizedQuery);

      final spacelessAbbreviationMatch =
          item.abbreviation != null &&
          item.abbreviation!
              .toLowerCase()
              .replaceAll(' ', '')
              .contains(spacelessQuery);

      final nicknameMatch =
          item.nickname != null &&
          item.nickname!.toLowerCase().contains(normalizedQuery);

      final spacelessNicknameMatch =
          item.nickname != null &&
          item.nickname!
              .toLowerCase()
              .replaceAll(' ', '')
              .contains(spacelessQuery);

      // Subtitle match
      final subtitleMatch =
          item.subtitle != null &&
          item.subtitle!.toLowerCase().contains(normalizedQuery);

      return nameMatch ||
          abbreviationMatch ||
          spacelessAbbreviationMatch ||
          nicknameMatch ||
          spacelessNicknameMatch ||
          subtitleMatch;
    }).toList();

    // Categorize results
    final colleges = matchedItems.where((i) => i.type == 'college').toList();
    final landmarks = matchedItems.where((i) => i.type == 'landmark').toList();
    final buildings = matchedItems.where((i) => i.type == 'building').toList();
    final facilities = matchedItems.where((i) => i.type == 'facility').toList();
    final offices = matchedItems.where((i) => i.type == 'office').toList();

    // Add unique results in priority order
    for (var item in [
      ...colleges,
      ...landmarks,
      ...buildings,
      ...facilities,
      ...offices,
    ]) {
      if (!addedReferences.contains(item.reference)) {
        results.add(item.reference);
        addedReferences.add(item.reference);
      }
    }

    return results;
  }
}

// Database search item helper class
class DatabaseSearchItem {
  final String name;
  final String? abbreviation;
  final String? nickname;
  final String? subtitle;
  final String type;
  final dynamic reference;

  DatabaseSearchItem({
    required this.name,
    this.abbreviation,
    this.nickname,
    this.subtitle,
    required this.type,
    required this.reference,
  });
}

class BicolBuildingPolygon {
  final List<LatLng> points;
  final String name;
  final String description;
  final String? osmId;
  final Map<String, dynamic> osmTags;
  final int? buildingId;
  final FacilityType? facilityType;
  final String? databaseName;
  final String? databaseNickname;

  BicolBuildingPolygon({
    required this.points,
    required this.name,
    required this.description,
    this.osmId,
    this.osmTags = const {},
    this.buildingId,
    this.facilityType,
    this.databaseName,
    this.databaseNickname,
  });

  LatLng getCenterPoint() => GeometryUtils.getCenterFromPoints(points);

  bool get hasDetailedInfo => buildingId != null;
  bool get isFacility => facilityType != null;
  bool get isPool => facilityType == FacilityType.swimmingPool;
  bool get isField =>
      facilityType == FacilityType.sportsField ||
      facilityType == FacilityType.track ||
      facilityType == FacilityType.stadium;

  // Display name prioritizes database name
  String get displayName => databaseName ?? name;
}

class BicolMarker {
  final LatLng position;
  final String name;
  final String? abbreviation;
  final String type;
  final int itemId;
  final int? buildingId;
  final String? databaseName;

  BicolMarker({
    required this.position,
    required this.name,
    this.abbreviation,
    required this.type,
    required this.itemId,
    this.buildingId,
    this.databaseName,
  });

  bool get isCollege => type == 'college';
  bool get isLandmark => type == 'landmark';

  // Display name prioritizes database name
  String get displayName => databaseName ?? name;
}

class GeometryUtils {
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
