import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itouru/maps_assets/location_service.dart';
import 'package:itouru/maps_assets/map_boundary.dart'; // Import your boundary
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1';
  static const String _routingProfile = 'foot';

  // Cache for campus gates
  static List<CampusGate>? _cachedGates;
  static DateTime? _gatesCacheTime;
  static const Duration _cacheValidity = Duration(hours: 1);

  /// Gets route between two points, respecting campus boundaries and gates
  /// If start is outside campus and end is inside, route goes through nearest gate
  static Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    try {
      final bool startInsideCampus = MapBoundary.isWithinCampusBounds(start);
      final bool endInsideCampus = MapBoundary.isWithinCampusBounds(end);

      print('🗺️ Route request:');
      print('   Start inside campus: $startInsideCampus');
      print('   End inside campus: $endInsideCampus');

      // Case 1: Both points inside campus - direct route
      if (startInsideCampus && endInsideCampus) {
        print('✅ Both inside campus - direct route');
        return await _getDirectRoute(start, end);
      }

      // Case 2: Start outside, end inside - route through gate
      if (!startInsideCampus && endInsideCampus) {
        print('🚪 Start outside, end inside - routing through gate');
        return await _getRouteViaGate(start, end, isEntry: true);
      }

      // Case 3: Start inside, end outside - route through gate
      if (startInsideCampus && !endInsideCampus) {
        print('🚪 Start inside, end outside - routing through gate');
        return await _getRouteViaGate(start, end, isEntry: false);
      }

      // Case 4: Both outside - direct route (shouldn't happen in your use case)
      print('⚠️ Both outside campus - direct route');
      return await _getDirectRoute(start, end);
    } catch (e) {
      print('❌ Error getting route: $e');
      return RouteResult.error('Error getting route: $e');
    }
  }

  /// Get direct route between two points (both inside campus)
  static Future<RouteResult> _getDirectRoute(LatLng start, LatLng end) async {
    final String url =
        '$_osrmBaseUrl/$_routingProfile/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}?'
        'overview=full&geometries=polyline&steps=true&alternatives=false';

    print('🛣️ Requesting direct route: $url');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final geometry = route['geometry'];
        final distance = route['distance'];
        final duration = route['duration'];

        final List<PointLatLng> result = PolylinePoints.decodePolyline(
          geometry,
        );
        final List<LatLng> routePoints = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        print('✅ Direct route found: ${routePoints.length} points');

        return RouteResult.success(
          points: routePoints,
          distance: _formatDistance(distance),
          duration: _formatDuration(duration),
        );
      }
    }

    return RouteResult.error('No route found');
  }

  /// Get route via campus gate (for entry or exit)
  static Future<RouteResult> _getRouteViaGate(
    LatLng start,
    LatLng end, {
    required bool isEntry,
  }) async {
    // Get campus gates
    final gates = await _getCampusGates();

    if (gates.isEmpty) {
      print('⚠️ No gates found, using direct route');
      return await _getDirectRoute(start, end);
    }

    // Find nearest gate to the outside point
    final outsidePoint = isEntry ? start : end;
    // Removed unused insidePoint variable

    final nearestGate = _findNearestGate(gates, outsidePoint);
    print('🚪 Nearest gate: ${nearestGate.name} at ${nearestGate.location}');

    // Get two-segment route
    if (isEntry) {
      // Outside → Gate → Inside destination
      return await _getMultiSegmentRoute([start, nearestGate.location, end]);
    } else {
      // Inside start → Gate → Outside destination
      return await _getMultiSegmentRoute([start, nearestGate.location, end]);
    }
  }

  /// Get multi-segment route (e.g., start → gate → end)
  static Future<RouteResult> _getMultiSegmentRoute(
    List<LatLng> waypoints,
  ) async {
    if (waypoints.length < 2) {
      return RouteResult.error('Need at least 2 waypoints');
    }

    // Build waypoints string for OSRM
    final waypointsStr = waypoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');

    final String url =
        '$_osrmBaseUrl/$_routingProfile/$waypointsStr?'
        'overview=full&geometries=polyline&steps=true&alternatives=false';

    print(
      '🛣️ Requesting multi-segment route via ${waypoints.length} waypoints',
    );

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final geometry = route['geometry'];
        final distance = route['distance'];
        final duration = route['duration'];

        final List<PointLatLng> result = PolylinePoints.decodePolyline(
          geometry,
        );
        final List<LatLng> routePoints = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        print('✅ Multi-segment route found: ${routePoints.length} points');

        return RouteResult.success(
          points: routePoints,
          distance: _formatDistance(distance),
          duration: _formatDuration(duration),
          viaGate: waypoints.length > 2, // Indicates route goes through gate
        );
      }
    }

    return RouteResult.error('No multi-segment route found');
  }

  /// Get campus gates with caching
  static Future<List<CampusGate>> _getCampusGates() async {
    // Check cache validity
    if (_cachedGates != null &&
        _gatesCacheTime != null &&
        DateTime.now().difference(_gatesCacheTime!) < _cacheValidity) {
      print('✅ Using cached gates (${_cachedGates!.length} gates)');
      return _cachedGates!;
    }

    // Fetch fresh gates
    print('🔄 Fetching fresh gate data...');
    final gates = await fetchCampusGates(
      campusCenter: MapBoundary.bicolUniversityCenter,
      radiusMeters: 600,
    );

    // Update cache
    _cachedGates = gates;
    _gatesCacheTime = DateTime.now();

    return gates;
  }

  /// Find nearest gate to a point
  static CampusGate _findNearestGate(List<CampusGate> gates, LatLng point) {
    CampusGate? nearestGate;
    double minDistance = double.infinity;

    for (var gate in gates) {
      final distance = calculateDistance(point, gate.location);
      if (distance < minDistance) {
        minDistance = distance;
        nearestGate = gate;
      }
    }

    return nearestGate ?? gates.first;
  }

  /// Get campus gates from OpenStreetMap using Overpass API
  static Future<List<CampusGate>> fetchCampusGates({
    required LatLng campusCenter,
    double radiusMeters = 500,
  }) async {
    try {
      final bbox = _calculateBoundingBox(campusCenter, radiusMeters);

      final query =
          '''
[out:json][timeout:25];
(
  node["entrance"="yes"](${bbox.south},${bbox.west},${bbox.north},${bbox.east});
  node["barrier"="gate"](${bbox.south},${bbox.west},${bbox.north},${bbox.east});
  node["barrier"="entrance"](${bbox.south},${bbox.west},${bbox.north},${bbox.east});
  node["highway"="gate"](${bbox.south},${bbox.west},${bbox.north},${bbox.east});
);
out body;
''';

      final url = 'https://overpass-api.de/api/interpreter';
      final response = await http.post(Uri.parse(url), body: query);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<CampusGate> gates = [];

        if (data['elements'] != null) {
          for (var element in data['elements']) {
            if (element['lat'] != null && element['lon'] != null) {
              gates.add(
                CampusGate(
                  id: element['id'].toString(),
                  name: element['tags']?['name'] ?? 'Gate ${gates.length + 1}',
                  location: LatLng(element['lat'], element['lon']),
                  tags: Map<String, String>.from(element['tags'] ?? {}),
                ),
              );
            }
          }
        }

        print('✅ Found ${gates.length} gates from OSM');

        // If no gates found from OSM, create default gates at boundary intersections
        if (gates.isEmpty) {
          gates.addAll(_createDefaultGates(campusCenter));
          print('⚠️ No OSM gates found, using ${gates.length} default gates');
        }

        return gates;
      }

      print('❌ Failed to fetch gates: ${response.statusCode}');
      return _createDefaultGates(campusCenter);
    } catch (e) {
      print('❌ Error fetching gates: $e');
      return _createDefaultGates(campusCenter);
    }
  }

  /// Create default gates if OSM data is not available
  /// You should customize these based on your campus's actual entrances
  static List<CampusGate> _createDefaultGates(LatLng center) {
    // Get boundary points
    final boundaryPoints = MapBoundary.getCampusBoundaryPoints();

    // Find main access points (you should customize these based on actual gates)
    // For now, we'll create gates at cardinal directions
    final gates = <CampusGate>[];

    // You should replace these with actual gate coordinates for Bicol University
    // These are just examples - find the actual entry points in your boundary
    if (boundaryPoints.length >= 4) {
      // Example: Create gates at specific boundary points
      // You need to identify which boundary points are actual gates
      gates.add(
        CampusGate(
          id: 'main_gate',
          name: 'Main Gate',
          location: boundaryPoints[0], // Replace with actual main gate point
          tags: {'entrance': 'main'},
        ),
      );

      // Add more gates based on your campus layout
      // gates.add(CampusGate(...));
    }

    return gates;
  }

  /// Calculate bounding box for Overpass query
  static _BoundingBox _calculateBoundingBox(
    LatLng center,
    double radiusMeters,
  ) {
    const double earthRadius = 6371000;

    double latDelta = (radiusMeters / earthRadius) * (180 / math.pi);
    double lonDelta =
        (radiusMeters /
            (earthRadius * math.cos(center.latitude * math.pi / 180))) *
        (180 / math.pi);

    return _BoundingBox(
      north: center.latitude + latDelta,
      south: center.latitude - latDelta,
      east: center.longitude + lonDelta,
      west: center.longitude - lonDelta,
    );
  }

  /// Calculates bounds for a list of route points
  static LatLngBounds calculateRouteBounds(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  /// Fits the map to show the entire route
  static void fitMapToRoute(
    MapController mapController,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return;

    final bounds = calculateRouteBounds(routePoints);
    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  static String _formatDistance(num distanceInMeters) {
    // Changed from double to num
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceInMeters.toInt()} m';
    }
  }

  static String _formatDuration(num durationInSeconds) {
    // Changed from double to num
    final int minutes = (durationInSeconds / 60).round();
    if (minutes >= 60) {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}m';
    }
  }

  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double calculateBearing(LatLng start, LatLng end) {
    double lat1Rad = start.latitude * (math.pi / 180);
    double lat2Rad = end.latitude * (math.pi / 180);
    double deltaLngRad = (end.longitude - start.longitude) * (math.pi / 180);

    double y = math.sin(deltaLngRad) * math.cos(lat2Rad);
    double x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);

    double bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }
}

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

class CampusGate {
  final String id;
  final String name;
  final LatLng location;
  final Map<String, String> tags;

  CampusGate({
    required this.id,
    required this.name,
    required this.location,
    this.tags = const {},
  });

  bool get isMainEntrance =>
      tags['entrance'] == 'main' || name.toLowerCase().contains('main');

  @override
  String toString() => 'CampusGate(name: $name, location: $location)';
}

// Keep your existing NavigationManager and RouteResult classes...
class NavigationManager {
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  LatLng? _previousLocation;
  double _currentBearing = 0.0;
  bool _isNavigating = false;
  bool _isDisposed = false;

  dynamic _currentDestination;
  List<LatLng> _polylinePoints = [];
  String? _routeDistance;
  String? _routeDuration;

  Function(LatLng, double)? onLocationUpdate;
  Function(dynamic)? onDestinationReached;
  Function(String)? onError;

  bool get isNavigating => _isNavigating;
  bool get isDisposed => _isDisposed;
  LatLng? get currentLocation => _currentLocation;
  double get currentBearing => _currentBearing;
  dynamic get currentDestination => _currentDestination;
  List<LatLng> get polylinePoints => _polylinePoints;
  String? get routeDistance => _routeDistance;
  String? get routeDuration => _routeDuration;

  Future<void> startNavigation({
    required dynamic destination,
    required List<LatLng> routePoints,
    String? distance,
    String? duration,
    Function(LatLng, double)? onLocationUpdate,
    Function(dynamic)? onDestinationReached,
    Function(String)? onError,
  }) async {
    if (_isDisposed) return;

    _currentDestination = destination;
    _polylinePoints = routePoints;
    _routeDistance = distance;
    _routeDuration = duration;
    _isNavigating = true;

    this.onLocationUpdate = onLocationUpdate;
    this.onDestinationReached = onDestinationReached;
    this.onError = onError;

    await _startLocationTracking();
  }

  void stopNavigation() {
    if (_isDisposed) return;

    _isNavigating = false;
    _currentDestination = null;
    _polylinePoints.clear();
    _routeDistance = null;
    _routeDuration = null;
    _currentBearing = 0.0;
    _previousLocation = null;

    _stopLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    if (_isDisposed) return;

    final initialLocationResult = await LocationService.getCurrentLocation();

    if (!initialLocationResult.isSuccess) {
      onError?.call(initialLocationResult.error ?? 'Location error');
      return;
    }

    _currentLocation = initialLocationResult.location;
    _previousLocation = initialLocationResult.location;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_isDisposed) return;

            final newLocation = LatLng(position.latitude, position.longitude);

            if (_previousLocation != null) {
              _currentBearing = RoutingService.calculateBearing(
                _previousLocation!,
                newLocation,
              );
            }

            _currentLocation = newLocation;
            _previousLocation = newLocation;

            onLocationUpdate?.call(newLocation, _currentBearing);

            if (_isNavigating && _currentDestination != null) {
              _checkDestinationReached();
            }
          },
          onError: (error) {
            if (!_isDisposed) {
              onError?.call('Location error: $error');
            }
          },
        );
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _checkDestinationReached() {
    if (_currentLocation == null || _currentDestination == null) return;

    LatLng destinationPoint;
    if (_currentDestination.runtimeType.toString().contains('Building')) {
      destinationPoint = _currentDestination.getCenterPoint();
    } else {
      destinationPoint = _currentDestination as LatLng;
    }

    final distance = RoutingService.calculateDistance(
      _currentLocation!,
      destinationPoint,
    );

    if (distance < 5) {
      _destinationReached();
    }
  }

  void _destinationReached() {
    if (_isDisposed) return;

    _isNavigating = false;
    onDestinationReached?.call(_currentDestination);

    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        stopNavigation();
      }
    });
  }

  void clearRoute() {
    if (_isDisposed) return;

    _polylinePoints.clear();
    _routeDistance = null;
    _routeDuration = null;
    _currentDestination = null;
    _isNavigating = false;
    _currentBearing = 0.0;
    _previousLocation = null;
  }

  Future<RouteResult> getRouteAndPrepareNavigation(
    LatLng start,
    LatLng end,
    dynamic destination,
  ) async {
    if (_isDisposed) return RouteResult.error('Navigation manager disposed');

    final routeResult = await RoutingService.getRoute(start, end);

    if (routeResult.isSuccess && routeResult.points != null) {
      _polylinePoints = routeResult.points!;
      _routeDistance = routeResult.distance;
      _routeDuration = routeResult.duration;
      _currentDestination = destination;
    }

    return routeResult;
  }

  void dispose() {
    _isDisposed = true;
    _stopLocationTracking();
  }
}

class RouteResult {
  final List<LatLng>? points;
  final String? distance;
  final String? duration;
  final String? error;
  final bool isSuccess;
  final bool viaGate;

  RouteResult._({
    this.points,
    this.distance,
    this.duration,
    this.error,
    required this.isSuccess,
    this.viaGate = false,
  });

  factory RouteResult.success({
    required List<LatLng> points,
    String? distance,
    String? duration,
    bool viaGate = false,
  }) {
    return RouteResult._(
      points: points,
      distance: distance,
      duration: duration,
      isSuccess: true,
      viaGate: viaGate,
    );
  }

  factory RouteResult.error(String error) {
    return RouteResult._(error: error, isSuccess: false);
  }
}

class RouteHelper {
  static Polyline createRoutePolyline(List<LatLng> points) {
    return Polyline(
      points: points,
      color: const Color(0xFF2196F3),
      strokeWidth: 4.0,
    );
  }

  static bool isValidRoute(List<LatLng> points) {
    return points.isNotEmpty && points.length >= 2;
  }

  static double calculateRouteDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += RoutingService.calculateDistance(
        points[i],
        points[i + 1],
      );
    }
    return totalDistance;
  }
}
