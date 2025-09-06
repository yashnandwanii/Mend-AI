// File: lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  Gender _selectedGender = Gender.other;
  final List<String> _selectedGoals = [];
  final List<String> _selectedChallenges = [];
  final _additionalChallengesController = TextEditingController();

  // Predefined options
  final List<String> _relationshipGoals = [
    'Better Communication',
    'Conflict Resolution',
    'Emotional Intimacy',
    'Trust Building',
    'Quality Time',
    'Physical Intimacy',
    'Future Planning',
    'Stress Management',
  ];

  final List<String> _commonChallenges = [
    'We argue too often',
    'We don\'t communicate well',
    'We feel disconnected',
    'Trust issues',
    'Different life goals',
    'Financial stress',
    'Work-life balance',
    'Intimacy concerns',
    'Parenting disagreements',
    'Extended family issues',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _additionalChallengesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
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

  void _completeOnboarding() async {
    final currentUser = ref.read(currentUserProvider).value;

    final challenges = [..._selectedChallenges];
    if (_additionalChallengesController.text.isNotEmpty) {
      challenges.add(_additionalChallengesController.text);
    }

    // If there's no authenticated Firebase user (anonymous sign-in failed),
    // proceed with a temporary local user id so onboarding can continue.
    String userId;
    if (currentUser == null) {
      userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Proceeding in local mode — profile will not be saved to the server.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      userId = currentUser.uid;
    }

    final user = UserModel(
      id: userId,
      name: _nameController.text,
      email: _emailController.text,
      gender: _selectedGender,
      relationshipGoals: _selectedGoals,
      currentChallenges: challenges,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Only attempt to save remotely when we have a Firebase user.
    if (currentUser != null) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.createUserProfile(user);
    }

    if (mounted) {
      context.go('/partner-invite');
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _emailController.text.isNotEmpty;
      case 1:
        return true; // Gender can be optional
      case 2:
        return _selectedGoals.isNotEmpty;
      case 3:
        return _selectedChallenges.isNotEmpty;
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
        title: Text('Setup Profile'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

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
                _buildBasicInfoPage(),
                _buildGenderPage(),
                _buildGoalsPage(),
                _buildChallengesPage(),
              ],
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedButton(
              onPressed: _canProceed() ? _nextPage : null,
              backgroundColor: _canProceed()
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              foregroundColor: Colors.white,
              child: Text(
                _currentPage < 3 ? 'Continue' : 'Complete Setup',
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

  Widget _buildBasicInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s get to know you',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your experience',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you identify?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us provide personalized guidance',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          ...Gender.values.map((gender) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(gender.name.toUpperCase()),
                leading: Radio<Gender>(
                  value: gender,
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedGender == gender
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your relationship goals?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _relationshipGoals.length,
              itemBuilder: (context, index) {
                final goal = _relationshipGoals[index];
                final isSelected = _selectedGoals.contains(goal);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGoals.remove(goal);
                      } else {
                        _selectedGoals.add(goal);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        goal,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What challenges are you facing?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us provide targeted support',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: _commonChallenges.length + 1,
              itemBuilder: (context, index) {
                if (index == _commonChallenges.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _additionalChallengesController,
                      decoration: const InputDecoration(
                        labelText: 'Other challenges (optional)',
                        hintText: 'Describe any other challenges...',
                      ),
                      maxLines: 3,
                    ),
                  );
                }

                final challenge = _commonChallenges[index];
                final isSelected = _selectedChallenges.contains(challenge);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    title: Text(challenge),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedChallenges.add(challenge);
                        } else {
                          _selectedChallenges.remove(challenge);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
