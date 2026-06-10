import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Akun & Keanggotaan',
      'items': [
        {
          'q': 'Bagaimana cara menjadi member terverifikasi Gostar-Mart?',
          'a': 'Status member terverifikasi didapatkan secara eksklusif bagi klien yang diundang secara khusus oleh manajemen Gostar. Akun Anda akan otomatis terverifikasi setelah Anda login menggunakan email terdaftar.'
        },
        {
          'q': 'Mengapa profil WhatsApp wajib diisi saat onboarding?',
          'a': 'Gostar-Mart menggunakan WhatsApp sebagai media komunikasi utama antara pembeli (Anda) dan official seller untuk transaksi eksklusif Anda.'
        }
      ]
    },
    {
      'category': 'Transaksi & Pembelian',
      'items': [
        {
          'q': 'Bagaimana cara melakukan pembelian properti atau unit?',
          'a': '1. Cari produk yang Anda inginkan di halaman utama.\n2. Buka detail produk, lalu tekan tombol "Hubungi Penjual".\n3. Anda akan diarahkan ke WhatsApp official seller dengan draf pesan otomatis untuk melanjutkan negosiasi dan transaksi.'
        },
        {
          'q': 'Apakah ada biaya tambahan (fee) transaksi?',
          'a': 'Biaya transaksi, komisi, atau biaya administratif platform ditentukan secara transparan sesuai kesepakatan tertulis. Tidak ada biaya tersembunyi di luar apa yang diinformasikan seller resmi kami.'
        }
      ]
    },
    {
      'category': 'Privasi & Keamanan',
      'items': [
        {
          'q': 'Apakah data pribadi saya aman di Gostar-Mart?',
          'a': 'Kami sangat menjaga privasi Anda. Semua informasi pribadi, nomor kontak, serta histori ketertarikan produk dilindungi dengan enkripsi tinggi dan tidak dibagikan kepada pihak ketiga di luar ekosistem Gostar.'
        }
      ]
    }
  ];

  List<Map<String, dynamic>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = List.from(_faqs);
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = List.from(_faqs);
      } else {
        _filteredFaqs = _faqs.map((category) {
          final items = (category['items'] as List<Map<String, String>>).where((item) {
            return item['q']!.toLowerCase().contains(query.toLowerCase()) ||
                item['a']!.toLowerCase().contains(query.toLowerCase());
          }).toList();
          return {
            'category': category['category'],
            'items': items,
          };
        }).where((category) => (category['items'] as List).isNotEmpty).toList();
      }
    });
  }

  Future<void> _contactSupport() async {
    const csNumber = '628123456789'; // Mock CS number
    final message = Uri.encodeComponent(
      'Halo Admin Gostar-Mart, saya butuh bantuan mengenai aplikasi.',
    );
    final url = Uri.parse('https://wa.me/$csNumber?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp CS')),
      );
    }
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
          'Bantuan & FAQ',
          style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
        ),
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
        child: Column(
          children: [
            _buildSearchBox(),
            Expanded(
              child: _filteredFaqs.isEmpty
                  ? _buildNoResults()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredFaqs.length,
                      itemBuilder: (context, idx) {
                        final cat = _filteredFaqs[idx];
                        return _buildCategorySection(cat);
                      },
                    ),
            ),
            _buildCsBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.goldBorder, width: 0.5),
        ),
        child: TextField(
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Cari bantuan atau pertanyaan...',
            hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
            prefixIcon: const Icon(Icons.search, color: AppColors.sovereignGold, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: _filterSearch,
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline_rounded, size: 48, color: AppColors.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Pertanyaan tidak ditemukan',
            style: AppTextStyles.labelLg.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> cat) {
    final String title = cat['category'];
    final List<dynamic> items = cat['items'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.sovereignGold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.goldBorder.withOpacity(0.3), width: 0.5),
          ),
          child: Column(
            children: items.map<Widget>((item) {
              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: AppColors.sovereignGold,
                  collapsedIconColor: AppColors.outline,
                  title: Text(
                    item['q'],
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        item['a'],
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCsBanner() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: AppColors.goldBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Butuh Bantuan Lain?',
                  style: AppTextStyles.labelLg.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hubungi admin untuk respons cepat.',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.support_agent_rounded, size: 16),
            label: const Text('Chat Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sovereignGold,
              foregroundColor: AppColors.midnightNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
