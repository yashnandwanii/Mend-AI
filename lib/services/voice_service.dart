// File: lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';

class VoiceService {
  late SpeechToText _speechToText;
  late FlutterTts _flutterTts;

  bool _speechEnabled = false;
  bool _isListening = false;
  String _currentSpeaker = '';
  Timer? _mockTimer;

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<bool> _listeningController =
      StreamController<bool>.broadcast();
  final StreamController<String> _speakerController =
      StreamController<String>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<String> get speakerStream => _speakerController.stream;

  bool get isListening => _isListening;
  String get currentSpeaker => _currentSpeaker;

  Future<void> initialize() async {
    _speechToText = SpeechToText();
    _flutterTts = FlutterTts();

    print('🎤 Initializing VoiceService...');

    // Check current microphone permission status
    final currentStatus = await Permission.microphone.status;
    print('🔐 Current microphone permission status: $currentStatus');

    PermissionStatus permissionStatus;

    if (currentStatus == PermissionStatus.granted) {
      print('✅ Microphone permission already granted');
      permissionStatus = currentStatus;
    } else if (currentStatus == PermissionStatus.permanentlyDenied) {
      print('❌ Microphone permission permanently denied');
      print(
        '🔧 Microphone permission permanently denied. You can open app settings to enable the permission.',
      );
      // Try to open app settings programmatically.
      final opened = await openAppSettingsFromCode();
      if (!opened) {
        print(
          '❌ Failed to open app settings programmatically. Please open Settings manually.',
        );
      }
      _speechEnabled = false;
      return;
    } else {
      print('🔐 Requesting microphone permission...');
      permissionStatus = await Permission.microphone.request();
    }

    if (permissionStatus != PermissionStatus.granted) {
      print('❌ Microphone permission denied - Status: $permissionStatus');
      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        print('🔧 Permission permanently denied. Please:');
        print('   1. Go to iOS Settings > Privacy & Security > Microphone');
        print('   2. Enable microphone access for Mend AI');
        print('   3. Or reset simulator: xcrun simctl erase all');
        // Try to open app settings as a last resort
        final opened = await openAppSettingsFromCode();
        if (!opened) {
          print('❌ Could not open App Settings. Please open them manually.');
        }
      } else {
        print('🔧 Please enable microphone access when prompted');
      }
      _speechEnabled = false;
      return;
    }

    print('✅ Microphone permission granted successfully');

    // Request speech recognition permission (iOS specific)
    final speechPermission = await Permission.speech.request();
    if (speechPermission != PermissionStatus.granted) {
      print(
        '❌ Speech recognition permission denied - Status: $speechPermission',
      );
    } else {
      print('✅ Speech recognition permission granted');
    }

    // Initialize speech-to-text
    print('🔄 Initializing speech recognition engine...');
    _speechEnabled = await _speechToText.initialize(
      onError: (errorNotification) {
        print('❌ Speech recognition error: ${errorNotification.errorMsg}');
        print('🔧 Permanent error: ${errorNotification.permanent}');
        _speechEnabled = false;
      },
      onStatus: (status) {
        print('🔄 Speech recognition status: $status');
      },
    );

    if (_speechEnabled) {
      print('✅ VoiceService initialized with REAL speech recognition');
      final locales = await _speechToText.locales();
      print('� Available locales: ${locales.length}');
      for (var locale in locales.take(3)) {
        print('  📍 ${locale.localeId}: ${locale.name}');
      }
    } else {
      print('❌ Speech recognition initialization failed - using mock mode');
      print('🔧 Check device microphone and permissions');
    }

    // Initialize TTS
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    print('🔊 Text-to-Speech initialized');
  }

  /// Attempts to open the system app settings so the user can enable permissions.
  /// Returns true if the settings screen was opened, false otherwise.
  Future<bool> openAppSettingsFromCode() async {
    try {
      final opened = await openAppSettings();
      print('🔑 openAppSettings result: $opened');
      return opened;
    } catch (e) {
      print('❌ Error opening app settings: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    required String speaker,
  }) async {
    if (!_speechEnabled || _isListening) return;

    _currentSpeaker = speaker;
    _isListening = true;

    print('🎤 Starting REAL speech recognition for $speaker');
    print('📊 Audio input stream: ACTIVE');
    print(
      '🔍 Voice recognition mode: ${speaker.contains('A') ? 'MALE_VOICE' : 'FEMALE_VOICE'}',
    );

    if (_speechEnabled && _speechToText.isAvailable) {
      // Use REAL speech recognition
      print('🎙️ Starting REAL speech recognition engine...');
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            String transcript = result.recognizedWords;
            print('');
            print('════════════════════════════════════════');
            print('🗣️ [$speaker] SPEECH-TO-TEXT RESULT:');
            print('📝 Text: "$transcript"');
            print(
              '� Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
            );
            print('🔄 Is Final: ${result.finalResult}');
            print('⏱️ Timestamp: ${DateTime.now().toString().split(' ')[1]}');
            print('════════════════════════════════════════');
            print('');

            onResult(transcript);
            _transcriptController.add('$speaker: $transcript');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          // Show sound level every few seconds to avoid spam
          if (level > 0.5) {
            print(
              '🔊 Audio Level: ${level.toStringAsFixed(1)}dB - Speaking detected',
            );
          }
        },
      );
    } else {
      // Fallback to enhanced mock mode
      print('⚠️ Using enhanced mock mode - speech recognition not available');
      print(
        '🔧 Reason: Speech recognition ${_speechEnabled ? 'available but not ready' : 'disabled'}',
      );
      _startMockListening(onResult, speaker);
    }

    // Simulate audio input feedback
    _listeningController.add(true);
    _speakerController.add(speaker);
    print('✅ Audio capture initialized for $speaker');
  }

  void _startMockListening(Function(String) onResult, String speaker) {
    // Enhanced mock transcript simulation with more realistic timing
    _mockTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (!_isListening) {
        print('⏹️ Audio input stream: STOPPED');
        timer.cancel();
        return;
      }

      // Generate more realistic mock transcripts
      List<String> mockPhrases = [
        'I understand your perspective on this',
        'Could you help me understand better',
        'That makes sense from your point of view',
        'I appreciate you sharing that with me',
        'Let me think about what you\'re saying',
        'I feel like we\'re making progress here',
        'This conversation is really helpful',
        'I want to work through this together',
      ];

      String mockTranscript = mockPhrases[Random().nextInt(mockPhrases.length)];

      // Enhanced debug logging for mock mode
      print('');
      print('════════════════════════════════════════');
      print('🤖 [$speaker] MOCK SPEECH-TO-TEXT:');
      print('📝 Text: "$mockTranscript"');
      print('� Confidence: ${85 + Random().nextInt(15)}%');
      print('🔄 Is Final: true');
      print('⏱️ Timestamp: ${DateTime.now().toString().split(' ')[1]}');
      print('🎚️ Audio Level: ${60 + Random().nextInt(40)}dB');
      print('════════════════════════════════════════');
      print('');

      onResult(mockTranscript);
      _transcriptController.add('$speaker: $mockTranscript');
    });
  }

  Future<void> stopListening() async {
    print('🛑 Stopping speech recognition for $_currentSpeaker');
    print('📊 Audio input stream: DEACTIVATED');

    _isListening = false;

    // Stop real speech recognition
    if (_speechEnabled && _speechToText.isListening) {
      await _speechToText.stop();
      print('✅ Real speech recognition stopped');
    }

    // Stop mock timer
    _mockTimer?.cancel();
    _mockTimer = null;

    _currentSpeaker = '';
    _listeningController.add(false);
    _speakerController.add('');

    print('✅ Audio capture terminated - ready for next speaker');
  }

  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  Future<void> speakInterruptionWarning() async {
    await speak("Please let your partner finish speaking before responding.");
  }

  Future<void> speakGuidedQuestion(String question) async {
    await speak("Here's a question to consider: $question");
  }

  void dispose() {
    _mockTimer?.cancel();
    _transcriptController.close();
    _listeningController.close();
    _speakerController.close();
    if (_speechEnabled) {
      _speechToText.cancel();
    }
    _flutterTts.stop();
  }

  // Mock voice activity detection
  bool detectVoiceActivity() {
    // TODO: Implement actual voice activity detection
    // This would analyze audio input to detect when someone is speaking
    return _isListening;
  }

  // Mock speaker identification
  String identifySpeaker(String audioData) {
    // TODO: Implement speaker identification
    // This would use voice characteristics to identify which partner is speaking
    return _currentSpeaker;
  }
}
