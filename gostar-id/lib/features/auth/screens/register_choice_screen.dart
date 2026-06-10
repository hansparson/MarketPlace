import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      children: [
                        // Title Section
                        _buildTitleSection(),

                        const SizedBox(height: 48),

                        // Choice Cards
                        _ChoiceCard(
                          title: 'Daftar sebagai Member',
                          description: 'Akses pasar kelas atas eksklusif kami, koleksi terkurasi, dan rekomendasi pribadi. Sempurna untuk pembeli profesional yang mengutamakan kualitas.',
                          icon: Icons.shopping_bag_outlined,
                          accentColor: AppColors.secondary,
                          bgColor: AppColors.surfaceContainerLowest,
                          benefits: const [
                            'Rilisan produk eksklusif',
                            'Umpan belanja yang dipersonalisasi',
                            'Tingkatan harga khusus member',
                          ],
                          buttonText: 'Mulai sebagai Member',
                          onTap: () => Navigator.pushNamed(context, '/register', arguments: {'role': 'member'}),
                        ),

                        const SizedBox(height: 32),

                        _ChoiceCard(
                          title: 'Daftar sebagai Reseller',
                          description: 'Tingkatkan skala bisnis Anda dalam ekosistem kami. Akses manajemen inventaris profesional, analitik reseller, dan potensi penghasilan yang lebih tinggi.',
                          icon: Icons.groups_outlined,
                          accentColor: AppColors.tertiary,
                          bgColor: AppColors.surfaceContainerLowest,
                          isReseller: true,
                          benefits: const [
                            'Akses harga grosir',
                            'Dasbor penjualan tingkat lanjut',
                            'Prioritas alokasi inventaris',
                          ],
                          buttonText: 'Luncurkan Portal Reseller Anda',
                          onTap: () => Navigator.pushNamed(context, '/register', arguments: {'role': 'reseller'}),
                        ),

                        const SizedBox(height: 40),

                        // Bottom Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah memiliki akun? ',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Masuk di sini',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Footer
                        _buildFooter(),
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

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'BERGABUNG DENGAN JARINGAN',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tentukan Perjalanan Anda',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Pilih peran yang paling sesuai dengan tujuan Anda. Baik Anda di sini untuk berbelanja atau mengembangkan bisnis, kami memiliki tempat untuk Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: AppColors.outlineVariant.withOpacity(0.1)),
        const SizedBox(height: 24),
        Text(
          '© 2024 Jaringan Profesional GostarID. Hak cipta dilindungi undang-undang.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterLink(text: 'PRIVASI'),
            const SizedBox(width: 24),
            _FooterLink(text: 'KETENTUAN'),
            const SizedBox(width: 24),
            _FooterLink(text: 'DUKUNGAN'),
          ],
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final List<String> benefits;
  final String buttonText;
  final VoidCallback onTap;
  final bool isReseller;

  const _ChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.benefits,
    required this.buttonText,
    required this.onTap,
    this.isReseller = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: isReseller ? Border(left: BorderSide(color: accentColor, width: 4)) : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Decoration
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 32),
                ),
                
                const SizedBox(height: 20),

                // Title & Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (isReseller) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PERTUMBUHAN TINGGI',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Benefits List
                ...benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: accentColor),
                      const SizedBox(width: 12),
                      Text(
                        benefit,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                )).toList(),

                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReseller ? AppColors.primary : accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(isReseller ? Icons.rocket_launch : Icons.arrow_forward, size: 18),
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
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurfaceVariant.withOpacity(0.6),
        letterSpacing: 1,
      ),
    );
  }
}
