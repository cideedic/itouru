// lib/maps_assets/map_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 30),
      ),
    );
  }

  // Animate to location with zoom
  static void animateToLocation(
    MapController mapController,
    LatLng location, {
    double zoom = 18.0,
  }) {
    mapController.move(location, zoom);
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
}
