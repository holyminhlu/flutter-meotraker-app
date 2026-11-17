<div align="center">

<img src="mobile/assets/icons/Logo_MeoTracker.png" alt="Meo Traker logo" width="180" />

# 🐱 Meo Traker

### Ăn uống lành mạnh · Vận động mỗi ngày · Khỏe cùng chú mèo Meo

*Ứng dụng theo dõi sức khỏe & dinh dưỡng: chụp ảnh bữa ăn để AI phân tích, nhắc uống nước,
tập thể dục có hướng dẫn, tích điểm — streak, và trợ lý AI đồng hành.*

<br/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express-000000?style=for-the-badge&logo=express&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-3DDC84?style=flat-square)
![Backend](https://img.shields.io/badge/API-Render-46E3B7?style=flat-square&logo=render)
![Database](https://img.shields.io/badge/DB-Aiven%20PostgreSQL-FF5722?style=flat-square)
![AI](https://img.shields.io/badge/AI-Gemini%20%2B%20OpenRouter-8E75B2?style=flat-square)

</div>

---

## ✨ Tính năng nổi bật

<table>
  <tr>
    <td align="center" width="33%">
      <img src="mobile/assets/icons/02_chup_anh_ai_phan_tich.png" width="64" /><br/>
      <b>Chụp ảnh — AI phân tích</b><br/>
      <sub>Gemini nhận diện món ăn, kiểm tra ảnh thật (EXIF), gợi ý dinh dưỡng</sub>
    </td>
    <td align="center" width="33%">
      <img src="mobile/assets/icons/03_thanh_phan_dinh_duong.png" width="64" /><br/>
      <b>Dinh dưỡng cá nhân hóa</b><br/>
      <sub>Tự tính BMI · BMR · TDEE, mục tiêu calo theo sở thích & ngân sách</sub>
    </td>
    <td align="center" width="33%">
      <img src="mobile/assets/icons/08_khung_gio_nhac_nho.png" width="64" /><br/>
      <b>Nhắc bữa ăn thông minh</b><br/>
      <sub>Lịch ăn 3 bữa, thông báo đúng khung giờ, lời động viên</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="mobile/assets/icons/06_uong_nuoc_am.png" width="64" /><br/>
      <b>Theo dõi uống nước</b><br/>
      <sub>6 ly mỗi ngày, cộng điểm khi đủ chỉ tiêu</sub>
    </td>
    <td align="center">
      <img src="mobile/assets/icons/07_van_dong_nhe.png" width="64" /><br/>
      <b>Tập thể dục 10 phút</b><br/>
      <sub>Giáo án có hình + đếm ngược, hoàn thành phiên là +1 điểm</sub>
    </td>
    <td align="center">
      <img src="mobile/assets/icons/09_diem_thuong.png" width="64" /><br/>
      <b>Điểm thưởng & Streak</b><br/>
      <sub>Chuỗi ngày, rương quà, huy hiệu 7 / 30 / 90 / 120 ngày</sub>
    </td>
  </tr>
</table>

> 💬 **Trợ lý Meo AI** — chatbot (OpenRouter · Mimo) hiểu tiến độ hôm nay của bạn để tư vấn phù hợp.
> 🛡️ **Trang quản trị** — admin xem danh sách người dùng, tiến độ theo ngày, ảnh bữa ăn và phân tích.

---

## 🏋️ Giáo án tập 10 phút

<div align="center">
<img src="mobile/assets/images/TheDuc/xoayco.png" width="90" />
<img src="mobile/assets/images/TheDuc/xoaykhopvai.png" width="90" />
<img src="mobile/assets/images/TheDuc/xoaycanhtay.png" width="90" />
<img src="mobile/assets/images/TheDuc/batnhay.png" width="90" />
<img src="mobile/assets/images/TheDuc/dachanchamkhuytay.png" width="90" />
<img src="mobile/assets/images/TheDuc/gapnguoi.png" width="90" />
</div>

<div align="center"><sub>Khởi động → Jumping Jacks → Gối chạm khuỷu → Giãn cơ · tự chuyển động tác theo đồng hồ đếm ngược</sub></div>

---

## 🏆 Cơ chế điểm thưởng

| Hoạt động | Điều kiện | Điểm |
| --- | --- | --- |
| 🍽️ Ăn đủ bữa | Hoàn thành các bữa trong ngày | +1 |
| 💧 Uống nước | Đủ số ly mục tiêu | +1 |
| 🏃 Tập thể dục | Hoàn thành 1 phiên tập | +1 / phiên |
| 🔥 Streak | Duy trì hoạt động liên tục | Mở rương & huy hiệu |

<div align="center">
<img src="mobile/assets/images/ruong15d.png" width="80" />
<img src="mobile/assets/images/ruong30d.png" width="80" />
</div>

---

## 🧱 Kiến trúc hệ thống

```mermaid
flowchart LR
    A["📱 Flutter App<br/>Android · Web"] -->|HTTPS REST| B["⚙️ Express API<br/>Render"]
    B -->|"SQL over SSL"| C[("🐘 PostgreSQL<br/>Aiven")]
    B -->|"Nhận diện món ăn"| D["🤖 Gemini API"]
    B -->|"Chatbot Meo AI"| E["💬 OpenRouter · Mimo"]
```

| Tầng | Công nghệ |
| --- | --- |
| 📱 Mobile / Web | Flutter · Dart (Android + Web build) |
| ⚙️ Backend API | Node.js · Express.js · JWT auth |
| 🐘 Database | PostgreSQL (Aiven managed, SSL) |
| 🤖 AI | Google Gemini (ảnh món ăn) · OpenRouter Mimo (chat) |
| 🖼️ Xử lý ảnh | `sharp` → nén AVIF |
| ☁️ Triển khai | Render (Docker cho web, Node cho API) |

---

## 🚀 Luồng onboarding

```mermaid
flowchart TD
    R["Đăng ký / Đăng nhập"] --> P["Thông tin cơ thể<br/>cao · nặng · tuổi · giới · vận động"]
    P --> M["Tự tính BMI · BMR · TDEE<br/>+ mục tiêu calo/ngày"]
    M --> D["Sở thích ăn uống<br/>món thích/ghét · dị ứng · ngân sách"]
    D --> H["🏠 Màn hình chính"]
```

---

## 📂 Cấu trúc dự án

```text
meo-tracker/
├── mobile/            # Ứng dụng Flutter (Android · Web)
│   ├── lib/           # Mã nguồn theo feature
│   └── assets/        # Icon, ảnh, giáo án tập
├── backend/           # Express API
│   ├── src/           # routes · controllers · services · config
│   └── scripts/       # migrate · seed admin · kiểm tra DB
├── database/          # schema.sql + migrations
├── deploy/            # cấu hình Nginx cho web
├── Dockerfile         # build Flutter web → Nginx
├── render.yaml        # Blueprint deploy Render (web + api)
└── docs/
```

---

## 🛠️ Chạy dự án ở local

**Yêu cầu:** Flutter SDK, Node.js 18+, PostgreSQL (hoặc dùng Aiven).

```powershell
# 1) Backend
cd backend
npm install
copy .env.example .env      # điền DB, JWT, API keys
npm run db:migrate          # tạo schema
npm run dev                 # http://localhost:3000

# 2) Mobile (debug)
cd ../mobile
flutter pub get
flutter run -d windows      # hoặc -d chrome / thiết bị Android
```

Kết nối tới backend đã deploy:

```powershell
flutter run --dart-define=API_BASE_URL=https://meo-traker-api.onrender.com
```

---

## 📦 Build & Deploy

**APK Android:**

```powershell
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://meo-traker-api.onrender.com
# → build/app/outputs/flutter-apk/app-release.apk
```

**Web (Docker + Nginx):**

```bash
docker build --build-arg API_BASE_URL=https://meo-traker-api.onrender.com -t meo-traker-web .
```

**Render:** dùng `render.yaml` (Blueprint) tạo cùng lúc web + API, hoặc tạo thủ công 2 service.

| Script backend | Mục đích |
| --- | --- |
| `npm run db:migrate` | Chạy schema + migrations |
| `npm run db:seed-admin` | Tạo tài khoản admin |
| `npm run db:check` | Kiểm tra kết nối & schema |

---

## 🔐 Biến môi trường (`backend/.env`)

```env
NODE_ENV=production
DATABASE_URL=postgres://user:pass@host:port/dbname?sslmode=require
DB_SSL=true
JWT_SECRET=<chuỗi ngẫu nhiên dài>
GEMINI_API_KEY=<key Gemini>
OPENROUTER_API_KEY=<key OpenRouter>
```

> `.env` đã được gitignore — dùng `.env.example` làm mẫu.

---

<div align="center">
<img src="mobile/assets/icons/streak.png" width="40" />&nbsp;&nbsp;
<img src="mobile/assets/icons/xu.png" width="40" />
<br/><br/>
<sub>Made with 🐱 &amp; Flutter — <b>Eat Well · Move More · Grow Strong</b></sub>
</div>
