# 🔥 BurnIn — Staff Ordering & Billing App

A **private Flutter app** for staff at Burnin Hotfire burger shop.  
Staff use it to take walk-in orders, generate UPI QR bills, and send them to customers via WhatsApp.

---

## 📁 Project Structure

```
lib/
├── main.dart             — App entry, Firebase init, routing
├── theme/                — Color palette, typography, Material 3 themes
├── models/               — MenuItem, Order, StaffUser, ShopStatus
├── services/             — Firebase, Auth, WhatsApp, QR services
├── screens/              — 8 screens (splash, login, menu, cart, payment, add_item, history, profile)
├── widgets/              — Shared: AppLogo, VegDot, QuantityStepper, PrimaryButton, DateChip
└── providers/            — Riverpod: CartProvider, AuthProvider, ThemeModeProvider
```

---

## 🔧 Setup for a New Deployment

### 1. Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com) → Create project (or use existing).
2. In **Authentication** → Sign-in method → enable **Email/Password**.
3. In **Authentication** → Users → manually add each staff email + password (no public signup).
4. In **Firestore Database** → create a database in production mode.
5. In **Storage** → create a default bucket.
6. Register an **Android app** (package name: `com.burnin.burnin_app`).
7. Download `google-services.json` → place at `android/app/google-services.json`.

### 2. Firestore Collections

Create these collections (they auto-create on first write, but security rules reference them):

| Collection | Purpose |
|---|---|
| `menu_items` | Each document = one menu item |
| `orders` | Each document = one completed order |
| `shop_status` | Doc ID = `YYYY-MM-DD`, fields: `isOpen`, `openedAt`, `closedAt` |

### 3. Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
> Only authenticated (logged-in) staff can read/write. No public access.

### 4. Firebase Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 💳 Set the Shop's UPI ID

Open `lib/services/qr_service.dart` and update:

```dart
static const String kShopUpiId = 'yourshop@upi';   // ← Change this
static const String kShopName  = 'Burnin Hotfire';  // ← Change if needed
```

Any valid UPI address works: `9876543210@paytm`, `name@okaxis`, `name@ybl`, etc.

---

## 🏗 Build a Release APK

```bash
# From the burnin_app/ directory:
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk

# For split APKs (smaller file per architecture):
flutter build apk --split-per-abi --release
```

Sideload the APK on staff Android devices (Settings → Install from unknown sources).

---

## 📱 Screens

| # | Screen | Route |
|---|--------|-------|
| 1 | Splash | `/` |
| 2 | Login  | `/login` |
| 3 | Menu (Home) | `/menu` |
| 4 | Cart + Bill Preview | `/cart` |
| 5 | Payment Mode | `/payment` |
| 6 | Add / Edit Item | `/add-item` |
| 7 | Order History | `/history` |
| 8 | Profile | `/profile` |

---

## 📦 Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management |
| `firebase_core` | ^3.x | Firebase init |
| `firebase_auth` | ^5.x | Staff login |
| `cloud_firestore` | ^5.x | Menu + orders DB |
| `firebase_storage` | ^12.x | Menu photos |
| `hive_flutter` | ^1.1.0 | Offline cache |
| `qr_flutter` | ^4.1.0 | UPI QR code generation |
| `url_launcher` | ^6.x | WhatsApp wa.me link |
| `image_picker` | ^1.x | Camera / gallery |
| `lottie` | ^3.x | Flame burst animation |
| `google_fonts` | ^6.x | Oswald + Inter fonts |

---

## 🔒 Notes

- This is a **private, sideloaded** app — not published on the Play Store.
- No public sign-up. Staff accounts are created manually in the Firebase Console.
- WhatsApp billing uses the free `wa.me` deep link — no WhatsApp Business API required.
- The UPI QR is generated locally on-device using `qr_flutter` — no external service needed.
