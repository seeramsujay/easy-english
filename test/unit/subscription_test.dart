import 'package:flutter_test/flutter_test.dart';
import 'package:easy_english/core/constants/app_constants.dart';
import 'package:easy_english/core/services/revenuecat_service.dart';

void main() {
  group('RevenueCat Integration Tests', () {
    test('AppConstants should have correct API key and entitlement ID', () {
      expect(AppConstants.revenueCatApiKey, 'test_GgvQOwcslbINPAtgGoOOehUJdhe');
      expect(AppConstants.proEntitlementId, 'easy_english_pro');
      expect(AppConstants.productYearly, 'yearly');
      expect(AppConstants.productMonthly, 'monthly');
    });

    test('checkProEntitlement returns false when CustomerInfo is null', () {
      final isPro = RevenueCatService.checkProEntitlement(null);
      expect(isPro, isFalse);
    });

    test('Desktop environment returns false for isProUser by default without crashing', () async {
      final isPro = await RevenueCatService.isProUser();
      expect(isPro, isFalse);
    });

    test('Desktop environment returns stubbed App User ID safely', () async {
      final userId = await RevenueCatService.getAppUserId();
      expect(userId, isNotEmpty);
    });
  });
}
