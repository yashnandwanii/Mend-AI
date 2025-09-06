// File: lib/screens/partner_invite_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/relationship_provider.dart';
import '../widgets/animated_button.dart';

class PartnerInviteScreen extends ConsumerStatefulWidget {
  const PartnerInviteScreen({super.key});

  @override
  ConsumerState<PartnerInviteScreen> createState() =>
      _PartnerInviteScreenState();
}

class _PartnerInviteScreenState extends ConsumerState<PartnerInviteScreen>
    with TickerProviderStateMixin {
  final _inviteCodeController = TextEditingController();
  late AnimationController _inviteCodeAnimationController;
  late Animation<double> _inviteCodeAnimation;
  bool _isJoining = false;
  String? _generatedInviteCode;

  @override
  void initState() {
    super.initState();
    _inviteCodeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _inviteCodeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _inviteCodeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _createInviteCode();
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _inviteCodeAnimationController.dispose();
    super.dispose();
  }

  void _createInviteCode() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final relationshipNotifier = ref.read(
      relationshipNotifierProvider.notifier,
    );
    await relationshipNotifier.createRelationship(currentUser.uid);

    final relationshipState = ref.read(relationshipNotifierProvider);
    relationshipState.whenData((relationship) {
      if (relationship != null) {
        setState(() {
          _generatedInviteCode = relationship.inviteCode;
        });
        _inviteCodeAnimationController.forward();
      }
    });
  }

  void _joinWithCode() async {
    if (_inviteCodeController.text.isEmpty) return;

    setState(() {
      _isJoining = true;
    });

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final relationshipNotifier = ref.read(
      relationshipNotifierProvider.notifier,
    );
    await relationshipNotifier.joinRelationship(
      _inviteCodeController.text.toUpperCase(),
      currentUser.uid,
    );

    final relationshipState = ref.read(relationshipNotifierProvider);

    setState(() {
      _isJoining = false;
    });

    relationshipState.whenData((relationship) {
      if (relationship != null && relationship.isActive) {
        context.go('/home');
      } else {
        _showErrorSnackBar('Invalid invite code or relationship not found');
      }
    });
  }

  void _copyInviteCode() {
    if (_generatedInviteCode != null) {
      Clipboard.setData(ClipboardData(text: _generatedInviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code copied to clipboard!')),
      );
    }
  }

  void _shareInviteCode() {
    if (_generatedInviteCode != null) {
      Share.share(
        'Join me on Mend for better relationship communication! Use invite code: $_generatedInviteCode',
        subject: 'Join me on Mend',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _skipForNow() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Partner'),
        actions: [
          TextButton(
            onPressed: _skipForNow,
            child: Text(
              'Skip',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.people,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connect with Your Partner',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mend works best when both partners are involved. Invite your partner to join your journey.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Create Invite Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'Invite Your Partner',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_generatedInviteCode != null) ...[
                    FadeTransition(
                      opacity: _inviteCodeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_inviteCodeAnimation),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Invite Code',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _generatedInviteCode!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                                color: Colors.blue.shade800,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _copyInviteCode,
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy code',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _copyInviteCode,
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy Code'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _shareInviteCode,
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    const Center(child: Text('Generating your invite code...')),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // OR Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),

            const SizedBox(height: 32),

            // Join with Code Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.login, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'Join Your Partner',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _inviteCodeController,
                    decoration: InputDecoration(
                      labelText: 'Enter invite code',
                      hintText: 'ABC123',
                      prefixIcon: const Icon(Icons.code),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.shade300),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  AnimatedButton(
                    onPressed:
                        _inviteCodeController.text.isNotEmpty && !_isJoining
                        ? _joinWithCode
                        : null,
                    backgroundColor: _inviteCodeController.text.isNotEmpty
                        ? Colors.green.shade600
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    child: _isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Join Partnership',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Skip Section
            Center(
              child: Column(
                children: [
                  Text(
                    'You can always invite your partner later',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _skipForNow,
                    child: const Text('Continue Solo for Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
