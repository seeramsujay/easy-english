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
          seedColor: const Color(0xFF58CC02), // Duolingo green
          primary: const Color(0xFF58CC02),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WelcomeOnboardingScreen(),
    );
  }
}

/// Duolingo-inspired clean Welcome & Location selector
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Duolingo style friendly Mascot / Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF58CC02).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🦉', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Welcome to EasyEnglish!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4B4B4B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Speak real English with real learners over pure audio.\nWhere are you practicing from today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF777777),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Country Picker Section Header
              const Text(
                'CHOOSE YOUR REGION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFAFAFAF),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Region list showing active online learners
              Expanded(
                child: ListView.separated(
                  itemCount: _countries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _countries[index];
                    final isSelected = _selectedCountry == item['name'];

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _selectedCountry = item['name'] as String;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF58CC02) : const Color(0xFFE5E5E5),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(item['flag'] as String, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        (item['name'] as String).split(' ')[0],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B4B4B),
                                        ),
                                      ),
                                      if (item['recommended'] == true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF58CC02),
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
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF58CC02),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${item['onlineCount']} learners online right now',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF777777),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? const Color(0xFF58CC02) : const Color(0xFFCCCCCC),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Duolingo-style 3D Chunky Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: const Color(0xFF46A302),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(selectedRegion: _selectedCountry),
                    ),
                  );
                },
                child: const Text(
                  'CONTINUE TO PRACTICE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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

    // Online learners count based on region
    final onlineCount = selectedRegion.contains('India') ? '1,420' : '650';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🦉', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            const Text(
              'EasyEnglish',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF4B4B4B),
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // Region pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF58CC02),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  selectedRegion,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B4B4B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Subscription & Customer Center',
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF4B4B4B)),
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
              // Duolingo-style Streak & Online HUD Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHudItem('🔥', '3 DAYS', 'Speaking Streak'),
                    Container(height: 36, width: 1, color: const Color(0xFFE5E5E5)),
                    _buildHudItem('🟢', '$onlineCount ONLINE', 'Learners in $selectedRegion'),
                    Container(height: 36, width: 1, color: const Color(0xFFE5E5E5)),
                    _buildHudItem(isPro ? '👑' : '⭐', isPro ? 'PRO' : 'FREE', 'Account Status'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Membership Banner Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPro ? const Color(0xFFFFF9E6) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPro ? const Color(0xFFFFC107) : const Color(0xFFE5E5E5),
                    width: isPro ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isPro ? const Color(0xFFFFC107) : const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                      child: Icon(isPro ? Icons.star : Icons.headset),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPro ? 'EasyEnglish Pro Active' : 'Free Audio Learner',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4B4B4B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPro
                                ? 'Unlimited Gemini 2.5 Flash Lite Coach & Grammar'
                                : '100% Free P2P Pure Audio matchmaking included',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isPro)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58CC02),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

              const SizedBox(height: 24),

              const Text(
                'CHOOSE PRACTICE MODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFAFAFAF),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Feature 1: Pure Audio 1-on-1 P2P Practice
              _buildDuolingoModeCard(
                context,
                emoji: '🎧',
                title: 'Live 1-on-1 Audio Room',
                subtitle: 'Match with active learners in $selectedRegion for pure audio conversations. Zero camera pressure.',
                badge: '100% FREE',
                badgeBg: const Color(0xFFE8F5E9),
                badgeTextColor: const Color(0xFF2E7D32),
                borderColor: const Color(0xFF58CC02),
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
              _buildDuolingoModeCard(
                context,
                emoji: '🤖',
                title: 'Gemini 2.5 AI Coach',
                subtitle: 'Practice with our AI speaking tutor using Google Live Captions with instant grammar corrections.',
                badge: 'PRO UNLOCKED',
                badgeBg: const Color(0xFFFFF3E0),
                badgeTextColor: const Color(0xFFE65100),
                borderColor: const Color(0xFFFF9800),
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

              // Bottom utility navigation buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaywallScreen()),
                        );
                      },
                      icon: const Icon(Icons.credit_card_outlined, color: Color(0xFF4B4B4B)),
                      label: const Text('Plans & Pricing', style: TextStyle(color: Color(0xFF4B4B4B))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      onPressed: () {
                        RevenueCatService.presentCustomerCenter();
                      },
                      icon: const Icon(Icons.manage_accounts_outlined, color: Color(0xFF4B4B4B)),
                      label: const Text('My Account', style: TextStyle(color: Color(0xFF4B4B4B))),
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

  Widget _buildHudItem(String emoji, String title, String subtitle) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4B4B4B),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Color(0xFF777777)),
        ),
      ],
    );
  }

  Widget _buildDuolingoModeCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeBg,
    required Color badgeTextColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4B4B4B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF777777),
                      height: 1.35,
                    ),
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
