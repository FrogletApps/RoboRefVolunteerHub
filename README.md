# RoboRef Volunteer Hub

[![Platform - Flutter](https://img.shields.io/badge/Platform-Flutter%20%7C%20Dart-02569B?logo=flutter)](https://flutter.dev)
[![UI - Material 3](https://img.shields.io/badge/UI-Material%20Design%203-7B1FA2)](https://m3.material.io)
[![State - Riverpod](https://img.shields.io/badge/State-Riverpod%202.x-0553B1)](https://riverpod.dev)

**RoboRef Volunteer Hub** is an unofficial volunteer management and event coordination application built specifically for VEX Robotics competitions (**V5RC**, **VIQRC**, and **VEX U**), initially focused on the **United Kingdom**.

It allows certified volunteers to register via invite codes, declare their certified qualifications, control contact privacy (public phone/email vs. anonymized email forwarding address), and mark themselves as **Available** or **Confirmed** for UK events fetched directly from the official **VEX Events API** (`events.vex.com`).

---

## ✨ Key Features

- 🎟️ **Invite-Only Access**:
  - Gated volunteer registration verifying against a static administrator invite code list (e.g. `UKVEX-2026`, `VEX-REF-UK`, `ROBO-VOL-2026`, `UK-EP-VERIFIED`).
  - Protects event rosters from spam while maintaining an extensible architecture for future user-issued invites.
- 🏅 **Qualification Management**:
  - Track official volunteer roles: **Head Referee**, **Field Referee**, **Judge Advisor**, **Judge**, and **Other** (Field Queuer, TM Operator, Robot Inspection, Emcee).
  - Profile management for certifications and role preferences.
- 🛡️ **Privacy & Email Forwarding Relay**:
  - Volunteers choose between making contact details public (phone or email) or utilizing an anonymized forwarding relay address (`vol-<hash>@volunteer.roboref.app`).
  - Organizers and colleagues can contact volunteers without exposing private phone numbers or personal email inboxes.
- 📅 **Per-Event Availability & Confirmation Tracking**:
  - Volunteers can mark themselves as **Available** (interested/free) or **Confirmed** (committed attendance).
  - **Dynamic Qualified Role Selector**: When signing up for an event, users select potential roles drawn directly from their qualified roles, with the ability to specify custom unlisted roles.
  - **Volunteer Withdrawal**: Volunteers can pull out / withdraw from an event at any time with an instant update to the live roster.
- 🔒 **Event Partner (EP) Verification Checkmark**:
  - Event Partners can formally verify and lock in volunteer role assignments with a prominent **EP Verified** badge.
- 🌐 **UK VEX Events Integration**:
  - Queries upcoming UK tournaments from the official **VEX Events API** (`events.vex.com/api/v2/events`) with caching and fallback resiliency.
  - Search by tournament name, venue, city, or SKU (`RE-V5RC-...`, `RE-VIQRC-...`).
  - Direct **"View on VEX Events"** action button launching `events.vex.com`.
- 📊 **Real-Time Coverage KPI & Roster View**:
  - Breakdown of confirmed vs available volunteers, role fulfillment counts (e.g. Head Ref 1/1, Ref 4/4, Judge 3/6), and segmented filtering.

---

## 🏗 Architecture & Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | **Flutter** (Dart ^3.5.0) | Cross-platform client for Web, Android, and iOS |
| **State Management** | **Riverpod** 2.x | Reactive state and dependency injection |
| **Local Storage** | **SharedPreferences** & **Drift** | Offline session and volunteer signups persistence |
| **UI Design** | **Material Design 3** | RoboRef brand green theme with accessible contrast |
| **External API** | **VEX Events API v2** | `events.vex.com` event data and schedule ingestion |

---

## 🔑 Administrator Invite Codes

The initial release validates against the following static invite codes:

| Code | Role / Privileges |
| :--- | :--- |
| `UKVEX-2026` | Standard UK Volunteer Access |
| `VEX-REF-UK` | Referee & Official Access |
| `ROBO-VOL-2026` | General Volunteer Access |
| `UK-EP-VERIFIED` | Event Partner (EP) Access with Verification & Lock-In Privileges |
| `FROGLET-INVITE-26` | Partner Invite Code |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.5.0` or higher) with Dart `^3.5.0`

### 1. Clone & Install Dependencies
```bash
cd app
flutter pub get
```

### 2. Run the Application
#### Run on Web (Chrome):
```bash
flutter run -d chrome
```

#### Run on Mobile Emulator or Device:
```bash
flutter run
```

### 3. Run Automated Tests
```bash
flutter test
```

### 4. Run Code Analysis
```bash
flutter analyze
```

---

## 📂 Project Structure

```text
RoboRefVolunteerHub/
├── app/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   └── roles.dart              # Role definitions, colors, admin invite codes
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart          # RoboRef Material 3 theme & badge colors
│   │   │   └── utils/
│   │   │       ├── sku_utils.dart          # SKU validation & program resolution (from RoboRef)
│   │   │       ├── event_regions.dart      # UK regions & international taxonomy (from RoboRef)
│   │   │       └── url_utils.dart          # VEX Events external link, mailto & tel launcher
│   │   ├── features/
│   │   │   ├── auth_invites/               # Invite code gate, volunteer registration, auth state
│   │   │   ├── profile/                    # Qualifications & privacy settings (forwarding vs public)
│   │   │   ├── events/                     # UK VEX Events search, filter, VEX Events API client
│   │   │   └── volunteering/               # Event signup, dynamic role picker, roster & EP verification
│   │   └── main.dart                       # Entry point with invite-gated routing
│   ├── test/
│   │   ├── invite_auth_test.dart           # Invite code validation & auth session tests
│   │   ├── models_test.dart                # Volunteer, signup & event model tests
│   │   ├── roster_test.dart                # Event signup, withdrawal & EP verification tests
│   │   ├── sku_utils_test.dart             # SKU regex & URL launcher tests
│   │   └── widget_test.dart                # App smoke & InviteGateScreen widget tests
│   └── pubspec.yaml
└── README.md
```

---

## 📄 License

Unofficial community utility for VEX Robotics competitions. VEX, VRC, V5RC, and VIQRC are trademarks of Innovation First International (IFI) / REC Foundation.
