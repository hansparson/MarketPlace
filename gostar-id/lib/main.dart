import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/register_choice_screen.dart';
import 'features/auth/screens/verification_screen.dart';
import 'features/auth/screens/register_success_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
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

    // Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      print('FCM Token refreshed: $fcmToken');
      await ApiService.updateDeviceToken(fcmToken);
    });
  } catch (e) {
    print('Error initializing Firebase/FCM: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GostarID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register-choice': (context) => const RegisterChoiceScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/register-success': (context) => const RegisterSuccessScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
