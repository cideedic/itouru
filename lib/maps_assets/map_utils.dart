import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'map_boundary.dart';
import 'routing_service.dart';

class MapUtils {
  // ✨ Zoom level thresholds for marker visibility
  static const double zoomShowColleges = 17.5;
  static const double zoomShowLandmarks = 18.0;
  static const double zoomShowAllDetails = 19.0;

  // ✨ Fade transition zone (how many zoom levels for smooth fade)
  static const double fadeDuration = 1; // 1 zoom level for fade transition

  // ✨ Check if colleges should be visible at current zoom
  static bool shouldShowColleges(double currentZoom) {
    return currentZoom >= zoomShowColleges;
  }

  // ✨ Check if landmarks should be visible at current zoom
  static bool shouldShowLandmarks(double currentZoom) {
    return currentZoom >= zoomShowLandmarks;
  }

  // ✨ Check if all details should be shown
  static bool shouldShowAllDetails(double currentZoom) {
    return currentZoom >= zoomShowAllDetails;
  }

  // ✨ ENHANCED: Get marker opacity with smoother fade-in/fade-out
  static double getMarkerOpacity(double currentZoom, String markerType) {
    switch (markerType) {
      case 'college':
        return _calculateFadeOpacity(currentZoom, zoomShowColleges);

      case 'landmark':
        return _calculateFadeOpacity(currentZoom, zoomShowLandmarks);

      case 'detail':
        return _calculateFadeOpacity(currentZoom, zoomShowAllDetails);

      default:
        return 1.0;
    }
  }

  // ✨ NEW: Calculate smooth fade opacity with easing
  static double _calculateFadeOpacity(double currentZoom, double threshold) {
    // Fade starts 0.5 zoom levels before threshold
    final fadeStartZoom = threshold - 0.5;
    final fadeEndZoom = threshold + 0.5;

    if (currentZoom < fadeStartZoom) {
      // Completely invisible before fade starts
      return 0.0;
    } else if (currentZoom >= fadeEndZoom) {
      // Completely visible after fade ends
      return 1.0;
    } else {
      // Calculate fade progress (0.0 to 1.0)
      final progress =
          (currentZoom - fadeStartZoom) / (fadeEndZoom - fadeStartZoom);

      // Apply easing for smoother animation
      return _easeInOutQuad(progress).clamp(0.0, 1.0);
    }
  }

  // ✨ NEW: Easing function for smooth fade
  static double _easeInOutQuad(double t) {
    return t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
  }

  // ✨ ENHANCED: Get marker size with smooth scaling
  static double getMarkerSize(double currentZoom, String markerType) {
    final baseSize = markerType == 'landmark' ? 60.0 : 70.0;

    // Determine threshold based on marker type
    double threshold;
    switch (markerType) {
      case 'college':
        threshold = zoomShowColleges;
        break;
      case 'landmark':
        threshold = zoomShowLandmarks;
        break;
      default:
        threshold = zoomShowColleges;
    }

    if (currentZoom < threshold - 0.5) {
      return 0; // Hidden
    } else if (currentZoom < threshold + 0.5) {
      // Scale up smoothly during fade-in
      final progress = (currentZoom - (threshold - 0.5)) / 1.0;
      return baseSize * _easeInOutQuad(progress);
    } else if (currentZoom < 19.0) {
      return baseSize; // Normal size
    } else {
      // Scale up slightly at max zoom
      final progress = (currentZoom - 19.0).clamp(0.0, 1.0);
      return baseSize + (10 * progress); // Up to 10px larger
    }
  }

  // ✨ NEW: Create animated marker wrapper (FADE ONLY - NO SCALING)
  static Widget createAnimatedMarker({
    required Widget child,
    required double currentZoom,
    required String markerType,
    Duration animationDuration = const Duration(milliseconds: 300),
  }) {
    final opacity = getMarkerOpacity(currentZoom, markerType);
    final size = getMarkerSize(currentZoom, markerType);

    return AnimatedOpacity(
      opacity: opacity,
      duration: animationDuration,
      curve: Curves.easeInOut,
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  // ✨ NEW: Wrap any custom marker widget with animation (FADE ONLY - NO SCALING)
  static Widget wrapMarkerWithAnimation({
    required Widget markerWidget,
    required double currentZoom,
    required String markerType,
    Duration animationDuration = const Duration(milliseconds: 300),
  }) {
    final opacity = getMarkerOpacity(currentZoom, markerType);

    return AnimatedOpacity(
      opacity: opacity,
      duration: animationDuration,
      curve: Curves.easeInOut,
      child: markerWidget,
    );
  }

  // ✅ Get default map options with all callbacks
  static MapOptions getDefaultMapOptions(
    LatLng center,
    CameraConstraint cameraConstraint, {
    Function(MapCamera, bool)? onPositionChanged,
    Function(TapPosition, LatLng)? onTap,
  }) {
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
      onPositionChanged: onPositionChanged,
      onTap: onTap,
    );
  }

  // Get default tile layer
  static TileLayer getDefaultTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
      location = _getNearestPointInBounds(location);
    }

    await _animatedMapMove(
      controller,
      location,
      zoom ?? controller.camera.zoom,
      duration,
    );
  }

  // Get nearest point within campus bounds
  static LatLng _getNearestPointInBounds(LatLng point) {
    final center = MapBoundary.bicolUniversityCenter;

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
    if (!MapBoundary.isWithinCampusBounds(targetLocation)) {
      targetLocation = MapBoundary.bicolUniversityCenter;
    }

    final currentZoom = controller.camera.zoom;
    final finalZoom = targetZoom ?? currentZoom;

    final constrainedZoom = finalZoom.clamp(
      MapBoundary.getMinZoom(),
      MapBoundary.getMaxZoom(),
    );

    await _animatedMapMove(
      controller,
      targetLocation,
      constrainedZoom,
      animationDuration,
    );
  }

  // Smooth animated map movement using interpolation
  static Future<void> _animatedMapMove(
    MapController controller,
    LatLng destLocation,
    double destZoom,
    Duration duration,
  ) async {
    final camera = controller.camera;
    final startLatLng = camera.center;
    final startZoom = camera.zoom;

    const fps = 60;
    final frames = (duration.inMilliseconds / (1000 / fps)).round();

    for (int i = 0; i <= frames; i++) {
      final t = i / frames;
      final easedT = _easeInOutCubic(t);

      final lat =
          startLatLng.latitude +
          (destLocation.latitude - startLatLng.latitude) * easedT;

      final lng =
          startLatLng.longitude +
          (destLocation.longitude - startLatLng.longitude) * easedT;

      final zoom = startZoom + (destZoom - startZoom) * easedT;

      controller.move(LatLng(lat, lng), zoom);

      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }

    controller.move(destLocation, destZoom);
  }

  /// Easing function for smooth animation
  static double _easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      return 1 - math.pow(-2 * t + 2, 3) / 2;
    }
  }

  // Building-specific animation with boundary checking
  static Future<void> animateToBuildingLocation(
    MapController controller,
    LatLng buildingLocation, {
    double zoom = 19.0,
    Duration duration = const Duration(milliseconds: 600),
  }) async {
    if (!MapBoundary.isWithinCampusBounds(buildingLocation)) {
      buildingLocation = MapBoundary.bicolUniversityCenter;
    }

    final constrainedZoom = zoom.clamp(
      MapBoundary.getMinZoom(),
      MapBoundary.getMaxZoom(),
    );

    await _animatedMapMove(
      controller,
      buildingLocation,
      constrainedZoom,
      duration,
    );
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

  // Check if location is within campus bounds
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

  /// Enhanced route animation with ultra-smooth line drawing
  static Future<void> animateAlongRouteWithCamera(
    MapController mapController,
    List<LatLng> routePoints, {
    required Function(List<LatLng>) onRouteUpdate,
    double followZoom = 19.0,
    double destinationZoom = 19.5,
    Duration overviewDuration = const Duration(milliseconds: 1000),
    Duration zoomInDuration = const Duration(milliseconds: 800),
    Duration routeDrawDuration = const Duration(
      seconds: 8,
    ), // ✨ NEW: Dedicated draw time
    Duration finalZoomDuration = const Duration(milliseconds: 800),
  }) async {
    if (routePoints.isEmpty) {
      print('⚠️ animateAlongRouteWithCamera: Empty route points');
      return;
    }

    print('🎬 Animating camera along route with ${routePoints.length} points');

    try {
      // Step 1: Show entire route overview (route NOT visible yet)
      await Future.delayed(const Duration(milliseconds: 500));
      onRouteUpdate([]);

      RoutingService.fitMapToRoute(mapController, routePoints);
      await Future.delayed(overviewDuration);

      // Step 2: Zoom to route start
      await animateToBuildingLocation(
        mapController,
        routePoints.first,
        zoom: followZoom,
        duration: zoomInDuration,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: ✨ SMOOTH route animation with camera follow
      await _smoothRouteAnimationWithCamera(
        mapController,
        routePoints,
        onRouteUpdate: onRouteUpdate,
        zoom: followZoom,
        duration: routeDrawDuration,
      );

      // Step 4: Final zoom to destination
      await animateToBuildingLocation(
        mapController,
        routePoints.last,
        zoom: destinationZoom,
        duration: finalZoomDuration,
      );

      print('✅ Route camera animation complete');
    } catch (e, stackTrace) {
      print('❌ ERROR in animateAlongRouteWithCamera: $e');
      print('Stack trace: $stackTrace');
      onRouteUpdate(routePoints); // Fail gracefully
    }
  }

  /// ✨ NEW: Smooth route animation using interpolation
  static Future<void> _smoothRouteAnimationWithCamera(
    MapController mapController,
    List<LatLng> routePoints, {
    required Function(List<LatLng>) onRouteUpdate,
    required double zoom,
    required Duration duration,
  }) async {
    if (routePoints.length < 2) {
      onRouteUpdate(routePoints);
      return;
    }

    print('🎨 Starting smooth route animation');

    // Calculate cumulative distances for smooth interpolation
    final distances = <double>[0.0];
    double cumulative = 0.0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      final distance = RoutingService.calculateDistance(
        routePoints[i],
        routePoints[i + 1],
      );
      cumulative += distance;
      distances.add(cumulative);
    }
    final totalDistance = distances.last;

    // Simplify camera points (every 5th point)
    final cameraPoints = <LatLng>[];
    for (int i = 0; i < routePoints.length; i += 5) {
      cameraPoints.add(routePoints[i]);
    }
    if (cameraPoints.last != routePoints.last) {
      cameraPoints.add(routePoints.last);
    }

    print('📹 Following ${cameraPoints.length} camera waypoints');

    // Time per camera point
    final msPerCameraPoint = duration.inMilliseconds ~/ cameraPoints.length;

    // Animate through camera points while smoothly drawing route
    const fps = 60;
    final frameDelay = Duration(milliseconds: (1000 / fps).round());
    final startTime = DateTime.now();

    int currentCameraIndex = 0;
    LatLng currentCameraTarget = cameraPoints[0];
    LatLng? nextCameraTarget = cameraPoints.length > 1 ? cameraPoints[1] : null;

    while (currentCameraIndex < cameraPoints.length) {
      final elapsed = DateTime.now().difference(startTime);
      final globalProgress = (elapsed.inMilliseconds / duration.inMilliseconds)
          .clamp(0.0, 1.0);

      // ✨ Get smoothly interpolated route segment
      final visibleRoute = _getSmoothRouteSegment(
        routePoints,
        distances,
        totalDistance,
        globalProgress,
      );

      // Update visible route
      onRouteUpdate(visibleRoute);

      // Smooth camera movement
      if (nextCameraTarget != null) {
        final cameraStartTime = currentCameraIndex * msPerCameraPoint;
        final cameraEndTime = (currentCameraIndex + 1) * msPerCameraPoint;
        final cameraElapsed = elapsed.inMilliseconds - cameraStartTime;

        if (cameraElapsed >= 0 && cameraElapsed < msPerCameraPoint) {
          final cameraProgress = (cameraElapsed / msPerCameraPoint).clamp(
            0.0,
            1.0,
          );
          final easedProgress = _easeInOutCubic(cameraProgress);

          // Interpolate camera position
          final lat =
              currentCameraTarget.latitude +
              (nextCameraTarget.latitude - currentCameraTarget.latitude) *
                  easedProgress;
          final lng =
              currentCameraTarget.longitude +
              (nextCameraTarget.longitude - currentCameraTarget.longitude) *
                  easedProgress;

          // Calculate bearing
          final bearing = RoutingService.calculateBearing(
            currentCameraTarget,
            nextCameraTarget,
          );

          // Move camera with rotation
          mapController.moveAndRotate(LatLng(lat, lng), zoom, -bearing);
        } else if (elapsed.inMilliseconds >= cameraEndTime) {
          // Move to next camera segment
          currentCameraIndex++;
          currentCameraTarget = cameraPoints[currentCameraIndex];
          nextCameraTarget = currentCameraIndex + 1 < cameraPoints.length
              ? cameraPoints[currentCameraIndex + 1]
              : null;
        }
      }

      if (globalProgress >= 1.0) break;
      await Future.delayed(frameDelay);
    }

    // Ensure full route is visible
    onRouteUpdate(routePoints);
    mapController.moveAndRotate(routePoints.last, zoom, 0);

    print('✅ Smooth route animation complete');
  }

  static List<LatLng> _getSmoothRouteSegment(
    List<LatLng> fullRoute,
    List<double> distances,
    double totalDistance,
    double progress,
  ) {
    if (fullRoute.isEmpty) return [];
    if (progress <= 0) return [];
    if (progress >= 1.0) return fullRoute;

    final targetDistance = totalDistance * progress;

    // ✨ OPTIMIZATION: Binary search for segment (faster for long routes)
    int segmentIndex = 0;
    int left = 0;
    int right = distances.length - 1;

    while (left <= right) {
      int mid = (left + right) ~/ 2;
      if (mid < distances.length - 1 &&
          targetDistance >= distances[mid] &&
          targetDistance <= distances[mid + 1]) {
        segmentIndex = mid;
        break;
      } else if (targetDistance < distances[mid]) {
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }

    // Get complete points up to current segment
    final visiblePoints = fullRoute.sublist(0, segmentIndex + 1).toList();

    // ✨ CRITICAL: Add interpolated partial point for smooth growth
    if (segmentIndex < fullRoute.length - 1) {
      final segmentStart = distances[segmentIndex];
      final segmentEnd = distances[segmentIndex + 1];
      final segmentDistance = segmentEnd - segmentStart;

      if (segmentDistance > 0) {
        // Calculate precise position within segment
        final segmentProgress =
            (targetDistance - segmentStart) / segmentDistance;
        final startPoint = fullRoute[segmentIndex];
        final endPoint = fullRoute[segmentIndex + 1];

        // ✨ Interpolate with HIGH precision
        final lat =
            startPoint.latitude +
            (endPoint.latitude - startPoint.latitude) * segmentProgress;
        final lng =
            startPoint.longitude +
            (endPoint.longitude - startPoint.longitude) * segmentProgress;

        visiblePoints.add(LatLng(lat, lng));
      }
    }

    return visiblePoints;
  }

  /// Smooth camera movement WITH ROTATION
  /// Camera tilts/rotates to face the direction of travel
  static Future<void> smoothCameraMoveWithRotation(
    MapController mapController,
    LatLng target, {
    required double zoom,
    double? bearing,
    required Duration duration,
  }) async {
    final camera = mapController.camera;
    final startLatLng = camera.center;
    final startZoom = camera.zoom;
    final startRotation = camera.rotation;

    // Target rotation (convert bearing to map rotation)
    // Flutter map rotation: 0° = North, clockwise
    // We want to rotate so "forward" faces the bearing direction
    final targetRotation = bearing != null ? -bearing : 0.0;

    const fps = 60;
    final frames = (duration.inMilliseconds / (1000 / fps)).round();

    for (int i = 0; i <= frames; i++) {
      final t = i / frames;
      final easedT = _easeInOutQuad(t);

      // Interpolate position
      final lat =
          startLatLng.latitude +
          (target.latitude - startLatLng.latitude) * easedT;
      final lng =
          startLatLng.longitude +
          (target.longitude - startLatLng.longitude) * easedT;

      // Interpolate zoom
      final currentZoom = startZoom + (zoom - startZoom) * easedT;

      // Interpolate rotation (handle wraparound)
      final currentRotation = _interpolateRotation(
        startRotation,
        targetRotation,
        easedT,
      );

      // Move camera with rotation
      mapController.moveAndRotate(
        LatLng(lat, lng),
        currentZoom,
        currentRotation,
      );

      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }

    // Final position with exact rotation
    mapController.moveAndRotate(target, zoom, targetRotation);
  }

  /// Interpolate rotation angles, handling 360° wraparound
  static double _interpolateRotation(double start, double end, double t) {
    // Normalize angles to -180 to 180
    start = start % 360;
    end = end % 360;

    if (start > 180) start -= 360;
    if (start < -180) start += 360;
    if (end > 180) end -= 360;
    if (end < -180) end += 360;

    // Find shortest rotation direction
    double diff = end - start;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    return start + (diff * t);
  }

  /// Standard smooth camera move (without rotation)
  /// Keep this for backward compatibility
  static Future<void> smoothCameraMove(
    MapController mapController,
    LatLng target, {
    required double zoom,
    double? bearing,
    required Duration duration,
  }) async {
    final camera = mapController.camera;
    final startLatLng = camera.center;
    final startZoom = camera.zoom;

    const fps = 60;
    final frames = (duration.inMilliseconds / (1000 / fps)).round();

    for (int i = 0; i <= frames; i++) {
      final t = i / frames;
      final easedT = _easeInOutQuad(t);

      final lat =
          startLatLng.latitude +
          (target.latitude - startLatLng.latitude) * easedT;
      final lng =
          startLatLng.longitude +
          (target.longitude - startLatLng.longitude) * easedT;
      final currentZoom = startZoom + (zoom - startZoom) * easedT;

      mapController.move(LatLng(lat, lng), currentZoom);

      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }

    mapController.move(target, zoom);
  }

  static List<LatLng> getAnimatedRouteSegment(
    List<LatLng> fullRoute,
    double progress,
  ) {
    if (fullRoute.isEmpty) return [];
    if (progress <= 0) return [];
    if (progress >= 1) return fullRoute;

    final targetIndex = (fullRoute.length * progress).floor();
    return fullRoute.sublist(0, math.min(targetIndex + 1, fullRoute.length));
  }
}
