# 🌍 EasyEnglish

> **Serverless, End-to-End Encrypted Peer-to-Peer Language Learning with Zero-Cost Gemini AI Coaching**  
> *Built with Flutter & Powered by RevenueCat for the Shipaton 2026 Hackathon.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![WebRTC](https://img.shields.io/badge/WebRTC-P2P_E2EE-333333?logo=webrtc&logoColor=white)](https://webrtc.org/)
[![RevenueCat](https://img.shields.io/badge/RevenueCat-In--App_Purchases-E84E36?logo=revenuecat&logoColor=white)](https://www.revenuecat.com/)
[![Google Gemini](https://img.shields.io/badge/Google_Gemini-1.5_Flash-8E75B2?logo=google&logoColor=white)](https://ai.google.dev/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Samsung-green.svg)](#)

---

## 🏆 RevenueCat Shipaton 2026 Submission

EasyEnglish is engineered specifically for the **RevenueCat Shipaton 2026**:
- **Target Launch:** August 1 – September 30, 2026.
- **Supported Stores:** Google Play Store, Apple App Store, and Samsung Galaxy Store.
- **Monetization Engine:** **RevenueCat SDK (`purchases_flutter`)** powering our **EasyEnglish Pro** subscriptions.
- **"They Pay, You Keep It 100% Free" Architecture:**
  - P2P calls have **$0 media server costs**.
  - Pro AI Coaching is powered by your **Google Gemini API key safely hosted on a free Vercel Edge Function**.
  - The Vercel function verifies the user's active RevenueCat subscription via the RevenueCat REST API before querying Gemini.
  - A strict daily quota (50 queries/day) in Upstash Redis free tier ensures you **never exceed Google's or Vercel's free tiers**.

---

## ✨ Key Features

- **🌐 Serverless P2P Audio & Video Calls:** Direct WebRTC media streaming between language partners worldwide with zero cloud relay bottlenecks.
- **🔐 End-to-End Encryption (E2EE):** Ephemeral ECDH (X25519) key agreement with AES-256-GCM data encryption and frame-level WebRTC Insertable Streams (SFrame). No intermediary can eavesdrop.
- **🛡️ On-Device Safety Shield:** Dual-tier client-side moderation (regex/homoglyph/leetspeak filtering + on-device toxicity evaluation) ensures safe conversations without cloud privacy leaks.
- **🤖 Intelligent Gemini AI Speaking Coach (Pro):** Fast, friendly conversational practice and instant grammar corrections powered by Gemini 1.5 Flash via our secure Vercel Edge Proxy.
- **💳 Seamless In-App Monetization:** Native paywalls and subscription management via RevenueCat, offering monthly, annual, and lifetime fluency passes with full offline entitlement caching.
- **⚡ Battery & Low-Spec Optimized:** Engineered to run smoothly on budget smartphones and developable on modest laptops (clean architecture, mock test drivers, zero emulator bloat).

---

## 🏛️ System Architecture

```
                                  ┌──────────────────────────────┐
                                  │   Ephemeral Edge Signaling   │
                                  │ (Cloudflare Worker / Vercel) │
                                  └──────────────┬───────────────┘
                                                 │
                                 Stateless SDP/ICE Exchange (<100ms)
                                                 │
                   ┌─────────────────────────────┴─────────────────────────────┐
                   ▼                                                           ▼
       ┌───────────────────────┐                                   ┌───────────────────────┐
       │     Local Peer A      │                                   │     Remote Peer B     │
       │                       │                                   │                       │
       │ ┌───────────────────┐ │                                   │ ┌───────────────────┐ │
       │ │   Local Safety    │ │                                   │ │   Local Safety    │ │
       │ │  Moderation Tier  │ │                                   │ │  Moderation Tier  │ │
       │ └─────────┬─────────┘ │                                   │ └─────────┬─────────┘ │
       │           │           │                                   │           │           │
       │ ┌─────────▼─────────┐ │       E2EE P2P WebRTC Stream      │ ┌─────────▼─────────┐ │
       │ │  E2EE Crypto Core │ │ ◄═══════════════════════════════► │ │  E2EE Crypto Core │ │
       │ │   (ECDH + AES)    │ │   (Encrypted Audio/Video/Data)    │ │   (ECDH + AES)    │ │
       │ └───────────────────┘ │                                   │ └───────────────────┘ │
       │                       │                                   │                       │
       │ ┌───────────────────┐ │                                   │ ┌───────────────────┐ │
       │ │ RevenueCat Gate   │ │                                   │ │ RevenueCat Gate   │ │
       │ │ (purchases_flutter│ │                                   │ │ (purchases_flutter│ │
       │ └─────────┬─────────┘ │                                   │ └───────────────────┘ │
       └───────────┼───────────┘                                   └───────────────────────┘
                   │
                   │ (If Pro: Verified via RevenueCat REST API)
                   ▼
       ┌────────────────────────────────────────────────────────┐
       │         Vercel Serverless AI Proxy (`/api/coach`)      │
       │  1. Verifies RevenueCat `pro` entitlement in real time │
       │  2. Tracks daily query quota (50/day) in Upstash Redis │
       │  3. Queries Google Gemini 1.5 Flash (Free Tier)        │
       │  ► Zero cost to creator | Key never exposed in APK     │
       └────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Domain | Technology / Package | Purpose | Cost to Creator |
| :--- | :--- | :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev) / Dart 3.x | Cross-platform mobile UI | Free |
| **P2P Networking** | [`flutter_webrtc`](https://pub.dev/packages/flutter_webrtc) | Native WebRTC audio/video/data channels | $0.00 |
| **Signaling Engine** | Cloudflare Workers / Upstash Redis | Ephemeral, stateless SDP relay | $0.00 |
| **Monetization** | [`purchases_flutter`](https://pub.dev/packages/purchases_flutter) & `purchases_ui_flutter` | RevenueCat subscriptions, entitlements & paywalls | $0.00 (under $2.5k/mo) |
| **AI Speaking Coach** | Google Gemini 1.5 Flash via Vercel Edge Proxy | Real-time grammar & solo companion dialogue | $0.00 (within free tier) |
| **Cryptography** | [`cryptography`](https://pub.dev/packages/cryptography) / Native FFI | Ephemeral ECDH X25519 & AES-256-GCM | $0.00 |
| **State Management** | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | Predictable, reactive, easily mockable state | Free |
| **Local Storage** | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Encrypted keychain and cached entitlements | Free |

---

## 📂 Project Structure

```
easy-english/
├── Flutter P2P App Architecture.md   # Architectural research report
├── idea.md                           # Hackathon product pitch & zero-cost business model
├── README.md                         # Project overview & developer guide
├── ROADMAP.md                        # Phased Shipaton 2026 execution plan
├── api/
│   └── coach.js                      # Vercel Serverless Gemini Proxy with RevenueCat verification
├── docs/                             # Deep-dive technical specifications
│   ├── ARCHITECTURE.md               # WebRTC signaling, ICE, & E2EE details
│   ├── VERCEL_GEMINI_AI_PROXY.md     # Full guide on Vercel + Gemini + RC verification
│   ├── REVENUECAT_INTEGRATION.md     # RevenueCat offering, entitlements & paywalls
│   ├── SAFETY_AND_MODERATION.md      # Dual-tier on-device moderation engine
│   └── LOW_SPEC_DEV_GUIDE.md         # Fast dev guide for modest hardware (i5 / 8GB RAM)
├── lib/
│   ├── main.dart                     # App entry point & initialization
│   ├── core/
│   │   ├── constants/                # App keys, endpoints, route names
│   │   ├── theme/                    # Light/Dark design system
│   │   └── utils/                    # Logging, platform checks, network status
│   ├── features/
│   │   ├── call/                     # WebRTC P2P video/voice call interface
│   │   ├── chat/                     # E2EE real-time text & practice chat
│   │   ├── matchmaking/              # Ephemeral peer discovery & room pairing
│   │   ├── moderation/               # On-device text & audio safety filters
│   │   ├── ai_coach/                 # Gemini AI Coach client & speech UI
│   │   └── paywall/                  # RevenueCat paywalls, tier gates & customer info
│   └── services/
│       ├── webrtc_service.dart       # WebRTC peer connection manager
│       ├── signaling_service.dart    # Serverless edge signaling client
│       ├── crypto_service.dart       # ECDH & AES-256-GCM encryption
│       ├── ai_coach_service.dart     # HTTP client calling Vercel Gemini Proxy
│       └── revenuecat_service.dart   # RevenueCat SDK wrapper & entitlement stream
└── test/
    ├── unit/                         # Fast unit tests for logic & services
    ├── widget/                       # UI widget tests (headless)
    └── mocks/                        # Mock signaling & mock RevenueCat clients
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK:** 3.19+ ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK:** 3.3+
- **Physical Device (Recommended):** An Android or iOS device connected via USB or Wi-Fi (avoids running heavy emulators on 8GB RAM machines).

### Quick Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/easy-english.git
   cd easy-english
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create an `.env` file (or use `--dart-define`):
   ```env
   REVENUECAT_GOOGLE_API_KEY=goog_xxxxxxx
   REVENUECAT_APPLE_API_KEY=appl_xxxxxxx
   AI_COACH_ENDPOINT=https://your-easyenglish-api.vercel.app/api/coach
   ```

4. **Deploy Vercel AI Proxy:**
   Deploy `api/coach.js` to Vercel with environment variables:
   - `GEMINI_API_KEY` (from [Google AI Studio](https://aistudio.google.com/))
   - `REVENUECAT_SECRET_KEY` (from RevenueCat Dashboard)
   - `UPSTASH_REDIS_REST_URL` & `UPSTASH_REDIS_REST_TOKEN` (from [Upstash](https://upstash.com/))

5. **Run on a Connected Physical Device:**
   ```bash
   flutter run -d <device_id>
   ```

> 💡 **Developing on a resource-constrained laptop?**  
> Check out [docs/LOW_SPEC_DEV_GUIDE.md](docs/LOW_SPEC_DEV_GUIDE.md) for tips on headless testing, disabling heavy Gradle daemons, using mock signaling drivers, and hot-reload shortcuts that keep your system fast and responsive.

---

## 📄 Documentation

- [Product Pitch & Concept (`idea.md`)](idea.md)
- [Comprehensive Implementation Roadmap (`ROADMAP.md`)](ROADMAP.md)
- [Vercel Gemini AI Proxy Guide (`docs/VERCEL_GEMINI_AI_PROXY.md`)](docs/VERCEL_GEMINI_AI_PROXY.md)
- [WebRTC & Signaling Architecture (`docs/ARCHITECTURE.md`)](docs/ARCHITECTURE.md)
- [RevenueCat Integration Guide (`docs/REVENUECAT_INTEGRATION.md`)](docs/REVENUECAT_INTEGRATION.md)
- [On-Device Safety & Moderation (`docs/SAFETY_AND_MODERATION.md`)](docs/SAFETY_AND_MODERATION.md)
- [Low-Spec Development Workflow (`docs/LOW_SPEC_DEV_GUIDE.md`)](docs/LOW_SPEC_DEV_GUIDE.md)

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
