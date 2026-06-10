import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../product_detail/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  static final refreshNotifier = ValueNotifier<int>(0);
  static void triggerRefresh() {
    refreshNotifier.value++;
  }

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<Map<String, dynamic>> _favorites = [];
  String _clientId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientIdAndFavorites();
    FavoritesScreen.refreshNotifier.addListener(_onRefreshEvent);
  }

  void _onRefreshEvent() {
    if (mounted) {
      _loadClientIdAndFavorites();
    }
  }

  @override
  void dispose() {
    FavoritesScreen.refreshNotifier.removeListener(_onRefreshEvent);
    super.dispose();
  }

  Future<void> _loadClientIdAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('clientId') ?? '';
    setState(() {
      _clientId = clientId;
    });
    if (clientId.isNotEmpty) {
      await _fetchFavorites();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFavorites() async {
    if (_clientId.isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final ApiService api = ApiService();
      final favList = await api.getFavorites(_clientId);
      final categories = await api.getCategories();
      final categoryMap = {for (var c in categories) c['id'].toString(): c['name']};

      setState(() {
        _favorites.clear();
        for (var p in favList) {
          final catId = p['category_id']?.toString() ?? '';
          final categoryName = categoryMap[catId] ?? 'Produk';
          final thumbKey = (p['thumbnail_url'] as String? ?? '');
          final imageUrl = ApiService.getImageUrl(thumbKey);

          _favorites.add({
            'id': p['id'],
            'title': p['title'] ?? 'Tanpa Judul',
            'category': categoryName,
            'price': 'Rp ${(p['price'] ?? 0)}',
            'location': (p['location_name'] != null && p['location_name'].toString().isNotEmpty)
                ? p['location_name']
                : 'Indonesia',
            'thumbnail_url': imageUrl,
            'description': p['description'] ?? '',
            'created_at': p['created_at'],
            'isFavorite': true,
            'color': const Color(0xFF1A2A4A),
            'emoji': _getEmojiForCategory(categoryName),
            'status': (p['status'] as String? ?? 'ACTIVE').toUpperCase(),
            'stock': p['stock'] as int? ?? 1,
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(int index) async {
    final item = _favorites[index];
    final productId = item['id']?.toString() ?? '';
    if (_clientId.isEmpty || productId.isEmpty) return;

    final removedItem = _favorites.removeAt(index);
    setState(() {});

    try {
      final ApiService api = ApiService();
      await api.toggleFavorite(_clientId, productId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dihapus dari favorit',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Rollback on failure
      setState(() {
        _favorites.insert(index, removedItem);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus favorit: $e')),
      );
    }
  }

  String _getEmojiForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'rumah':
      case 'properti':
      case 'perlengkapan rumah':
        return '🏡';
      case 'tanah':
        return '🗺️';
      case 'mobil':
        return '🚗';
      case 'motor':
        return '🏍️';
      case 'elektronik':
      case 'handphone':
        return '📱';
      case 'fashion':
        return '✨';
      case 'hobi & olahraga':
        return '⚽';
      default:
        return '✨';
    }
  }

  String _formatPrice(String priceStr) {
    final cleanStr = priceStr.replaceAll('Rp', '').trim();
    if (cleanStr.contains(RegExp(r'[a-zA-Z]')) || cleanStr.contains(',')) {
      return priceStr.startsWith('Rp') ? priceStr : 'Rp $priceStr';
    }
    final parsed = int.tryParse(cleanStr.replaceAll('.', '').replaceAll(',', ''));
    if (parsed != null) {
      final buffer = StringBuffer();
      final str = parsed.toString();
      int count = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        buffer.write(str[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write('.');
        }
      }
      return 'Rp ${buffer.toString().split('').reversed.join('')}';
    }
    return priceStr;
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.sovereignGold))
              : _favorites.isEmpty
                  ? _buildEmptyState()
                  : _buildList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.sovereignGold,
      backgroundColor: AppColors.midnightNavy,
      strokeWidth: 2.5,
      onRefresh: _fetchFavorites,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFavoriteItem(index),
              childCount: _favorites.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFF5D170), Color(0xFFD4AF37)],
            ).createShader(bounds),
            child: Text(
              'Favorit Saya',
              style: AppTextStyles.h1.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_favorites.length} item tersimpan',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: AppColors.outlineVariant.withOpacity(0.4)),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(int index) {
    final item = _favorites[index];
    final hasImage = item['thumbnail_url'] != null && (item['thumbnail_url'] as String).isNotEmpty;

    return Dismissible(
      key: ValueKey(item['id']?.toString() ?? item['title']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeFromFavorites(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.errorContainer.withOpacity(0.3),
        child: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: item),
            ),
          ).then((_) => _fetchFavorites());
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldBorder, width: 0.5),
          ),
          child: Row(
            children: [
              // Thumbnail / Image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldBorder, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hasImage
                      ? Image.network(
                          item['thumbnail_url'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackVisualSmall(item),
                        )
                      : _buildFallbackVisualSmall(item),
                ),
              ),

              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sovereignGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        (item['category'] as String).toUpperCase(),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.sovereignGold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['title'] as String,
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.outline),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item['location'] as String,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.outline,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Price + remove
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(item['price'] as String),
                    style: AppTextStyles.price.copyWith(
                      color: AppColors.sovereignGold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _removeFromFavorites(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackVisualSmall(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerLow,
            AppColors.midnightNavy.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          item['emoji'] as String? ?? '✨',
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.sovereignGold,
      backgroundColor: AppColors.midnightNavy,
      strokeWidth: 2.5,
      onRefresh: _fetchFavorites,
      child: Stack(
        children: [
          ListView(), // Dynamic layout requires scrollable widget for RefreshIndicator to trigger
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AppColors.outlineVariant,
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum Ada Favorit',
                  style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simpan produk yang Anda minati\nuntuk mudah ditemukan kembali.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _fetchFavorites,
                  icon: const Icon(Icons.refresh_outlined, size: 18),
                  label: const Text('Segarkan Halaman'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
