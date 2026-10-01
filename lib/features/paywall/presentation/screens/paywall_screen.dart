import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/subscription_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _selectedPackage;

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    final isPro = ref.watch(isProUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyEnglish Pro'),
        actions: [
          TextButton(
            onPressed: subscriptionState.isLoading
                ? null
                : () async {
                    final restored = await ref
                        .read(subscriptionControllerProvider.notifier)
                        .restore();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored
                              ? 'Purchases successfully restored! 🎉'
                              : 'No previous active subscription found.'),
                        ),
                      );
                    }
                  },
            child: const Text('Restore'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pro Badge & Header
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        isPro ? 'PRO ACTIVE' : 'UNLOCK FLUENCY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Speak English with Confidence',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Get unlimited AI conversational coaching, live grammar tips, and solo speaking practice.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Feature Highlights List
              _buildFeatureItem(
                Icons.smart_toy_outlined,
                'Gemini AI Speaking Partner',
                'Practice speaking English 24/7 with zero stage fright.',
              ),
              _buildFeatureItem(
                Icons.spellcheck,
                'Real-Time Grammar Suggestions',
                'Instant, non-intrusive feedback during speaking sessions.',
              ),
              _buildFeatureItem(
                Icons.speed,
                'Priority Peer Matchmaking',
                'Skip waiting queues and connect with active learners instantly.',
              ),
              _buildFeatureItem(
                Icons.block,
                '100% Ad-Free Experience',
                'Zero interruptions during your language learning journey.',
              ),
              const SizedBox(height: 24),

              // Offerings Loader
              offeringsAsync.when(
                data: (offerings) {
                  final packages = offerings?.current?.availablePackages ?? [];
                  if (packages.isEmpty) {
                    return _buildEmptyPackagesView(context);
                  }

                  // Default select yearly or first package
                  _selectedPackage ??= packages.firstWhere(
                    (p) => p.packageType == PackageType.annual,
                    orElse: () => packages.first,
                  );

                  return Column(
                    children: packages.map((package) {
                      final isSelected = _selectedPackage == package;
                      final isYearly = package.packageType == PackageType.annual;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPackage = package;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          package.storeProduct.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (isYearly) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade700,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'SAVE 48%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      package.storeProduct.description,
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                package.storeProduct.priceString,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Unable to load subscription plans: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action: Purchase Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: (subscriptionState.isLoading || _selectedPackage == null)
                    ? null
                    : () async {
                        final success = await ref
                            .read(subscriptionControllerProvider.notifier)
                            .purchase(_selectedPackage!);
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Welcome to EasyEnglish Pro!'),
                              ),
                            );
                            Navigator.of(context).pop();
                          } else if (subscriptionState.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(subscriptionState.errorMessage!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: subscriptionState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Continue to EasyEnglish Pro',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 12),

              // Open Customer Center button
              if (isPro) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(subscriptionControllerProvider.notifier).showCustomerCenter();
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Manage Subscription (Customer Center)'),
                ),
                const SizedBox(height: 12),
              ],

              // Terms & Privacy Policy
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Terms of Service', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Privacy Policy', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPackagesView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 36),
          const SizedBox(height: 8),
          const Text(
            'No offerings loaded from RevenueCat dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure you have created your "yearly" and "monthly" packages in the RevenueCat dashboard under your current Offering.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(subscriptionControllerProvider.notifier).showPaywall();
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Try Remote Native Paywall'),
          ),
        ],
      ),
    );
  }
}
