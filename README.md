# 🔥 Burnin — Staff Ordering & Billing App

A **private Flutter app** for staff at Burnin Hotfire burger shop.  
Staff use it to take walk-in orders, generate UPI QR bills, and send them to customers via WhatsApp.

---

## 📁 Project Structure

```
lib/
├── main.dart             — App entry, Firebase init, offline cache, routing
├── theme/                — Color palette (Flame Gradients), typography, Material 3 themes
├── models/               — MenuItem, Order, StaffUser, ShopStatus
├── services/             — Firebase, Auth, WhatsApp, QR, Notification & Networking services
├── screens/              — App screens (Splash, Login, Menu, Cart, Payment, AddItem, History, Profile, Sales, About)
├── widgets/              — Shared UI: AppLogo, VegDot, QuantityStepper, FireBeamAvatar, DateChip
└── providers/            — Riverpod: Cart, Auth, Theme, Connectivity & Notifications
```

---

## 🔧 Setup & Configuration

### 1. Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com) → Create project.
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
# Before building, ensure gradle has enough memory if you face OOM crashes
# Open android/gradle.properties and set: org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m

# From the burnin_app/ directory:
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```
Sideload the APK on staff Android devices (Settings → Install from unknown sources).

---

## 📱 Screens & Routing

The app utilizes Flutter's native Named Routes for smooth, slide-and-fade transitions.

| # | Screen | Route | Description |
|---|--------|-------|-------------|
| 1 | **Splash** | `/` | Cinematic video intro with smart auth redirection (`video_player`) |
| 2 | **Login** | `/login` | Staff auth with keyboard-aware animations |
| 3 | **Menu** (Home) | `/menu` | Real-time POS menu with sticky Cart bar |
| 4 | **Cart** | `/cart` | Item review & WhatsApp bill generation |
| 5 | **Payment** | `/payment` | UPI QR rendering & order completion |
| 6 | **Add Item** | `/add-item` | Add/Edit items to the global menu via Firebase Storage |
| 7 | **History** | `/history` | Daily order logs grouped by date |
| 8 | **Profile** | `/profile` | Staff settings, local avatar caching (`shared_preferences`) |
| 9 | **Sales** | `/sales` | Visual charts (`fl_chart`) & revenue breakdown |
| 10| **About** | `/about` | Private app info & branding |

---

## 📦 Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management |
| `firebase_core/auth/storage` | ^5.x | Firebase Suite |
| `cloud_firestore` | ^5.6.7 | Real-time database with offline persistence |
| `hive_flutter` | ^1.1.0 | Offline cache storage |
| `shared_preferences` | ^2.5.3 | Local preferences & Profile Avatar caching |
| `qr_flutter` | ^4.1.0 | On-device UPI QR Code generation |
| `url_launcher` | ^6.3.1 | WhatsApp deep linking (`wa.me`) |
| `flutter_local_notifications`| ^18.0.1| Order alerts and daily reminders |
| `image_picker` | ^1.1.2 | Camera / gallery for Menu items and Avatars |
| `video_player` | ^2.9.2 | Cinematic Splash Screen video playback |
| `fl_chart` | ^1.2.0 | Revenue and sales analytics charting |
| `flutter_animate` | ^4.5.2 | UI micro-animations and physics |
| `lottie` & `confetti` | ^3.x | Visual celebratory animations |

---

## 🔒 Notes & Architecture

- **Offline Support:** Firestore offline persistence is enabled explicitly. The app handles network disconnections gracefully using `connectivity_plus` and caches crucial data.
- **Auto-Registration:** Staff accounts are auto-registered using their inputted name to bypass strict email workflows while remaining secure.
- **WhatsApp Billing:** Uses the free `wa.me` deep link — no WhatsApp Business API required.
- **Memory Optimization:** Gradle daemon properties (`android/gradle.properties`) have been tuned to prevent `Out of Memory` (OOM) crashes during heavy release builds on Windows.
- **Local Storage:** Avatar images are encoded in Base64 and stored locally via `SharedPreferences` to instantly load the Profile UI without fetching from Firebase Storage.
