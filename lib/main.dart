import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/theme_provider.dart';
import 'screens/add_item/add_item_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/profile/about_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive (offline cache)
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Explicitly configure offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    const ProviderScope(
      child: BurninApp(),
    ),
  );
}

class BurninApp extends ConsumerWidget {
  const BurninApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'BurnIn — Staff Portal',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      // ── Routes ─────────────────────────────────────────────────────
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/login': (ctx) => const LoginScreen(),
        '/menu': (ctx) => const MainScreen(),
        '/cart': (ctx) => const CartScreen(),
        '/payment': (ctx) => const PaymentScreen(),
        '/add-item': (ctx) => const AddItemScreen(),
        '/history': (ctx) => const HistoryScreen(),
        '/profile': (ctx) => const ProfileScreen(),
        '/about': (ctx) => const AboutScreen(),
        '/sales': (ctx) => const SalesScreen(),
      },

      // ── Page transition: warm upward slide ─────────────────────────
      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          '/': (ctx) => const SplashScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/sales': (ctx) => const SalesScreen(),
          '/menu': (ctx) => const MainScreen(),
          '/cart': (ctx) => const CartScreen(),
          '/payment': (ctx) => const PaymentScreen(),
          '/add-item': (ctx) => const AddItemScreen(),
          '/history': (ctx) => const HistoryScreen(),
          '/profile': (ctx) => const ProfileScreen(),
          '/about': (ctx) => const AboutScreen(),
        };

        final builder = routes[settings.name];
        if (builder == null) return null;

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              builder(ctx),
          transitionsBuilder:
              (ctx, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.06);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
