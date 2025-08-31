import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itouru/maps_assets/location_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1';

  /// Gets route between two points
  static Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    try {
      final String url =
          '$_osrmBaseUrl/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}?'
          'overview=full&geometries=polyline&steps=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final distance = route['distance'];
          final duration = route['duration'];

          // Decode the polyline
          final polylinePoints = PolylinePoints();
          final List<PointLatLng> result = polylinePoints.decodePolyline(
            geometry,
          );

          // Convert to LatLng
          final List<LatLng> routePoints = result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          return RouteResult.success(
            points: routePoints,
            distance: _formatDistance(distance),
            duration: _formatDuration(duration),
          );
        }
      }

      return RouteResult.error('No route found');
    } catch (e) {
      return RouteResult.error('Error getting route: $e');
    }
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

  /// Formats distance from meters to human-readable format
  static String _formatDistance(double distanceInMeters) {
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceInMeters.toInt()} m';
    }
  }

  /// Formats duration from seconds to human-readable format
  static String _formatDuration(double durationInSeconds) {
    final int minutes = (durationInSeconds / 60).round();
    if (minutes >= 60) {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Calculate distance between two points in meters using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

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

  /// Calculate bearing between two points
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

// Navigation Manager Class - NEW
class NavigationManager {
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  LatLng? _previousLocation;
  double _currentBearing = 0.0;
  bool _isNavigating = false;
  bool _isDisposed = false;

  // Destination info
  dynamic _currentDestination;
  List<LatLng> _polylinePoints = [];
  String? _routeDistance;
  String? _routeDuration;

  // Callbacks
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

  /// Start navigation to a destination
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

    // Set callbacks
    this.onLocationUpdate = onLocationUpdate;
    this.onDestinationReached = onDestinationReached;
    this.onError = onError;

    // Start location tracking
    await _startLocationTracking();
  }

  /// Stop navigation
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

  /// Start location tracking for navigation
  Future<void> _startLocationTracking() async {
    if (_isDisposed) return;

    // Use your existing LocationService for initial permission/location check
    final initialLocationResult = await LocationService.getCurrentLocation();

    if (!initialLocationResult.isSuccess) {
      onError?.call(initialLocationResult.error ?? 'Location error');
      return;
    }

    // Set initial location
    _currentLocation = initialLocationResult.location;
    _previousLocation = initialLocationResult.location;

    // Now start the position stream (permissions already handled)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // More sensitive for navigation
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_isDisposed) return;

            final newLocation = LatLng(position.latitude, position.longitude);

            // Calculate bearing if we have a previous location
            if (_previousLocation != null) {
              _currentBearing = RoutingService.calculateBearing(
                _previousLocation!,
                newLocation,
              );
            }

            _currentLocation = newLocation;
            _previousLocation = newLocation;

            // Notify location update
            onLocationUpdate?.call(newLocation, _currentBearing);

            // Check if destination is reached
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

  /// Stop location tracking
  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Check if destination is reached
  void _checkDestinationReached() {
    if (_currentLocation == null || _currentDestination == null) return;

    // Get destination center point (assuming it has getCenterPoint method)
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

    // If within 50 meters of destination, consider it reached
    if (distance < 5) {
      _destinationReached();
    }
  }

  /// Handle destination reached
  void _destinationReached() {
    if (_isDisposed) return;

    _isNavigating = false;
    onDestinationReached?.call(_currentDestination);

    // Clear navigation data after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        stopNavigation();
      }
    });
  }

  /// Clear route data
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

  /// Get route and prepare for navigation
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

  /// Dispose the navigation manager
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

  RouteResult._({
    this.points,
    this.distance,
    this.duration,
    this.error,
    required this.isSuccess,
  });

  factory RouteResult.success({
    required List<LatLng> points,
    String? distance,
    String? duration,
  }) {
    return RouteResult._(
      points: points,
      distance: distance,
      duration: duration,
      isSuccess: true,
    );
  }

  factory RouteResult.error(String error) {
    return RouteResult._(error: error, isSuccess: false);
  }
}

/// Helper class for route-related operations
class RouteHelper {
  /// Creates a polyline for the route
  static Polyline createRoutePolyline(List<LatLng> points) {
    return Polyline(
      points: points,
      color: const Color(0xFF2196F3), // Blue color
      strokeWidth: 4.0,
    );
  }

  /// Validates if route points are valid
  static bool isValidRoute(List<LatLng> points) {
    return points.isNotEmpty && points.length >= 2;
  }

  /// Gets the total distance of a route in meters (approximate)
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
