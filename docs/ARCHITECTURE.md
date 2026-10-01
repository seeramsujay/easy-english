# 🏛️ EasyEnglish System Architecture & Technical Specification

## 1. System Overview

EasyEnglish operates as a **zero-backend, serverless Peer-to-Peer (P2P) platform**. Traditional calling architectures require centralized media relay servers (SFUs/MCUs), user database clusters, and media recording pipelines. EasyEnglish removes the cloud backend from active communications entirely:

```
+-----------------------------------------------------------------------------------+
|                               SIGNALING LAYER                                     |
| Cloudflare Workers / Vercel Edge + Upstash Redis KV (Ephemeral state < 60s)       |
+-----------------------------------------+-----------------------------------------+
                                          |
                      1. Ephemeral Matchmaking & SDP Exchange
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              MEDIA & DATA LAYER                                   |
| Flutter WebRTC Direct Peer-to-Peer (UDP / DTLS / SRTP)                            |
| 1-on-1 Full Duplex Video, Audio, and RTCDataChannel                               |
+-----------------------------------------+-----------------------------------------+
                                          |
                      2. E2EE Layer (Insertable Streams + AES-GCM)
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              ON-DEVICE CLIENT LAYER                               |
| - Safety Shield: Local Regex & Homoglyph Normalizer + On-Device Toxicity NLU      |
| - Monetization Core: RevenueCat SDK (purchases_flutter) & Entitlement Gate        |
+-----------------------------------------+-----------------------------------------+
                                          |
                      3. Pro AI Query: If Active Pro Subscriber
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                     VERCEL SERVERLESS GEMINI AI PROXY                             |
| - Real-time RevenueCat REST API subscriber verification (`/v1/subscribers`)       |
| - Upstash Redis rate limiter (50 queries/day/user) to protect Google Free Tier    |
| - Google Gemini 1.5 Flash API (Zero cost to creator, secret key safe on server)   |
+-----------------------------------------------------------------------------------+
```

---

## 2. Serverless Signaling Architecture

### 2.1 Ephemeral Peer Lifecycle
Signaling is used strictly to exchange Session Description Protocol (SDP) payloads and Interactive Connectivity Establishment (ICE) candidates. 

```
Peer A                                Edge Worker (KV)                             Peer B
  │                                          │                                       │
  │── 1. POST /match (lang=en, level=b1) ───►│                                       │
  │   ◄── 200 OK (peerId=p_8f9, wait) ───────│                                       │
  │                                          │◄── 2. POST /match (lang=en, b1) ──────│
  │                                          │─── 200 OK (peerId=p_12a, match=p_8f9)►│
  │                                          │                                       │
  │◄── 3. WebSocket: PeerMatched(p_12a) ─────│                                       │
  │                                          │                                       │
  │── 4. POST /signal (SDP Offer) ──────────►│─── Forward SDP Offer ────────────────►│
  │                                          │                                       │
  │◄── Forward SDP Answer ───────────────────│◄── 5. POST /signal (SDP Answer) ──────│
  │                                          │                                       │
  │── 6. Exchange ICE Candidates ───────────►│─── Forward ICE Candidates ───────────►│
  │                                          │                                       │
  │══ 7. Direct UDP WebRTC Connection Established (Signaling Socket Closed) ═════════│
```

### 2.2 Signaling Payload Specifications

#### SDP Offer Payload:
```json
{
  "type": "offer",
  "senderId": "peer_8f92a",
  "targetId": "peer_12a4b",
  "sdp": "v=0\r\no=- 4234567 2 IN IP4 127.0.0.1...",
  "timestamp": 1722470400000
}
```

#### ICE Candidate Payload:
```json
{
  "type": "candidate",
  "senderId": "peer_8f92a",
  "targetId": "peer_12a4b",
  "candidate": {
    "candidate": "candidate:842163049 1 udp 1677729535 192.168.1.15 54321 typ host...",
    "sdpMid": "0",
    "sdpMLineIndex": 0
  }
}
```

### 2.3 NAT Traversal Strategy (STUN & Fallback TURN)
- **STUN (Session Traversal Utilities for NAT):** Primary mechanism resolving public IP/port bindings. Succeeds in ~75-80% of residential network configurations. We use public Google STUN servers (`stun:stun.l.google.com:19302`).
- **Cloudflare TURN Fallback:** When both peers are behind symmetric NATs or restrictive cellular firewalls, direct UDP fails. The app automatically requests ephemeral credentials from Cloudflare Calls / TURN service. The TURN server acts solely as a blind packet forwarder; because all media packets are end-to-end encrypted, zero cleartext data is accessible to the relay.

---

## 3. Cryptographic Specification (Zero-Trust E2EE)

```
        Peer A                                                    Peer B
          │                                                         │
          ├─ Generate X25519 Keypair (PrivA, PubA)                  ├─ Generate X25519 Keypair (PrivB, PubB)
          │                                                         │
          │──────────── Send PubA over RTCDataChannel ─────────────►│
          │◄─────────── Send PubB over RTCDataChannel ──────────────│
          │                                                         │
          ├─ Compute Shared Secret S = ECDH(PrivA, PubB)            ├─ Compute Shared Secret S = ECDH(PrivB, PubA)
          │                                                         │
          ├─ KDF: KeyMaterial = HKDF-SHA256(S, SessionSalt)         ├─ KDF: KeyMaterial = HKDF-SHA256(S, SessionSalt)
          │   ├── Symmetric Key: K_data (AES-256-GCM)               │   ├── Symmetric Key: K_data (AES-256-GCM)
          │   └── Symmetric Key: K_media (AES-128/256-GCM)          │   └── Symmetric Key: K_media (AES-128/256-GCM)
          │                                                         │
          └─ Compute Short Auth String (SAS) ───────────────────────└─ Compute Short Auth String (SAS)
                 (Display 4-digit code & 3 emoji check)                    (Display 4-digit code & 3 emoji check)
```

### 3.1 Data Channel Protection (AES-256-GCM)
All text, practice prompts, and signaling metadata over `RTCDataChannel` are framed as:
```
[12-byte IV] + [Ciphertext: Encrypted JSON Payload] + [16-byte GCM Auth Tag]
```
- **Additional Authenticated Data (AAD):** `[SessionID || MonotonicSequenceNumber]` to guarantee frame order and prevent replay attacks.

### 3.2 Media Stream Protection (Insertable Streams / SFrame)
Using `flutter_webrtc`'s `createEncodedStreams()` hooks:
1. Microphone / Camera captures raw frames and passes them to native audio (Opus) / video (VP8) encoders.
2. The encoded chunk is intercepted before RTP packetization.
3. The raw media payload is encrypted with `K_media` using AES-GCM, leaving the standard RTP header metadata intact so network packet routers function normally.
4. The receiver decrypts the payload chunk and forwards it to the native video renderer or speaker track.

---

## 4. Vercel Serverless Gemini AI Proxy Architecture

To keep AI coaching high-quality without bankrupting the developer or exposing secret API keys:
1. **Endpoint:** `POST https://your-app.vercel.app/api/coach`
2. **Authentication:** The Flutter client sends `Authorization: Bearer <rc_app_user_id>`.
3. **RevenueCat Check:** The Vercel function queries `https://api.revenuecat.com/v1/subscribers/{app_user_id}` with its server secret key. If no active `pro` entitlement exists, it returns HTTP 403 Forbidden.
4. **Daily Quota Limit:** Upstash Redis tracks usage with `INCR quota:{user}:{date}`. If usage > 50, it returns HTTP 429.
5. **Gemini Execution:** Only verified, within-quota requests invoke Google Gemini 1.5 Flash.
6. **Result:** Users pay you $7.99/mo; your cloud bills remain **$0.00** across Vercel, Google Gemini, and Upstash free tiers.

---

## 5. State Management & Architecture Patterns

EasyEnglish strictly adopts **Clean Architecture with Feature-First organization** powered by `flutter_riverpod`:

```
┌──────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│ Widgets, Screens, Dialogs (Reactive to Riverpod State)    │
└────────────────────────────┬─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│                   Application Layer                      │
│ StateNotifier / AsyncNotifier Controllers & Use Cases     │
└────────────────────────────┬─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│                    Domain Layer                          │
│ Entities, Value Objects, Repository Interfaces           │
└────────────────────────────┬─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│                 Infrastructure Layer                     │
│ WebRTC, Signaling Client, RevenueCat SDK, AICoachClient   │
└──────────────────────────────────────────────────────────┘
```
