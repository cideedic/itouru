// lib/maps_assets/map_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class MapUtils {
  // Convert screen coordinates to LatLng
  static LatLng screenToLatLng(
    Offset screenPoint,
    MapController mapController,
    Size screenSize,
  ) {
    final camera = mapController.camera;
    final bounds = camera.visibleBounds;

    final lat =
        bounds.north -
        (screenPoint.dy / screenSize.height) * (bounds.north - bounds.south);
    final lng =
        bounds.west +
        (screenPoint.dx / screenSize.width) * (bounds.east - bounds.west);

    return LatLng(lat, lng);
  }

  // Calculate distance between two points
  static double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  // Calculate distance between two points in meters (using Haversine formula)
  static double calculateDistanceInMeters(LatLng point1, LatLng point2) {
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

  // Calculate bearing between two points
  static double calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (math.pi / 180);
    double lat2 = end.latitude * (math.pi / 180);
    double deltaLng = (end.longitude - start.longitude) * (math.pi / 180);

    double y = math.sin(deltaLng) * math.cos(lat2);
    double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    double bearing = math.atan2(y, x) * (180 / math.pi);
    return (bearing + 360) % 360; // Normalize to 0-360 degrees
  }

  // Get map options with default settings
  static MapOptions getDefaultMapOptions(
    LatLng initialCenter,
    CameraConstraint constraint,
  ) {
    return MapOptions(
      initialCenter: initialCenter,
      initialZoom: 18.0,
      minZoom: 16.0,
      maxZoom: 20.0,
      cameraConstraint: constraint,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all,
        enableScrollWheel: true,
      ),
    );
  }

  // Create default tile layer
  static TileLayer getDefaultTileLayer() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.bicoluniversity.etouro',
      maxNativeZoom: 19,
    );
  }

  // Create user location marker
  static Marker createUserLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 30),
      ),
    );
  }

  // Create navigation marker with direction indicator
  static Marker createNavigationMarker(LatLng position, double bearing) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: Transform.rotate(
        angle: bearing * (math.pi / 180), // Convert degrees to radians
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // Enhanced animate to location with smoother transitions
  static void animateToLocation(
    MapController mapController,
    LatLng location, {
    double zoom = 18.0,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    // Use the move method which provides smooth animation
    mapController.move(location, zoom);
  }

  // Enhanced method for smooth panning to building with visual feedback
  static Future<void> animateToBuildingLocation(
    MapController mapController,
    LatLng location, {
    double zoom = 19.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) async {
    // First, smoothly animate to the location
    mapController.move(location, zoom);

    // Add a small delay to ensure the animation completes
    await Future.delayed(duration);
  }

  // Method to pan from current view to a specific location with custom zoom
  static Future<void> panToLocationFromCurrentView(
    MapController mapController,
    LatLng targetLocation, {
    double targetZoom = 19.0,
    Duration animationDuration = const Duration(milliseconds: 1000),
  }) async {
    // Get current camera position
    final currentCenter = mapController.camera.center;
    final currentZoom = mapController.camera.zoom;

    // Calculate distance to determine if we need to zoom out first for better visual effect
    final distance = calculateDistanceInMeters(currentCenter, targetLocation);

    if (distance > 500) {
      // If far away, create a smoother transition
      // First zoom out slightly to show the path
      final intermediateZoom = math.min(currentZoom - 1, 17.0);
      mapController.move(currentCenter, intermediateZoom);

      // Wait for zoom out animation
      await Future.delayed(const Duration(milliseconds: 300));

      // Then pan to target location
      mapController.move(targetLocation, intermediateZoom);

      // Wait for pan animation
      await Future.delayed(const Duration(milliseconds: 500));

      // Finally zoom in to target zoom level
      mapController.move(targetLocation, targetZoom);
    } else {
      // For nearby locations, just pan directly
      mapController.move(targetLocation, targetZoom);
    }
  }

  // Zoom in/out functions
  static void zoomIn(MapController mapController) {
    final currentZoom = mapController.camera.zoom;
    mapController.move(mapController.camera.center, currentZoom + 1);
  }

  static void zoomOut(MapController mapController) {
    final currentZoom = mapController.camera.zoom;
    mapController.move(mapController.camera.center, currentZoom - 1);
  }

  // Method to fit bounds with padding
  static void fitBounds(
    MapController mapController,
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(50),
  }) {
    if (points.isEmpty) return;

    // Calculate bounds
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // Calculate center point
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final center = LatLng(centerLat, centerLng);

    // Calculate appropriate zoom level
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = math.max(latDiff, lngDiff);

    // Estimate zoom level based on difference
    double zoom = 18.0;
    if (maxDiff > 0.01)
      zoom = 15.0;
    else if (maxDiff > 0.005)
      zoom = 16.0;
    else if (maxDiff > 0.002)
      zoom = 17.0;
    else if (maxDiff > 0.001)
      zoom = 18.0;
    else
      zoom = 19.0;

    mapController.move(center, zoom);
  }
}
