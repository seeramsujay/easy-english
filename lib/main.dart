import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'core/services/revenuecat_service.dart';
import 'features/ai_coach/presentation/screens/ai_coach_screen.dart';
import 'features/paywall/presentation/screens/paywall_screen.dart';
import 'features/paywall/providers/subscription_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RevenueCat SDK with the provided API Key
  await RevenueCatService.initialize();

  runApp(
    const ProviderScope(
      child: EasyEnglishApp(),
    ),
  );
}

class EasyEnglishApp extends StatelessWidget {
  const EasyEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyEnglish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Vibrant blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyEnglish'),
        actions: [
          IconButton(
            tooltip: 'Subscription & Customer Center',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              RevenueCatService.presentCustomerCenter();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Status Card
              Card(
                elevation: 0,
                color: isPro
                    ? Colors.amber.shade50
                    : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isPro ? Colors.amber.shade700 : Colors.blue.shade200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isPro ? Colors.amber.shade700 : Colors.blue,
                        foregroundColor: Colors.white,
                        child: Icon(isPro ? Icons.star : Icons.person_outline),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPro ? 'EasyEnglish Pro Member' : 'Free Tier Learner',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPro
                                  ? 'Active Entitlement: easy_english_pro'
                                  : 'Unlimited 1-on-1 P2P calls included',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isPro)
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PaywallScreen()),
                            );
                          },
                          child: const Text('Upgrade'),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Practice Action Cards
              const Text(
                'Start Speaking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Free Feature: 1-on-1 Human P2P
              _buildActionCard(
                context,
                icon: Icons.people_alt_outlined,
                title: '1-on-1 Peer Matchmaking',
                subtitle: 'Practice with a random English learner worldwide via direct P2P WebRTC.',
                badgeText: 'FREE',
                badgeColor: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('P2P Matchmaking Room initialized.')),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Pro Feature: Gemini AI Speaking Coach
              _buildActionCard(
                context,
                icon: Icons.smart_toy_outlined,
                title: 'Gemini AI Speaking Coach',
                subtitle: 'Practice speaking with our 24/7 AI tutor and get real-time grammar corrections.',
                badgeText: 'PRO',
                badgeColor: Colors.amber.shade800,
                onTap: () async {
                  if (isPro) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiCoachScreen()),
                    );
                  } else {
                    // Present RevenueCat dynamic Paywall if not pro
                    final result = await RevenueCatService.presentPaywallIfNeeded();
                    if (result == PaywallResult.notPresented && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    }
                  }
                },
              ),

              const Spacer(),

              // Quick Access Buttons for Paywall & Customer Center
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaywallScreen()),
                        );
                      },
                      icon: const Icon(Icons.credit_card_outlined),
                      label: const Text('View Paywall'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        RevenueCatService.presentCustomerCenter();
                      },
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: const Text('Customer Center'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
