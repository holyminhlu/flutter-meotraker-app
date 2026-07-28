require('dotenv').config();
const { GoogleGenAI } = require('@google/genai');
const fs = require('fs');
const path = require('path');

async function main() {
  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MEAL_MODEL || 'gemini-3.5-flash-lite';
  if (!apiKey) {
    console.error('FAIL: thiếu GEMINI_API_KEY trong .env');
    process.exit(1);
  }

  const ai = new GoogleGenAI({ apiKey });
  const imgPath = path.join(__dirname, '..', 'tmp_food.jpg');
  if (!fs.existsSync(imgPath)) {
    console.error('FAIL: thiếu tmp_food.jpg — tạo ảnh test trước');
    process.exit(1);
  }
  const b64 = fs.readFileSync(imgPath).toString('base64');

  console.log('Model:', model);
  const t0 = Date.now();
  const response = await ai.models.generateContent({
    model,
    contents: [
      { inlineData: { mimeType: 'image/jpeg', data: b64 } },
      {
        text:
          'Return ONLY JSON: {"isMeal":bool,"containsFood":bool,"confidence":0-1,"description":"str"}',
      },
    ],
    config: {
      temperature: 0.2,
      responseMimeType: 'application/json',
      maxOutputTokens: 256,
    },
  });
  console.log('MS', Date.now() - t0);
  console.log('REPLY', response.text);
}

main().catch((e) => {
  console.error('FAIL', e.message);
  process.exit(1);
});
