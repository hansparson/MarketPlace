import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _isLoading = false;
  bool _referralValid = false;
  String? _referralError;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _referralCtrl.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _validateReferral(String val) {
    // TODO: Call API to validate referral code
    setState(() {
      _referralValid = val.length >= 6;
      _referralError = val.isEmpty
          ? null
          : val.length < 6
              ? 'Kode referral minimal 6 karakter'
              : null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_referralValid) {
      setState(() => _referralError = 'Masukkan kode referral yang valid');
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String clientId = args?['clientId'] ?? '';

    if (clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi tidak valid. Silahkan login kembali.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final ApiService apiService = ApiService();
      await apiService.completeProfile(
        clientId,
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _referralCtrl.text.trim(),
      );
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _nameCtrl.text.trim());
      await prefs.setString('phone', _phoneCtrl.text.trim());
      await prefs.setString('referralCode', _referralCtrl.text.trim());

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _referralError = e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060D1E), AppColors.midnightNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Header
                  _buildHeader(),

                  const SizedBox(height: 40),

                  // Progress indicator
                  _buildProgressBar(),

                  const SizedBox(height: 40),

                  // Form fields
                  _buildLabel('Nama Lengkap'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameCtrl,
                    hint: 'Masukkan nama lengkap Anda',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),

                  const SizedBox(height: 24),

                  _buildLabel('Nomor WhatsApp'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneCtrl,
                    hint: 'Contoh: 08123456789',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nomor WhatsApp wajib diisi';
                      if (v.length < 10) return 'Nomor tidak valid';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Referral code field with special glow treatment
                  _buildLabel('Kode Referral'),
                  const SizedBox(height: 4),
                  Text(
                    'Wajib diisi. Dapatkan kode dari member atau reseller Gostar.',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildReferralField(),

                  const SizedBox(height: 40),

                  // Submit button
                  _buildSubmitButton(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lengkapi\nProfil Anda',
          style: AppTextStyles.h1.copyWith(color: AppColors.onSurface, height: 1.2),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 48,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.sovereignGold, Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Data ini diperlukan untuk mengaktifkan akses marketplace Anda.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LANGKAH 1 DARI 1',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.outlineVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 1.0,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.sovereignGold, Color(0xFFF5D170)],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildReferralField() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _referralValid
                ? [
                    BoxShadow(
                      color: AppColors.sovereignGold.withOpacity(0.2 * _glowAnim.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: child,
        );
      },
      child: TextFormField(
        controller: _referralCtrl,
        textCapitalization: TextCapitalization.characters,
        style: AppTextStyles.bodyMd.copyWith(
          color: _referralValid ? AppColors.sovereignGold : AppColors.onSurface,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
        onChanged: _validateReferral,
        decoration: InputDecoration(
          hintText: 'Contoh: GST-ABC123',
          hintStyle: AppTextStyles.bodySm.copyWith(
            color: AppColors.outline,
            letterSpacing: 1,
          ),
          prefixIcon: const Icon(Icons.key_outlined, size: 20),
          suffixIcon: _referralValid
              ? const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 20)
              : null,
          errorText: _referralError,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _referralValid
                  ? AppColors.sovereignGold.withOpacity(0.6)
                  : AppColors.outlineVariant,
              width: _referralValid ? 1.5 : 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.sovereignGold, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sovereignGold,
          foregroundColor: AppColors.midnightNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.midnightNavy),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aktifkan Akun Saya',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}
