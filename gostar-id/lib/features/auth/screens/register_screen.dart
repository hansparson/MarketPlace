import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late String role;
  bool isInitialized = false;

  // Form State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Image Picking State
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  XFile? _ktpImage;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isLoading = false;

  // Referral verification state
  String? _verifiedMemberName;
  String? _referralError;
  bool _isVerifyingReferral = false;
  Timer? _referralDebounce;

  // DANA verification state
  bool _isVerifyingDanaPhone = false;
  String? _danaPhoneError;
  bool _isDanaPhoneValid = false;
  Timer? _danaPhoneDebounce;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _referralDebounce?.cancel();
    _danaPhoneDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      role = args?['role'] ?? 'member';
      isInitialized = true;
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = pickedFile;
          } else {
            _ktpImage = pickedFile;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _onReferralChanged(String value) {
    _referralDebounce?.cancel();
    setState(() {
      _verifiedMemberName = null;
      _referralError = null;
    });
    if (value.trim().isEmpty) return;
    _referralDebounce = Timer(const Duration(milliseconds: 800), () {
      _verifyReferral(value.trim());
    });
  }

  Future<void> _verifyReferral(String code) async {
    setState(() {
      _isVerifyingReferral = true;
      _referralError = null;
      _verifiedMemberName = null;
    });
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/auth/verify-referral/$code');
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _verifiedMemberName = data['message_data']['name'];
          _referralError = null;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _referralError = 'Member yang merujuk belum aktif.';
          _verifiedMemberName = null;
        });
      } else {
        setState(() {
          _referralError = 'Kode referral tidak ditemukan.';
          _verifiedMemberName = null;
        });
      }
    } catch (_) {
      setState(() {
        _referralError = 'Gagal memeriksa kode referral.';
        _verifiedMemberName = null;
      });
    } finally {
      if (mounted) setState(() => _isVerifyingReferral = false);
    }
  }

  void _onPhoneChanged(String value) {
    _danaPhoneDebounce?.cancel();
    setState(() {
      _isDanaPhoneValid = false;
      _danaPhoneError = null;
    });
    if (value.trim().isEmpty) return;
    _danaPhoneDebounce = Timer(const Duration(milliseconds: 800), () {
      _verifyDanaPhone(value.trim());
    });
  }

  Future<void> _verifyDanaPhone(String phone) async {
    setState(() {
      _isVerifyingDanaPhone = true;
      _danaPhoneError = null;
      _isDanaPhoneValid = false;
    });
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/auth/verify-dana-phone/$phone');
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final isValid = data['message_data']['is_valid'] ?? false;
        final status = data['message_data']['status'] ?? 'ERROR';
        setState(() {
          if (isValid && status == 'ACTIVE') {
            _isDanaPhoneValid = true;
            _danaPhoneError = null;
          } else if (status == 'UNREGISTERED') {
            _isDanaPhoneValid = false;
            _danaPhoneError = 'Nomor tidak terdaftar di DANA.';
          } else if (status == 'FROZEN') {
            _isDanaPhoneValid = false;
            _danaPhoneError = 'Akun DANA dibekukan.';
          } else {
            _isDanaPhoneValid = false;
            _danaPhoneError = 'Status DANA tidak valid: $status';
          }
        });
      } else {
        setState(() {
          _danaPhoneError = 'Gagal memverifikasi nomor DANA.';
          _isDanaPhoneValid = false;
        });
      }
    } catch (e) {
      debugPrint('DANA verification error: $e');
      setState(() {
        _danaPhoneError = 'Gagal memeriksa nomor DANA: $e';
        _isDanaPhoneValid = false;
      });
    } finally {
      if (mounted) setState(() => _isVerifyingDanaPhone = false);
    }
  }

  Future<void> _submitRegistration() async {
    if (_nameController.text.isEmpty ||
        _nikController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Mohon isi semua data yang wajib.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Kata sandi tidak cocok.');
      return;
    }

    if (!_isDanaPhoneValid) {
      _showError('Nomor telepon harus terverifikasi sebagai nomor DANA aktif.');
      return;
    }

    final bool isReseller = role == 'reseller';
    if (isReseller && _referralController.text.isEmpty) {
      _showError('ID Referensi wajib diisi untuk Reseller.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(isReseller 
        ? '${AppConfig.baseUrl}/auth/register/reseller' 
        : '${AppConfig.baseUrl}/auth/register/member');

      var request = http.MultipartRequest('POST', uri);
      request.fields['name'] = _nameController.text;
      request.fields['nik'] = _nikController.text;
      request.fields['email'] = _emailController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['username'] = _usernameController.text;
      request.fields['password'] = _passwordController.text;

      if (isReseller) {
        request.fields['referral_code'] = _referralController.text;
      }

      if (_profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_image', _profileImage!.path));
      }
      
      if (_ktpImage != null) {
        request.files.add(await http.MultipartFile.fromPath('ktp_image', _ktpImage!.path));
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (mounted) {
          try {
            final data = jsonDecode(respStr);
            final msgData = data['message_data'];
            final paymentUrl = msgData['payment_url'];
            final invoiceNumber = msgData['invoice_number'];
            final userId = (msgData['member'] ?? msgData['reseller'])['id'];
            
            // Save credentials for auto-login after payment
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_phone', _phoneController.text);
            await prefs.setString('pending_password', _passwordController.text);
            
            Navigator.pushNamed(
              context, 
              '/register-success',
              arguments: {
                'payment_url': paymentUrl,
                'invoice_number': invoiceNumber,
                'user_id': userId,
                'role': role,
              },
            );
          } catch (_) {
            Navigator.pushNamed(context, '/register-success');
          }
        }
      } else {
        // Try parse JSON error
        String errMsg = 'Gagal mendaftar.';
        try {
          final data = jsonDecode(respStr);
          if (data['message_data'] != null) {
            errMsg = data['message_data'];
          }
        } catch (_) {}
        _showError('Gagal mendaftar: $errMsg');
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

  @override
  Widget build(BuildContext context) {
    final bool isReseller = role == 'reseller';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            bottom: -100,
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

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        _buildEditorialContext(isReseller),
                        const SizedBox(height: 48),
                        _buildFormCanvas(isReseller),
                        const SizedBox(height: 40),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: isReseller 
                                ? 'Sudah memiliki akun reseller? ' 
                                : 'Sudah memiliki akun member? ',
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                              children: [
                                TextSpan(
                                  text: 'Masuk di sini',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialContext(bool isReseller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRAM MITRA',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bergabunglah dengan Jaringan Sovereign.',
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Dapatkan akses pasar eksklusif, struktur komisi yang kompetitif, dan infrastruktur aman yang dibangun untuk skala profesional.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_outlined, color: AppColors.tertiary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Terverifikasi',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Text(
                      'Kredibilitas instan untuk operasional Anda.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCTeuaC9ZJQx5cE9XRvoaL2qIB6Awz-J7cEFYJdWkr1qzChPw-SiG-zsHJ0Q1m83xzU6nuzRh_mRcVowyObVo2GBqpjmNgU4JLLsAywbwdMHFle2FEDXglRRC38uExCmCsf8HZHBJznDBOg_45fvIfzbmAlm9jjOOKmhC0ZUEr2xGanxauLRVIUEgno_HrWAzdw4z0rsdp-lxZZZ9fCviqo39-JQ_gc9PKGW0PACjGwK_olh7_AKT9JK3CCwQFv6yzqsWSe4sAkxiA'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.primary.withOpacity(0.6)],
              ),
            ),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomLeft,
            child: Text(
              'Pertumbuhan adalah Kolektif.',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCanvas(bool isReseller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Top Accent Line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: AppColors.kineticGradient,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  isReseller ? 'Pendaftaran Reseller' : 'Pendaftaran Member',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lengkapi data diri Anda di bawah ini',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                if (isReseller) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(
                          color: _verifiedMemberName != null
                              ? AppColors.secondary
                              : _referralError != null
                                  ? AppColors.error
                                  : AppColors.tertiary,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VERIFIKASI WAJIB',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _referralController,
                          onChanged: _onReferralChanged,
                          decoration: InputDecoration(
                            hintText: 'ID Referensi (wajib)',
                            fillColor: Colors.white,
                            suffixIcon: _isVerifyingReferral
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _verifiedMemberName != null
                                    ? const Icon(Icons.check_circle, color: AppColors.secondary)
                                    : _referralError != null
                                        ? const Icon(Icons.cancel, color: AppColors.error)
                                        : const Icon(Icons.fingerprint, color: AppColors.outline, size: 24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_verifiedMemberName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, color: AppColors.secondary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DIRUJUK OLEH',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.secondary,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      Text(
                                        _verifiedMemberName!,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_referralError != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _referralError!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'HUBUNGI ANGGOTA YANG MERUJUK ANDA UNTUK ID INI',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // --- Identity Section ---
                _buildSectionHeader('INFORMASI IDENTITAS'),
                const SizedBox(height: 16),
                _buildFormLabel('NAMA LENGKAP'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Sesuai identitas legal (KTP)',
                    fillColor: AppColors.surfaceContainerHigh.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),

                _buildFormLabel('NOMOR KTP'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '16 digit nomor NIK',
                    fillColor: AppColors.surfaceContainerHigh.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 32),

                // --- Contact Section ---
                _buildSectionHeader('INFORMASI KONTAK'),
                const SizedBox(height: 16),
                _buildFormLabel('ALAMAT EMAIL'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'contoh@email.com',
                    fillColor: AppColors.surfaceContainerHigh.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),

                _buildFormLabel('NOMOR TELEPON (DANA)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                  decoration: InputDecoration(
                    hintText: '0812xxxx',
                    fillColor: AppColors.surfaceContainerHigh.withOpacity(0.5),
                    suffixIcon: _isVerifyingDanaPhone
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _isDanaPhoneValid
                            ? const Icon(Icons.check_circle, color: AppColors.secondary)
                            : _danaPhoneError != null
                                ? const Icon(Icons.cancel, color: AppColors.error)
                                : const Icon(Icons.phone_android_outlined, color: AppColors.outline),
                  ),
                ),
                if (_danaPhoneError != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _danaPhoneError!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_isDanaPhoneValid) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Nomor DANA Aktif & Terverifikasi',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // --- Credentials Section ---
                _buildSectionHeader('KEAMANAN AKUN'),
                const SizedBox(height: 16),
                _buildFormLabel('USERNAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'nama_pengguna',
                    fillColor: AppColors.surfaceContainerHigh.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),

                _buildFormLabel('KATA SANDI'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    fillColor: AppColors.surfaceContainerHigh.withOpacity(0.5),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.outline,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildFormLabel('KONFIRMASI KATA SANDI'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    fillColor: AppColors.surfaceContainerHigh.withOpacity(0.5),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.outline,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader('DOKUMEN PENDUKUNG'),
                const SizedBox(height: 16),
                _buildUploadTile('Unggah Foto Profil', Icons.account_circle_outlined, _profileImage, () => _pickImage(true)),
                const SizedBox(height: 12),
                _buildUploadTile('Unggah Foto KTP', Icons.badge_outlined, _ktpImage, () => _pickImage(false)),

                const SizedBox(height: 48),

                // --- Register Button ---
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.kineticGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Daftarkan Akun',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.check_circle_outline, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: AppColors.outlineVariant.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primary.withOpacity(0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUploadTile(String label, IconData icon, XFile? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null ? AppColors.secondary : AppColors.outlineVariant.withOpacity(0.3),
            width: image != null ? 2 : 1,
          ),
          image: image != null 
            ? DecorationImage(
                image: FileImage(File(image.path)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
              )
            : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image == null) ...[
              Icon(icon, color: AppColors.outline.withOpacity(0.7), size: 32),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ] else ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              const Text(
                'BERHASIL DIUNGGAH',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
