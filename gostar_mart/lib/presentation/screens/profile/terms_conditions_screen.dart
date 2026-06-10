import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'Syarat & Ketentuan',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syarat & Ketentuan Penggunaan',
                style: AppTextStyles.h2.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Terakhir diperbarui: 22 Mei 2026',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. Ketentuan Umum',
                'Selamat datang di Gostar-Mart. Aplikasi ini merupakan marketplace eksklusif yang hanya dapat diakses oleh member/klien terverifikasi dari Gostar. Dengan mengakses dan menggunakan aplikasi ini, Anda setuju untuk terikat oleh Syarat dan Ketentuan berikut.',
              ),
              _buildSection(
                '2. Keanggotaan & Akun',
                'Akses ke Gostar-Mart bersifat undangan dan terbatas. Setiap member bertanggung jawab penuh atas kerahasiaan informasi akun mereka, termasuk kredensial login Google. Akun tidak dapat dipindahtangankan kepada pihak lain tanpa persetujuan tertulis dari manajemen.',
              ),
              _buildSection(
                '3. Transaksi & Hubungan Penjual',
                'Gostar-Mart memfasilitasi penayangan produk premium dan menghubungkan Anda langsung ke penjual resmi melalui integrasi WhatsApp. Transaksi dan pembayaran dilakukan secara langsung di luar platform ini dengan pengawasan resmi. Kami tidak memproses transaksi pembayaran kartu atau dompet digital secara langsung di dalam aplikasi.',
              ),
              _buildSection(
                '4. Batasan Tanggung Jawab',
                'Kami berusaha menyajikan data produk seakurat mungkin. Namun, spesifikasi akhir, ketersediaan unit, dan harga resmi properti/produk harus diverifikasi kembali dengan seller resmi kami selama proses diskusi di WhatsApp.',
              ),
              _buildSection(
                '5. Perubahan Ketentuan',
                'Manajemen Gostar-Mart berhak untuk mengubah, memodifikasi, menambah, atau menghapus bagian dari Syarat & Ketentuan ini sewaktu-waktu. Perubahan akan diinformasikan melalui aplikasi atau email terdaftar Anda.',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLg.copyWith(
              color: AppColors.sovereignGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
