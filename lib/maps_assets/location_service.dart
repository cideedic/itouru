// lib/maps_assets/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationResult.success(
        LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      return LocationResult.error('Error getting location: $e');
    }
  }

  static Stream<LocationResult> getLocationStream() {
    return Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        )
        .map((position) {
          return LocationResult.success(
            LatLng(position.latitude, position.longitude),
          );
        })
        .handleError((error) {
          return LocationResult.error('Location stream error: $error');
        });
  }
}

class LocationResult {
  final LatLng? location;
  final String? error;
  final bool isSuccess;

  LocationResult._({this.location, this.error, required this.isSuccess});

  factory LocationResult.success(LatLng location) {
    return LocationResult._(location: location, isSuccess: true);
  }

  factory LocationResult.error(String error) {
    return LocationResult._(error: error, isSuccess: false);
  }
}
