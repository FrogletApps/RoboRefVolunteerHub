# RoboRef Volunteer Hub

[![Platform - Flutter](https://img.shields.io/badge/Platform-Flutter%20%7C%20Dart-02569B?logo=flutter)](https://flutter.dev)
[![UI - Material 3](https://img.shields.io/badge/UI-Material%20Design%203-7B1FA2)](https://m3.material.io)
[![State - Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-0553B1)](https://riverpod.dev)

**RoboRef Volunteer Hub** is an unofficial volunteer management and event coordination application built specifically for VEX Robotics competitions (**V5RC**, **VIQRC**, and **VEX U**), initially focused on the **United Kingdom**.

It allows invited volunteers to authenticate via **Continue with Google** or passwordless **6-digit Email OTP**, declare their certified qualifications, keep personal contact details strictly isolated from public rosters, and mark themselves as **Available** or **Confirmed** for UK events fetched directly from the official **VEX Events API** (`events.vex.com`).

---

## ✨ Key Features

- 🔐 **Passwordless Auth (Google + 6-Digit Email OTP) & Persistent Sessions**:
  - Invite-only new volunteer onboarding verified server-side against encrypted Cloudflare Secrets (`INVITE_CODES`) for both Google Sign-In and Email OTP.
  - Native **Cloudflare Email Service** (`send_email`) delivery protected by 4-layer rate limiting (60s cooldown, **12 emails/day per user**, per-IP cap, Cloudflare Turnstile, and a global daily circuit breaker).
  - Persistent device sessions via **Firebase Authentication** (`Persistence.LOCAL` on Web, Keychain on iOS, Keystore on Android) so volunteers stay signed in across weeks/months until explicit logout.
- 🛡️ **Zero-PII Roster Architecture**:
  - Personal contact details (`email`, `phone`) are isolated in owner-only `volunteer_private/{uid}` documents in **Cloud Firestore** (`firestore.rules`) and are never exposed on `volunteers/{uid}` or `event_signups` documents.
- 🏅 **Qualification Management**:
  - Track official volunteer roles: **Head Referee**, **Field Referee**, **Judge Advisor**, **Judge**, and **Other** (Field Queuer, TM Operator, Robot Inspection, Emcee).
- 📅 **Per-Event Availability & Confirmation Tracking**:
  - Volunteers can mark themselves as **Available** or **Confirmed**, pick qualified roles, or withdraw at any time with live updates.
- 🌐 **UK VEX Events Integration**:
  - Queries upcoming UK tournaments from the official **VEX Events API** (`events.vex.com/api/v2/events`) with search by name, venue, city, or SKU (`RE-V5RC-...`, `RE-VIQRC-...`).

---

## 🏗 Architecture & Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Client Framework** | **Flutter** (Dart ^3.5.0) | Cross-platform client for Web, Android, and iOS |
| **State Management** | **Riverpod** 2.x | Reactive auth gating, state, and dependency injection |
| **Identity & Sessions** | **Firebase Authentication** | Custom-token sign-in with long-lived remembered device sessions |
| **Database & Rules** | **Cloud Firestore** | Real-time rosters & strict `firestore.rules` PII isolation |
| **Auth Edge Worker** | **Cloudflare Workers + KV + Email Service** | Standalone `workers/auth-otp/` invite validator, rate limiter & 6-digit OTP sender |
| **External API** | **VEX Events API v2** | `events.vex.com` event data and schedule ingestion |

---

## 🚀 Getting Started

### 1. Cloudflare Auth OTP Worker (`workers/auth-otp/`)
See [workers/auth-otp/README.md](workers/auth-otp/README.md) to configure the `AUTH_OTP_KV` namespace, onboard `roboref.app` in Cloudflare Email Service, set `INVITE_CODES` / `OTP_HMAC_SECRET` / `FIREBASE_SERVICE_ACCOUNT_JSON` / `TURNSTILE_SECRET_KEY` secrets, and deploy:
```bash
cd workers/auth-otp
npm test
npx wrangler deploy
```

### 2. Firebase & Flutter Application (`app/`)
1. Provision a Firebase project (London `europe-west2` Firestore region), deploy `firestore.rules`:
   ```bash
   npx -y firebase-tools@latest deploy --only firestore:rules
   ```
2. Configure FlutterFire inside `app/`:
   ```bash
   cd app
   flutterfire configure
   flutter pub get
   ```
3. Run tests and code analysis:
   ```bash
   flutter analyze
   flutter test
   ```

---

## 📂 Project Structure

```text
RoboRefVolunteerHub/
├── app/                                    # Flutter Web / Android / iOS application
│   ├── lib/
│   │   ├── firebase_options.dart           # Firebase platform config (--dart-define or flutterfire)
│   │   ├── features/
│   │   │   ├── auth_invites/               # Passwordless 6-digit OTP login, onboarding & Firebase Auth state
│   │   │   ├── profile/                    # Qualifications & PII-isolated profile model
│   │   │   ├── events/                     # UK VEX Events search, filter, VEX Events API client
│   │   │   └── volunteering/               # Firestore event signups & roster screen
│   │   └── main.dart                       # Persistent session initialization & reactive auth router
│   └── test/                               # Unit & widget test suites
├── workers/
│   └── auth-otp/                           # Standalone Cloudflare Worker (OTP + Invite Gate + Rate Limiter)
├── firestore.rules                         # Hardened Cloud Firestore Security Rules
├── firestore.indexes.json                  # Firestore index definitions
└── firebase.json                           # Firebase Hosting & Firestore configuration
```

---

## 📄 License

Unofficial community utility for VEX Robotics competitions. VEX, VRC, V5RC, and VIQRC are trademarks of Innovation First International (IFI) / REC Foundation.
