import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _profile;
  List<dynamic> _payouts = [];
  List<dynamic> _commissions = [];
  bool _loading = true;
  int _selectedTab = 0; // 0 = Payouts, 1 = Commissions
  int _minWithdrawal = 20000;        // default, updated from backend config
  int _maxWithdrawalsPerDay = 1;     // default, updated from backend config

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getStats(),
      ApiService.getMyPayouts(),
      ApiService.getMyCommissions(),
      ApiService.getProfile(),
      ApiService.getPublicConfigs(),
    ]);
    final configs = results[4] as Map<String, String>;
    setState(() {
      _stats = results[0] as Map<String, dynamic>?;
      _payouts = results[1] as List<dynamic>;
      _commissions = results[2] as List<dynamic>;
      _profile = results[3] as Map<String, dynamic>?;
      _minWithdrawal = int.tryParse(configs['minimum_withdrawal_amount'] ?? '') ?? 20000;
      _maxWithdrawalsPerDay = int.tryParse(configs['max_withdrawals_per_day'] ?? '') ?? 1;
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _parseNullString(dynamic val) {
    if (val == null) return '';
    if (val is Map) {
      final valid = val['Valid'] ?? val['valid'];
      final str = val['String'] ?? val['string'];
      if (valid == true) {
        return str?.toString() ?? '';
      }
      return '';
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.secondary,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                    const SizedBox(height: 48),
                    _buildPayoutHistory(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final total = _stats?['total_commission'] ?? 0;
    final available = _stats?['available_balance'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SALDO TERSEDIA',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800,
                  color: AppColors.secondary, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(_formatRupiah(available),
              style: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w800,
                  color: AppColors.primary, letterSpacing: -1)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text('Total komisi: ${_formatRupiah(total)}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showWithdrawInfo(context),
                  icon: const Icon(Icons.payments, size: 18),
                  label: const Text('Tarik Dana'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAlertDialog({
    required BuildContext context,
    required String title,
    required String message,
    bool isSuccess = false,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSuccess 
                        ? const Color(0xFFE8F5E9) 
                        : const Color(0xFFFFEBEE), 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error_outline,
                    color: isSuccess ? const Color(0xFF4CAF50) : AppColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (onClose != null) onClose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess ? AppColors.secondary : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWithdrawInfo(BuildContext pageContext) {
    final available = _stats?['available_balance'] ?? 0;
    final String danaPhone = _profile?['dana_phone'] ?? '';

    if (danaPhone.isEmpty) {
      showDialog(
        context: pageContext,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nomor DANA Belum Diatur', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          content: Text(
              'Untuk melakukan penarikan komisi, Anda harus mengatur nomor DANA terlebih dahulu di menu Profil.',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(pageContext),
                child: Text('Mengerti', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.secondary))),
          ],
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tarik Komisi Instan',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dana akan ditransfer secara otomatis ke akun DANA Anda.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo Tersedia',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                ),
                                Text(
                                  _formatRupiah(available),
                                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF108EE9).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF108EE9).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_android, color: Color(0xFF108EE9)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nomor DANA Tujuan',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                                ),
                                Text(
                                  danaPhone,
                                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF108EE9)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Info banner: limit rules
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ketentuan Penarikan',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF795548)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Minimum penarikan: ${_formatRupiah(_minWithdrawal)}\n• Maksimal ${_maxWithdrawalsPerDay}x penarikan per hari (reset tengah malam)',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF795548), height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'JUMLAH PENARIKAN (RP)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah (misal: 50000)',
                        fillColor: AppColors.surfaceContainerHigh.withOpacity(0.4),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CATATAN (OPSIONAL)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        hintText: 'Penarikan komisi GostarID',
                        fillColor: AppColors.surfaceContainerHigh.withOpacity(0.4),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amountVal = int.tryParse(amountController.text);
                                if (amountVal == null || amountVal <= 0) {
                                  _showAlertDialog(
                                    context: modalContext,
                                    title: 'Input Tidak Valid',
                                    message: 'Masukkan jumlah penarikan yang valid.',
                                  );
                                  return;
                                }

                                if (amountVal < _minWithdrawal) {
                                  _showAlertDialog(
                                    context: modalContext,
                                    title: 'Jumlah Terlalu Kecil',
                                    message: 'Minimum penarikan adalah ${_formatRupiah(_minWithdrawal)}.',
                                  );
                                  return;
                                }

                                if (amountVal > available) {
                                  _showAlertDialog(
                                    context: modalContext,
                                    title: 'Saldo Kurang',
                                    message: 'Saldo tidak mencukupi untuk penarikan ini.',
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                final response = await ApiService.requestWithdrawal(amountVal, notesController.text);
                                setModalState(() => isSubmitting = false);

                                if (response != null && response['message_action'] == 'WITHDRAWAL_SUCCESSFUL') {
                                  if (pageContext.mounted && modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                    _loadData();
                                    _showAlertDialog(
                                      context: pageContext,
                                      title: 'Penarikan Berhasil',
                                      message: 'Komisi sebesar ${_formatRupiah(amountVal)} berhasil ditarik ke nomor DANA $danaPhone.',
                                      isSuccess: true,
                                    );
                                  }
                                } else {
                                  String errMsg = 'Gagal memproses penarikan.';
                                  if (response != null) {
                                    if (response['message_data'] != null) {
                                      errMsg = response['message_data'].toString();
                                    } else if (response['reason'] != null) {
                                      errMsg = _formatFailedReason(response['reason'].toString());
                                    } else if (response['error'] != null) {
                                      errMsg = response['error'].toString();
                                    }
                                  }
                                  if (modalContext.mounted) {
                                    _showAlertDialog(
                                      context: modalContext,
                                      title: 'Penarikan Gagal',
                                      message: errMsg,
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF108EE9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Tarik Dana Sekarang',
                                style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickStats() {
    final available = _stats?['available_balance'] ?? 0;
    final paid = _stats?['total_paid'] ?? 0;
    final shares = _stats?['total_shares'] ?? 0;
    final clicks = _stats?['total_clicks'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard(label: 'SALDO TERSEDIA', value: _formatRupiah(available), color: AppColors.secondary, bgColor: AppColors.secondary.withOpacity(0.06))),
            const SizedBox(width: 16),
            Expanded(child: _statCard(label: 'SUDAH DIBAYAR', value: _formatRupiah(paid), color: AppColors.tertiary, bgColor: AppColors.tertiary.withOpacity(0.06), borderColor: AppColors.tertiary)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard(label: 'TOTAL SHARE', value: '$shares', color: AppColors.primary, bgColor: AppColors.primary.withOpacity(0.05))),
            const SizedBox(width: 16),
            Expanded(child: _statCard(label: 'TOTAL KLIK', value: '$clicks', color: AppColors.secondary, bgColor: AppColors.secondary.withOpacity(0.05))),
          ],
        ),
      ],
    );

  }

  Widget _statCard({required String label, required String value,
      required Color color, required Color bgColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border(left: BorderSide(color: borderColor, width: 4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildPayoutHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(
                      color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                      width: 2,
                    )),
                  ),
                  child: Center(
                    child: Text('Riwayat Penarikan',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: _selectedTab == 0 ? FontWeight.w800 : FontWeight.w600,
                          color: _selectedTab == 0 ? AppColors.primary : AppColors.outline,
                        )),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(
                      color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                      width: 2,
                    )),
                  ),
                  child: Center(
                    child: Text('Riwayat Komisi',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: _selectedTab == 1 ? FontWeight.w800 : FontWeight.w600,
                          color: _selectedTab == 1 ? AppColors.primary : AppColors.outline,
                        )),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_selectedTab == 0) ...[
          if (_payouts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.outline),
                  const SizedBox(height: 8),
                  Text('Belum ada riwayat penarikan',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                ],
              ),
            )
          else
            ...(_payouts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _payoutTile(p),
                ))),
        ] else ...[
          if (_commissions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Icon(Icons.monetization_on_outlined, size: 40, color: AppColors.outline),
                  const SizedBox(height: 8),
                  Text('Belum ada riwayat komisi',
                      style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                ],
              ),
            )
          else
            ...(_commissions.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _commissionTile(c),
                ))),
        ],
      ],
    );
  }

  Widget _payoutTile(Map<String, dynamic> p) {
    final amount = p['amount'] ?? 0;
    final notes = _parseNullString(p['notes']);
    final date = _formatDate(p['created_at']);
    final status = p['status'] ?? 'SUCCESS';

    Color statusColor = AppColors.secondary;
    String statusTitle = 'Penarikan Berhasil';
    Color amountColor = Colors.red;

    if (status == 'PENDING') {
      statusColor = Colors.orange;
      statusTitle = 'Penarikan Diproses';
      amountColor = Colors.orange;
    } else if (status == 'FAILED') {
      statusColor = Colors.red;
      statusTitle = 'Penarikan Gagal';
      amountColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayoutDetailPage(
              payout: p,
              userDanaPhone: _profile?['dana_phone'],
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerLow)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                status == 'FAILED' 
                    ? Icons.error_outline 
                    : (status == 'PENDING' ? Icons.hourglass_empty : Icons.payments_outlined), 
                color: statusColor, 
                size: 22
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusTitle,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Text(notes.isEmpty ? date : '$notes • $date',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.outline),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              status == 'FAILED' ? _formatRupiah(amount) : '-${_formatRupiah(amount)}',
              style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w800, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commissionTile(Map<String, dynamic> c) {
    final amount = c['amount'] ?? 0;
    final status = c['status'] ?? 'PENDING';
    final date = _formatDate(c['created_at']);
    final thumbnailUrl = c['thumbnail_url'] ?? '';
    
    Color statusColor = AppColors.outline;
    String statusText = status;
    
    if (status == 'PAID') {
      statusColor = AppColors.secondary;
      statusText = 'DIBAYAR';
    } else if (status == 'PENDING') {
      statusColor = Colors.orange;
      // User requested to show "SUKSES" if already recorded/sold
      statusText = 'SUKSES'; 
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerLow)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: thumbnailUrl.isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage(ApiService.getImageUrl(thumbnailUrl)),
                      fit: BoxFit.cover)
                  : null),
            child: thumbnailUrl.isEmpty 
              ? const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22)
              : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['product_title'] ?? 'Komisi Penjualan',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),

                Text('$statusText • $date',
                    style: GoogleFonts.inter(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          Text('+${_formatRupiah(amount)}',
              style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.secondary)),
        ],
      ),
    );
  }
}

class PayoutDetailPage extends StatelessWidget {
  final Map<String, dynamic> payout;
  final String? userDanaPhone;

  const PayoutDetailPage({
    super.key,
    required this.payout,
    this.userDanaPhone,
  });

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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final minutes = dt.minute.toString().padLeft(2, '0');
      final hours = dt.hour.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hours:$minutes';
    } catch (_) {
      return dateStr;
    }
  }

  String _parseNullString(dynamic val) {
    if (val == null) return '';
    if (val is Map) {
      final valid = val['Valid'] ?? val['valid'];
      final str = val['String'] ?? val['string'];
      if (valid == true) {
        return str?.toString() ?? '';
      }
      return '';
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final amount = payout['amount'] ?? 0;
    final status = payout['status'] ?? 'SUCCESS';
    final notes = _parseNullString(payout['notes']);
    final danaTxId = _parseNullString(payout['dana_transaction_id']);
    final failedReason = _formatFailedReason(_parseNullString(payout['failed_reason']));
    final date = _formatDate(payout['created_at']);

    Color statusColor = AppColors.secondary;
    String statusText = 'Berhasil';
    IconData statusIcon = Icons.check_circle_outline;

    if (status == 'PENDING') {
      statusColor = Colors.orange;
      statusText = 'Diproses';
      statusIcon = Icons.hourglass_empty;
    } else if (status == 'FAILED') {
      statusColor = Colors.red;
      statusText = 'Gagal';
      statusIcon = Icons.error_outline;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Penarikan',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceContainerLow),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Badge Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount
                    Text(
                      '-${_formatRupiah(amount)}',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: status == 'FAILED' ? AppColors.outline : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Detail Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceContainerLow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rincian Transaksi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Tipe Transaksi', 'Tarik Dana'),
                    const Divider(height: 24, color: AppColors.surfaceContainerLow),
                    if (userDanaPhone != null && userDanaPhone!.isNotEmpty) ...[
                      _buildDetailRow('Akun DANA Penerima', userDanaPhone!),
                      const Divider(height: 24, color: AppColors.surfaceContainerLow),
                    ],
                    if (danaTxId.isNotEmpty) ...[
                      _buildDetailRow('ID Transaksi DANA', danaTxId),
                      const Divider(height: 24, color: AppColors.surfaceContainerLow),
                    ],
                    if (notes.isNotEmpty) ...[
                      _buildDetailRow('Catatan', notes),
                      const Divider(height: 24, color: AppColors.surfaceContainerLow),
                    ],
                    if (status == 'FAILED' && failedReason.isNotEmpty) ...[
                      _buildDetailRow('Alasan Gagal', failedReason, isError: true),
                      const Divider(height: 24, color: AppColors.surfaceContainerLow),
                    ],
                    // Always show transaction ID if present
                    _buildDetailRow('ID Penarikan', payout['id'] ?? '-'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.outline,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isError ? Colors.red : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatFailedReason(String raw) {
  if (raw.isEmpty) return '';

  // Check if it's a DANA API error with a JSON body
  if (raw.contains('body:')) {
    final jsonPart = raw.substring(raw.indexOf('body:') + 5).trim();
    try {
      final decoded = json.decode(jsonPart);
      if (decoded is Map) {
        final resMsg = decoded['additionalInfo']?['resultMsg'] ?? decoded['responseMessage'] ?? decoded['responseCode'];
        if (resMsg != null) {
          return _mapDanaErrorToUserFriendly(resMsg.toString(), decoded['responseCode']?.toString());
        }
      }
    } catch (_) {
      // JSON parsing fails, fall back to manual checks
    }
  }

  // Fallback parser if JSON parse fails or is partially serialized
  final upper = raw.toUpperCase();
  if (upper.contains('SYSTEM_ERROR') || upper.contains('5003801')) {
    return 'Sistem DANA sedang mengalami kendala. Silakan coba beberapa saat lagi.';
  }
  if (upper.contains('PAYEE_USER_NOT_EXIST')) {
    return 'Nomor HP tujuan tidak terdaftar di DANA.';
  }
  if (upper.contains('PAYEE_USER_STATUS_DISABLE')) {
    return 'Akun DANA tujuan sedang dibekukan atau dinonaktifkan.';
  }
  if (upper.contains('LIMIT_EXCEED')) {
    return 'Jumlah penarikan melebihi batas limit akun DANA penerima.';
  }
  if (upper.contains('INSUFFICIENT_BALANCE')) {
    return 'Koneksi pembayaran sedang bermasalah (Saldo Limit Merchant Habis).';
  }

  // Clean up generic DANA disbursement API error prefix
  if (raw.startsWith('DANA disbursement API error:')) {
    final clean = raw.replaceAll('DANA disbursement API error:', '').trim();
    if (clean.length > 50) {
      return 'Gagal memproses penarikan lewat DANA. Silakan hubungi admin.';
    }
    return clean;
  }

  return raw;
}

String _mapDanaErrorToUserFriendly(String resultMsg, String? responseCode) {
  switch (resultMsg.toUpperCase()) {
    case 'SYSTEM_ERROR':
      return 'Sistem DANA sedang mengalami kendala. Silakan coba beberapa saat lagi.';
    case 'PAYEE_USER_NOT_EXIST':
      return 'Nomor HP tujuan tidak terdaftar di DANA.';
    case 'PAYEE_USER_STATUS_DISABLE':
      return 'Akun DANA tujuan sedang dibekukan atau dinonaktifkan.';
    case 'ORDER_AMOUNT_LIMIT_EXCEED':
    case 'TOTAL_AMOUNT_LIMIT_EXCEED':
      return 'Batas limit transaksi DANA tujuan telah terlampaui.';
    case 'INSUFFICIENT_BALANCE':
      return 'Koneksi pembayaran sedang bermasalah (Saldo Limit Merchant Habis).';
    case 'SUSPENDED_USER':
      return 'Akun DANA Anda ditangguhkan atau dibekukan.';
    default:
      if (resultMsg.isNotEmpty) {
        final clean = resultMsg.replaceAll('_', ' ');
        return 'Gagal transfer: $clean ${responseCode != null ? '($responseCode)' : ''}';
      }
      return 'Terjadi kesalahan sistem DANA ${responseCode != null ? '($responseCode)' : ''}';
  }
}

