import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_map/flutter_map.dart';
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
    mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
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
      totalDistance += _calculateDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  /// Calculates distance between two points using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
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
}
