import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> txStrings = prefs.getStringList('transactions') ?? [];
      
      List<Map<String, dynamic>> loadedTx = [];
      for (var str in txStrings) {
        try {
          loadedTx.add(Map<String, dynamic>.from(jsonDecode(str)));
        } catch (e) {
          debugPrint("Error decoding transaction item: $e");
        }
      }

      // If empty, add some premium mock transactions so the screen is not empty on first load
      if (loadedTx.isEmpty) {
        loadedTx = _getMockTransactions();
      }

      setState(() {
        _transactions = loadedTx;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading transactions: $e");
      setState(() {
        _transactions = _getMockTransactions();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockTransactions() {
    return [
      {
        'id': 'TX-8947201',
        'title': 'Cluster Luxury Lavender - Menteng',
        'price': 'Rp 8.500.000.000',
        'category': 'RUMAH MEWAH',
        'location': 'Menteng, Jakarta Pusat',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'status': 'Selesai',
        'thumbnail_url': '',
      },
      {
        'id': 'TX-7281034',
        'title': 'Apartemen Senopati Suites Penthouse',
        'price': 'Rp 12.000.000.000',
        'category': 'APARTEMEN',
        'location': 'Kebayoran Baru, Jakarta Selatan',
        'timestamp': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'status': 'Selesai',
        'thumbnail_url': '',
      },
    ];
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus Riwayat?',
          style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
        ),
        content: Text(
          'Tindakan ini akan menghapus semua riwayat transaksi lokal Anda.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppTextStyles.button.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.2),
              foregroundColor: AppColors.error,
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('transactions');
      setState(() {
        _transactions = [];
      });
    }
  }

  String _formatDate(String timestampStr) {
    try {
      final date = DateTime.parse(timestampStr);
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Beberapa hari lalu';
    }
  }

  String _formatPrice(String priceStr) {
    final clean = priceStr.replaceAll('Rp ', '').replaceAll('.', '').trim();
    final amount = int.tryParse(clean) ?? 0;
    if (amount == 0) return priceStr;
    final str = amount.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      result = str[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.' + result;
      }
    }
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Transaksi',
          style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
        ),
        actions: [
          if (_transactions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _clearHistory,
              tooltip: 'Hapus Riwayat',
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060D1E), AppColors.midnightNavy, Color(0xFF0D1A38)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.sovereignGold),
              )
            : _transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      return _buildTransactionCard(tx);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sovereignGold.withOpacity(0.05),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.sovereignGold.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada transaksi',
            style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Riwayat ketertarikan produk Anda akan muncul di sini saat Anda menghubungi penjual.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final status = tx['status'] ?? 'Menghubungi Penjual';
    final isDone = status == 'Selesai';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.sovereignGold.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with ID & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tx['id'] ?? 'TX-0000000',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone 
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.sovereignGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDone ? AppColors.success : AppColors.sovereignGold,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTextStyles.labelSm.copyWith(
                          color: isDone ? AppColors.success : AppColors.sovereignGold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                
                // Middle row with product details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image container (with emoji fallback)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.midnightNavy,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.goldBorder.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: tx['thumbnail_url'] != null && tx['thumbnail_url'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                tx['thumbnail_url'].toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.home_work_outlined, color: AppColors.sovereignGold),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.home_work_outlined, color: AppColors.sovereignGold),
                            ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Product title, category, location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (tx['category'] ?? 'PROPERTI').toString().toUpperCase(),
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.sovereignGold,
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx['title'] ?? 'Nama Produk',
                            style: AppTextStyles.labelLg.copyWith(
                              color: AppColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.outline),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  tx['location'] ?? 'Lokasi',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.outline,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                
                // Bottom row with date and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(tx['timestamp'] ?? ''),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.outline,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _formatPrice(tx['price'] ?? '0'),
                      style: AppTextStyles.price.copyWith(
                        color: AppColors.sovereignGold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
