import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'audio_guide_service.dart';

class VirtualTourStop {
  final int stopNumber;
  final int buildingId;
  final String buildingName;
  final String buildingNickname;
  final String? buildingDescription;
  LatLng? location;
  bool isMarker;
  LatLng? entranceLocation;

  VirtualTourStop({
    required this.stopNumber,
    required this.buildingId,
    required this.buildingName,
    required this.buildingNickname,
    this.buildingDescription,
    this.location,
    this.isMarker = false,
    this.entranceLocation,
  });

  // Extract first sentence for audio announcement
  String? get firstSentence {
    if (buildingDescription == null || buildingDescription!.isEmpty) {
      return null;
    }

    final description = buildingDescription!.trim();

    // Find first period
    final firstDotIndex = description.indexOf('.');

    if (firstDotIndex == -1) {
      // No period found, return entire description if short enough
      return description.length <= 200 ? description : null;
    }

    // Return text up to and including the first period
    return description.substring(0, firstDotIndex + 1).trim();
  }

  void setLocation(LatLng newLocation, {bool isMarkerType = false}) {
    location = newLocation;
    isMarker = isMarkerType;
  }

  void setEntranceLocation(LatLng entrance) {
    entranceLocation = entrance;
  }

  LatLng get navigationTarget => entranceLocation ?? location!;

  void updateLocation(LatLng newLocation) {
    location = newLocation;
  }

  String get displayName =>
      buildingNickname.isNotEmpty ? buildingNickname : buildingName;
}

class VirtualTourManager extends ChangeNotifier {
  // Audio guide
  final AudioGuideService _audioGuide = AudioGuideService();

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
  int? get currentBuildingId => currentStop?.buildingId;
  bool get isAudioGuideEnabled => _audioGuide.isEnabled;
  bool get isAudioGuideSpeaking => _audioGuide.isSpeaking;

  double get progress =>
      _stops.isEmpty ? 0 : (_currentStopIndex + 1) / _stops.length;
  String get progressText => '${_currentStopIndex + 1} of ${_stops.length}';

  /// Initialize audio guide
  Future<void> initializeAudioGuide() async {
    await _audioGuide.initialize();
  }

  /// Toggle audio guide
  bool toggleAudioGuide() {
    final enabled = _audioGuide.toggle();
    notifyListeners();
    return enabled;
  }

  /// Enable audio guide
  void enableAudioGuide() {
    _audioGuide.enable();
    notifyListeners();
  }

  /// Disable audio guide
  void disableAudioGuide() {
    _audioGuide.disable();
    notifyListeners();
  }

  /// Start a virtual tour
  Future<void> startTour({
    required String tourName,
    required List<VirtualTourStop> stops,
    required LatLng startingGate,
    int startAtIndex = 0,
  }) async {
    _tourName = tourName;
    _stops = stops;
    _startingGate = startingGate;
    _currentStopIndex = startAtIndex.clamp(0, stops.length - 1);
    _isActive = true;
    _isAnimatingToStop = false;
    _isShowingStopCard = false;

    // ✅ REMOVED: Tour name announcement - just start silently

    notifyListeners();
  }

  /// Start animating to current stop
  Future<void> beginAnimationToStop() async {
    _isAnimatingToStop = true;
    _isShowingStopCard = false;

    // Announce navigation
    if (currentStop != null) {
      if (isFirstStop) {
        // ✅ FIXED: Only announce the stop name during navigation, not the description
        await _audioGuide.announceFirstStop(currentStop!.displayName);
        // ❌ REMOVED: Don't announce description here - wait until arrival
      } else if (isLastStop) {
        await _audioGuide.announceLastStop(currentStop!.displayName);
      } else {
        await _audioGuide.announceNavigatingTo(currentStop!.displayName);
      }
    }

    notifyListeners();
  }

  /// Animation completed, show the stop card
  void completeAnimationToStop() {
    _isAnimatingToStop = false;
    _isShowingStopCard = true;
    notifyListeners();

    // ✅ FIXED: Now announce arrival with description (works for all stops including first)
    if (currentStop != null) {
      _audioGuide.announceArrivalWithDescription(
        currentStop!.displayName,
        currentStop!.firstSentence,
      );
    }
  }

  /// Go to next stop
  Future<void> nextStop() async {
    if (_currentStopIndex < _stops.length - 1) {
      _currentStopIndex++;
      _isShowingStopCard = false;

      // Announce next stop
      if (currentStop != null) {
        await _audioGuide.announceNextStop(currentStop!.displayName);
      }

      notifyListeners();
    }
  }

  /// Go to previous stop
  Future<void> previousStop() async {
    if (_currentStopIndex > 0) {
      _currentStopIndex--;
      _isShowingStopCard = false;

      // Announce previous stop navigation
      if (currentStop != null) {
        await _audioGuide.announceNavigatingTo(currentStop!.displayName);
      }

      notifyListeners();
    }
  }

  /// End the tour
  Future<void> endTour() async {
    _isActive = false;
    _currentStopIndex = 0;
    _stops = [];
    _tourName = '';
    _startingGate = null;
    _isAnimatingToStop = false;
    _isShowingStopCard = false;

    // Stop any ongoing audio
    await _audioGuide.stop();

    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _audioGuide.dispose();
    super.dispose();
  }
}
