import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/config/firebase_config.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/main_shell.dart';
import 'presentation/screens/profile/transaction_history_screen.dart';
import 'presentation/screens/profile/help_faq_screen.dart';
import 'presentation/screens/profile/terms_conditions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set orientasi & status bar
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Inisialisasi Firebase secara manual
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );
    print("Firebase Initialized Successfully (Manual Config)");
    
    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
    
    // Enable foreground notifications
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    final token = await messaging.getToken();
    print('FCM Token: $token');

    // Register token refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      print('FCM Token refreshed: $fcmToken');
      final prefs = await SharedPreferences.getInstance();
      final clientId = prefs.getString('clientId');
      if (clientId != null && clientId.isNotEmpty) {
        final ApiService apiService = ApiService();
        await apiService.updateDeviceToken(clientId, fcmToken);
      }
    });
  } catch (e) {
    print("Firebase/FCM initialization error: $e");
  }

  runApp(const GostarMartApp());
}

class GostarMartApp extends StatelessWidget {
  const GostarMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gostar-Mart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.main: (_) => const MainShell(),
        AppRoutes.transactionHistory: (_) => const TransactionHistoryScreen(),
        AppRoutes.helpFaq: (_) => const HelpFaqScreen(),
        AppRoutes.termsConditions: (_) => const TermsConditionsScreen(),
      },
    );
  }
}
