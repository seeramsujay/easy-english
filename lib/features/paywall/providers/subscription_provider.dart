import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../../core/services/revenuecat_service.dart';

/// Stream provider for real-time RevenueCat customer subscription state.
final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  return RevenueCatService.customerInfoStream;
});

/// Direct boolean provider to check if the user has an active `easy_english_pro` subscription.
final isProUserProvider = Provider<bool>((ref) {
  final customerInfoAsync = ref.watch(customerInfoStreamProvider);
  return customerInfoAsync.maybeWhen(
    data: (info) => RevenueCatService.checkProEntitlement(info),
    orElse: () => false,
  );
});

/// Future provider to fetch the latest offerings (Yearly & Monthly packages) configured in RevenueCat.
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return await RevenueCatService.getOfferings();
});

/// State representation for in-flight purchase/restore operations.
class SubscriptionState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const SubscriptionState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Controller managing purchases, restores, Paywall presentation, and Customer Center.
class SubscriptionController extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    return const SubscriptionState();
  }

  /// Purchases a subscription package (e.g., Yearly or Monthly).
  Future<bool> purchase(Package package) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final customerInfo = await RevenueCatService.purchasePackage(package);
      final isPro = RevenueCatService.checkProEntitlement(customerInfo);
      if (isPro) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Purchase was not completed or was cancelled.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Restores previous purchases for returning users.
  Future<bool> restore() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final customerInfo = await RevenueCatService.restorePurchases();
      final isPro = RevenueCatService.checkProEntitlement(customerInfo);
      if (isPro) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No active EasyEnglish Pro subscription found to restore.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Launches the RevenueCat dynamic Paywall UI.
  Future<PaywallResult> showPaywall() async {
    return await RevenueCatService.presentPaywall();
  }

  /// Launches the RevenueCat dynamic Paywall UI only if the user lacks `easy_english_pro`.
  Future<PaywallResult> showPaywallIfNeeded() async {
    return await RevenueCatService.presentPaywallIfNeeded();
  }

  /// Opens the RevenueCat Customer Center for managing subscriptions.
  Future<void> showCustomerCenter() async {
    await RevenueCatService.presentCustomerCenter();
  }
}

/// Provider for SubscriptionController using Riverpod 3 NotifierProvider.
final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(() {
  return SubscriptionController();
});
