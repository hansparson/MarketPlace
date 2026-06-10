import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterSuccessScreen extends StatefulWidget {
  const RegisterSuccessScreen({super.key});

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _paymentUrl;
  String? _invoiceNumber;
  String? _userId;
  String? _role;
  String _paymentStatus = 'PENDING'; // 'PENDING', 'PAID', 'FAILED'
  Timer? _statusTimer;
  bool _argsLoaded = false;
  int? _paymentAmount;
  bool _isProcessingSuccess = false;

  String _formatCurrency(int amount) {
    final value = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      buffer.write(value[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusImmediately();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _paymentUrl = args['payment_url'];
        _invoiceNumber = args['invoice_number'];
        _userId = args['user_id'];
        _role = args['role'];
      }
      _argsLoaded = true;

      _initializeDetails();
    }
  }

  Future<void> _initializeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Fallback to shared preferences if args are missing
    if (_userId == null) {
      _userId = prefs.getString('pending_user_id');
      _role = prefs.getString('pending_role');
    } else {
      // Save it for future visits/refreshes
      await prefs.setString('pending_user_id', _userId!);
      if (_role != null) {
        await prefs.setString('pending_role', _role!);
      }
    }

    if (_userId != null) {
      // Fetch details from backend immediately
      final statusData = await ApiService.checkRegistrationStatus(_userId!);
      if (statusData != null) {
        final status = statusData['status'];
        if (mounted) {
          setState(() {
            _paymentStatus = status ?? 'PENDING';
            _paymentUrl = statusData['payment_url'];
            _invoiceNumber = statusData['invoice_number'];
            _paymentAmount = statusData['amount'] != null ? (statusData['amount'] as num).toInt() : null;
          });
        }
        if (status == 'PAID' || status == 'SUCCESS') {
          _handleSuccessfulPayment();
          return;
        }
      }
      _startPollingStatus();
    }
  }

  Future<void> _checkStatusImmediately() async {
    if (_userId == null || _isProcessingSuccess) return;
    final statusData = await ApiService.checkRegistrationStatus(_userId!);
    if (statusData != null) {
      final status = statusData['status'];
      if (status != null) {
        if (mounted) {
          setState(() {
            _paymentStatus = status;
            _paymentAmount = statusData['amount'] != null ? (statusData['amount'] as num).toInt() : null;
          });
        }
        if (status == 'PAID' || status == 'SUCCESS') {
          _statusTimer?.cancel();
          _handleSuccessfulPayment();
        }
      }
    }
  }

  void _startPollingStatus() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_userId == null || _isProcessingSuccess) return;
      final statusData = await ApiService.checkRegistrationStatus(_userId!);
      if (statusData != null) {
        final status = statusData['status'];
        if (status != null && status != _paymentStatus) {
          if (mounted) {
            setState(() {
              _paymentStatus = status;
              _paymentAmount = statusData['amount'] != null ? (statusData['amount'] as num).toInt() : null;
            });
          }
          if (status == 'PAID' || status == 'SUCCESS') {
            timer.cancel();
            _handleSuccessfulPayment();
          }
        }
      }
    });
  }

  Future<void> _handleSuccessfulPayment() async {
    if (_isProcessingSuccess) return;
    _isProcessingSuccess = true;

    // Show a beautiful loading/success dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: AppColors.secondary),
                const SizedBox(height: 24),
                Text(
                  'Pembayaran Berhasil!',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mempersiapkan akun Anda...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('pending_phone');
    final password = prefs.getString('pending_password');

    if (phone != null && password != null) {
      try {
        final isReseller = _role == 'RESELLER';
        final loginUri = Uri.parse(isReseller
            ? '${AppConfig.baseUrl}/auth/login/reseller'
            : '${AppConfig.baseUrl}/auth/login/member');

        final response = await http.post(
          loginUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final user = data['message_data']['user'];
          
          await prefs.setString('token', data['message_data']['token']);
          await prefs.setString('role', data['message_data']['role']);
          
          final userName = (user?['name'] ?? '').toString();
          if (userName.isNotEmpty) await prefs.setString('name', userName);
          
          final photoUrl = (user?['photo_url'] ?? '').toString();
          if (photoUrl.isNotEmpty) await prefs.setString('photo_url', photoUrl);

          await prefs.remove('pending_phone');
          await prefs.remove('pending_password');
          await prefs.remove('pending_user_id');
          await prefs.remove('pending_role');

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // Close dialog
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          }
          return;
        }
      } catch (e) {
        print('Error during background login: $e');
      }
    }

    // Fallback: if credentials don't exist or login failed, redirect to login page
    await prefs.remove('pending_user_id');
    await prefs.remove('pending_role');
    
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran Terverifikasi! Silakan masuk ke akun Anda.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSuccessIcon(),
              const SizedBox(height: 32),
              _buildHeadline(),
              const SizedBox(height: 24),
              _buildDescription(),
              const SizedBox(height: 48),
              _buildStatusCard(),
              const SizedBox(height: 48),
              _buildEditorialVisual(),
              const SizedBox(height: 48),
              _buildActionArea(),
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.verified_user,
        size: 32,
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pendaftaran\nBerhasil!',
          style: GoogleFonts.manrope(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Terima kasih telah bergabung dengan Jaringan GostarID.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final bool isPaid = _paymentStatus == 'PAID' || _paymentStatus == 'SUCCESS';
    final bool hasPayment = _paymentUrl != null;

    if (hasPayment && !isPaid) {
      return Text(
        'Akun Anda telah dibuat! Silakan lakukan pembayaran registrasi DANA untuk mengaktifkan akun Anda. Aplikasi akan aktif secara otomatis setelah pembayaran berhasil.',
        style: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.onSurfaceVariant,
          height: 1.6,
        ),
      );
    } else if (hasPayment && isPaid) {
      return Text(
        'Pembayaran diterima! Akun Anda telah aktif sepenuhnya. Silakan tekan tombol di bawah untuk masuk ke aplikasi.',
        style: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.secondary,
          height: 1.6,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(
      'Data Anda saat ini sedang dalam proses verifikasi oleh tim kami. Mohon tunggu sebentar selagi kami memastikan keamanan dan validitas akun Anda.',
      style: GoogleFonts.inter(
        fontSize: 16,
        color: AppColors.onSurfaceVariant,
        height: 1.6,
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool hasPayment = _paymentUrl != null;
    final bool isPaid = _paymentStatus == 'PAID' || _paymentStatus == 'SUCCESS';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'STATUS PEMBAYARAN & AKUN',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPaid) ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: FadeTransition(
                            opacity: ReverseAnimation(_pulseController),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.tertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Menunggu Pembayaran',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle, color: AppColors.secondary, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Pembayaran Diterima',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStepIndicator('Registrasi', true, true),
              const SizedBox(width: 8),
              _buildStepIndicator('Pembayaran', true, isPaid),
              const SizedBox(width: 8),
              _buildStepIndicator('Akses Penuh', isPaid, isPaid),
            ],
          ),
          if (hasPayment && !isPaid) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryContainer.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INVOICE: ${_invoiceNumber ?? ""}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _paymentAmount != null
                        ? _formatCurrency(_paymentAmount!)
                        : (_role == 'MEMBER' ? 'Rp 10.000' : 'Rp 50.000'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF108EE9).withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF108EE9).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFF108EE9), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Pembayaran Instan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF108EE9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan bayar menggunakan saldo DANA atau metode pembayaran lain di aplikasi DANA untuk mengaktifkan akun Anda secara otomatis.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator(String label, bool isDone, bool isFullyDone) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDone 
                ? (isFullyDone ? AppColors.secondary : AppColors.secondary.withOpacity(0.3))
                : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(3),
            ),
            child: isDone && !isFullyDone
              ? FractionallySizedBox(
                  widthFactor: 0.5,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )
              : null,
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isDone ? AppColors.primary : AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEditorialVisual() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCJqCb2N3V8gtYR1ySR5hdB2lzr3S8xNgbS3IeWv--A4eZXdC_DXrm89of0fmHkyjZ_-Pl9p4i_z_ZJyvtMcH916azkKbQbR6WwnuGmzsa8qc3BLERVfUBSiJ1PEt86FY47yxQnZ1Y_vkdcNpXQFPbN4Rggrh-3ztatCzn7YsHPndYN-rK5aLHhtnwbCuOIoCfbUmtVgu9R8-wQobCmUQP0mmgjHY0cKP4EDjNQpH54_AM9AbQENAc60yIkysIQ4Rag4B7tfwbyvl8',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.security, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keamanan Terjamin',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Standar Enkripsi Level Bank',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -20,
          right: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tertiary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, color: AppColors.onTertiaryContainer),
                const SizedBox(height: 4),
                Text(
                  'Sovereign Tier',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onTertiaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionArea() {
    final bool isPaid = _paymentStatus == 'PAID' || _paymentStatus == 'SUCCESS';
    final bool hasPayment = _paymentUrl != null;

    if (hasPayment && !isPaid) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF108EE9), // DANA Blue color
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF108EE9).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                if (_paymentUrl != null) {
                  await launchUrl(Uri.parse(_paymentUrl!), mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Bayar Sekarang dengan DANA',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckStatusButton(),
        ],
      );
    }

    // Default button (Go to login / dashboard)
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryContainer],
            ),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Masuk ke Aplikasi',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckStatusButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: () async {
          if (_userId != null) {
            final statusData = await ApiService.checkRegistrationStatus(_userId!);
            if (!mounted) return;
            if (statusData != null) {
              final status = statusData['status'];
              if (status != null) {
                setState(() {
                  _paymentStatus = status;
                  _paymentAmount = statusData['amount'] != null ? (statusData['amount'] as num).toInt() : null;
                });
                if (status == 'PAID' || status == 'SUCCESS') {
                  _statusTimer?.cancel();
                  _handleSuccessfulPayment();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pembayaran belum diterima.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            }
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.outline.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'Periksa Status Pembayaran',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(height: 1),
        const SizedBox(height: 32),
        Text(
          '© 2024 Sovereign Network. Seluruh Hak Cipta Dilindungi.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _footerLink('Kebijakan Privasi'),
            const SizedBox(width: 24),
            _footerLink('Pusat Bantuan'),
          ],
        ),
      ],
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.primary.withOpacity(0.7),
      ),
    );
  }
}
