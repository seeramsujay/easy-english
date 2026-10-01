# 💳 RevenueCat Integration Guide (Shipaton 2026)

## 1. Hackathon Objective & Role of RevenueCat

The core challenge of the **RevenueCat Shipaton 2026** is to:
1. Ship a brand-new app to the App Store, Google Play Store, or Samsung Galaxy Store between August 1st and September 30th, 2026.
2. Integrate the **RevenueCat SDK** to power at least one in-app purchase (IAP) or serve ads through RevenueCat Ads.

In **EasyEnglish**, RevenueCat is the operational engine that bridges our zero-server P2P architecture with a sustainable business model:
- **Free Core Tier:** Unmetered 1-on-1 human P2P conversational practice.
- **EasyEnglish Pro Tier (RevenueCat):** Unlocks 24/7 Gemini AI Companion Mode, real-time in-call grammar suggestions, post-call fluency analytics, and priority matchmaking.
- **Serverless Verification:** The client's RevenueCat App User ID is sent to our Vercel Edge Proxy to verify subscriber status before allowing queries to our Google Gemini API key.

---

## 2. Dependencies & Setup

In `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  purchases_flutter: ^8.1.0       # Core RevenueCat Flutter SDK
  purchases_ui_flutter: ^8.1.0    # RevenueCat Native Paywalls UI
  flutter_riverpod: ^2.5.1        # State management & reactive entitlement listening
  http: ^1.2.1                    # Calling the Vercel Gemini AI Proxy
```

### Store Identifier Configuration:
Create RevenueCat apps for each target store:
- **Apple App Store:** `appl_xxxxxxxxxxxxxxxxxxxx`
- **Google Play Store:** `goog_xxxxxxxxxxxxxxxxxxxx`
- **Samsung Galaxy Store:** `goog_xxxxxxxxxxxxxxxxxxxx` (or Samsung credentials configured in RevenueCat dashboard)

---

## 3. Product & Entitlement Architecture

### Entitlement:
- **Identifier:** `pro`
- **Description:** Unlocks on-device AI coaching, live grammar HUD, solo practice, and priority matching.

### Offerings & Packages:
| Package ID | Type | Price (USD) | Trial Period | Strategic Value |
| :--- | :--- | :--- | :--- | :--- |
| `$rc_monthly` | Auto-Renewing Subscription | $7.99 / month | 7 Days Free Trial | Low friction entry point for new learners |
| `$rc_annual` | Auto-Renewing Subscription | $49.99 / year | 7 Days Free Trial | Best value (48% discount), primary hero package |
| `$rc_lifetime` | Non-Consumable IAP | $99.99 one-time | N/A | High-ticket option for committed language learners |

---

## 4. Implementation Blueprint

### 4.1 Service Layer (`revenuecat_service.dart`)

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _appleApiKey = 'appl_your_apple_api_key';
  static const _googleApiKey = 'goog_your_google_api_key';

  static Future<void> init() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

    late PurchasesConfiguration configuration;
    if (Platform.isIOS || Platform.isMacOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    } else if (Platform.isAndroid) {
      // Supports Google Play and Samsung Galaxy Store
      configuration = PurchasesConfiguration(_googleApiKey);
    } else {
      return;
    }

    // Configured with automatic entitlement caching in secure storage
    await Purchases.configure(configuration);
  }

  /// Get current App User ID to send to Vercel Gemini AI Proxy
  static Future<String> getAppUserId() async {
    return await Purchases.appUserID;
  }

  /// Stream of customer info updates (subscription state changes)
  static Stream<CustomerInfo> get customerInfoStream {
    return Purchases.customerInfoStream;
  }

  /// Check if user has active Pro entitlement
  static Future<bool> isPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (e) {
      debugPrint('Error fetching CustomerInfo: $e');
      return false;
    }
  }

  /// Fetch current offerings
  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  static Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (e) {
      debugPrint('Purchase failed or canceled: $e');
      return false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
}
```

---

### 4.2 Server-Side Entitlement Verification on Vercel

When a user calls our Vercel Gemini AI endpoint (`api/coach.js`), the function validates the subscriber directly via RevenueCat's v1 REST API:

```javascript
// Server-side check inside Vercel Function
async function verifyRevenueCatPro(appUserId) {
  const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`, {
    headers: {
      'Authorization': `Bearer ${process.env.REVENUECAT_SECRET_KEY}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) return false;
  const data = await response.json();
  const pro = data.subscriber?.entitlements?.pro;
  if (!pro) return false;

  // Verify expiration date
  if (pro.expires_date) {
    return new Date(pro.expires_date).getTime() > Date.now();
  }
  return true; // Lifetime purchase
}
```

This ensures that:
1. Nobody can steal your Gemini API key from the app binary.
2. Only paying subscribers who generate revenue for you can query the AI model.
3. Upstash Redis caps their queries (e.g. 50/day), ensuring your Gemini usage stays comfortably inside Google's free tier.

---

### 4.3 Riverpod Entitlement State Management

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';

/// Stream provider listening to real-time subscription status changes
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  return RevenueCatService.customerInfoStream;
});

/// Boolean provider indicating whether the user has active Pro access
final isProUserProvider = Provider<bool>((ref) {
  final customerInfoAsync = ref.watch(customerInfoProvider);
  return customerInfoAsync.maybeWhen(
    data: (info) => info.entitlements.active.containsKey('pro'),
    orElse: () => false,
  );
});
```

---

### 4.4 Paywall UI Presentation

Using `purchases_ui_flutter`, paywalls can be configured and updated dynamically from the RevenueCat dashboard without submitting app store updates:

```dart
import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallHelper {
  /// Opens the RevenueCat native paywall if user lacks the 'pro' entitlement
  static Future<void> showPaywallIfNeeded(BuildContext context) async {
    final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
      'pro',
      displayCloseButton: true,
    );
    
    switch (paywallResult) {
      case PaywallResult.purchased:
      case PaywallResult.restored:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to EasyEnglish Pro! 🎉')),
        );
        break;
      case PaywallResult.notPresented:
        // User already has entitlement
        break;
      case PaywallResult.cancelled:
      case PaywallResult.error:
        break;
    }
  }
}
```

---

## 5. Offline Entitlement Resilience

- **How RevenueCat Handles Offline:** The RevenueCat SDK automatically caches `CustomerInfo` to local hardware keystore / secure storage whenever it is fetched.
- **Offline Startup:** When the app launches without network access, `Purchases.getCustomerInfo()` immediately returns the cached entitlement snapshot with its cryptographic expiration date.
- **Verification:** The app inspects the cached entitlement to enable offline UI states while showing friendly messages when network access is required for live Gemini AI queries.

---

## 6. Store Submission Checklist (Shipaton 2026)

- [ ] **Apple App Store:**
  - Clear terms: subscription length, trial period, recurring charge details in paywall.
  - Functional "Restore Purchases" button prominently displayed.
  - Link to Terms of Use (EULA) and Privacy Policy.
- [ ] **Google Play Store:**
  - Active subscription IDs configured in Google Play Console.
  - Service Account JSON uploaded to RevenueCat dashboard.
  - RTDN (Real-Time Developer Notifications) Pub/Sub topic linked to RevenueCat webhook.
- [ ] **Samsung Galaxy Store:**
  - Samsung IAP SDK / RevenueCat Samsung integration configured.
  - Release APK/AAB certified for Galaxy Store device matrix.
