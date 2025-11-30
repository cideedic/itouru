import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

class LocationService {
  static StreamSubscription<CompassEvent>? _compassSubscription;
  static double _currentHeading = 0.0;
  static bool _isCompassAvailable = false;

  /// Initialize compass stream
  static Future<void> initializeCompass() async {
    try {
      // Check if compass is available
      final compassEvents = FlutterCompass.events;
      if (compassEvents == null) {
        _isCompassAvailable = false;
        return;
      }

      _isCompassAvailable = true;

      // Listen to compass updates
      _compassSubscription = compassEvents.listen((CompassEvent event) {
        if (event.heading != null) {
          _currentHeading = event.heading!;
        }
      });
    } catch (e) {
      _isCompassAvailable = false;
    }
  }

  /// Get current heading from compass
  static double getCurrentHeading() {
    return _currentHeading;
  }

  /// Check if compass is available
  static bool get isCompassAvailable => _isCompassAvailable;

  /// Dispose compass stream
  static void disposeCompass() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  static Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Location services disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error('Location permission permanently denied');
      }

      // Get current position with LocationSettings
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LocationResult.success(
        LatLng(position.latitude, position.longitude),
        heading: _currentHeading, // Include compass heading
      );
    } catch (e) {
      return LocationResult.error('Error getting location: $e');
    }
  }

  static Stream<LocationResult> getLocationStream() {
    return Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3, // Update every 3 meters
          ),
        )
        .map((position) {
          return LocationResult.success(
            LatLng(position.latitude, position.longitude),
            heading: _currentHeading, // Include real-time compass heading
          );
        })
        .handleError((error) {
          return LocationResult.error('Location stream error: $error');
        });
  }
}

class LocationResult {
  final LatLng? location;
  final double? heading;
  final String? error;
  final bool isSuccess;

  LocationResult._({
    this.location,
    this.heading,
    this.error,
    required this.isSuccess,
  });

  factory LocationResult.success(LatLng location, {double? heading}) {
    return LocationResult._(
      location: location,
      heading: heading,
      isSuccess: true,
    );
  }

  factory LocationResult.error(String error) {
    return LocationResult._(error: error, isSuccess: false);
  }
}
