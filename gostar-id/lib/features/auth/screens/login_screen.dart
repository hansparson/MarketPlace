import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isReseller = false;
  bool rememberMe = false;
  bool obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool savedRememberMe = prefs.getBool('remember_me') ?? false;
      if (savedRememberMe) {
        setState(() {
          rememberMe = true;
          _phoneController.text = prefs.getString('saved_phone') ?? '';
          _passwordController.text = prefs.getString('saved_password') ?? '';
          isReseller = prefs.getBool('saved_is_reseller') ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error loading saved credentials: $e");
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Mohon isi nomor telepon dan kata sandi.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(isReseller 
        ? '${AppConfig.baseUrl}/auth/login/reseller' 
        : '${AppConfig.baseUrl}/auth/login/member');



      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['message_data']['user'];
        final status = user['status'];
        final prefs = await SharedPreferences.getInstance();

        if (rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('saved_phone', _phoneController.text);
          await prefs.setString('saved_password', _passwordController.text);
          await prefs.setBool('saved_is_reseller', isReseller);
        } else {
          await prefs.remove('remember_me');
          await prefs.remove('saved_phone');
          await prefs.remove('saved_password');
          await prefs.remove('saved_is_reseller');
        }

        if (status == 'PENDING') {
          await prefs.setString('pending_user_id', user['id'].toString());
          await prefs.setString('pending_role', data['message_data']['role'].toString());
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/register-success',
              arguments: {
                'user_id': user['id'].toString(),
                'role': data['message_data']['role'].toString(),
              },
            );
          }
        } else if (status == 'ACTIVE') {
          // Save token and role
          await prefs.setString('token', data['message_data']['token']);
          await prefs.setString('role', data['message_data']['role']);
          // Save name for profile display
          final userName = (data['message_data']['user']?['name'] ?? '').toString();
          if (userName.isNotEmpty) await prefs.setString('name', userName);
          
          final photoUrl = (data['message_data']['user']?['photo_url'] ?? '').toString();
          if (photoUrl.isNotEmpty) await prefs.setString('photo_url', photoUrl);
          
          // Get FCM token and register it
          try {
            final fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null && fcmToken.isNotEmpty) {
              await ApiService.updateDeviceToken(fcmToken);
            }
          } catch (e) {
            debugPrint("Error registering FCM token on login: $e");
          }

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          _showError('Akun Anda tidak aktif atau diblokir.');
        }
      } else {
        String errMsg = data['message_data'] ?? 'Gagal masuk.';
        _showError(errMsg);
      }
    } catch (e) {
      _showError('Terjadi kesalahan koneksi.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  // Active Role Colors
  Color get activeRoleColor => isReseller ? AppColors.tertiaryFixed : AppColors.secondary;
  Color get activeOnRoleColor => isReseller ? Colors.black87 : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Decorations
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withOpacity(0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeRoleColor.withOpacity(0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Header Section with Logo
                  Column(
                    children: [
                      // Brand Logo
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/gostar-id-logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.stars_rounded, size: 80, color: AppColors.primary);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'GostarID',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeRoleColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: activeRoleColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isReseller ? '[RESELLER]' : '[ANGGOTA]',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isReseller ? AppColors.primary : AppColors.secondary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Masuk ke portal Anda',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Masuk dengan aman ke ruang kerja profesional Anda',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onSurface.withOpacity(0.05),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Type Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            children: [
                              // Sliding Background
                              AnimatedAlign(
                                alignment: isReseller ? Alignment.centerRight : Alignment.centerLeft,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutBack,
                                child: FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ToggleItem(
                                      label: 'Anggota',
                                      isActive: !isReseller,
                                      activeColor: AppColors.secondary,
                                      onTap: () => setState(() => isReseller = false),
                                    ),
                                  ),
                                  Expanded(
                                    child: _ToggleItem(
                                      label: 'Reseller',
                                      isActive: isReseller,
                                      activeColor: AppColors.tertiaryFixed,
                                      onTap: () => setState(() => isReseller = true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Form Fields
                        _Label(text: 'NAMA PENGGUNA'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Masukkan ID Anda',
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(Icons.person_outline, color: AppColors.outline, size: 22),
                            ),
                          ),
                        ),


                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Label(text: 'KATA SANDI'),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Lupa Kata Sandi?',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: activeRoleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(Icons.lock_outline, color: AppColors.outline, size: 22),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.outline,
                                size: 20,
                              ),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),


                        const SizedBox(height: 20),

                        // Remember Me
                        GestureDetector(
                          onTap: () => setState(() => rememberMe = !rememberMe),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: rememberMe ? activeRoleColor : AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: rememberMe 
                                  ? Icon(Icons.check, size: 14, color: activeOnRoleColor)
                                  : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ingat perangkat ini',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action Button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isReseller 
                                ? [const Color(0xFFFFD700), AppColors.tertiaryFixed]
                                : [AppColors.secondary, AppColors.onSecondaryContainer],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeRoleColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoading)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(activeOnRoleColor),
                                      ),
                                    ),
                                  ),
                                Text(
                                  _isLoading ? 'Sedang Masuk...' : 'Masuk ke GostarID',
                                  style: TextStyle(color: activeOnRoleColor, fontWeight: FontWeight.bold),
                                ),
                                if (!_isLoading) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20, color: activeOnRoleColor),
                                ],
                              ],
                            ),
                          ),

                        ),

                        const SizedBox(height: 24),

                        // Bottom Action
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: AppColors.outlineVariant.withOpacity(0.2),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Baru di platform ini?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pushNamed(context, '/register-choice'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Daftar Akun Baru',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Trust Indicator
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Badge(text: 'TERENKRIPSI'),
                          const SizedBox(width: 24),
                          _Badge(text: 'TERVERIFIKASI'),
                          const SizedBox(width: 24),
                          _Badge(text: 'AMAN'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '© 2024 Jaringan GostarID. Hak cipta dilindungi undang-undang.',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : AppColors.onSurfaceVariant.withOpacity(0.6),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface.withOpacity(0.4),
        letterSpacing: 2,
      ),
    );
  }
}
