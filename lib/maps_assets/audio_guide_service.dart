import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioGuideService {
  static final AudioGuideService _instance = AudioGuideService._internal();
  factory AudioGuideService() => _instance;
  AudioGuideService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isEnabled = false;
  bool _isSpeaking = false;

  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
      debugPrint('✅ Audio Guide initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Audio Guide: $e');
    }
  }

  void enable() {
    _isEnabled = true;
  }

  void disable() {
    _isEnabled = false;
    stop();
  }

  bool toggle() {
    _isEnabled = !_isEnabled;
    if (!_isEnabled) {
      stop();
    }
    return _isEnabled;
  }

  Future<void> speak(String text) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      await _tts.stop();
      await _tts.speak(text);
      debugPrint('🔊 Speaking: $text');
    } catch (e) {
      debugPrint('❌ Speech error: $e');
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('❌ Stop error: $e');
    }
  }

  // Tour announcements
  Future<void> announceTourStart(String tourName) async {
    await speak("Starting $tourName. Please follow the directions.");
  }

  Future<void> announceFirstStop(String buildingName) async {
    await speak("Your first stop is $buildingName");
  }

  Future<void> announceNavigatingTo(String buildingName) async {
    await speak("Navigating to $buildingName");
  }

  Future<void> announceNextStop(String buildingName) async {
    await speak("Next stop, $buildingName");
  }

  Future<void> announceLastStop(String buildingName) async {
    await speak("Navigating to your final stop, $buildingName");
  }

  Future<void> announceArrived(String buildingName) async {
    await speak("You have arrived at $buildingName");
  }

  //  Announce building description
  Future<void> announceDescription(String description) async {
    if (!_isEnabled || !_isInitialized) return;

    // Small pause before reading description
    await Future.delayed(const Duration(milliseconds: 3000));
    await speak(description);
  }

  //  Combined announcement
  Future<void> announceArrivalWithDescription(
    String buildingName,
    String? description,
  ) async {
    await announceArrived(buildingName);

    if (description != null && description.isNotEmpty) {
      await announceDescription(description);
    }
  }

  Future<void> dispose() async {
    await _tts.stop();
    _isInitialized = false;
    _isEnabled = false;
  }
}

/// Floating Audio Guide Button
class AudioGuideButton extends StatelessWidget {
  final bool isEnabled;
  final bool isSpeaking;
  final VoidCallback onToggle;

  const AudioGuideButton({
    super.key,
    required this.isEnabled,
    required this.isSpeaking,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'audio_guide_btn',
      onPressed: onToggle,
      backgroundColor: isEnabled ? Colors.orange : Colors.white,
      elevation: 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            isEnabled ? Icons.volume_up : Icons.volume_off,
            color: isEnabled ? Colors.white : Colors.grey[600],
            size: 24,
          ),
          // Speaking indicator
          if (isSpeaking && isEnabled)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Extended Audio Guide Toggle with Label
class AudioGuideToggle extends StatelessWidget {
  final bool isEnabled;
  final bool isSpeaking;
  final VoidCallback onToggle;

  const AudioGuideToggle({
    super.key,
    required this.isEnabled,
    required this.isSpeaking,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.orange[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? Colors.orange : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.volume_up : Icons.volume_off,
              color: isEnabled ? Colors.orange : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Audio Guide',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isEnabled ? Colors.orange[900] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Switch(
              value: isEnabled,
              onChanged: (_) => onToggle(),
              activeColor: Colors.orange,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            // Speaking indicator
            if (isSpeaking)
              Container(
                margin: EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    _buildSpeakingBar(0),
                    SizedBox(width: 2),
                    _buildSpeakingBar(1),
                    SizedBox(width: 2),
                    _buildSpeakingBar(2),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakingBar(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 3,
          height: 12 * value,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
