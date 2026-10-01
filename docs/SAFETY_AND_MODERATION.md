# 🛡️ On-Device Safety & Local Content Moderation Specification

## 1. The Decentralized Safety Dilemma

In traditional social and language platforms, safety moderation is handled on centralized media servers:
- Audio/video streams pass through cloud relays where automated computer vision or speech-to-text filters inspect content.
- Text messages are logged in relational databases and analyzed by cloud moderation APIs (e.g., Perspective API, OpenAI Moderation).

**In EasyEnglish, this traditional model is impossible for two reasons:**
1. **Privacy Invariant:** Communications are End-to-End Encrypted (E2EE). No server possesses the private keys needed to inspect frames or messages.
2. **Zero-Backend Invariant:** Running 24/7 cloud transcription and inspection proxies would incur massive recurring bills, violating our serverless cost structure.

**The Solution:** An **on-device, multi-tier safety engine** executing inside the Flutter client runtime before any encrypted packet leaves the device.

---

## 2. Multi-Tiered Safety Architecture

```
User Input (Chat / Speech)
           │
           ▼
┌────────────────────────────────────────────────────────┐
│  Tier 1: Rule-Based Pattern & Normalization Engine     │
│  - Strip zero-width & invisible unicode characters     │
│  - Homoglyph & leetspeak replacement (@->a, 1->i, $->s)│
│  - Context-aware Scunthorpe token boundary check       │
│  - Execution latency: < 1ms                            │
└──────────────────────────┬─────────────────────────────┘
                           │
                 Passed Layer 1 Check?
                /                     \
              No                       Yes
             /                           \
            ▼                             ▼
   [Suppress Transmission]     ┌────────────────────────────────────────────────────────┐
   [Show Local Warning UI]     │  Tier 2: On-Device Machine Learning Toxicity Classifier│
                               │  - Quantized MobileBERT / LiteRT NLP model             │
                               │  - Multi-class toxicity vector evaluation:             │
                               │    V = [toxic, severe_toxic, obscene, threat, insult]  │
                               │  - Execution latency: 15–30ms                          │
                               └──────────────────────────┬─────────────────────────────┘
                                                          │
                                                Any score > Threshold?
                                               /                      \
                                             Yes                       No
                                            /                            \
                                           ▼                              ▼
                                 [Block & Warn User]            [Encrypt via AES-256-GCM]
                                 [Increment Strike]             [Transmit over P2P DataChannel]
```

---

## 3. Tier 1: Normalization & Regex Engine

### 3.1 Homoglyph & Leetspeak Replacement
Bad actors often attempt to bypass naive keyword filters using visual character substitutions (homoglyphs) or leetspeak:

| Obfuscated Input | Normalized Output | Normalized Rule |
| :--- | :--- | :--- |
| `f|_|ck` or `f.u.c.k` | `fuck` | Strip separators & reconstruct tokens |
| `h@te` | `hate` | Map `@` ➔ `a` |
| `b!tch` | `bitch` | Map `!` or `1` ➔ `i` |
| `a\u200Bss` | `ass` | Strip zero-width space `\u200B` |

### 3.2 Solving the "Scunthorpe Problem" (False Positives)
A naive substring filter blocks harmless words that contain banned sub-tokens:
- **"therapist"** contains "the-rapist"
- **"grape"** contains "rape"
- **"arsenal"** contains "arse"
- **"basement"** contains "semen"

**EasyEnglish Implementation:**
Token boundaries are enforced using word-segmentation regex:
```dart
bool containsProfanity(String text, Set<String> blockedTokens) {
  final normalized = normalizeText(text);
  final words = normalized.split(RegExp(r'\s+|[^\w\s]'));
  
  for (final word in words) {
    if (blockedTokens.contains(word)) {
      return true;
    }
  }
  return false;
}
```

---

## 4. Tier 2: On-Device Toxicity Classification (LiteRT / TFLite)

For subtle harassment, intimidation, or toxic intent that evades static dictionary matching, input is passed to an on-device quantized NLP model:

```dart
class ToxicityScores {
  final double toxicity;
  final double severeToxicity;
  final double threat;
  final double insult;

  ToxicityScores({
    required this.toxicity,
    required this.severeToxicity,
    required this.threat,
    required this.insult,
  });

  bool isViolating({double threshold = 0.75}) {
    return toxicity > threshold ||
        severeToxicity > 0.50 ||
        threat > 0.40 ||
        insult > threshold;
  }
}
```

If `isViolating()` returns `true`:
1. Message transmission over the `RTCDataChannel` is immediately canceled.
2. The user is presented with a non-intrusive warning dialog: *"This message violates our community guidelines against harassment."*
3. The peer is never exposed to the offensive content.

---

## 5. Peer Abuse Reporting Protocol (Audio/Video Calls)

When two users are connected in an encrypted voice or video call, a peer could verbally violate community standards. Because no server is listening, how does reporting work?

```
Active Call (E2EE Audio Track)
         │
         ▼
[15-Second Rolling FIFO Audio Buffer in RAM]
         │
         │  (Continuously overwrites oldest 1-second segment)
         │  (Zero disk storage; destroyed on call exit)
         ▼
User Taps "Report & Block User" Button
         │
         ├─ 1. Freeze 15s Audio Buffer
         ├─ 2. Run Offline Speech-to-Text (Vosk) on Local Device
         ├─ 3. Highlight Detected Offense & Timestamp
         ├─ 4. Cryptographically Sign Incident with Device Private Key
         ├─ 5. Add Peer Public Key to Local Encrypted Blocklist (Hive)
         └─ 6. Instantly Terminate WebRTC Peer Connection
```

### Key Guarantees:
- **Privacy:** Unencrypted audio never leaves the device. The incident is signed and retained locally.
- **Permanent Peer Disconnection:** The offending peer's public key fingerprint is stored in an encrypted local blocklist. The signaling engine refuses to match the user with this peer in future sessions.
- **Store Compliance:** Fulfills Google Play and Apple App Store App Review guidelines for user safety, immediate blocking, and harassment prevention in communication apps.
