// File: lib/providers/voice_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_service.dart';

// Voice service provider
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  service.initialize();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Voice state notifier
class VoiceNotifier extends StateNotifier<VoiceState> {
  final VoiceService _voiceService;

  VoiceNotifier(this._voiceService) : super(const VoiceState()) {
    _voiceService.transcriptStream.listen((transcript) {
      state = state.copyWith(transcript: [...state.transcript, transcript]);
    });

    _voiceService.listeningStream.listen((isListening) {
      state = state.copyWith(isListening: isListening);
    });

    _voiceService.speakerStream.listen((currentSpeaker) {
      state = state.copyWith(currentSpeaker: currentSpeaker);
    });
  }

  Future<void> startListening(String speakerId) async {
    await _voiceService.startListening(
      onResult: (transcript) {
        state = state.copyWith(transcript: [...state.transcript, transcript]);
      },
      speaker: speakerId,
    );
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  Future<void> speak(String text) async {
    await _voiceService.speak(text);
  }

  Future<void> speakInterruptionWarning() async {
    await _voiceService.speakInterruptionWarning();
  }

  Future<void> speakGuidedQuestion(String question) async {
    await _voiceService.speakGuidedQuestion(question);
  }

  void clearTranscript() {
    state = state.copyWith(transcript: []);
  }

  void addTranscript(String text) {
    state = state.copyWith(transcript: [...state.transcript, text]);
  }
}

final voiceNotifierProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((
  ref,
) {
  final voiceService = ref.watch(voiceServiceProvider);
  return VoiceNotifier(voiceService);
});

// Voice state model
class VoiceState {
  final bool isListening;
  final String currentSpeaker;
  final List<String> transcript;
  final bool isProcessing;

  const VoiceState({
    this.isListening = false,
    this.currentSpeaker = '',
    this.transcript = const [],
    this.isProcessing = false,
  });

  VoiceState copyWith({
    bool? isListening,
    String? currentSpeaker,
    List<String>? transcript,
    bool? isProcessing,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      currentSpeaker: currentSpeaker ?? this.currentSpeaker,
      transcript: transcript ?? this.transcript,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
