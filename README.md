# 🔥 Burnin — Staff Ordering & Billing App

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

## 🔧 Setup & Configuration

### 1. Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com) → Create project (or use existing).
2. In **Authentication** → Sign-in method → enable **Email/Password**.
3. In **Firestore Database** → create a database in production mode.
4. In **Storage** → create a default bucket.
5. Register an **Android app** (package name: `com.burnin.burnin_app`).
6. Download `google-services.json` → place at `android/app/google-services.json`.

### 2. Firestore Collections

The app automatically handles creating these collections upon first interaction:

| Collection | Purpose |
|---|---|
| `menu_items` | Each document = one menu item |
| `orders` | Each document = one completed order |
| `shop_status` | Doc ID = `YYYY-MM-DD`, fields: `isOpen`, `openedAt`, `closedAt` |
| `staff_users`| Each document = one staff user's profile |

### 3. Firebase Security Rules (Deployed via CLI)

To protect your data, robust security rules have been implemented in `firestore.rules`.
These ensure that only authenticated staff members can access or modify your shop's data.

**To deploy the security rules:**
```bash
# Ensure you are logged into Firebase CLI and have the project selected
firebase deploy --only firestore:rules --project burnin-92d79
```

### 4. Firebase Storage Rules

Currently, storage rules should be set in the Firebase Console:
```javascript
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

## 🏗 Building & Icons

### Updating the App Icon
The app uses `flutter_launcher_icons` to manage the icon (set to `assets/images/appicon.png`).
To regenerate the icons after changing the source image, run:
```bash
flutter pub run flutter_launcher_icons
```

### Build a Release APK
To create an APK that can be installed on an Android device:
```bash
# From the burnin_app/ directory:
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
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
| `lottie` | ^3.x | Lottie Animations |
| `flutter_animate` | ^4.5.2 | UI micro-animations |
| `flutter_launcher_icons` | ^0.14.1| App icon generator |
| `google_fonts` | ^6.x | Oswald + Inter fonts |

---

## 🔒 Notes

- This is a **private, sideloaded** app — not published on the Play Store.
- **Login:** The app now supports automatic Username registration on the login screen. It auto-generates a Firebase Auth account behind the scenes so the staff member doesn't need a real email!
- WhatsApp billing uses the free `wa.me` deep link — no WhatsApp Business API required.
- The UPI QR is generated locally on-device using `qr_flutter` — no external service needed.
