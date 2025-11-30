import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itouru/maps_assets/location_service.dart';
import 'package:itouru/maps_assets/map_boundary.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_map/flutter_map.dart';
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

      // Case 1: Both points inside campus - direct route
      if (startInsideCampus && endInsideCampus) {
        return await _getDirectRoute(start, end);
      }

      // Case 2: Start outside, end inside - route through gate
      if (!startInsideCampus && endInsideCampus) {
        return await _getRouteViaGate(start, end, isEntry: true);
      }

      // Case 3: Start inside, end outside - route through gate
      if (startInsideCampus && !endInsideCampus) {
        return await _getRouteViaGate(start, end, isEntry: false);
      }

      // Case 4: Both outside - direct route (shouldn't happen in your use case)
      return await _getDirectRoute(start, end);
    } catch (e) {
      return RouteResult.error('Error getting route: $e');
    }
  }

  static Future<LatLng?> fetchBuildingEntrance(
    LatLng buildingCenter,
    String buildingName,
  ) async {
    try {
      final double radius = 50;

      // Calculate bounding box
      final double latOffset = radius / 111320;
      final double lngOffset =
          radius / (111320 * math.cos(buildingCenter.latitude * math.pi / 180));

      final double minLat = buildingCenter.latitude - latOffset;
      final double maxLat = buildingCenter.latitude + latOffset;
      final double minLng = buildingCenter.longitude - lngOffset;
      final double maxLng = buildingCenter.longitude + lngOffset;

      // Overpass API query for entrances
      final String query =
          '''
[out:json][timeout:25];
(
  node["entrance"]($minLat,$minLng,$maxLat,$maxLng);
  node["door"]($minLat,$minLng,$maxLat,$maxLng);
);
out body;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        if (elements.isNotEmpty) {
          // Find the closest entrance to building center
          LatLng? closestEntrance;
          double minDistance = double.infinity;

          for (var element in elements) {
            final lat = element['lat'] as double;
            final lon = element['lon'] as double;
            final entranceLocation = LatLng(lat, lon);

            final distance = calculateDistance(
              buildingCenter,
              entranceLocation,
            );
            if (distance < minDistance) {
              minDistance = distance;
              closestEntrance = entranceLocation;
            }
          }

          return closestEntrance;
        }
      }

      // No entrance found, return building center
      return null;
    } catch (e) {
      debugPrint('Error fetching building entrance: $e');
      return null;
    }
  }

  /// Get direct route between two points (both inside campus)
  static Future<RouteResult> _getDirectRoute(LatLng start, LatLng end) async {
    final String url =
        '$_osrmBaseUrl/$_routingProfile/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}?'
        'overview=full&geometries=polyline&steps=true&alternatives=false';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final geometry = route['geometry'];
        final distance = route['distance'];

        final List<PointLatLng> result = PolylinePoints.decodePolyline(
          geometry,
        );
        final List<LatLng> routePoints = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        return RouteResult.success(
          points: routePoints,
          distance: formatDistance(distance),
          duration: calculateWalkingDuration(distance),
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
      return await _getDirectRoute(start, end);
    }

    // Find nearest gate to the outside point
    final outsidePoint = isEntry ? start : end;
    // Removed unused insidePoint variable

    final nearestGate = _findNearestGate(gates, outsidePoint);

    // Get two-segment route
    if (isEntry) {
      // Outside → Gate → Inside destination
      return await _getMultiSegmentRoute([start, nearestGate.location, end]);
    } else {
      // Inside start → Gate → Outside destination
      return await _getMultiSegmentRoute([start, nearestGate.location, end]);
    }
  }

  /// Get multi-segment route
  static Future<RouteResult> _getMultiSegmentRoute(
    List<LatLng> waypoints,
  ) async {
    if (waypoints.length < 2) {
      return RouteResult.error('Need at least 2 waypoints');
    }

    final waypointsStr = waypoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');

    final String url =
        '$_osrmBaseUrl/$_routingProfile/$waypointsStr?'
        'overview=full&geometries=polyline&steps=true&alternatives=false';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final geometry = route['geometry'];
        final distance = route['distance']; // This is in meters

        final List<PointLatLng> result = PolylinePoints.decodePolyline(
          geometry,
        );
        final List<LatLng> routePoints = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        return RouteResult.success(
          points: routePoints,
          distance: formatDistance(distance),
          duration: calculateWalkingDuration(distance),
          viaGate: waypoints.length > 2,
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
      return _cachedGates!;
    }

    // Fetch fresh gates
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

  /// Fetch campus gates from OSM via Overpass API
  static Future<List<CampusGate>> fetchCampusGates({
    required LatLng campusCenter,
    double radiusMeters = 500,
  }) async {
    // Always use predefined gates for accuracy
    return _createDefaultGates(campusCenter);
  }

  static List<CampusGate> _createDefaultGates(LatLng center) {
    return [
      CampusGate(
        id: 'gate_1',
        name: 'Gate 1',
        location: LatLng(13.14395504, 123.72590159),
        tags: {'entrance': 'yes', 'access': 'main'},
      ),
      CampusGate(
        id: 'gate_2',
        name: 'Gate 2',
        location: LatLng(13.14445260, 123.72525112),
        tags: {'entrance': 'yes', 'access': 'secondary'},
      ),
      CampusGate(
        id: 'gate_3',
        name: 'Gate 3',
        location: LatLng(13.14502437, 123.72455284),
        tags: {'entrance': 'yes', 'access': 'secondary'},
      ),
      CampusGate(
        id: 'gate_4',
        name: 'Gate 4',
        location: LatLng(13.14564489, 123.72377642),
        tags: {'entrance': 'yes', 'access': 'secondary'},
      ),
      CampusGate(
        id: 'gate_5',
        name: 'Gate 5',
        location: LatLng(13.14620255, 123.72305763),
        tags: {'entrance': 'yes', 'access': 'secondary'},
      ),
      CampusGate(
        id: 'gate_8',
        name: 'Gate 8',
        location: LatLng(13.14282074, 123.72155345),
        tags: {'entrance': 'yes', 'access': 'service'},
      ),
    ];
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

  static String formatDistance(num distanceInMeters) {
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceInMeters.toInt()} m';
    }
  }

  static String calculateWalkingDuration(num distanceInMeters) {
    const double metersPerMinute = 58.3;

    final double totalMinutes = distanceInMeters / metersPerMinute;

    if (totalMinutes < 1) {
      final int seconds = (totalMinutes * 60).round();
      return '${seconds}s';
    } else if (totalMinutes >= 60) {
      final int hours = totalMinutes ~/ 60;
      final int minutes = (totalMinutes % 60).round();
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}m';
    } else {
      return '${totalMinutes.round()}m';
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

class NavigationManager {
  Timer? _headingUpdateTimer;
  Timer? _routeRecalculationTimer;
  LatLng? _currentLocation;
  double _currentBearing = 0.0;
  double _targetBearing = 0.0;
  bool _isNavigating = false;
  bool _isDisposed = false;

  dynamic _currentDestination;
  List<LatLng> _polylinePoints = [];
  String? _routeDistance;
  String? _routeDuration;

  static const double _routeRecalculationThreshold = 15.0;
  static const Duration _routeRecalculationInterval = Duration(seconds: 1);
  static const double _bearingSmoothingFactor = 0.3;

  Function(LatLng, double)? onLocationUpdate;
  Function(dynamic)? onDestinationReached;
  Function(String)? onError;
  Function(List<LatLng>)? onRouteUpdated;

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
    Function(List<LatLng>)? onRouteUpdated,
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
    this.onRouteUpdated = onRouteUpdated;

    _startHeadingUpdates();
    _startRouteRecalculation();
  }

  void stopNavigation() {
    if (_isDisposed) return;

    _isNavigating = false;
    _currentDestination = null;
    _polylinePoints.clear();
    _routeDistance = null;
    _routeDuration = null;
    _currentBearing = 0.0;
    _targetBearing = 0.0;

    _stopHeadingUpdates();
    _stopRouteRecalculation();
  }

  void updateLocation(LatLng newLocation, double heading) {
    if (_isDisposed) return;

    _currentLocation = newLocation;

    // Smooth bearing interpolation
    _targetBearing = heading;

    // Trigger callback
    onLocationUpdate?.call(newLocation, _currentBearing);

    // Check if reached destination
    if (_isNavigating && _currentDestination != null) {
      _checkDestinationReached();
    }
  }

  void _startHeadingUpdates() {
    _stopHeadingUpdates();

    // High-frequency updates (60 FPS equivalent) for smooth rotation
    _headingUpdateTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_currentLocation != null && _isNavigating) {
        // Smooth bearing interpolation using lerp
        _currentBearing = _lerpAngle(
          _currentBearing,
          _targetBearing,
          _bearingSmoothingFactor,
        );

        // Get fresh compass heading
        final compassHeading = LocationService.getCurrentHeading();
        _targetBearing = compassHeading;

        onLocationUpdate?.call(_currentLocation!, _currentBearing);
      }
    });
  }

  void _stopHeadingUpdates() {
    _headingUpdateTimer?.cancel();
    _headingUpdateTimer = null;
  }

  /// Start automatic route recalculation when navigating
  void _startRouteRecalculation() {
    _stopRouteRecalculation();

    _routeRecalculationTimer = Timer.periodic(_routeRecalculationInterval, (
      timer,
    ) async {
      if (_isDisposed || !_isNavigating) {
        timer.cancel();
        return;
      }

      if (_currentLocation != null && _currentDestination != null) {
        await _recalculateRouteIfNeeded();
      }
    });
  }

  void _stopRouteRecalculation() {
    _routeRecalculationTimer?.cancel();
    _routeRecalculationTimer = null;
  }

  /// Recalculate route if user deviates from current route
  Future<void> _recalculateRouteIfNeeded() async {
    if (_currentLocation == null || _polylinePoints.isEmpty) return;

    // Check if user is off route
    final distanceToRoute = _calculateDistanceToRoute(
      _currentLocation!,
      _polylinePoints,
    );

    if (distanceToRoute > _routeRecalculationThreshold) {
      // User is off route - recalculate
      await _recalculateRoute();
    } else {
      // User is on route - trim passed waypoints for efficiency
      _trimPassedWaypoints();
    }
  }

  /// Calculate shortest distance from point to route
  double _calculateDistanceToRoute(LatLng point, List<LatLng> route) {
    if (route.length < 2) return 0.0;

    double minDistance = double.infinity;

    for (int i = 0; i < route.length - 1; i++) {
      final segmentDistance = _distanceToLineSegment(
        point,
        route[i],
        route[i + 1],
      );
      minDistance = minDistance < segmentDistance
          ? minDistance
          : segmentDistance;
    }

    return minDistance;
  }

  /// Calculate distance from point to line segment
  double _distanceToLineSegment(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;

    if (dx == 0 && dy == 0) {
      return RoutingService.calculateDistance(point, lineStart);
    }

    final t =
        ((point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy) /
        (dx * dx + dy * dy);

    if (t < 0) {
      return RoutingService.calculateDistance(point, lineStart);
    } else if (t > 1) {
      return RoutingService.calculateDistance(point, lineEnd);
    }

    final projection = LatLng(
      lineStart.latitude + t * dy,
      lineStart.longitude + t * dx,
    );

    return RoutingService.calculateDistance(point, projection);
  }

  /// Remove waypoints that user has already passed
  void _trimPassedWaypoints() {
    if (_currentLocation == null || _polylinePoints.length < 2) return;

    // Find closest point on route
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < _polylinePoints.length; i++) {
      final distance = RoutingService.calculateDistance(
        _currentLocation!,
        _polylinePoints[i],
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Remove points before closest (user has passed them)
    if (closestIndex > 0) {
      _polylinePoints = _polylinePoints.sublist(closestIndex);

      // Update distance/duration for remaining route
      final remainingDistance = RouteHelper.calculateRouteDistance(
        _polylinePoints,
      );
      _routeDistance = RoutingService.formatDistance(remainingDistance);
      _routeDuration = RoutingService.calculateWalkingDuration(
        remainingDistance,
      );

      // Notify UI
      onRouteUpdated?.call(_polylinePoints);
    }
  }

  /// Recalculate entire route from current location
  Future<void> _recalculateRoute() async {
    if (_currentLocation == null || _currentDestination == null) return;

    LatLng destinationPoint;
    if (_currentDestination.runtimeType.toString().contains('Building')) {
      destinationPoint = _currentDestination.getCenterPoint();
    } else {
      destinationPoint = _currentDestination as LatLng;
    }

    final routeResult = await RoutingService.getRoute(
      _currentLocation!,
      destinationPoint,
    );

    if (routeResult.isSuccess && routeResult.points != null) {
      _polylinePoints = routeResult.points!;
      _routeDistance = routeResult.distance;
      _routeDuration = routeResult.duration;

      // Notify UI of new route
      onRouteUpdated?.call(_polylinePoints);
    }
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

    if (distance < 10) {
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
    _targetBearing = 0.0;

    _stopHeadingUpdates();
    _stopRouteRecalculation();
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

  double _lerpAngle(double current, double target, double factor) {
    double diff = target - current;

    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;

    return (current + diff * factor) % 360;
  }

  void dispose() {
    _isDisposed = true;
    _stopHeadingUpdates();
    _stopRouteRecalculation();
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
