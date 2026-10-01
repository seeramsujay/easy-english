// api/coach.js - Vercel Serverless Function
// Free Tier: 100k invocations/month | Gemini 2.5 Flash Lite Free Tier: 15 RPM, 1500 RPD
// Keeps the entire backend $0 for you while paying subscribers access your Gemini key safely.

const REVENUECAT_SECRET_KEY = process.env.REVENUECAT_SECRET_KEY;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const UPSTASH_URL = process.env.UPSTASH_REDIS_REST_URL;
const UPSTASH_TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;

const DAILY_LIMIT = 50; // Max AI queries per paying user per day to guarantee $0 costs

export default async function handler(req, res) {
  // CORS setup for mobile client
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

  // 1. Extract RevenueCat App User ID
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Authorization: Bearer <app_user_id>' });
  }
  const appUserId = authHeader.replace('Bearer ', '').trim();

  // 2. Validate Pro Entitlement via RevenueCat REST API
  const isSubscribed = await verifyRevenueCatPro(appUserId);
  if (!isSubscribed) {
    return res.status(403).json({
      error: 'Pro subscription required to access AI Coach.',
      code: 'ENTITLEMENT_REQUIRED'
    });
  }

  // 3. Rate limiting / Daily Quota check via Upstash Redis
  if (UPSTASH_URL && UPSTASH_TOKEN) {
    const quotaOk = await checkAndIncrementQuota(appUserId);
    if (!quotaOk) {
      return res.status(429).json({
        error: `Daily limit of ${DAILY_LIMIT} prompts reached. Resets at midnight UTC!`,
        code: 'QUOTA_EXCEEDED'
      });
    }
  }

  // 4. Validate request body
  const { mode, text, conversationHistory } = req.body || {};
  if (!text || typeof text !== 'string') {
    return res.status(400).json({ error: 'Field "text" is required.' });
  }

  // 5. Query Google Gemini Flash Lite
  try {
    const aiResponse = await callGeminiFlashLite({ mode, text, conversationHistory });
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
    const proEntitlement = data.subscriber?.entitlements?.easy_english_pro || data.subscriber?.entitlements?.pro;

    if (!proEntitlement) return false;

    // Check expiration date
    if (proEntitlement.expires_date) {
      const expiresAt = new Date(proEntitlement.expires_date).getTime();
      return expiresAt > Date.now();
    }

    // Lifetime entitlement (no expires_date)
    return true;
  } catch (err) {
    console.error('RevenueCat verification error:', err);
    return false;
  }
}

/**
 * Enforces daily usage limit per user via Upstash Redis REST API
 */
async function checkAndIncrementQuota(appUserId) {
  const dateKey = new Date().toISOString().split('T')[0];
  const redisKey = `quota:${appUserId}:${dateKey}`;\n
  try {
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
 * Calls Gemini Flash Lite using Google Generative Language REST API
 * Upgraded to Gemini 2.5 Flash Lite
 */
async function callGeminiFlashLite({ mode, text, conversationHistory = [] }) {
  const systemInstruction = `You are EasyEnglish Coach, an encouraging, native English speaking conversational coach. 
Analyze the learner's speech/caption utterance. 
Return a JSON response with:
1. "correctedText": The natural, grammatically correct version (or same if already perfect).
2. "feedback": A 1-2 sentence tip explaining any grammar or vocabulary improvement (empty if perfect).
3. "reply": A friendly, natural conversational reply (under 25 words) to keep the conversation flowing.
Always output pure JSON.`;

  const prompt = `Learner caption: "${text}". Mode: ${mode || 'conversation'}`;

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

  // Primary model: gemini-2.5-flash-lite, fallback: gemini-1.5-flash
  const models = ['gemini-2.5-flash-lite', 'gemini-1.5-flash'];
  let lastErr = null;

  for (const model of models) {
    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(requestBody)
        }
      );

      if (response.ok) {
        const data = await response.json();
        const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (rawText) {
          try {
            return JSON.parse(rawText);
          } catch {
            return {
              correctedText: text,
              feedback: "",
              reply: rawText || "Great job! Let's keep practicing."
            };
          }
        }
      } else {
        lastErr = new Error(`Model ${model} returned ${response.status}`);
      }
    } catch (err) {
      lastErr = err;
    }
  }

  throw lastErr || new Error('Failed to query Gemini model');
}
