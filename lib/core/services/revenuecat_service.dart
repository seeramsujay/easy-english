import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../constants/app_constants.dart';

/// Comprehensive service wrapping the modern RevenueCat Flutter SDK (v10+).
/// Handles initialization, offerings, purchases, entitlement checking,
/// dynamic Paywalls, and Customer Center for `easy_english_pro`.
class RevenueCatService {
  static bool _isInitialized = false;
  static final StreamController<CustomerInfo> _customerInfoStreamController =
      StreamController<CustomerInfo>.broadcast();

  /// Returns true if RevenueCat has been initialized.
  static bool get isInitialized => _isInitialized;

  /// Platforms natively supporting in-app billing via RevenueCat SDK.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// 1. Initialize the RevenueCat SDK with the provided API Key.
  static Future<void> initialize({String? apiKey}) async {
    if (!isSupportedPlatform) {
      debugPrint('[RevenueCat] Running on unsupported platform (e.g. Linux desktop). Billing stubbed.');
      _isInitialized = true;
      return;
    }

    try {
      // Set log level to debug for testing/dev environments
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      final key = apiKey ?? AppConstants.revenueCatApiKey;
      final configuration = PurchasesConfiguration(key);

      // Configure SDK
      await Purchases.configure(configuration);

      // Listen for customer info updates (e.g. renewals, expirations)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        if (!_customerInfoStreamController.isClosed) {
          _customerInfoStreamController.add(customerInfo);
        }
      });

      _isInitialized = true;
      debugPrint('[RevenueCat] Successfully configured SDK with key.');
    } on PlatformException catch (e) {
      debugPrint('[RevenueCat] Configuration PlatformException: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('[RevenueCat] Initialization error: $e');
    }
  }

  /// 2. Stream real-time CustomerInfo changes (e.g., renewed, canceled, purchased).
  static Stream<CustomerInfo> get customerInfoStream {
    return _customerInfoStreamController.stream;
  }

  /// 3. Retrieve current CustomerInfo snapshot.
  static Future<CustomerInfo?> getCustomerInfo() async {
    if (!isSupportedPlatform) return null;
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      debugPrint('[RevenueCat] Error getting CustomerInfo: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unexpected error getting CustomerInfo: $e');
      return null;
    }
  }

  /// 4. Check active entitlement for `easy_english_pro`.
  static Future<bool> isProUser() async {
    if (!isSupportedPlatform) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return checkProEntitlement(customerInfo);
    } catch (e) {
      debugPrint('[RevenueCat] Error checking Pro status: $e');
      return false;
    }
  }

  /// Helper to check if a CustomerInfo object contains an active `easy_english_pro` entitlement.
  static bool checkProEntitlement(CustomerInfo? customerInfo) {
    if (customerInfo == null) return false;
    final entitlement = customerInfo.entitlements.active[AppConstants.proEntitlementId];
    return entitlement != null && entitlement.isActive;
  }

  /// 5. Fetch Offerings configured in RevenueCat Dashboard (Yearly, Monthly).
  static Future<Offerings?> getOfferings() async {
    if (!isSupportedPlatform) return null;
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        debugPrint('[RevenueCat] Current offering: ${offerings.current?.identifier}');
        debugPrint('[RevenueCat] Available packages: ${offerings.current?.availablePackages.map((p) => p.identifier).toList()}');
      }
      return offerings;
    } on PlatformException catch (e) {
      debugPrint('[RevenueCat] Error fetching offerings: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unexpected error fetching offerings: $e');
      return null;
    }
  }

  /// 6. Purchase a selected package with error handling using modern PurchaseParams.
  static Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!isSupportedPlatform) {
      debugPrint('[RevenueCat] Purchases not supported on this platform.');
      return null;
    }

    try {
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = purchaseResult.customerInfo;
      final isPro = checkProEntitlement(customerInfo);
      debugPrint('[RevenueCat] Purchase completed. Pro active: $isPro');
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RevenueCat] User cancelled the purchase.');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        debugPrint('[RevenueCat] User not allowed to make purchases.');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        debugPrint('[RevenueCat] Payment is pending approval.');
      } else {
        debugPrint('[RevenueCat] Purchase failed: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unexpected purchase error: $e');
      return null;
    }
  }

  /// 7. Restore previously purchased subscriptions.
  static Future<CustomerInfo?> restorePurchases() async {
    if (!isSupportedPlatform) return null;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPro = checkProEntitlement(customerInfo);
      debugPrint('[RevenueCat] Purchases restored. Pro active: $isPro');
      return customerInfo;
    } on PlatformException catch (e) {
      debugPrint('[RevenueCat] Restore failed: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unexpected restore error: $e');
      return null;
    }
  }

  /// 8. Present RevenueCat Native Paywall if user lacks `easy_english_pro`.
  static Future<PaywallResult> presentPaywallIfNeeded() async {
    if (!isSupportedPlatform) {
      return PaywallResult.notPresented;
    }
    try {
      return await RevenueCatUI.presentPaywallIfNeeded(
        AppConstants.proEntitlementId,
        displayCloseButton: true,
      );
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting Paywall: $e');
      return PaywallResult.error;
    }
  }

  /// Present Paywall explicitly (e.g., from an "Upgrade to Pro" button).
  static Future<PaywallResult> presentPaywall() async {
    if (!isSupportedPlatform) {
      return PaywallResult.error;
    }
    try {
      return await RevenueCatUI.presentPaywall(
        displayCloseButton: true,
      );
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting Paywall: $e');
      return PaywallResult.error;
    }
  }

  /// 9. Present RevenueCat Customer Center (subscription management, cancellation flow, etc.).
  static Future<void> presentCustomerCenter() async {
    if (!isSupportedPlatform) {
      debugPrint('[RevenueCatUI] Customer Center not supported on this platform.');
      return;
    }
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting Customer Center: $e');
    }
  }

  /// Retrieve App User ID (used for backend serverless verification on Vercel).
  static Future<String> getAppUserId() async {
    if (!isSupportedPlatform) return 'desktop_test_user';
    try {
      return await Purchases.appUserID;
    } catch (e) {
      debugPrint('[RevenueCat] Error getting appUserID: $e');
      return 'anonymous_user';
    }
  }
}
