import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class BuildingMatcher {
  static List<Map<String, dynamic>> _buildings = [];
  static List<Map<String, dynamic>> _colleges = [];
  static List<Map<String, dynamic>> _offices = [];

  // Load buildings (includes landmarks AND facilities like pools/fields)
  static Future<void> loadBuildings() async {
    try {
      final response = await Supabase.instance.client
          .from('Building')
          .select(
            'building_id, building_name, building_nickname, building_type',
          );

      _buildings = List<Map<String, dynamic>>.from(response as List);

      final landmarkCount = _buildings
          .where((b) => b['building_type'] == 'Landmark')
          .length;
      final facilityCount = _buildings
          .where((b) => b['building_type'] == 'Facility')
          .length;
      final regularCount = _buildings.length - landmarkCount - facilityCount;

      debugPrint('✅ Loaded ${_buildings.length} buildings from Supabase');
      debugPrint('   🏢 $regularCount regular buildings');
      debugPrint('   🏛️ $landmarkCount landmarks');
      debugPrint('   ⚽ $facilityCount facilities (pools/fields/ovals)');
    } catch (e) {
      debugPrint('❌ Error loading buildings: $e');
      _buildings = [];
    }
  }

  // Load colleges from database
  static Future<void> loadColleges() async {
    try {
      final response = await Supabase.instance.client
          .from('College')
          .select('college_id, college_name, college_abbreviation');

      _colleges = List<Map<String, dynamic>>.from(response as List);
      debugPrint('✅ Loaded ${_colleges.length} colleges from Supabase');
    } catch (e) {
      debugPrint('❌ Error loading colleges: $e');
      _colleges = [];
    }
  }

  // Load offices from database with NULL handling
  static Future<void> loadOffices() async {
    try {
      final response = await Supabase.instance.client
          .from('Office')
          .select('office_id, office_name, building_id, office_abbreviation');

      final rawList = List<Map<String, dynamic>>.from(response as List);
      _offices = rawList.where((office) {
        final buildingId = office['building_id'];
        if (buildingId == null) {
          debugPrint(
            '! Skipping office "${office['office_name']}" - NULL building_id',
          );
          return false;
        }
        return true;
      }).toList();

      debugPrint('✅ Loaded ${_offices.length} offices from Supabase');
      if (rawList.length != _offices.length) {
        debugPrint(
          '! Skipped ${rawList.length - _offices.length} offices with NULL building_id',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading offices: $e');
      _offices = [];
    }
  }

  // Get offices for a specific building (with NULL safety)
  static List<OfficeData> getOfficesForBuilding(int buildingId) {
    return _offices
        .where((office) => office['building_id'] == buildingId)
        .map((office) {
          final officeId = office['office_id'];
          if (officeId == null) return null;

          return OfficeData(
            id: officeId as int,
            name: office['office_name'] as String? ?? 'Unknown Office',
            abbreviation: office['office_abbreviation'] as String?,
            buildingId: office['building_id'] as int,
          );
        })
        .whereType<OfficeData>()
        .toList();
  }

  // Get all offices as searchable items (with NULL safety)
  static List<OfficeData> getAllOffices() {
    return _offices
        .map((office) {
          final officeId = office['office_id'];
          final buildingId = office['building_id'];

          if (officeId == null || buildingId == null) return null;

          return OfficeData(
            id: officeId as int,
            name: office['office_name'] as String? ?? 'Unknown Office',
            abbreviation: office['office_abbreviation'] as String?,
            buildingId: buildingId as int,
          );
        })
        .whereType<OfficeData>()
        .toList();
  }

  // Get building name by ID (with NULL safety)
  static String? getBuildingNameById(int buildingId) {
    try {
      final building = _buildings.firstWhere(
        (b) => b['building_id'] == buildingId,
      );
      return building['building_name'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Match OSM facility to Supabase building (with NULL safety)
  static BuildingMatch? matchFacility(String osmName) {
    if (_buildings.isEmpty) return null;

    final normalized = _normalizeForMatching(osmName);

    // Try exact match first
    BuildingMatch? exactMatch;
    BuildingMatch? partialMatch;

    for (var building in _buildings) {
      final buildingId = building['building_id'];
      if (buildingId == null) continue;

      final buildingName = building['building_name'] as String? ?? '';
      if (buildingName.isEmpty) continue;

      final buildingNormalized = _normalizeForMatching(buildingName);

      // Check for common facility keywords
      final isFacilityInDB =
          buildingName.toLowerCase().contains('pool') ||
          buildingName.toLowerCase().contains('oval') ||
          buildingName.toLowerCase().contains('field') ||
          buildingName.toLowerCase().contains('ground') ||
          buildingName.toLowerCase().contains('track') ||
          buildingName.toLowerCase().contains('stadium') ||
          buildingName.toLowerCase().contains('complex') ||
          buildingName.toLowerCase().contains('court');

      if (!isFacilityInDB) continue;

      // Exact match
      if (normalized == buildingNormalized) {
        exactMatch = BuildingMatch(
          id: buildingId as int,
          type: building['building_type'] as String?,
          databaseName: buildingName,
          databaseNickname: building['building_nickname'] as String?,
        );
        break;
      }

      // Store partial matches but keep looking for exact
      if (normalized.contains(buildingNormalized) ||
          buildingNormalized.contains(normalized)) {
        partialMatch ??= BuildingMatch(
          id: buildingId as int,
          type: building['building_type'] as String?,
          databaseName: buildingName,
          databaseNickname: building['building_nickname'] as String?,
        );
      }
    }

    if (exactMatch != null) return exactMatch;

    if (partialMatch != null) {
      return partialMatch;
    }

    return null;
  }

  // ✨ IMPROVED: Smart building matching with prioritization
  static BuildingMatch? matchBuilding(String osmName) {
    if (_buildings.isEmpty) return null;

    final normalized = _normalizeForMatching(osmName);

    // Store potential matches with scores
    BuildingMatch? exactMatch;
    BuildingMatch? bestPartialMatch;
    int bestMatchScore = 0;

    for (var building in _buildings) {
      final buildingId = building['building_id'];
      if (buildingId == null) continue;

      final buildingName = building['building_name'] as String? ?? '';
      if (buildingName.isEmpty) continue;

      final buildingNormalized = _normalizeForMatching(buildingName);

      // 1. EXACT MATCH - highest priority
      if (normalized == buildingNormalized) {
        exactMatch = BuildingMatch(
          id: buildingId as int,
          type: building['building_type'] as String?,
          databaseName: buildingName,
          databaseNickname: building['building_nickname'] as String?,
        );
        break; // Stop searching, we found exact match
      }

      // 2. Calculate match score for partial matches
      int matchScore = _calculateMatchScore(
        normalized,
        buildingNormalized,
        osmName,
        buildingName,
      );

      if (matchScore > bestMatchScore) {
        bestMatchScore = matchScore;
        bestPartialMatch = BuildingMatch(
          id: buildingId as int,
          type: building['building_type'] as String?,
          databaseName: buildingName,
          databaseNickname: building['building_nickname'] as String?,
        );
      }
    }

    // Return exact match if found
    if (exactMatch != null) return exactMatch;

    // Return best partial match if score is good enough
    if (bestPartialMatch != null && bestMatchScore >= 3) {
      return bestPartialMatch;
    }

    return null;
  }

  // Calculate match score for better partial matching
  static int _calculateMatchScore(
    String osmNormalized,
    String dbNormalized,
    String osmOriginal,
    String dbOriginal,
  ) {
    int score = 0;

    // Score based on containment (prefer longer matches)
    if (osmNormalized.contains(dbNormalized)) {
      // How much of the OSM name does the DB name cover?
      double coverage = dbNormalized.length / osmNormalized.length;
      score += (coverage * 5).round(); // 0-5 points
    } else if (dbNormalized.contains(osmNormalized)) {
      // How much of the DB name does the OSM name cover?
      double coverage = osmNormalized.length / dbNormalized.length;
      score += (coverage * 5).round(); // 0-5 points
    }

    // Bonus for matching important words
    final osmWords = osmNormalized.split(' ');
    final dbWords = dbNormalized.split(' ');
    int matchingWords = 0;

    for (var osmWord in osmWords) {
      if (osmWord.length > 2 && dbWords.contains(osmWord)) {
        matchingWords++;
      }
    }

    score += matchingWords * 2; // 2 points per matching word

    // Penalty for too much extra content in DB name
    if (dbWords.length > osmWords.length * 2) {
      score -= 2;
    }

    return score;
  }

  // Match OSM college ground name to Supabase college (with NULL safety)
  static CollegeMatch? matchCollegeGround(String osmName) {
    if (_colleges.isEmpty) return null;

    final normalized = _normalizeForMatching(osmName);

    // Try exact match first
    CollegeMatch? exactMatch;
    CollegeMatch? partialMatch;

    for (var college in _colleges) {
      final collegeId = college['college_id'];
      if (collegeId == null) continue;

      final collegeName = college['college_name'] as String? ?? '';
      if (collegeName.isEmpty) continue;

      final collegeNormalized = _normalizeForMatching(collegeName);

      // Exact match
      if (normalized == collegeNormalized) {
        exactMatch = CollegeMatch(
          id: collegeId as int,
          name: collegeName,
          abbreviation: college['college_abbreviation'] as String?,
        );
        break;
      }

      // Store first partial match
      if (partialMatch == null &&
          (normalized.contains(collegeNormalized) ||
              collegeNormalized.contains(normalized))) {
        partialMatch = CollegeMatch(
          id: collegeId as int,
          name: collegeName,
          abbreviation: college['college_abbreviation'] as String?,
        );
      }
    }

    if (exactMatch != null) return exactMatch;

    if (partialMatch != null) {
      return partialMatch;
    }

    return null;
  }

  //  Old method - kept for backwards compatibility
  static int? matchCollege(String osmName) {
    final match = matchCollegeGround(osmName);
    return match?.id;
  }

  //  Smarter normalization that preserves important words
  static String _normalizeForMatching(String text) {
    String normalized = text.toLowerCase();

    // Remove "Bicol University" prefix but keep other important words
    normalized = normalized
        .replaceAll('bicol university', '')
        .replaceAll(RegExp(r'^bu\s+'), '') // Only remove BU at start
        .trim();

    // Apply synonym mappings for better matching
    normalized = _applySynonyms(normalized);

    // Remove special characters but keep spaces
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), '');

    // Normalize multiple spaces to single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  // ✨ NEW: Apply synonym mappings for common variations
  static String _applySynonyms(String text) {
    // Gender synonyms
    text = text.replaceAll('male dormitory', 'mens dormitory');
    text = text.replaceAll('female dormitory', 'womens dormitory');
    text = text.replaceAll('women\'s', 'womens');
    text = text.replaceAll('men\'s', 'mens');
    text = text.replaceAll('womens\'', 'womens');
    text = text.replaceAll('mens\'', 'mens');

    // Building type synonyms
    text = text.replaceAll('gym ', 'gymnasium ');
    text = text.replaceAll(' gym', ' gymnasium');

    return text;
  }
}

// Office data class
class OfficeData {
  final int id;
  final String name;
  final String? abbreviation;
  final int buildingId;

  OfficeData({
    required this.id,
    required this.name,
    this.abbreviation,
    required this.buildingId,
  });
}

// Class to hold building match results
class BuildingMatch {
  final int id;
  final String? type;
  final String? databaseName;
  final String? databaseNickname;

  BuildingMatch({
    required this.id,
    this.type,
    this.databaseName,
    this.databaseNickname,
  });

  bool get isLandmark => type == 'Landmark';
  bool get isFacility => type == 'Facility';
  bool get isRegularBuilding => type != 'Landmark' && type != 'Facility';
}

// Class to hold college match results
class CollegeMatch {
  final int id;
  final String name;
  final String? abbreviation;

  CollegeMatch({required this.id, required this.name, this.abbreviation});
}
