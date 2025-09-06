// File: lib/screens/voice_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
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
  late AnimationController _borderAnimationController;
  late AnimationController _scaleAnimationController;

  late Animation<double> _waveformAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _borderAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _sessionTimer;
  int _sessionDuration = 0;
  String _currentAISuggestion = '';
  SessionModel? _currentSession;
  bool _isPaused = false;
  bool _isRecording = false;
  String _currentTranscript = '';

  final List<String> _sessionTranscript = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Delay provider operations to avoid lifecycle issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsOnce();
      _startSession();
    });
  }

  void _initializeAnimations() {
    // Waveform animation for audio visualization
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation for recording state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Border animation for recording state
    _borderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Scale animation for tap feedback
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _waveformAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveformController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _borderAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _waveformController.repeat(reverse: true);
  }

  Future<void> _checkPermissionsOnce() async {
    // Only check permissions if not already granted
    final micPermission = await Permission.microphone.status;

    if (micPermission != PermissionStatus.granted) {
      print('🔐 Microphone permission needed - showing dialog');
      if (micPermission == PermissionStatus.permanentlyDenied) {
        _showSettingsDialog();
      } else {
        _showPermissionDialog();
      }
    } else {
      print('✅ Microphone permission already granted');
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoal,
        title: Row(
          children: [
            Icon(Icons.mic, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Microphone Access', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'This app needs microphone access to capture your voice during communication sessions. Please grant permission to continue.',
          style: TextStyle(color: AppTheme.lightGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.lightGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await Permission.microphone.request();
              print('🔐 Permission request result: $result');

              if (result == PermissionStatus.granted) {
                await Permission.speech.request();
                _showMessage('✅ Microphone access granted!');
              } else {
                _showMessage('❌ Microphone access required for voice features');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.charcoal,
        title: Row(
          children: [
            Icon(Icons.settings, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Text('Permission Required', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Microphone access was permanently denied. Please enable it in device settings to use voice features.',
          style: TextStyle(color: AppTheme.lightGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.lightGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _startSession() async {
    final currentUser = ref.read(currentUserProvider).value;
    final relationshipState = ref.read(relationshipNotifierProvider);

    if (currentUser == null) return;

    relationshipState.whenData((relationship) async {
      if (relationship != null) {
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

  void _toggleRecording() async {
    // Trigger scale animation for tap feedback
    _scaleAnimationController.forward().then((_) {
      _scaleAnimationController.reverse();
    });

    // Add haptic feedback like iOS
    HapticFeedback.mediumImpact();

    if (_isRecording) {
      // Stop recording
      await _stopRecording();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Prevent recording if session is paused
    if (_isPaused) {
      _showMessage('Session is paused. Resume to continue.');
      return;
    }

    print('\n🎤 ===== STARTING RECORDING =====');
    print('🔴 User tapped "Tap to Speak" button');
    print('⏰ Time: ${DateTime.now().toString().split(' ')[1]}');

    setState(() {
      _isRecording = true;
      _currentTranscript = '';
    });

    // Start border animation (continuous loop while recording)
    _borderAnimationController.repeat();

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Get current user for this device
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      print('❌ No current user found');
      return;
    }

    String currentSpeakerId = currentUser.email ?? 'user';
    print('👤 Recording for user: $currentSpeakerId');

    // Start voice service
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    await voiceNotifier.startListening(currentSpeakerId);

    print('✅ Voice service started - listening for audio input');
  }

  Future<void> _stopRecording() async {
    print('\n🛑 ===== STOPPING RECORDING =====');
    print('🔴 User tapped button again to stop recording');
    print('⏰ Time: ${DateTime.now().toString().split(' ')[1]}');

    setState(() {
      _isRecording = false;
    });

    // Stop all animations
    _borderAnimationController.stop();
    _borderAnimationController.reset();
    _pulseController.stop();
    _pulseController.reset();

    // Stop voice service
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    await voiceNotifier.stopListening();

    // Get the transcript
    final voiceState = ref.read(voiceNotifierProvider);
    if (voiceState.transcript.isNotEmpty) {
      String latestTranscript = voiceState.transcript.last;
      print('\n📝 ===== SPEECH-TO-TEXT RESULT =====');
      print('🗣️ Raw Audio Input Converted To Text:');
      print('📄 "$latestTranscript"');
      print('📊 Word Count: ${latestTranscript.split(' ').length}');
      print('🎯 Character Count: ${latestTranscript.length}');
      print('⚡ Processing Complete');
      print('=====================================\n');

      setState(() {
        _currentTranscript = latestTranscript;
      });
    } else {
      print('❌ No speech detected during recording session');
    }

    print('✅ Recording session ended successfully');
  }

  void _pauseSession() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      if (_isRecording) {
        _stopRecording();
      }
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
    if (_isRecording) {
      await _stopRecording();
    }

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

  Widget _buildTranscriptDisplay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _currentTranscript.isNotEmpty || _isRecording ? 100 : 0,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.charcoal.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isRecording
                ? AppTheme.accentColor.withOpacity(0.3)
                : AppTheme.lightGray.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : AppTheme.lightGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_off,
                    color: _isRecording
                        ? AppTheme.accentColor
                        : AppTheme.lightGray,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? 'Live Transcript' : 'Voice Input',
                  style: TextStyle(
                    color: _isRecording
                        ? AppTheme.accentColor
                        : AppTheme.lightGray,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (_isRecording) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _currentTranscript.isNotEmpty
                        ? _currentTranscript
                        : (_isRecording
                              ? 'Listening...'
                              : 'Tap microphone to start speaking'),
                    key: ValueKey(_currentTranscript),
                    style: TextStyle(
                      color: _currentTranscript.isNotEmpty
                          ? Colors.white
                          : AppTheme.lightGray.withOpacity(0.6),
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: _currentTranscript.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    _borderAnimationController.dispose();
    _scaleAnimationController.dispose();
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
                              'AI Therapist',
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
                                  AppTheme.accentColor,
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

                      // Single Microphone for This Device
                      Column(
                        children: [
                          // Device role indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Your Device',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Main microphone button with animation
                          _buildMainMicrophoneButton(voiceState),

                          const SizedBox(height: 16),

                          // Status text
                          Text(
                            voiceState.isListening
                                ? 'Speaking...'
                                : (_isPaused
                                      ? 'Session Paused'
                                      : 'Tap to speak'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: voiceState.isListening
                                      ? AppTheme.accentColor
                                      : AppTheme.lightGray,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),

                      // Session status
                      if (_isPaused) ...[
                        const SizedBox(height: 32),
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

                // Real-time transcript display at bottom
                _buildTranscriptDisplay(),

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

  Widget _buildMainMicrophoneButton(VoiceState voiceState) {
    final currentUser = ref.read(currentUserProvider).value;

    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _borderAnimationController,
          _scaleAnimationController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _isRecording
                    ? AppTheme.accentColor.withOpacity(0.1)
                    : AppTheme.charcoal.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording
                      ? AppTheme.accentColor
                      : AppTheme.lightGray.withOpacity(0.3),
                  width: _isRecording ? 4 : 2,
                ),
                boxShadow: [
                  if (_isRecording) ...[
                    // Animated border glow effect
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(
                        0.4 + (_borderAnimation.value * 0.3),
                      ),
                      blurRadius: 30 + (_borderAnimation.value * 20),
                      spreadRadius: 8 + (_borderAnimation.value * 8),
                      offset: const Offset(0, 0),
                    ),
                    // Pulse effect
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(
                        0.6 + (_pulseAnimation.value * 0.2),
                      ),
                      blurRadius: 15 + (_pulseAnimation.value * 10),
                      spreadRadius: 3 + (_pulseAnimation.value * 5),
                      offset: const Offset(0, 0),
                    ),
                  ] else ...[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Microphone icon with enhanced animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? AppTheme.accentColor.withOpacity(
                              0.2 + (_pulseAnimation.value * 0.1),
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Transform.scale(
                      scale: _isRecording
                          ? (1.0 + (_pulseAnimation.value * 0.1))
                          : 1.0,
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording
                            ? AppTheme.accentColor
                            : Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Dynamic status text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isRecording ? 'Recording...' : 'Tap to Speak',
                      key: ValueKey(_isRecording),
                      style: TextStyle(
                        color: _isRecording
                            ? AppTheme.accentColor
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  if (currentUser != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      currentUser.email?.split('@')[0] ?? 'User',
                      style: TextStyle(
                        color: _isRecording
                            ? AppTheme.accentColor.withOpacity(0.8)
                            : AppTheme.lightGray.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
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
