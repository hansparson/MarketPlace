import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _phoneVerified = false;
  int _bioLength = 0;

  String _username = '';
  String _phone = '';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      setState(() => _bioLength = _bioController.text.length);
    });
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Safely extract string from dynamic — handles both String and Map (NullString artifact)
  String _safeStr(dynamic val) {
    if (val == null) return '';
    if (val is String) return val;
    if (val is Map) return (val['String'] ?? '').toString(); // fallback for sql.NullString JSON
    return val.toString();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await ApiService.getProfile();
    if (profile != null && mounted) {
      final imgKey = _safeStr(profile['profile_image']);
      setState(() {
        _nameController.text = _safeStr(profile['name']);
        _emailController.text = _safeStr(profile['email']);
        _bioController.text = _safeStr(profile['bio']);
        _bioLength = _bioController.text.length;
        _username = _safeStr(profile['username']);
        _phone = _safeStr(profile['phone']);
        _phoneVerified = profile['phone_verified'] == true;
        _profileImageUrl = imgKey.isNotEmpty ? ApiService.getImageUrl(imgKey) : '';
        _loading = false;
      });
    } else {
      // API gagal — tampilkan pesan error
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal memuat profil. Pastikan backend berjalan.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }
    setState(() => _saving = true);
    final success = await ApiService.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      bio: _bioController.text.trim(),
    );
    setState(() => _saving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil berhasil disimpan!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true); // return true → trigger refresh in ProfilePage
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan. Coba lagi.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _verifyPhone() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Verifikasi Nomor', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nomor telepon yang akan diverifikasi:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.outline)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text('+62 $_phone', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Konfirmasi bahwa nomor ini adalah nomor aktif Anda.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Verifikasi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.verifyPhone();
    if (!mounted) return;
    if (success) {
      setState(() => _phoneVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Nomor telepon berhasil diverifikasi!'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTopAppBar(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          children: [
                            _buildProfilePictureSection(),
                            const SizedBox(height: 32),
                            _buildFormFields(),
                            const SizedBox(height: 140),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomActionBar(),
              ],
            ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
      color: AppColors.background,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Edit Profil',
            style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.surfaceContainer,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _profileImageUrl.isNotEmpty
                    ? Image.network(
                        _profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),
            // Shield badge — photo from registration, read-only
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.secondary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Foto dari proses pendaftaran',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
        ),
        const SizedBox(height: 4),
        Text(
          'Foto profil diambil dari selfie saat registrasi',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.outlineVariant),
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    final initial = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?';
    return Container(
      color: AppColors.secondary.withOpacity(0.15),
      child: Center(
        child: Text(initial,
            style: GoogleFonts.manrope(
                fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.secondary)),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // ── Nama Lengkap ──
        _editableField(
          label: 'NAMA LENGKAP',
          controller: _nameController,
          icon: Icons.person_outline,
          hint: 'Nama lengkap Anda',
        ),
        const SizedBox(height: 20),

        // ── Username (READ-ONLY, permanent) ──
        _readonlyField(
          label: 'NAMA PENGGUNA',
          value: _username,
          prefix: '@',
          badge: 'Permanen',
          badgeColor: AppColors.tertiary,
          tooltip: 'Username tidak dapat diubah setelah pendaftaran',
        ),
        const SizedBox(height: 20),

        // ── Email ──
        _editableField(
          label: 'ALAMAT EMAIL',
          controller: _emailController,
          icon: Icons.mail_outline,
          hint: 'email@anda.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // ── Nomor Telepon (with verify) ──
        _buildPhoneField(),
        const SizedBox(height: 20),

        // ── Bio ──
        _buildBioField(),
      ],
    );
  }

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle()),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.outlineVariant),
                suffixIcon: Icon(icon, color: AppColors.outlineVariant, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readonlyField({
    required String label,
    required String value,
    String prefix = '',
    required String badge,
    required Color badgeColor,
    String tooltip = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(
        leftBorder: BorderSide(color: badgeColor, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: _labelStyle()),
              const SizedBox(width: 8),
              Tooltip(
                message: tooltip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(badge,
                      style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: badgeColor, letterSpacing: 0.8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (prefix.isNotEmpty)
                  Text(prefix,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.outlineVariant, fontWeight: FontWeight.w600)),
                if (prefix.isNotEmpty) const SizedBox(width: 4),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: value.isNotEmpty ? AppColors.onSurface.withOpacity(0.6) : AppColors.outlineVariant,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.lock_outline, size: 16, color: AppColors.outlineVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NOMOR TELEPON', style: _labelStyle()),
              if (_phoneVerified)
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.secondary, size: 14),
                    const SizedBox(width: 4),
                    Text('Terverifikasi',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.secondary)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('+62',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.outline)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_phone,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500)),
                      ),
                      const Icon(Icons.lock_outline, size: 16, color: AppColors.outlineVariant),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Verify Banner (only if NOT verified) ──
          if (!_phoneVerified) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _verifyPhone,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nomor belum diverifikasi. Tap untuk verifikasi.',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.amber.shade700, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBioField() {
    const maxBio = 250;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BIO SINGKAT', style: _labelStyle()),
              Text(
                '$_bioLength/$maxBio',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _bioLength > maxBio ? AppColors.error : AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: maxBio,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface, height: 1.6),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Ceritakan sedikit tentang diri Anda...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.outlineVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withOpacity(0),
              AppColors.background.withOpacity(0.95),
              AppColors.background,
            ],
          ),
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor: AppColors.secondary.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Simpan Perubahan',
                          style: GoogleFonts.manrope(
                              fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({BorderSide? leftBorder}) {
    return BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      border: leftBorder != null ? Border(left: leftBorder) : null,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 16, offset: const Offset(0, 4)),
      ],
    );
  }

  TextStyle _labelStyle() => GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary, letterSpacing: 1.5);
}
