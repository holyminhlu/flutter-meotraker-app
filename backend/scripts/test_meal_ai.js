require('dotenv').config();
const OpenAI = require('openai');
const fs = require('fs');
const http = require('http');
const path = require('path');

async function main() {
  const model = process.env.NVIDIA_MEAL_MODEL;
  console.log('Model:', model);

  const client = new OpenAI({
    apiKey: process.env.NVIDIA_API_KEY,
    baseURL: process.env.NVIDIA_BASE_URL,
    timeout: 90000,
  });

  const imgPath = path.join(__dirname, '..', 'tmp_food.jpg');
  const b64 = fs.readFileSync(imgPath).toString('base64');
  console.log('Image bytes:', fs.statSync(imgPath).size);

  console.log('1) NVIDIA vision...');
  const t0 = Date.now();
  const completion = await client.chat.completions.create({
    model,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text:
              'Return ONLY JSON with keys: isMeal, containsFood, confidence, description, looksLikeScreenshotOrStock, looksLikePackagingOnly, looksEditedOrFake, suggestedMealPeriod, notes',
          },
          {
            type: 'image_url',
            image_url: { url: `data:image/jpeg;base64,${b64}` },
          },
        ],
      },
    ],
    max_tokens: 300,
    temperature: 0.2,
    stream: false,
  });
  console.log('NVIDIA_MS', Date.now() - t0);
  console.log('NVIDIA_REPLY', completion.choices?.[0]?.message?.content);

  console.log('2) Backend /api/meals/analyze...');
  const login = await postJson('/api/auth/login', {
    email: 'ai_test@meotraker.local',
    password: 'Test1234!',
  });
  if (!login.token) throw new Error('login failed: ' + JSON.stringify(login));

  const t1 = Date.now();
  const analyze = await postJson(
    '/api/meals/analyze',
    {
      imageBase64: b64,
      mimeType: 'image/jpeg',
      mealPeriod: 'lunch',
      clientNowIso: new Date().toISOString(),
    },
    login.token,
  );
  console.log('ANALYZE_MS', Date.now() - t1);
  console.log(JSON.stringify(analyze, null, 2));
}

function postJson(urlPath, bodyObj, bearer) {
  const body = JSON.stringify(bodyObj);
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: 'localhost',
        port: 3000,
        path: urlPath,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
          ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}),
        },
        timeout: 120000,
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch {
            reject(new Error(`Bad JSON ${res.statusCode}: ${data.slice(0, 400)}`));
          }
        });
      },
    );
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy(new Error('timeout'));
    });
    req.write(body);
    req.end();
  });
}

main().catch((e) => {
  console.error('FAIL', e.status || '', e.message);
  if (e.error) console.error(JSON.stringify(e.error, null, 2));
  process.exit(1);
});
