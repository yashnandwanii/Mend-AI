// File: lib/screens/voice_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import '../providers/voice_provider.dart';
import '../providers/relationship_provider.dart';
import '../providers/auth_provider.dart';
import '../services/ai_service.dart';
import '../models/session_model.dart';
import '../config/app_theme.dart';

class VoiceChatScreen extends ConsumerStatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveformController;
  late AnimationController _pulseController;
  late AnimationController _maleGlowController;
  late AnimationController _femaleGlowController;
  late Animation<double> _waveformAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _maleGlowAnimation;
  late Animation<double> _femaleGlowAnimation;

  Timer? _sessionTimer;
  int _sessionDuration = 0;
  String _currentAISuggestion = '';
  SessionModel? _currentSession;
  bool _isPaused = false;

  final List<String> _sessionTranscript = [];
  String _partnerAId = '';
  String _partnerBId = '';
  String _activeSpeaker = '';
  bool _canPartnerASpeak = true;
  bool _canPartnerBSpeak = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSession();
  }

  void _initializeAnimations() {
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _maleGlowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _femaleGlowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _waveformAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveformController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
    _maleGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _maleGlowController, curve: Curves.easeInOut),
    );
    _femaleGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _femaleGlowController, curve: Curves.easeInOut),
    );

    _waveformController.repeat(reverse: true);
  }

  void _startSession() async {
    final currentUser = ref.read(currentUserProvider).value;
    final relationshipState = ref.read(relationshipNotifierProvider);

    if (currentUser == null) return;

    relationshipState.whenData((relationship) async {
      if (relationship != null) {
        _partnerAId = relationship.partnerAId;
        _partnerBId = relationship.partnerBId;

        final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
        await sessionNotifier.startSession(relationship.id);

        final session = ref.read(sessionNotifierProvider).value;
        if (session != null) {
          setState(() {
            _currentSession = session;
          });
          _startSessionTimer();
          _generateInitialAISuggestion();
        }
      }
    });
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _sessionDuration++;
        });
      }
    });
  }

  void _generateInitialAISuggestion() async {
    final suggestion = await AIService.generateGuidedQuestion(
      _sessionTranscript,
      'session_start',
    );
    setState(() {
      _currentAISuggestion = suggestion;
    });

    // Speak the suggestion
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    await voiceNotifier.speakGuidedQuestion(suggestion);
  }

  void _startListening(String partnerId) async {
    // Prevent speaking if session is paused
    if (_isPaused) {
      _showMessage('Session is paused. Resume to continue.');
      return;
    }

    // Check if the other partner is currently speaking
    final voiceState = ref.read(voiceNotifierProvider);
    if (voiceState.isListening && voiceState.currentSpeaker != partnerId) {
      _handleInterruption();
      return;
    }

    // Prevent concurrent speaking - mutual exclusion
    if (partnerId == _partnerAId && !_canPartnerASpeak) return;
    if (partnerId == _partnerBId && !_canPartnerBSpeak) return;

    // Set speaking permissions
    setState(() {
      _activeSpeaker = partnerId;
      if (partnerId == _partnerAId) {
        _canPartnerBSpeak = false; // Disable partner B
        _maleGlowController.repeat(reverse: true);
      } else {
        _canPartnerASpeak = false; // Disable partner A
        _femaleGlowController.repeat(reverse: true);
      }
    });

    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    await voiceNotifier.startListening(partnerId);

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Debug print for audio input
    print('🎤 Started listening for $partnerId');
    print(
      '🔊 Audio input enabled for: ${partnerId == _partnerAId ? "Male Partner" : "Female Partner"}',
    );
  }

  void _stopListening() async {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    await voiceNotifier.stopListening();

    // Reset speaking permissions
    setState(() {
      _activeSpeaker = '';
      _canPartnerASpeak = true;
      _canPartnerBSpeak = true;
    });

    // Stop all animations
    _pulseController.stop();
    _pulseController.reset();
    _maleGlowController.stop();
    _maleGlowController.reset();
    _femaleGlowController.stop();
    _femaleGlowController.reset();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    print('🛑 Stopped listening - both partners can now speak');
  }

  void _pauseSession() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _stopListening();
      _sessionTimer?.cancel();
      _showMessage('Session paused');
      print('⏸️ Session paused');
    } else {
      _startSessionTimer();
      _showMessage('Session resumed');
      print('▶️ Session resumed');
    }

    HapticFeedback.mediumImpact();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _handleInterruption() async {
    // Flash haptic feedback
    HapticFeedback.heavyImpact();

    _showMessage('Please let your partner finish speaking');

    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    await voiceNotifier.speakInterruptionWarning();

    print('❌ Interruption detected - blocking concurrent speech');
  }

  void _endSession() async {
    if (_currentSession == null) return;

    _sessionTimer?.cancel();
    _stopListening();

    // Calculate communication scores
    final voiceState = ref.read(voiceNotifierProvider);
    final partnerAScores = AIService.calculateCommunicationScores(
      voiceState.transcript,
      {}, // Mock emotions
      _sessionDuration ~/ 2, // Mock speaking time
      _sessionDuration ~/ 2, // Mock listening time
    );

    final partnerBScores = AIService.calculateCommunicationScores(
      voiceState.transcript,
      {}, // Mock emotions
      _sessionDuration ~/ 2, // Mock speaking time
      _sessionDuration ~/ 2, // Mock listening time
    );

    // Generate session summary
    final summary = await AIService.generateSessionSummary(
      voiceState.transcript,
      partnerAScores,
      partnerBScores,
      _sessionDuration,
    );

    // Update session
    final updatedSession = _currentSession!.copyWith(
      endTime: DateTime.now(),
      duration: _sessionDuration,
      partnerAScores: partnerAScores,
      partnerBScores: partnerBScores,
      transcript: voiceState.transcript,
      summary: summary,
    );

    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
    await sessionNotifier.updateSession(updatedSession);

    // Navigate to post-resolution
    if (mounted) {
      context.go('/post-resolution?sessionId=${_currentSession!.id}');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _waveformController.dispose();
    _pulseController.dispose();
    _maleGlowController.dispose();
    _femaleGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.pureBlack, // Black background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Column(
          children: [
            Text(
              'Communication Session',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDuration(_sessionDuration),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.lightGray),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Pause/Resume button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isPaused
                  ? AppTheme.accentColor
                  : AppTheme.lightGray.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _pauseSession,
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              tooltip: _isPaused ? 'Resume Session' : 'Pause Session',
            ),
          ),
          // End session button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _endSession,
              icon: const Icon(Icons.stop, color: Colors.red),
              tooltip: 'End Session',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppTheme.pureBlack,
              AppTheme.richBlack,
              AppTheme.deepCharcoal,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // AI Suggestion Card
                if (_currentAISuggestion.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.psychology,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'AI Guidance',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentAISuggestion,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.lightGray,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Voice Controls
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Waveform visualization
                      if (voiceState.isListening) ...[
                        Container(
                          height: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: AnimatedBuilder(
                            animation: _waveformAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: WaveformPainter(
                                  _waveformAnimation.value,
                                  _activeSpeaker == _partnerAId
                                      ? const Color(
                                          0xFF00FF88,
                                        ) // Green for male
                                      : const Color(
                                          0xFFFF1493,
                                        ), // Pink for female
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 120,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Partner buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPartnerButton(
                            partnerId: _partnerAId,
                            partnerName: 'Partner A',
                            isActive: voiceState.currentSpeaker == _partnerAId,
                            isMale: true,
                            canSpeak: _canPartnerASpeak,
                            onPressed: () => _startListening(_partnerAId),
                          ),
                          _buildPartnerButton(
                            partnerId: _partnerBId,
                            partnerName: 'Partner B',
                            isActive: voiceState.currentSpeaker == _partnerBId,
                            isMale: false,
                            canSpeak: _canPartnerBSpeak,
                            onPressed: () => _startListening(_partnerBId),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Stop listening button
                      if (voiceState.isListening) ...[
                        GestureDetector(
                          onTap: _stopListening,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to stop speaking',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.lightGray),
                        ),
                      ],

                      // Session status
                      if (_isPaused) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pause_circle_outline,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Session Paused',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Transcript preview
                if (voiceState.transcript.isNotEmpty) ...[
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.lightGray.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live Conversation',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: voiceState.transcript.length,
                            itemBuilder: (context, index) {
                              final transcript =
                                  voiceState.transcript[voiceState
                                          .transcript
                                          .length -
                                      1 -
                                      index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  transcript,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.lightGray,
                                        height: 1.4,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerButton({
    required String partnerId,
    required String partnerName,
    required bool isActive,
    required bool isMale,
    required bool canSpeak,
    required VoidCallback onPressed,
  }) {
    final glowColor = isMale
        ? const Color(0xFF00FF88)
        : const Color(0xFFFF1493);
    final isListening =
        isActive && ref.watch(voiceNotifierProvider).isListening;

    return GestureDetector(
      onTap: canSpeak ? onPressed : null,
      child: AnimatedBuilder(
        animation: isActive
            ? (isMale ? _maleGlowAnimation : _femaleGlowAnimation)
            : kAlwaysCompleteAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: isListening
                  ? glowColor.withOpacity(0.1)
                  : AppTheme.charcoal.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: isListening
                    ? glowColor
                    : (canSpeak
                          ? AppTheme.lightGray.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1)),
                width: isListening ? 3 : 2,
              ),
              boxShadow: [
                if (isListening) ...[
                  BoxShadow(
                    color: glowColor.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: glowColor.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ] else ...[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isListening
                        ? glowColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: isListening
                        ? glowColor
                        : (canSpeak ? Colors.white : Colors.grey.shade500),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  partnerName,
                  style: TextStyle(
                    color: isListening
                        ? glowColor
                        : (canSpeak ? Colors.white : Colors.grey.shade500),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMale ? 'Male' : 'Female',
                  style: TextStyle(
                    color: isListening
                        ? glowColor.withOpacity(0.8)
                        : AppTheme.lightGray.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;

  WaveformPainter(this.animationValue, this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final path = Path();

    for (int i = 0; i < size.width.toInt(); i += 5) {
      final x = i.toDouble();
      final amplitude =
          sin((i / 10) + (animationValue * 2 * pi)) *
          (20 + Random().nextDouble() * 30);
      final y = centerY + amplitude;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
