// File: lib/screens/post_resolution_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';
import '../services/firebase_database_service.dart';
import '../models/reflection_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_button.dart';

class PostResolutionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const PostResolutionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<PostResolutionScreen> createState() =>
      _PostResolutionScreenState();
}

class _PostResolutionScreenState extends ConsumerState<PostResolutionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late PageController _pageController;

  int _currentPage = 0;
  final _partnerAppreciationController = TextEditingController();
  final _personalImprovementController = TextEditingController();
  final _gratitudeController = TextEditingController();
  int _moodRating = 5;

  List<String> _bondingActivities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pageController = PageController();

    _celebrationController.forward();
    _loadBondingActivities();
  }

  void _loadBondingActivities() {
    setState(() {
      _bondingActivities = AIService.generateBondingActivities();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pageController.dispose();
    _partnerAppreciationController.dispose();
    _personalImprovementController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeReflection();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeReflection() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reflection = ReflectionModel(
        id: const Uuid().v4(),
        sessionId: widget.sessionId,
        userId: currentUser.uid,
        partnerAppreciation: _partnerAppreciationController.text,
        personalImprovement: _personalImprovementController.text,
        gratitudeMessage: _gratitudeController.text,
        moodRating: _moodRating,
        createdAt: DateTime.now(),
      );

      final databaseService = FirebaseDatabaseService();
      await databaseService.saveReflection(reflection);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving reflection: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return true; // Celebration page
      case 1:
        return _partnerAppreciationController.text.isNotEmpty;
      case 2:
        return _personalImprovementController.text.isNotEmpty;
      case 3:
        return _gratitudeController.text.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
        title: const Text('Session Complete'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          if (_currentPage > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: LinearProgressIndicator(
                value: _currentPage / 3,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildCelebrationPage(),
                _buildAppreciationPage(),
                _buildImprovementPage(),
                _buildGratitudePage(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const CircularProgressIndicator()
                : AnimatedButton(
                    onPressed: _canProceed() ? _nextPage : null,
                    backgroundColor: _canProceed()
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    child: Text(
                      _currentPage < 3 ? 'Continue' : 'Complete',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Celebration animation
          SizedBox(
            height: 200,
            child: Lottie.asset(
              'assets/animations/celebration.json',
              controller: _celebrationController,
              onLoaded: (composition) {
                _celebrationController.duration = composition.duration;
                _celebrationController.forward();
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration,
                    size: 80,
                    color: Colors.green.shade600,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Congratulations!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'You\'ve completed a meaningful conversation session. This is a step forward in your relationship journey.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Quick stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Session Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Duration', '12 min', Icons.timer),
                    _buildStatItem('Exchanges', '8', Icons.chat),
                    _buildStatItem('Progress', '+5%', Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bonding activities
          if (_bondingActivities.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.purple.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Suggested Activities',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ..._bondingActivities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.purple.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activity,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppreciationPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appreciate Your Partner',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'What\'s one thing your partner did today that you appreciated?',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _partnerAppreciationController,
            decoration: const InputDecoration(
              labelText: 'I appreciated when you...',
              hintText: 'Share something specific your partner did well',
              prefixIcon: Icon(Icons.favorite),
            ),
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Be specific about actions, words, or gestures that made you feel good.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Growth',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'What\'s one thing you can do better next time?',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _personalImprovementController,
            decoration: const InputDecoration(
              labelText: 'Next time, I will...',
              hintText: 'Reflect on how you can improve',
              prefixIcon: Icon(Icons.self_improvement),
            ),
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          Text(
            'How are you feeling right now?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Mood slider
          Column(
            children: [
              Slider(
                value: _moodRating.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _getMoodLabel(_moodRating),
                onChanged: (value) {
                  setState(() {
                    _moodRating = value.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('😞', style: Theme.of(context).textTheme.headlineSmall),
                  Text('😐', style: Theme.of(context).textTheme.headlineSmall),
                  Text('😊', style: Theme.of(context).textTheme.headlineSmall),
                  Text('😄', style: Theme.of(context).textTheme.headlineSmall),
                  Text('🥰', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGratitudePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Express Gratitude',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Write a message of gratitude to your partner',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _gratitudeController,
            decoration: const InputDecoration(
              labelText: 'Dear Partner...',
              hintText: 'Express your gratitude and love',
              prefixIcon: Icon(Icons.auto_awesome),
            ),
            maxLines: 6,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Why Gratitude Matters',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expressing gratitude strengthens your emotional bond and creates positive relationship patterns.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blue.shade600),
        ),
      ],
    );
  }

  String _getMoodLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Frustrated';
      case 2:
        return 'Okay';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Amazing';
      default:
        return 'Good';
    }
  }
}
