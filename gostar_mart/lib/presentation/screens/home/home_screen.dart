import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/api_service.dart';
import '../product_detail/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final refreshNotifier = ValueNotifier<int>(0);
  static void triggerRefresh() {
    refreshNotifier.value++;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryId = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _loadingMore = false;

  List<Map<String, dynamic>> _apiCategories = [
    {'id': '', 'label': 'Semua', 'icon': Icons.grid_view_rounded},
    {'id': '1', 'label': 'Perlengkapan Rumah', 'icon': Icons.chair_outlined},
    {'id': '2', 'label': 'Rumah', 'icon': Icons.home_outlined},
    {'id': '3', 'label': 'Tanah', 'icon': Icons.map_outlined},
    {'id': '4', 'label': 'Mobil', 'icon': Icons.directions_car_outlined},
    {'id': '5', 'label': 'Motor', 'icon': Icons.motorcycle_outlined},
    {'id': '6', 'label': 'Elektronik', 'icon': Icons.devices_outlined},
    {'id': '7', 'label': 'Fashion', 'icon': Icons.checkroom_outlined},
    {'id': '8', 'label': 'Handphone', 'icon': Icons.smartphone_outlined},
    {'id': '9', 'label': 'Hobi & Olahraga', 'icon': Icons.emoji_events_outlined},
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'title': 'Villa Eksklusif Bali',
      'category': 'Properti',
      'price': 'Rp 8,5 M',
      'location': 'Seminyak, Bali',
      'isFavorite': true,
      'color': const Color(0xFF1A2A4A),
      'emoji': '🏡',
    },
    {
      'title': 'Lexus LX 600 2024',
      'category': 'Kendaraan',
      'price': 'Rp 2,8 M',
      'location': 'Jakarta Selatan',
      'isFavorite': false,
      'color': const Color(0xFF1A1A2A),
      'emoji': '🚗',
    },
    {
      'title': 'Rolex Submariner',
      'category': 'Jam Tangan',
      'price': 'Rp 450 Jt',
      'location': 'Kuningan, Jakarta',
      'isFavorite': true,
      'color': const Color(0xFF1A2A1A),
      'emoji': '⌚',
    },
    {
      'title': 'Berlian GIA 2.1ct',
      'category': 'Perhiasan',
      'price': 'Rp 320 Jt',
      'location': 'Sudirman, Jakarta',
      'isFavorite': false,
      'color': const Color(0xFF2A1A2A),
      'emoji': '💎',
    },
    {
      'title': 'Apartemen SCBD Lt.35',
      'category': 'Properti',
      'price': 'Rp 4,2 M',
      'location': 'SCBD, Jakarta',
      'isFavorite': false,
      'color': const Color(0xFF1A2A3A),
      'emoji': '🏙️',
    },
    {
      'title': 'BMW M5 Competition',
      'category': 'Kendaraan',
      'price': 'Rp 3,1 M',
      'location': 'Menteng, Jakarta',
      'isFavorite': true,
      'color': const Color(0xFF2A1A1A),
      'emoji': '🏎️',
    },
  ];

  String _userName = 'Budi';
  String _clientId = '';
  Set<String> _favoriteProductIds = {};

  @override
  void initState() {
    super.initState();
    _loadClientIdAndFavorites();
    _loadCategories();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
    HomeScreen.refreshNotifier.addListener(_onRefreshEvent);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final nextOffset = _offset + _limit;
    try {
      final ApiService api = ApiService();
      final products = await api.getProducts(
        query: _searchController.text,
        categoryId: _selectedCategoryId,
        limit: _limit,
        offset: nextOffset,
      );

      if (products.isEmpty) {
        setState(() {
          _hasMore = false;
          _loadingMore = false;
        });
        return;
      }

      setState(() {
        _offset = nextOffset;
        for (var p in products) {
          final status = (p['status'] as String? ?? 'ACTIVE').toUpperCase();
          final stock = p['stock'] as int? ?? 1;

          if (status == 'SOLD' || stock <= 0) {
            continue;
          }

          final thumbKey = (p['thumbnail_url'] as String? ?? '');
          final imageUrl = ApiService.getImageUrl(thumbKey);

          final catId = p['category_id']?.toString() ?? '';
          final categoryName = _apiCategories.firstWhere(
            (c) => c['id'].toString() == catId,
            orElse: () => {'label': 'Produk'},
          )['label'] as String? ?? 'Produk';

          _products.add({
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
            'isFavorite': _favoriteProductIds.contains(p['id'].toString()),
            'color': const Color(0xFF1A2A4A),
            'emoji': _getEmojiForCategory(categoryName),
            'status': status,
            'stock': stock,
          });
        }

        if (products.length < _limit) {
          _hasMore = false;
        }
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint("Error loading more products: $e");
      setState(() => _loadingMore = false);
    }
  }

  void _onRefreshEvent() {
    if (mounted) {
      _loadClientIdAndFavorites();
      _loadCategories();
      _fetchProducts(
        query: _searchController.text,
        categoryId: _selectedCategoryId,
      );
    }
  }

  Future<void> _loadClientIdAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('clientId') ?? '';
    final name = prefs.getString('name') ?? 'Budi';
    setState(() {
      _clientId = clientId;
      _userName = name;
    });
    if (clientId.isNotEmpty) {
      await _fetchFavorites();
    }
  }

  Future<void> _fetchFavorites() async {
    if (_clientId.isEmpty) return;
    try {
      final ApiService api = ApiService();
      final favList = await api.getFavorites(_clientId);
      setState(() {
        _favoriteProductIds = favList.map<String>((f) => f['id'].toString()).toSet();
        // Update current products list favorites state
        for (var p in _products) {
          p['isFavorite'] = _favoriteProductIds.contains(p['id'].toString());
        }
      });
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  Future<void> _toggleProductFavorite(Map<String, dynamic> product, int index) async {
    if (_clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk terlebih dahulu untuk menggunakan fitur favorit.')),
      );
      return;
    }
    final productId = product['id']?.toString() ?? '';
    if (productId.isEmpty) return;

    final wasFavorite = product['isFavorite'] as bool? ?? false;
    setState(() {
      product['isFavorite'] = !wasFavorite;
      if (wasFavorite) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });

    try {
      final ApiService api = ApiService();
      final isNowFav = await api.toggleFavorite(_clientId, productId);
      setState(() {
        product['isFavorite'] = isNowFav;
        if (isNowFav) {
          _favoriteProductIds.add(productId);
        } else {
          _favoriteProductIds.remove(productId);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowFav ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        product['isFavorite'] = wasFavorite;
        if (wasFavorite) {
          _favoriteProductIds.add(productId);
        } else {
          _favoriteProductIds.remove(productId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah favorit: $e')),
      );
    }
  }

  Future<void> _loadCategories() async {
    try {
      final ApiService api = ApiService();
      final categories = await api.getCategories();
      if (categories.isNotEmpty) {
        setState(() {
          _apiCategories = [
            {'id': '', 'label': 'Semua', 'icon': Icons.grid_view_rounded}
          ];
          for (var c in categories) {
            _apiCategories.add({
              'id': c['id'],
              'label': c['name'],
              'icon': _getIconForCategory(c['name']),
            });
          }
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'perlengkapan rumah':
        return Icons.chair_outlined;
      case 'rumah':
        return Icons.home_outlined;
      case 'tanah':
        return Icons.map_outlined;
      case 'mobil':
        return Icons.directions_car_outlined;
      case 'motor':
        return Icons.motorcycle_outlined;
      case 'elektronik':
        return Icons.devices_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'handphone':
        return Icons.smartphone_outlined;
      case 'hobi & olahraga':
        return Icons.emoji_events_outlined;
      default:
        return Icons.grid_view_rounded;
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

  Future<void> _fetchProducts({String? query, String? categoryId}) async {
    try {
      setState(() {
        _offset = 0;
        _hasMore = true;
        _loadingMore = false;
      });
      final ApiService api = ApiService();
      final products = await api.getProducts(
        query: query,
        categoryId: categoryId,
        limit: _limit,
        offset: 0,
      );
      setState(() {
        _products.clear();
        for (var p in products) {
          final status = (p['status'] as String? ?? 'ACTIVE').toUpperCase();
          final stock = p['stock'] as int? ?? 1;

          // Jangan tampilkan produk yang sold out
          if (status == 'SOLD' || stock <= 0) {
            continue;
          }

          // thumbnail_url dari API adalah object_key MinIO
          // Gunakan ApiService.getImageUrl() untuk konversi ke URL penuh
          final thumbKey = (p['thumbnail_url'] as String? ?? '');
          final imageUrl = ApiService.getImageUrl(thumbKey);

          // Ambil nama kategori yang sebenarnya dari ID kategori
          final catId = p['category_id']?.toString() ?? '';
          final categoryName = _apiCategories.firstWhere(
            (c) => c['id'].toString() == catId,
            orElse: () => {'label': 'Produk'},
          )['label'] as String? ?? 'Produk';

          _products.add({
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
            'isFavorite': _favoriteProductIds.contains(p['id'].toString()),
            'color': const Color(0xFF1A2A4A),
            'emoji': _getEmojiForCategory(categoryName),
            'status': status,
            'stock': stock,
          });
        }
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  @override
  void dispose() {
    HomeScreen.refreshNotifier.removeListener(_onRefreshEvent);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.sovereignGold,
          backgroundColor: AppColors.midnightNavy,
          strokeWidth: 2.5,
          onRefresh: () async {
            await _loadCategories();
            await _fetchProducts(
              query: _searchController.text,
              categoryId: _selectedCategoryId,
            );
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildGreeting()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoryRow()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Listing Eksklusif',
                        style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.goldBorder, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: _isGridView ? AppColors.sovereignGold : AppColors.outline,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.view_list_rounded,
                                size: 16,
                                color: !_isGridView ? AppColors.sovereignGold : AppColors.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                sliver: _isGridView
                    ? SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductCard(_products[index], index),
                          childCount: _products.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductListCard(_products[index], index),
                          childCount: _products.length,
                        ),
                      ),
              ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.sovereignGold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $_userName! 👋',
                      style: AppTextStyles.h1.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Temukan kebutuhan eksklusif Anda hari ini.',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.sovereignGold.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sovereignGold.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E2020),
                      Color(0xFF1A1C1C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'B',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.sovereignGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withOpacity(0.6),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.goldBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.sovereignGold.withOpacity(0.06),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: AppColors.outline, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Cari properti, kendaraan, dll...',
                  hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (value) {
                  _fetchProducts(
                    query: value,
                    categoryId: _selectedCategoryId,
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sovereignGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Text(
                'Filter',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.sovereignGold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _apiCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _apiCategories[index];
          final isActive = cat['id'] == _selectedCategoryId;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryId = cat['id'] as String;
              });
              _fetchProducts(
                query: _searchController.text,
                categoryId: _selectedCategoryId,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.sovereignGold.withOpacity(0.15)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive ? AppColors.sovereignGold : AppColors.outlineVariant,
                  width: isActive ? 1.0 : 0.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.sovereignGold.withOpacity(0.15),
                          blurRadius: 12,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: isActive ? AppColors.sovereignGold : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isActive ? AppColors.sovereignGold : AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final hasImage = product['thumbnail_url'] != null && (product['thumbnail_url'] as String).isNotEmpty;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ).then((_) => _fetchFavorites());
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.goldBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.sovereignGold.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Product visual
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Expanded(
                      flex: 11,
                      child: Container(
                        width: double.infinity,
                        color: AppColors.surfaceContainerLowest,
                        child: hasImage
                            ? ShaderMask(
                                shaderCallback: (rect) {
                                  return LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.4),
                                    ],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.srcOver,
                                child: Image.network(
                                  product['thumbnail_url'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildFallbackVisual(product),
                                ),
                              )
                            : _buildFallbackVisual(product),
                      ),
                    ),
                    Container(
                      height: 0.5,
                      color: AppColors.goldBorder,
                    ),
                    Expanded(
                      flex: 9,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product['category'] != null)
                                  Text(
                                    (product['category'] as String).toUpperCase(),
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.sovereignGold.withOpacity(0.8),
                                      fontSize: 8.5,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  product['title'] as String,
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatPrice(product['price'] as String),
                                  style: AppTextStyles.price.copyWith(
                                    color: AppColors.sovereignGold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 11,
                                      color: AppColors.outline,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        product['location'] as String,
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Favorite button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _toggleProductFavorite(product, index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.midnightNavy.withOpacity(0.65),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (product['isFavorite'] as bool)
                          ? AppColors.sovereignGold.withOpacity(0.6)
                          : AppColors.goldBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    (product['isFavorite'] as bool)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 15,
                    color: (product['isFavorite'] as bool)
                        ? AppColors.sovereignGold
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackVisual(Map<String, dynamic> product) {
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sovereignGold.withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            Text(
              product['emoji'] as String? ?? '✨',
              style: const TextStyle(fontSize: 44),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListCard(Map<String, dynamic> product, int index) {
    final hasImage = product['thumbnail_url'] != null && (product['thumbnail_url'] as String).isNotEmpty;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ).then((_) => _fetchFavorites());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.goldBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image / Thumbnail
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.goldBorder, width: 0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImage
                    ? Image.network(
                        product['thumbnail_url'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackVisualSmall(product),
                      )
                    : _buildFallbackVisualSmall(product),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product['category'] != null)
                    Text(
                      (product['category'] as String).toUpperCase(),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.sovereignGold.withOpacity(0.8),
                        fontSize: 8.5,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    product['title'] as String,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatPrice(product['price'] as String),
                    style: AppTextStyles.price.copyWith(
                      color: AppColors.sovereignGold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['location'] as String,
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
            // Favorite Button
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _toggleProductFavorite(product, index),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.midnightNavy.withOpacity(0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (product['isFavorite'] as bool)
                        ? AppColors.sovereignGold.withOpacity(0.6)
                        : AppColors.goldBorder,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  (product['isFavorite'] as bool)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 15,
                  color: (product['isFavorite'] as bool)
                      ? AppColors.sovereignGold
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackVisualSmall(Map<String, dynamic> product) {
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
          product['emoji'] as String? ?? '✨',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
