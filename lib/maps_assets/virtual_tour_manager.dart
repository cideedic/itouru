import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class VirtualTourStop {
  final int stopNumber;
  final int buildingId;
  final String buildingName;
  final String buildingNickname;
  final String? notes;
  LatLng? location; // ✨ NOT final - will be resolved in Maps

  VirtualTourStop({
    required this.stopNumber,
    required this.buildingId,
    required this.buildingName,
    required this.buildingNickname,
    required this.notes,
    this.location,
  });

  // ✨ Helper method to update location
  void setLocation(LatLng newLocation) {
    location = newLocation;
  }
}

class VirtualTourManager extends ChangeNotifier {
  // Tour state
  bool _isActive = false;
  int _currentStopIndex = 0;
  List<VirtualTourStop> _stops = [];
  String _tourName = '';
  LatLng? _startingGate;

  // Animation state
  bool _isAnimatingToStop = false;
  bool _isShowingStopCard = false;

  // Getters
  bool get isActive => _isActive;
  int get currentStopIndex => _currentStopIndex;
  VirtualTourStop? get currentStop =>
      _stops.isNotEmpty && _currentStopIndex < _stops.length
      ? _stops[_currentStopIndex]
      : null;
  List<VirtualTourStop> get stops => _stops;
  String get tourName => _tourName;
  int get totalStops => _stops.length;
  bool get isFirstStop => _currentStopIndex == 0;
  bool get isLastStop => _currentStopIndex == _stops.length - 1;
  bool get isAnimatingToStop => _isAnimatingToStop;
  bool get isShowingStopCard => _isShowingStopCard;
  LatLng? get startingGate => _startingGate;

  // Progress
  double get progress =>
      _stops.isEmpty ? 0 : (_currentStopIndex + 1) / _stops.length;
  String get progressText => '${_currentStopIndex + 1} of ${_stops.length}';

  /// Initialize a virtual tour
  void startTour({
    required String tourName,
    required List<VirtualTourStop> stops,
    required LatLng startingGate,
  }) {
    print('\n🎬 === STARTING VIRTUAL TOUR ===');
    print('Tour: $tourName');
    print('Stops: ${stops.length}');
    print('Starting Gate: $startingGate');

    _tourName = tourName;
    _stops = stops;
    _startingGate = startingGate;
    _currentStopIndex = 0;
    _isActive = true;
    _isAnimatingToStop = false;
    _isShowingStopCard = false;

    print('✅ Tour initialized');
    notifyListeners();
  }

  /// Start animating to current stop
  void beginAnimationToStop() {
    print('🎬 Beginning animation to stop ${_currentStopIndex + 1}');
    _isAnimatingToStop = true;
    _isShowingStopCard = false;
    notifyListeners();
  }

  /// Animation completed, show the stop card
  void completeAnimationToStop() {
    print('✅ Animation complete, showing stop card');
    _isAnimatingToStop = false;
    _isShowingStopCard = true;
    notifyListeners();
  }

  /// Go to next stop
  void nextStop() {
    if (_currentStopIndex < _stops.length - 1) {
      print(
        '▶️ Moving to next stop: ${_currentStopIndex + 1} → ${_currentStopIndex + 2}',
      );
      _currentStopIndex++;
      _isShowingStopCard = false;
      notifyListeners();
    }
  }

  /// Go to previous stop
  void previousStop() {
    if (_currentStopIndex > 0) {
      print(
        '◀️ Moving to previous stop: ${_currentStopIndex + 1} → $_currentStopIndex',
      );
      _currentStopIndex--;
      _isShowingStopCard = false;
      notifyListeners();
    }
  }

  /// End the tour
  void endTour() {
    print('🏁 Virtual tour ended');
    _isActive = false;
    _currentStopIndex = 0;
    _stops = [];
    _tourName = '';
    _startingGate = null;
    _isAnimatingToStop = false;
    _isShowingStopCard = false;
    notifyListeners();
  }

  @override
  void dispose() {
    print('🗑️ VirtualTourManager disposed');
    super.dispose();
  }
}
