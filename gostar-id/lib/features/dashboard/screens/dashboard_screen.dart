import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/catalog_page.dart';
import '../pages/reseller_page.dart';
import '../pages/profile_page.dart';
import '../pages/earnings_page.dart';
import '../pages/leaderboard_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _role = '';
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? '';
      _loadingRole = false;
    });
  }

  // Pages for MEMBER: Katalog | Reseller | Leaderboard | Pendapatan | Profil
  // Pages for RESELLER: Katalog | Leaderboard | Pendapatan | Profil
  List<Widget> get _pages {
    if (_isReseller) {
      return [
        const CatalogPage(),
        const LeaderboardPage(),
        const EarningsPage(),
        const ProfilePage(),
      ];
    }
    return [
      const CatalogPage(),
      const ResellerPage(),
      const LeaderboardPage(),
      const EarningsPage(),
      const ProfilePage(),
    ];
  }

  bool get _isReseller => _role == 'RESELLER';

  LinearGradient get _currentGradient => _isReseller ? AppColors.resellerGradient : AppColors.memberGradient;

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: _currentGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _pages[_selectedIndex],
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _isReseller
                  ? [
                      Expanded(child: _navItem(0, Icons.shopping_bag_outlined, 'Katalog')),
                      Expanded(child: _navItem(1, Icons.emoji_events_outlined, 'Leaderboard')),
                      Expanded(child: _navItem(2, Icons.payments_outlined, 'Pendapatan')),
                      Expanded(child: _navItem(3, Icons.person_outline, 'Profil')),
                    ]
                  : [
                      Expanded(child: _navItem(0, Icons.shopping_bag_outlined, 'Katalog')),
                      Expanded(child: _navItem(1, Icons.groups_outlined, 'Reseller')),
                      Expanded(child: _navItem(2, Icons.emoji_events_outlined, 'Leaderboard')),
                      Expanded(child: _navItem(3, Icons.payments_outlined, 'Pendapatan')),
                      Expanded(child: _navItem(4, Icons.person_outline, 'Profil')),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    final Color activeColor = AppColors.primary;
    final Color inactiveColor = AppColors.primary.withOpacity(0.3);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
