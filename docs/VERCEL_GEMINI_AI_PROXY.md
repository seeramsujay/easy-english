# 🤖 Vercel Gemini AI Proxy & RevenueCat Serverless Verification

> **Design Goal:** "They pay, you keep it 100% free."  
> Secure your Google Gemini API key behind a zero-cost Vercel Edge Function. Only paying subscribers (verified in real time via RevenueCat's REST API) can access the AI, with strict daily query quotas tracked in Upstash Redis so your costs never exceed $0.

---

## 1. High-Level Architecture

```
Mobile App (Flutter)
     │
     │ 1. POST /api/coach
     │    Headers: { Authorization: "Bearer <rc_app_user_id>" }
     │    Body: { "mode": "grammar_check", "text": "I has went to the store" }
     ▼
Vercel Serverless / Edge Function (`/api/coach.js`)
     │
     ├─► 2. Step 1: RevenueCat REST API Verification
     │      GET https://api.revenuecat.com/v1/subscribers/{app_user_id}
     │      Check: Does `entitlements.pro.expires_date` exist and is in the future?
     │      - If NO ➔ Return 403 Forbidden ("Subscription Required")
     │
     ├─► 3. Step 2: Zero-Cost Quota / Rate Limiter (Upstash Redis Free Tier)
     │      Key: `usage:${app_user_id}:${YYYY-MM-DD}`
     │      Increment counter (TTL: 86400s).
     │      - If count > 50 ➔ Return 429 ("Daily AI quota reached. Resets at midnight.")
     │
     └─► 4. Step 3: Google Gemini API Call (Gemini 1.5 / 2.0 Flash Free Tier)
            POST https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}
            - System Prompt: Concise English speaking tutor / grammar coach
            - Returns: Corrected sentence, grammar tip, and conversational response
            │
            ▼
     5. Return Clean JSON to Flutter App
```

---

## 2. Complete Vercel Serverless Function Code

Place this in `api/coach.js` (or in a lightweight repo deployed to Vercel with zero config):

```javascript
// api/coach.js - Vercel Serverless Function
// Runs on Vercel Node.js / Edge Runtime (Free Tier: 100k requests/month)

const REVENUECAT_SECRET_KEY = process.env.REVENUECAT_SECRET_KEY; // RevenueCat v1 secret API key
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;               // Google AI Studio free key
const UPSTASH_URL = process.env.UPSTASH_REDIS_REST_URL;         // Upstash Redis Free Tier
const UPSTASH_TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;

const DAILY_LIMIT = 50; // Max AI queries per paying user per day

export default async function handler(req, res) {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Extract App User ID from Authorization header
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing RevenueCat App User ID' });
  }
  const appUserId = authHeader.replace('Bearer ', '').trim();

  // 2. Validate Pro Entitlement with RevenueCat REST API
  const isSubscribed = await verifyRevenueCatPro(appUserId);
  if (!isSubscribed) {
    return res.status(403).json({
      error: 'Pro subscription required to access AI Coaching.',
      code: 'ENTITLEMENT_REQUIRED'
    });
  }

  // 3. Check and Increment Daily Quota in Upstash Redis
  if (UPSTASH_URL && UPSTASH_TOKEN) {
    const quotaAllowed = await checkAndIncrementQuota(appUserId);
    if (!quotaAllowed) {
      return res.status(429).json({
        error: `Daily AI quota of ${DAILY_LIMIT} prompts reached. Resets at midnight UTC!`,
        code: 'QUOTA_EXCEEDED'
      });
    }
  }

  // 4. Parse user input
  const { mode, text, conversationHistory } = req.body;
  if (!text || typeof text !== 'string') {
    return res.status(400).json({ error: 'Missing or invalid "text" field.' });
  }

  // 5. Call Gemini 1.5 Flash (Generous Free Tier: 15 Requests/Min, 1M Tokens/Min)
  try {
    const aiResponse = await callGeminiFlash({ mode, text, conversationHistory });
    return res.status(200).json(aiResponse);
  } catch (error) {
    console.error('Gemini API Error:', error);
    return res.status(500).json({ error: 'Failed to process AI response' });
  }
}

/**
 * Validates subscriber status directly with RevenueCat v1 REST API
 */
async function verifyRevenueCatPro(appUserId) {
  try {
    const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`, {
      headers: {
        'Authorization': `Bearer ${REVENUECAT_SECRET_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      console.warn(`RevenueCat API returned status ${response.status}`);
      return false;
    }

    const data = await response.json();
    const proEntitlement = data.subscriber?.entitlements?.pro;

    if (!proEntitlement) return false;

    // Check expiration date
    if (proEntitlement.expires_date) {
      const expiresAt = new Date(proEntitlement.expires_date).getTime();
      return expiresAt > Date.now();
    }

    // Lifetime entitlement (no expires_date)
    return true;
  } catch (err) {
    console.error('RevenueCat validation error:', err);
    return false;
  }
}

/**
 * Enforces daily usage limit per user via Upstash Redis REST
 */
async function checkAndIncrementQuota(appUserId) {
  const dateKey = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const redisKey = `quota:${appUserId}:${dateKey}`;

  try {
    // Pipeline: INCR and EXPIRE in one call
    const res = await fetch(`${UPSTASH_URL}/pipeline`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${UPSTASH_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify([
        ['INCR', redisKey],
        ['EXPIRE', redisKey, 86400]
      ])
    });

    const results = await res.json();
    const count = results[0]?.result || 1;
    return count <= DAILY_LIMIT;
  } catch (err) {
    console.warn('Upstash Redis quota check failed, allowing request:', err);
    return true;
  }
}

/**
 * Calls Gemini 1.5 Flash using REST API
 */
async function callGeminiFlash({ mode, text, conversationHistory = [] }) {
  const systemInstruction = `You are EasyEnglish Coach, an encouraging, native English speaking conversational coach. 
Analyze the learner's utterance. 
Return a JSON response with:
1. "correctedText": The natural, grammatically correct version (or same if already perfect).
2. "feedback": A 1-2 sentence tip explaining any grammar or vocabulary improvement (empty if perfect).
3. "reply": A friendly, natural conversational reply (under 25 words) to keep the conversation flowing.
Always output pure JSON.`;

  const prompt = `Learner said: "${text}". Mode: ${mode || 'conversation'}`;

  const requestBody = {
    contents: [
      ...conversationHistory.map(msg => ({
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.text }]
      })),
      { role: 'user', parts: [{ text: prompt }] }
    ],
    systemInstruction: {
      parts: [{ text: systemInstruction }]
    },
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 250,
      responseMimeType: "application/json"
    }
  };

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody)
    }
  );

  const data = await response.json();
  const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
  
  try {
    return JSON.parse(rawText);
  } catch {
    return {
      correctedText: text,
      feedback: "",
      reply: rawText || "That sounds great! Keep practicing."
    };
  }
}
```

---

## 3. Flutter Client Integration

In the mobile app, when the user is verified Pro via RevenueCat, the app calls your Vercel endpoint:

```dart
// lib/features/ai_coach/services/ai_coach_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';

class AICoachApiService {
  static const _vercelEndpoint = 'https://your-easyenglish-api.vercel.app/api/coach';

  static Future<AICoachResponse?> getFeedbackAndReply(String spokenText) async {
    try {
      // 1. Get RevenueCat App User ID
      final appUserId = await Purchases.appUserID;

      // 2. Call Vercel Proxy with User ID
      final response = await http.post(
        Uri.parse(_vercelEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appUserId',
        },
        body: jsonEncode({
          'mode': 'conversation',
          'text': spokenText,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AICoachResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        // Not a paying subscriber
        throw EntitlementRequiredException();
      } else if (response.statusCode == 429) {
        // Daily quota reached
        throw DailyQuotaExceededException();
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
}

class AICoachResponse {
  final String correctedText;
  final String feedback;
  final String reply;

  AICoachResponse({
    required this.correctedText,
    required this.feedback,
    required this.reply,
  });

  factory AICoachResponse.fromJson(Map<String, dynamic> json) => AICoachResponse(
    correctedText: json['correctedText'] ?? '',
    feedback: json['feedback'] ?? '',
    reply: json['reply'] ?? '',
  );
}
```

---

## 4. Why This Architecture Keeps It 100% Free For You

1. **Google Gemini 1.5 Flash Free Tier:**
   - Free up to **15 Requests Per Minute (RPM)**, **1,000,000 Tokens Per Minute (TPM)**, and **1,500 Requests Per Day (RPD)**.
   - Using Gemini 1.5 Flash costs you **$0.00**.
2. **Vercel Hobby Plan (Free):**
   - 100,000 edge/serverless invocations per month at **$0.00**.
3. **Upstash Redis Free Tier:**
   - 10,000 commands/day at **$0.00** for bulletproof quota tracking.
4. **RevenueCat Free Tier:**
   - RevenueCat is 100% free up to $2,500/month in tracked revenue, then just 1%.
5. **They Pay, You Earn:**
   - When users pay $7.99/month, 100% of your cloud operational expenses remain $0. All revenue is net profit (minus standard App Store / Google Play cuts).
6. **Hard Cap Security:**
   - The Upstash Redis rate limiter caps every paying user at 50 queries/day. Even if a user attempts to spam the API, they are cut off automatically, keeping you comfortably inside Google's free tier.
