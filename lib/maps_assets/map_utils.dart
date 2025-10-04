import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'map_boundary.dart';

class MapUtils {
  // Get default map options with strict boundary enforcement
  static MapOptions getDefaultMapOptions(
    LatLng center,
    CameraConstraint cameraConstraint,
  ) {
    return MapOptions(
      initialCenter: center,
      initialZoom: MapBoundary.getInitialZoom(),
      minZoom: MapBoundary.getMinZoom(),
      maxZoom: MapBoundary.getMaxZoom(),
      cameraConstraint: cameraConstraint,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all,
        enableMultiFingerGestureRace: true,
      ),
      // Add boundary checking on camera move
      onPositionChanged: (MapCamera camera, bool hasGesture) {
        _enforceBoundaryConstraints(camera);
      },
    );
  }

  // Enforce boundary constraints
  static void _enforceBoundaryConstraints(MapCamera camera) {
    if (!MapBoundary.isWithinCampusBounds(camera.center)) {
      // If center goes outside campus, don't allow the move
      // This is handled by CameraConstraint, but we can add additional logic here
    }
  }

  // Get default tile layer
  static TileLayer getDefaultTileLayer() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      userAgentPackageName: 'com.example.bicol_university_app',
      maxZoom: MapBoundary.getMaxZoom(),
      minZoom: MapBoundary.getMinZoom(),
      subdomains: const ['a', 'b', 'c'],
      retinaMode: true,
    );
  }

  // Enhanced location animation that respects boundaries
  static Future<void> animateToLocation(
    MapController controller,
    LatLng location, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 800),
  }) async {
    // Check if the target location is within campus bounds
    if (!MapBoundary.isWithinCampusBounds(location)) {
      // If outside bounds, animate to the nearest point within bounds
      location = _getNearestPointInBounds(location);
    }

    // Remove await since controller.move() returns bool, not Future
    controller.move(location, zoom ?? MapBoundary.getInitialZoom());

    // Add a small delay to simulate animation if needed
    await Future.delayed(duration);
  }

  // Get nearest point within campus bounds
  static LatLng _getNearestPointInBounds(LatLng point) {
    final center = MapBoundary.bicolUniversityCenter;

    // If point is outside, return campus center as fallback
    if (!MapBoundary.isWithinCampusBounds(point)) {
      return center;
    }

    return point;
  }

  // Enhanced pan method with boundary checking
  static Future<void> panToLocationFromCurrentView(
    MapController controller,
    LatLng targetLocation, {
    double? targetZoom,
    Duration animationDuration = const Duration(milliseconds: 1000),
  }) async {
    // Ensure target location is within bounds
    if (!MapBoundary.isWithinCampusBounds(targetLocation)) {
      targetLocation = MapBoundary.bicolUniversityCenter;
    }

    final currentZoom = controller.camera.zoom;
    final finalZoom = targetZoom ?? currentZoom;

    // Ensure zoom is within limits
    final constrainedZoom = finalZoom.clamp(
      MapBoundary.getMinZoom(),
      MapBoundary.getMaxZoom(),
    );

    // Remove await since controller.move() returns bool, not Future
    controller.move(targetLocation, constrainedZoom);

    // Add delay to simulate animation
    await Future.delayed(animationDuration);
  }

  // Building-specific animation with boundary checking
  static Future<void> animateToBuildingLocation(
    MapController controller,
    LatLng buildingLocation, {
    double zoom = 19.0,
    Duration duration = const Duration(milliseconds: 600),
  }) async {
    // Ensure building location is within campus bounds
    if (!MapBoundary.isWithinCampusBounds(buildingLocation)) {
      buildingLocation = MapBoundary.bicolUniversityCenter;
    }

    final constrainedZoom = zoom.clamp(
      MapBoundary.getMinZoom(),
      MapBoundary.getMaxZoom(),
    );

    // Remove await since controller.move() returns bool, not Future
    controller.move(buildingLocation, constrainedZoom);

    // Add delay to simulate animation
    await Future.delayed(duration);
  }

  // Zoom controls with boundary-aware limits
  static void zoomIn(MapController controller) {
    final currentZoom = controller.camera.zoom;
    final newZoom = (currentZoom + 1).clamp(
      MapBoundary.getMinZoom(),
      MapBoundary.getMaxZoom(),
    );
    controller.move(controller.camera.center, newZoom);
  }

  static void zoomOut(MapController controller) {
    final currentZoom = controller.camera.zoom;
    final newZoom = (currentZoom - 1).clamp(
      MapBoundary.getMinZoom(),
      MapBoundary.getMaxZoom(),
    );
    controller.move(controller.camera.center, newZoom);
  }

  // Screen to LatLng conversion
  static LatLng screenToLatLng(
    Offset screenPosition,
    MapController controller,
    Size screenSize,
  ) {
    final camera = controller.camera;
    final mapSize = screenSize;

    final centerX = mapSize.width / 2;
    final centerY = mapSize.height / 2;

    final deltaX = screenPosition.dx - centerX;
    final deltaY = screenPosition.dy - centerY;

    final scale = math.pow(2, camera.zoom);
    final earthCircumference = 40075016.686; // meters
    final metersPerPixel = earthCircumference / (256 * scale);

    final deltaLatMeters = -deltaY * metersPerPixel;
    final deltaLngMeters = deltaX * metersPerPixel;

    final deltaLat = deltaLatMeters / 111320;
    final deltaLng =
        deltaLngMeters /
        (111320 * math.cos(camera.center.latitude * math.pi / 180));

    return LatLng(
      camera.center.latitude + deltaLat,
      camera.center.longitude + deltaLng,
    );
  }

  // User location marker
  static Marker createUserLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation marker with direction
  static Marker createNavigationMarker(LatLng location, double bearing) {
    return Marker(
      point: location,
      width: 30,
      height: 30,
      child: Transform.rotate(
        angle: bearing * math.pi / 180,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  // Check if location is within campus bounds (helper method)
  static bool isLocationWithinCampus(LatLng location) {
    return MapBoundary.isWithinCampusBounds(location);
  }

  // Reset to campus center if user gets lost
  static Future<void> resetToCampusCenter(MapController controller) async {
    await animateToLocation(
      controller,
      MapBoundary.bicolUniversityCenter,
      zoom: MapBoundary.getInitialZoom(),
    );
  }
}
