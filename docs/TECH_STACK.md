# Meo Traker — Tech Stack

## Mobile frontend
- **Framework:** Flutter
- **Language:** Dart
- **Targets:** Android, iOS
- **Layout:** feature-first under `mobile/lib/`

## Backend
- **Runtime:** Node.js
- **Framework:** Express.js
- **Entry:** `backend/src/server.js`
- **Config:** `dotenv` + `backend/src/config/`
- **DB client:** `pg` (node-postgres)

## Database
- **Engine:** PostgreSQL
- **Database name:** `meo_traker`
- **Default local user:** `postgres`
- **Scripts:** `database/init.sql`, `database/schema.sql`, `database/seeds/`

## Suggested next steps
1. Auth (JWT) + user registration
2. Flutter `http` / Dio client wired to Express
3. Migrations tool (e.g. node-pg-migrate or Prisma)
4. CI for Flutter analyze + backend tests
