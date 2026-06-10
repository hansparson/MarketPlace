import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static final refreshNotifier = ValueNotifier<int>(0);
  static void triggerRefresh() {
    refreshNotifier.value++;
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Budi Santoso';
  String _email = 'budi.santoso@gmail.com';
  String _avatarLetter = 'B';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ProfileScreen.refreshNotifier.addListener(_onRefreshEvent);
  }

  void _onRefreshEvent() {
    if (mounted) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    ProfileScreen.refreshNotifier.removeListener(_onRefreshEvent);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? 'Budi Santoso';
      _email = prefs.getString('email') ?? 'budi.santoso@gmail.com';
      if (_name.isNotEmpty) {
        _avatarLetter = _name[0].toUpperCase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060D1E), AppColors.midnightNavy, Color(0xFF0D1A38)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(context),
                const SizedBox(height: 24),
                _buildMenuSection(context),
                const SizedBox(height: 24),
                _buildLogoutButton(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2A4A), Color(0xFF0A1128)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.sovereignGold.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sovereignGold.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _avatarLetter,
                style: AppTextStyles.h1.copyWith(color: AppColors.sovereignGold),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _name,
            style: AppTextStyles.h2.copyWith(color: AppColors.onSurface),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, size: 14, color: AppColors.sovereignGold),
              const SizedBox(width: 4),
              Text(
                'Member Terverifikasi',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.sovereignGold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            _email,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }



  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.receipt_long_outlined,
        'title': 'Riwayat Transaksi',
        'subtitle': 'Lihat semua pembelian Anda',
        'route': AppRoutes.transactionHistory,
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Bantuan & FAQ',
        'subtitle': 'Pusat bantuan Gostar-Mart',
        'route': AppRoutes.helpFaq,
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Syarat & Ketentuan',
        'subtitle': 'Aturan penggunaan platform',
        'route': AppRoutes.termsConditions,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldBorder, width: 0.5),
        ),
        child: Column(
          children: menuItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.sovereignGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldBorder, width: 0.5),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: AppColors.sovereignGold,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.outlineVariant,
                    size: 18,
                  ),
                  onTap: () {
                    final route = item['route'] as String?;
                    if (route != null) {
                      Navigator.pushNamed(context, route);
                    }
                  },
                ),
                if (i < menuItems.length - 1)
                  Divider(
                    height: 0,
                    thickness: 0.5,
                    color: AppColors.outlineVariant.withOpacity(0.3),
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  'Keluar?',
                  style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                ),
                content: Text(
                  'Anda akan keluar dari akun ini.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Batal',
                      style: AppTextStyles.button.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final fcmToken = await FirebaseMessaging.instance.getToken();
                        if (fcmToken != null && fcmToken.isNotEmpty) {
                          final ApiService apiService = ApiService();
                          await apiService.deleteDeviceToken(fcmToken);
                        }
                      } catch (e) {
                        debugPrint("Error deleting device token on logout: $e");
                      }
                      
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      
                      final AuthService authService = AuthService();
                      await authService.signOut();

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.2),
                      foregroundColor: AppColors.error,
                      elevation: 0,
                    ),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
          label: Text(
            'Keluar dari Akun',
            style: AppTextStyles.button.copyWith(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error.withOpacity(0.4), width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
