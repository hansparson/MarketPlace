import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import '../../../../core/config/app_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _stats;
  String _name = '';
  String _role = '';
  String _photoUrl = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final stats = await ApiService.getStats();
    final profile = await ApiService.getProfile();
    
    String fetchedPhotoUrl = prefs.getString('photo_url') ?? '';
    if (profile != null) {
      final imgKey = (profile['profile_image'] ?? '').toString();
      if (imgKey.isNotEmpty) {
        fetchedPhotoUrl = ApiService.getImageUrl(imgKey);
        await prefs.setString('photo_url', fetchedPhotoUrl);
      }
    }

    setState(() {
      _name = prefs.getString('name') ?? prefs.getString('username') ?? 'Pengguna';
      _role = prefs.getString('role') ?? '';
      _photoUrl = fetchedPhotoUrl;
      _stats = stats;
      _loading = false;
    });
  }

  String _formatRupiah(dynamic value) {
    final n = (value is num) ? value.toInt() : 0;
    final s = n.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return 'Rp ${buf.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 40),
                  _buildStatsBento(),
                  const SizedBox(height: 32),
                  _buildReferralCard(),
                  const SizedBox(height: 24),
                  _buildAccountInfo(),
                  const SizedBox(height: 24),
                  _buildActions(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final isReseller = _role == 'RESELLER';
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.15),
            backgroundImage: _photoUrl.isNotEmpty 
                ? NetworkImage(_photoUrl.startsWith('http') ? _photoUrl : '${AppConfig.imageBaseUrl}/$_photoUrl')
                : null,
            child: _photoUrl.isEmpty
              ? Text(
                  _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                  style: GoogleFonts.manrope(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white),
                )
              : null,
          ),
        ),
        const SizedBox(height: 24),
        Text(_name,
            style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800,
                color: AppColors.primary, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary.withOpacity(0.1)),
          ),
          child: Text(
            isReseller ? 'RESELLER' : 'MEMBER',
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                letterSpacing: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBento() {
    final total = _stats?['total_commission'] ?? 0;
    final leads = _stats?['total_leads'] ?? 0;
    return Row(
      children: [
        Expanded(
          child: _statsCard(
            icon: Icons.payments,
            iconColor: AppColors.secondary,
            label: 'TOTAL KOMISI',
            value: _formatRupiah(total),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statsCard(
            icon: Icons.people_outline,
            iconColor: AppColors.tertiary,
            label: 'TOTAL LEADS',
            value: '$leads',
            borderColor: AppColors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _statsCard({required IconData icon, required Color iconColor,
      required String label, required String value, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border(left: BorderSide(color: borderColor, width: 4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 24, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.outline, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildReferralCard() {
    final code = _stats?['referral_code'] ?? '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.kineticGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KODE REFERRAL SAYA',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800,
                  color: Colors.white70, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(code,
              style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 6),
          Text('Bagikan kode ini untuk mendapatkan komisi tambahan',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    final referralCode = _stats?['referral_code'] ?? '-';
    final available = _stats?['available_balance'] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('INFORMASI AKUN',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900,
                    color: AppColors.primary.withOpacity(0.5), letterSpacing: 2)),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainerLow),
          _infoTile(icon: Icons.person_outline, label: 'Peran', value: _role),
          const Divider(height: 1, color: AppColors.surfaceContainerLow),
          _infoTile(icon: Icons.qr_code_outlined, label: 'Kode Referral', value: referralCode),
          const Divider(height: 1, color: AppColors.surfaceContainerLow),
          _infoTile(icon: Icons.account_balance_wallet_outlined, label: 'Saldo Tersedia', value: _formatRupiah(available)),
        ],
      ),
    );
  }

  Widget _infoTile({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.outline, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.outline, fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        _actionItem(
          icon: Icons.person_outline,
          title: 'Edit Profil',
          onTap: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
            if (updated == true) _loadData(); // refresh name/data after save
          },
        ),
        const SizedBox(height: 12),
        _actionItem(
          icon: Icons.settings_outlined,
          title: 'Pengaturan',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          },
          style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 56), foregroundColor: AppColors.error),
          child: Text('KELUAR',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        ),
      ],
    );
  }

  Widget _actionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary))),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
