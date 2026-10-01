import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'core/services/revenuecat_service.dart';
import 'features/ai_coach/presentation/screens/ai_coach_screen.dart';
import 'features/call/presentation/screens/call_screen.dart';
import 'features/paywall/presentation/screens/paywall_screen.dart';
import 'features/paywall/providers/subscription_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981), // Emerald Teal
          primary: const Color(0xFF059669),
          secondary: const Color(0xFF0284C7),
          surface: const Color(0xFFF8FAFC),
          surfaceContainerLowest: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF34D399),
          secondary: const Color(0xFF38BDF8),
          surface: const Color(0xFF0F172A),
          surfaceContainerLowest: const Color(0xFF1E293B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Color(0xFF1E293B), width: 1.5),
          ),
          color: Color(0xFF131C2E),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Color(0xFF0F172A),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const WelcomeOnboardingScreen(),
    );
  }
}

/// Material 3 Duolingo-styled Onboarding & Location Selector
class WelcomeOnboardingScreen extends StatefulWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  State<WelcomeOnboardingScreen> createState() => _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  String _selectedCountry = 'India 🇮🇳';

  final List<Map<String, dynamic>> _countries = [
    {'name': 'India 🇮🇳', 'onlineCount': 1420, 'flag': '🇮🇳', 'recommended': true},
    {'name': 'Japan 🇯🇵', 'onlineCount': 620, 'flag': '🇯🇵', 'recommended': false},
    {'name': 'Brazil 🇧🇷', 'onlineCount': 890, 'flag': '🇧🇷', 'recommended': false},
    {'name': 'Spain 🇪🇸', 'onlineCount': 410, 'flag': '🇪🇸', 'recommended': false},
    {'name': 'Germany 🇩🇪', 'onlineCount': 350, 'flag': '🇩🇪', 'recommended': false},
    {'name': 'South Korea 🇰🇷', 'onlineCount': 530, 'flag': '🇰🇷', 'recommended': false},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // App Brand Header Icon
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.secondary.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/images/app_logo.jpg',
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          '🎙️',
                          style: TextStyle(fontSize: 40, color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Welcome to EasyEnglish!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Practice spoken English with peer learners worldwide over pure, low-latency audio.\nWhere are you dialing in from?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 28),

              // Region Header
              Text(
                'SELECT REGIONAL ROOM',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),

              // Region Cards List
              Expanded(
                child: ListView.separated(
                  itemCount: _countries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _countries[index];
                    final isSelected = _selectedCountry == item['name'];

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedCountry = item['name'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                              : colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(alpha: 0.6),
                            width: isSelected ? 2.2 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(item['flag'] as String, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        (item['name'] as String).split(' ')[0],
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (item['recommended'] == true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'POPULAR',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${item['onlineCount']} learners online right now',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Material 3 Filled Action Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(selectedRegion: _selectedCountry),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'CONTINUE TO PRACTICE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  final String selectedRegion;

  const HomeScreen({
    super.key,
    this.selectedRegion = 'India 🇮🇳',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final onlineCount = selectedRegion.contains('India') ? '1,420' : '650';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.record_voice_over_rounded, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'EasyEnglish',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          // Active Region Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  selectedRegion,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Subscription & Customer Center',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              RevenueCatService.presentCustomerCenter();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Material 3 Speaking HUD Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHudItem(context, '🔥', '3 DAYS', 'Speaking Streak'),
                    Container(height: 38, width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    _buildHudItem(context, '🟢', '$onlineCount ONLINE', 'In $selectedRegion'),
                    Container(height: 38, width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    _buildHudItem(context, isPro ? '👑' : '⭐', isPro ? 'PRO' : 'FREE', 'Account Tier'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Membership Banner Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isPro
                      ? LinearGradient(
                          colors: [
                            const Color(0xFFFEF3C7),
                            const Color(0xFFFDE68A).withValues(alpha: 0.4),
                          ],
                        )
                      : null,
                  color: isPro ? null : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isPro ? const Color(0xFFF59E0B) : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: isPro ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isPro ? const Color(0xFFF59E0B) : colorScheme.primaryContainer,
                      foregroundColor: isPro ? Colors.white : colorScheme.primary,
                      child: Icon(isPro ? Icons.star_rounded : Icons.headset_mic_rounded, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPro ? 'EasyEnglish Pro Active' : 'Free Audio Learner',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPro
                                ? 'Unlimited Gemini 2.5 Flash Lite Coach & Live Captions'
                                : '100% Free P2P Pure Audio matchmaking included',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isPro)
                      FilledButton.tonal(
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          );
                        },
                        child: const Text('UPGRADE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Text(
                'PRACTICE MODES',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              // Feature 1: Pure Audio 1-on-1 P2P Room
              _buildPracticeCard(
                context,
                icon: Icons.graphic_eq_rounded,
                iconColor: colorScheme.primary,
                title: 'Live 1-on-1 Audio Room',
                subtitle: 'Match with active learners in $selectedRegion for low-latency conversations. Pure audio, zero video.',
                badge: '100% FREE',
                badgeColor: colorScheme.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CallScreen(
                        peerName: 'Rahul from Delhi',
                        peerLocation: selectedRegion,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Feature 2: Gemini 2.5 Flash Lite Speaking Coach
              _buildPracticeCard(
                context,
                icon: Icons.psychology_rounded,
                iconColor: colorScheme.secondary,
                title: 'Gemini 2.5 AI Coach',
                subtitle: 'Practice with our AI tutor using Google Live Captions with real-time grammar feedback cards.',
                badge: 'PRO UNLOCKED',
                badgeColor: const Color(0xFFF59E0B),
                onTap: () async {
                  if (isPro) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiCoachScreen()),
                    );
                  } else {
                    final result = await RevenueCatService.presentPaywallIfNeeded();
                    if (result == PaywallResult.notPresented && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 28),

              // Bottom Account Navigation Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaywallScreen()),
                        );
                      },
                      icon: const Icon(Icons.credit_card_outlined),
                      label: const Text('Plans & Pricing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        RevenueCatService.presentCustomerCenter();
                      },
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: const Text('My Account'),
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

  Widget _buildHudItem(BuildContext context, String emoji, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
