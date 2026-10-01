# 🗺️ EasyEnglish Implementation Roadmap

> **Shipaton 2026 Window:** August 1st – September 30th, 2026  
> **Target Release:** Google Play Store, Apple App Store, Samsung Galaxy Store  
> **Guiding Principle:** *Plan Before You Act.* Build modular, testable, lightweight components with clear interfaces. Maintain high code readability and keep dev environments fast on low-spec hardware.

---

## 🎯 High-Level Timeline & Milestones

```
  Phase 0              Phase 1               Phase 2               Phase 3               Phase 4               Phase 5               Phase 6
┌─────────┐          ┌─────────┐          ┌─────────┐          ┌─────────┐          ┌─────────┐          ┌─────────┐          ┌─────────┐
│ Scaffold│   ══►    │WebRTC & │   ══►    │ E2EE &  │   ══►    │On-Device│   ══►    │Revenue- │   ══►    │ Vercel  │   ══►    │ Polish, │
│ & Setup │          │Signaling│          │ Crypto  │          │ Safety  │          │ Cat IAP │          │Gemini AI│          │ Stores  │
└─────────┘          └─────────┘          └─────────┘          └─────────┘          └─────────┘          └─────────┘          └─────────┘
  Week 1               Week 2-3             Week 4               Week 5               Week 6-7             Week 8-9             Week 10
```

---

## 📋 Granular Task Breakdown

### 🔹 Phase 0: Project Setup, Tooling & Low-Spec Environment Configuration
> **Goal:** Set up a clean, modular Flutter project architecture with mock services, lint rules, and memory-efficient build profiles.

- [ ] **Task 0.1: Flutter Project Initialization**
  - Scaffold Flutter project using `flutter create --org com.easyenglish easy_english`.
  - Configure `analysis_options.yaml` with strict linting (`flutter_lints` + clean code rules).
  - Set up feature-first directory layout (`lib/core/`, `lib/features/`, `lib/services/`).
- [ ] **Task 0.2: Dependency Configuration & Version Pinning**
  - WebRTC & Networking: `flutter_webrtc`, `web_socket_channel`, `http`.
  - Monetization: `purchases_flutter`, `purchases_ui_flutter`.
  - State & Persistence: `flutter_riverpod`, `flutter_secure_storage`, `hive_flutter`.
  - Crypto & Utilities: `cryptography`, `intl`.
- [ ] **Task 0.3: Low-Spec Machine Optimization**
  - Configure `.gradle/gradle.properties` with memory limits (`-Xmx1536m -XX:MaxMetaspaceSize=512m`).
  - Set up mock signaling & mock WebRTC service layers for fast headless unit testing.
  - Enable physical device debugging instructions (saving ~2.5 GB RAM vs Android Studio emulators).

---

### 🔹 Phase 1: Serverless Signaling & Core WebRTC Pairing
> **Goal:** Enable two Flutter devices to discover each other, negotiate an SDP handshake via an edge serverless function, and establish a direct P2P audio/video/data connection.

- [ ] **Task 1.1: Stateless Edge Signaling Deployment**
  - Write Cloudflare Worker script (`signaling.js`) supporting ephemeral WebSocket / HTTP pairing.
  - Integrate Upstash Redis KV for pairing room lookup and short-lived ID expiration (<60s).
  - Deploy worker and verify low-latency round-trip time (<50ms).
- [ ] **Task 1.2: Client Signaling Service (`signaling_service.dart`)**
  - Implement connection state machine: `Disconnected` ➔ `Connecting` ➔ `WaitingForPeer` ➔ `Paired` ➔ `TornDown`.
  - Implement SDP Offer, Answer, and ICE candidate JSON serialization/deserialization.
  - Provide an offline `MockSignalingService` for instant unit/widget test runs.
- [ ] **Task 1.3: WebRTC Peer Connection Core (`webrtc_service.dart`)**
  - Configure public Google STUN servers + Cloudflare fallback TURN credentials.
  - Initialize local media streams (microphone & front camera with 480p/720p hardware-friendly constraints).
  - Establish bidirectional `RTCDataChannel` for real-time text and practice prompts.
  - Implement graceful session teardown and edge signaling socket closure once P2P media flows.

---

### 🔹 Phase 2: Cryptographic Layer & Media/Data Channel E2EE
> **Goal:** Guarantee zero-trust confidentiality so no intermediary (including TURN relays) can decrypt audio, video, or chat messages.

- [ ] **Task 2.1: Ephemeral Key Exchange (`crypto_service.dart`)**
  - Implement Ephemeral Elliptic Curve Diffie-Hellman (ECDH) on Curve25519 (X25519).
  - Exchange public keys over the newly opened `RTCDataChannel`.
  - Derive symmetric session keys using HKDF-SHA256 with random session salt.
- [ ] **Task 2.2: Short Authentication String (SAS) Verification UI**
  - Hash shared secrets into a 4-digit code and matching 3-emoji fingerprint.
  - Display SAS verification banner on both peer screens for visual man-in-the-middle (MitM) protection.
- [ ] **Task 2.3: Data Channel Frame Encryption**
  - Encrypt all chat messages, exercise payloads, and metadata using AES-256-GCM.
  - Include 12-byte IV and monotonic message sequence counter to prevent replay attacks.
- [ ] **Task 2.4: Media Stream Insertable Streams (SFrame)**
  - Hook into `flutter_webrtc` encoded frame transform pipeline (`createEncodedStreams()`).
  - Apply AES-128/256-GCM frame encryption to Opus audio and VP8/H.264 video chunks prior to packetization.

---

### 🔹 Phase 3: Client-Side Content Moderation & Safety Shield
> **Goal:** Provide safety and anti-harassment protections entirely on-device without violating user privacy or requiring centralized media moderation servers.

- [ ] **Task 3.1: Layer 1 Rule-Based Text Filter (`moderation_service.dart`)**
  - Implement unicode zero-width stripper and leetspeak/homoglyph normalizer (`@` ➔ `a`, `$` ➔ `s`, `1` ➔ `i`).
  - Implement tokenized Scunthorpe-safe profanity & harassment regex matcher.
  - Achieve <1ms execution latency for zero UI lag during live chat typing.
- [ ] **Task 3.2: Layer 2 Local Toxicity Classifier**
  - Integrate lightweight quantized toxicity classifier via `tflite_flutter` or native bindings.
  - Evaluate multi-vector toxicity scores (threat, insult, explicit).
  - Automatically suppress outgoing violations, display local warning, and log incident counter.
- [ ] **Task 3.3: In-Call Abuse Reporting & Local Blocklist**
  - Implement a 15-second rolling audio FIFO buffer in device memory.
  - On user tap "Report Peer", transcribe the audio locally with timestamp.
  - Add peer public key to local encrypted blocklist (`hive_flutter`) to prevent future matchmaking.

---

### 🔹 Phase 4: RevenueCat SDK Integration & Paywall UI (Shipaton 2026 Core)
> **Goal:** Fulfill the hackathon requirement with full in-app purchase capabilities, native paywalls, and robust offline entitlement management.

- [ ] **Task 4.1: RevenueCat Project & Product Setup**
  - Create RevenueCat dashboard project: `EasyEnglish`.
  - Configure Google Play, App Store, and Samsung Galaxy Store credentials.
  - Set up Entitlement: `pro`.
  - Configure Offerings:
    - `monthly`: $7.99/mo (7-day free trial).
    - `annual`: $49.99/yr (48% discount).
    - `lifetime`: $99.99 one-time.
- [ ] **Task 4.2: Flutter RevenueCat Integration (`revenuecat_service.dart`)**
  - Initialize `Purchases.configure()` with platform-specific API keys.
  - Expose reactive `Stream<CustomerInfo>` via Riverpod `isProUserProvider`.
  - Implement `purchasePackage()`, `restorePurchases()`, and local fallback state.
- [ ] **Task 4.3: Paywall UI & Conversion Flow**
  - Integrate `purchases_ui_flutter` for dynamic native paywalls and A/B test experiments.
  - Build custom fallback Paywall screen with clean feature comparison cards, trial terms, and Restore button.
  - Gate Pro features (AI Coach, Live Grammar Suggestions) behind entitlement checks.
- [ ] **Task 4.4: RevenueCat Ads Integration (Optional Free Tier)**
  - Integrate RevenueCat Ads or reward ads for free-tier users after call completion.

---

### 🔹 Phase 5: Vercel Gemini AI Proxy & "They Pay, You Keep It Free" Coaching
> **Goal:** Deliver ultra-smart Google Gemini 1.5 Flash AI coaching with $0 cloud cost to the creator.

- [ ] **Task 5.1: Deploy Vercel Serverless Function (`api/coach.js`)**
  - Deploy `api/coach.js` to Vercel free tier with environment variables: `GEMINI_API_KEY`, `REVENUECAT_SECRET_KEY`, `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`.
  - Verify RevenueCat REST API subscriber verification (`https://api.revenuecat.com/v1/subscribers/{app_user_id}`).
  - Verify Upstash Redis rate limiter (50 queries/day/user) to protect Google free tier limits.
- [ ] **Task 5.2: Client AI Coach Service (`ai_coach_service.dart`)**
  - Implement HTTP client calling Vercel `/api/coach` with `Authorization: Bearer <app_user_id>`.
  - Handle 403 Forbidden (trigger RevenueCat Paywall) and 429 Quota Exceeded (graceful quota warning banner).
- [ ] **Task 5.3: In-Call Live Grammar HUD & Solo Companion Mode**
  - Display non-intrusive floating grammar suggestion bubbles during speaking practice.
  - Build Solo Companion Mode allowing paying users to speak with Gemini AI when no human peer is available.

---

### 🔹 Phase 6: Store Readiness, Polish, Performance Tuning & Submission
> **Goal:** Ship production-ready builds to Google Play, Apple App Store, and Samsung Galaxy Store before September 30th, 2026.

- [ ] **Task 6.1: Store Compliance & Legal Requirements**
  - Add Apple & Google required Terms of Service (EULA) and Privacy Policy links.
  - Include functional "Restore Purchases" and "Manage Subscriptions" in Settings.
  - Add User Content Guidelines and prominent "Report / Block" UI in calls.
- [ ] **Task 6.2: Samsung Galaxy Store Integration**
  - Configure Samsung IAP support via RevenueCat or store package guidelines.
  - Prepare Samsung store metadata, screenshots, and device compatibility profiles.
- [ ] **Task 6.3: Release Build Optimization**
  - Enable Android App Bundle (AAB) splitting and ProGuard / R8 code shrinking.
  - Verify app startup time < 1.5s on low-end test devices.
  - Profile memory usage: keep baseline footprint under 120 MB RAM.
- [ ] **Task 6.4: Shipaton Submission & Build-in-Public Launch**
  - Prepare 60-second video demo showcasing P2P E2EE call + RevenueCat paywall + Gemini AI Coach.
  - Submit apps for store review in mid-August 2026.
  - Publish #BuildInPublic launch posts on X / LinkedIn with #Shipaton2026 tag.

---

## 🛠️ Testing & Quality Gates

| Gate | Requirement | Tool / Command |
| :--- | :--- | :--- |
| **Code Quality** | Zero analyzer warnings, consistent formatting | `flutter analyze && dart format --set-exit-if-changed .` |
| **Unit Tests** | 100% pass on signaling state machine, crypto, and safety filters | `flutter test test/unit/` |
| **Entitlement Tests** | Verify Pro features lock/unlock correctly with mock customer info | `flutter test test/unit/paywall_test.dart` |
| **AI Proxy Tests** | Verify Vercel proxy validates RevenueCat header and rejects invalid IDs | Automated curl / Jest tests |
| **Memory Profile** | Peak memory under 200 MB during active video call | Flutter DevTools Profiler |
