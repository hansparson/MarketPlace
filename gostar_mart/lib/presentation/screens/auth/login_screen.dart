import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _glowAnim = Tween<double>(begin: 0.1, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  final AuthService _authService = AuthService();
  bool _isLoggingIn = false;

  Future<void> _onGoogleSignIn() async {
    if (_isLoggingIn) return;
    
    setState(() => _isLoggingIn = true);
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        final email = userCredential.user?.email ?? '';
        final googleId = userCredential.user?.uid ?? '';
        
        // Simpan data login Google ke Backend Golang
        final ApiService apiService = ApiService();
        final response = await apiService.loginGoogle(googleId, email);
        
        final data = response['data'];
        final String clientId = data['id'] ?? '';
        
        bool isProfileComplete = false;
        
        // Helper function to extract string from NullString or direct string
        String extractString(dynamic field) {
          if (field == null) return '';
          if (field is String) return field;
          if (field is Map) {
            if (field['Valid'] == true) {
              return field['String'] ?? '';
            }
          }
          return '';
        }
        
        final name = extractString(data['name']);
        final phone = extractString(data['phone']);
        
        if (name.isNotEmpty && phone.isNotEmpty) {
          isProfileComplete = true;
        }
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('clientId', clientId);
        await prefs.setString('email', email);
        await prefs.setString('name', name);
        await prefs.setString('phone', phone);
        
        // Get FCM token and register it
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await apiService.updateDeviceToken(clientId, fcmToken);
          }
        } catch (e) {
          debugPrint("Failed to register device token on login: $e");
        }
        
        if (mounted) {
          if (isProfileComplete) {
            Navigator.pushReplacementNamed(context, AppRoutes.main);
          } else {
            Navigator.pushReplacementNamed(
              context, 
              AppRoutes.onboarding,
              arguments: {'clientId': clientId, 'email': email},
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal masuk: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF060D1E),
                  AppColors.midnightNavy,
                  Color(0xFF0D1A38),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Top ambient glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sovereignGold.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom ambient glow
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0F2B5C).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Sparkles backdrop
          Positioned.fill(
            child: CustomPaint(
              painter: SparklePainter(),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.08),
                      _buildBrandHeader(),
                      SizedBox(height: size.height * 0.06),
                      _buildLoginCard(context),
                      const SizedBox(height: 32),
                      Text(
                        'Dengan masuk, Anda menyetujui\nSyarat & Ketentuan dan Kebijakan Privasi Gostar-Mart.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.outline,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, child) {
            return Container(
              width: 155,
              height: 155,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.sovereignGold.withOpacity(_glowAnim.value),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sovereignGold.withOpacity(_glowAnim.value * 0.8),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/gostar-mart-logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'EXCLUSIVE MARKETPLACE FOR MEMBERS',
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.sovereignGold,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.sovereignGold.withOpacity(0.15),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sovereignGold.withOpacity(0.03),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang',
                  style: AppTextStyles.h2.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk mengakses marketplace eksklusif Anda.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.outlineVariant.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'MASUK DENGAN',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.outline,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.outlineVariant.withOpacity(0.3),
                        thickness: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _GoogleSignInButton(
                  onTap: _onGoogleSignIn,
                  isLoading: _isLoggingIn,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Sign-In Button ─────────────────────────────────────────────────
class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _GoogleSignInButton({required this.onTap, required this.isLoading});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _btnAnimController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _btnAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _btnAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _btnAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => widget.isLoading ? null : _btnAnimController.forward(),
        onTapUp: (_) {
          _btnAnimController.reverse();
          if (!widget.isLoading) widget.onTap();
        },
        onTapCancel: () => _btnAnimController.reverse(),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceContainerHigh.withOpacity(0.8),
                AppColors.surfaceContainerLow.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.sovereignGold.withOpacity(0.3),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sovereignGold.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.sovereignGold),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google-logo.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lanjutkan dengan Google',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Sparkle Painter ────────────────────────────────────────────────────────
class SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sovereignGold.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    void drawSparkle(Offset center, double size) {
      final path = Path()
        ..moveTo(center.dx, center.dy - size)
        ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
        ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
        ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
        ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
        ..close();
      
      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..color = AppColors.sovereignGold.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center, size * 0.6, glowPaint);
    }

    drawSparkle(const Offset(40, 100), 10);
    drawSparkle(const Offset(310, 160), 7);
    drawSparkle(const Offset(70, 380), 9);
    drawSparkle(const Offset(330, 540), 12);
    drawSparkle(const Offset(50, 680), 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


