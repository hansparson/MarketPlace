import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ResellerPage extends StatefulWidget {
  const ResellerPage({super.key});

  @override
  State<ResellerPage> createState() => _ResellerPageState();
}

class _ResellerPageState extends State<ResellerPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final data = await ApiService.getStats();
    setState(() {
      _stats = data;
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _buildHeader(),
              ),
              const SizedBox(height: 16),
              TabBar(
                isScrollable: false,
                labelColor: AppColors.secondary,
                unselectedLabelColor: AppColors.outline,
                indicatorColor: AppColors.secondary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Ringkasan'),
                  Tab(text: 'Jaringan'),
                  Tab(text: 'Aktivitas'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : TabBarView(
                        children: [
                          _buildOverviewTab(),
                          _buildNetworkTab(),
                          _buildActivityTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildReferralCard(),
            const SizedBox(height: 32),
            _buildSectionTitle('Performa Jaringan'),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildEarningsCard(),
            const SizedBox(height: 24),
            _buildTeamPerformanceCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildTeamPerformanceCard() {
    final teamSales = _stats?['total_sales'] ?? 0;
    final teamComm = _stats?['team_commission'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, size: 20, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('RINGKASAN TIM', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.outline, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _simpleStat('Total Penjualan', '$teamSales'),
              Container(width: 1, height: 40, color: AppColors.outlineVariant.withOpacity(0.3)),
              _simpleStat('Omzet Jaringan', _formatRupiah(teamComm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simpleStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.outline)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildNetworkTab() {
    final network = (_stats?['network'] as List?) ?? [];
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.secondary,
      child: network.isEmpty
          ? _buildEmptyState(Icons.people_outline, 'Belum ada jaringan reseller')
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: network.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final res = network[index];
                return _buildResellerCard(res);
              },
            ),
    );
  }

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: _buildRecentActivities(),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.outline.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: AppColors.outline)),
        ],
      ),
    );
  }

  Widget _buildResellerCard(Map<String, dynamic> res) {
    final name = res['name'] ?? '-';
    final code = res['referral_code'] ?? '-';
    final status = res['status'] ?? 'ACTIVE';
    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('ID: $code', style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'AKTIF' : 'PENDING',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PUSAT JARINGAN',
            style: GoogleFonts.manrope(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: AppColors.secondary, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text('Ekosistem Reseller',
            style: GoogleFonts.manrope(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: AppColors.primary, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('Pantau performa dan kelola jaringan Anda.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.3)),
      ],
    );
  }

  Widget _buildReferralCard() {
    final code = _stats?['referral_code'] ?? '-';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KODE REFERENSI',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppColors.outline, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(code,
                      style: GoogleFonts.manrope(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: AppColors.primary, letterSpacing: 1)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode disalin!'), backgroundColor: AppColors.secondary));
                  },
                  icon: const Icon(Icons.content_copy, size: 14),
                  label: const Text('Salin'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Bagikan kode ini kepada reseller baru untuk menghubungkan mereka.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalReseller = (_stats?['network'] as List?)?.length ?? 0;
    final totalClicks = _stats?['total_clicks'] ?? 0;
    return Row(
      children: [
        Expanded(child: _statCard(label: 'TOTAL RESELLER', value: '$totalReseller', color: AppColors.secondary)),
        const SizedBox(width: 16),
        Expanded(child: _statCard(label: 'TOTAL KLIK', value: '$totalClicks',
            color: AppColors.tertiary, borderColor: AppColors.tertiary)),
      ],
    );
  }

  Widget _buildEarningsCard() {
    final commission = _stats?['total_commission'] ?? 0;
    final paid = _stats?['total_paid'] ?? 0;
    final available = _stats?['available_balance'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.kineticGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL PENGHASILAN',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.7), letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(_formatRupiah(commission),
              style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              _earningChip('Sudah Dibayar', _formatRupiah(paid), Colors.white.withOpacity(0.2)),
              const SizedBox(width: 12),
              _earningChip('Tersedia', _formatRupiah(available), Colors.white.withOpacity(0.3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earningChip(String label, String value, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = (_stats?['recent_activities'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivitas Terbaru',
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Icon(Icons.inbox_outlined, size: 40, color: AppColors.outline),
                const SizedBox(height: 8),
                Text('Belum ada aktivitas', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
              ],
            ),
          )
        else
          ...activities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _activityTile(a),
              )),
      ],
    );
  }

  Widget _activityTile(Map<String, dynamic> a) {
    final type = (a['activity_type'] ?? '').toString();
    final product = a['product_title'] ?? '-';
    final commission = a['commission_amount'] ?? 0;
    final visitorName = a['visitor_name'] ?? '';
    final visitorPhone = a['visitor_phone'] ?? '';
    final isLead = type == 'LEAD';
    
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
                color: (isLead ? AppColors.secondary : AppColors.tertiary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(isLead ? Icons.person_add_outlined : Icons.shopping_bag_outlined,
                color: isLead ? AppColors.secondary : AppColors.tertiary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isLead ? 'Lead Baru: $visitorName' : 'Penjualan',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                Text(product,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.outline),
                    overflow: TextOverflow.ellipsis),
                if (isLead && visitorPhone.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      var phone = visitorPhone.replaceAll(RegExp(r'\D'), '');
                      if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
                      final url = Uri.parse('https://wa.me/$phone');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 10, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(visitorPhone, style: GoogleFonts.inter(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isLead)
            Text('+${_formatRupiah(commission)}',
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.secondary)),
          if (isLead)
             IconButton(
               icon: const Icon(Icons.chat_outlined, size: 20, color: Colors.green),
               onPressed: () {
                  var phone = visitorPhone.replaceAll(RegExp(r'\D'), '');
                  if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
                  // Use url_launcher to open WA
               },
             ),
        ],
      ),
    );
  }

  Widget _statCard({required String label, required String value,
      required Color color, Color? borderColor}) {
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
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ],
      ),
    );
  }
}
