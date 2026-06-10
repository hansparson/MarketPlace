import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> _ranks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _loading = true);
    final data = await ApiService.getLeaderboard();
    if (mounted) {
      setState(() {
        _ranks = data;
        _loading = false;
      });
    }
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLeaderboard,
          color: AppColors.secondary,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEADERBOARD',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Komisi Terbanyak 🏆',
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '10 Reseller & Member berprestasi dengan komisi tertinggi di Gostar-ID.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_ranks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.outline),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada data komisi terkumpul',
                                style: GoogleFonts.inter(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Top 3 Podium Cards
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: _buildPodiumSection(),
                        ),
                      ),

                      // Rank 4-10 list
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _ranks[index + 3];
                              final rank = index + 4;
                              final name = item['user_name'] ?? 'User';
                              final role = item['user_type'] ?? 'MEMBER';
                              final total = item['total_amount'] ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                                ),
                                child: Row(
                                  children: [
                                    // Rank Number Badge
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#$rank',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Avatar Initial
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.secondary.withOpacity(0.15),
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Name & Role Badge
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              role,
                                              style: GoogleFonts.inter(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.secondary,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Total Commission amount
                                    Text(
                                      _formatRupiah(total),
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _ranks.length > 3 ? _ranks.length - 3 : 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection() {
    // Arrange podium order: Rank 2 (Left), Rank 1 (Center), Rank 3 (Right)
    final top1 = _ranks.isNotEmpty ? _ranks[0] : null;
    final top2 = _ranks.length > 1 ? _ranks[1] : null;
    final top3 = _ranks.length > 2 ? _ranks[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 2nd Place (Left)
        Expanded(
          child: top2 != null ? _buildPodiumCard(top2, 2, 100, Colors.grey[300]!) : const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        // 1st Place (Center)
        Expanded(
          child: top1 != null ? _buildPodiumCard(top1, 1, 130, const Color(0xFFFFD700)) : const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        // 3rd Place (Right)
        Expanded(
          child: top3 != null ? _buildPodiumCard(top3, 3, 90, const Color(0xFFCD7F32)) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPodiumCard(dynamic data, int rank, double height, Color medalColor) {
    final name = data['user_name'] ?? 'User';
    final total = data['total_amount'] ?? 0;
    final role = data['user_type'] ?? 'MEMBER';
    final String trophy = rank == 1 ? '🏆' : (rank == 2 ? '🥈' : '🥉');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal/Rank Emoji Circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: medalColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              trophy,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 10),

          // Name
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: rank == 1 ? 15 : 13,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              role,
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Commission
          Text(
            _formatRupiah(total),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: rank == 1 ? 13 : 11,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
