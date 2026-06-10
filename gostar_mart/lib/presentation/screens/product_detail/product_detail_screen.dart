import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  String _clientId = '';
  final ApiService _apiService = ApiService();
  List<String> _imageUrls = [];
  int _currentImageIndex = 0;
  bool _isLoadingAssets = true;
  final PageController _heroPageController = PageController();
  String _adminWhatsappNumber = '628123456789'; // default fallback
  Map<String, dynamic>? _fullProduct;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product['isFavorite'] as bool? ?? false;
    _loadClientIdAndDetail();
  }

  Future<void> _loadClientIdAndDetail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clientId = prefs.getString('clientId') ?? '';
    });
    _fetchProductDetail();
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductDetail() async {
    // Fetch product detail and public configs concurrently
    final productId = widget.product['id'];
    final futures = <Future>[
      _apiService.getPublicConfigs(),
    ];
    if (productId != null) {
      futures.add(_apiService.getProductDetail(productId.toString()));
    }

    try {
      final results = await Future.wait(futures);
      final configs = results[0] as Map<String, String>;
      if (configs.containsKey('admin_whatsapp_number') &&
          configs['admin_whatsapp_number']!.isNotEmpty) {
        _adminWhatsappNumber = configs['admin_whatsapp_number']!;
      }

      if (productId != null && results.length > 1) {
        final detail = results[1] as Map<String, dynamic>;
        final fetchedProduct = detail['product'] as Map<String, dynamic>? ?? detail;
        final assets = detail['assets'] as List<dynamic>? ?? [];
        setState(() {
          _fullProduct = fetchedProduct;
          _imageUrls = assets
              .map((asset) => ApiService.getImageUrl(asset['object_key'] as String?))
              .toList();
          if (_imageUrls.isEmpty && widget.product['thumbnail_url'] != null) {
            _imageUrls.add(widget.product['thumbnail_url'] as String);
          }
          _isLoadingAssets = false;
        });
      } else {
        setState(() {
          if (widget.product['thumbnail_url'] != null) {
            _imageUrls.add(widget.product['thumbnail_url'] as String);
          }
          _isLoadingAssets = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching product detail or configs: $e");
      setState(() {
        if (widget.product['thumbnail_url'] != null) {
          _imageUrls.add(widget.product['thumbnail_url'] as String);
        }
        _isLoadingAssets = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk terlebih dahulu untuk menggunakan fitur favorit.')),
      );
      return;
    }
    final productId = widget.product['id']?.toString() ?? '';
    if (productId.isEmpty) return;

    final wasFavorite = _isFavorite;
    setState(() {
      _isFavorite = !wasFavorite;
    });

    try {
      final isNowFav = await _apiService.toggleFavorite(_clientId, productId);
      setState(() {
        _isFavorite = isNowFav;
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
        _isFavorite = wasFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah favorit: $e')),
      );
    }
  }

  Future<void> _saveTransaction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> txStrings = prefs.getStringList('transactions') ?? [];
      
      final String txId = 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final tx = {
        'id': txId,
        'title': widget.product['title'] ?? '',
        'price': widget.product['price'] ?? '0',
        'category': widget.product['category'] ?? '',
        'location': widget.product['location'] ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Menghubungi Penjual',
        'thumbnail_url': widget.product['thumbnail_url'] ?? '',
      };
      
      txStrings.insert(0, jsonEncode(tx));
      await prefs.setStringList('transactions', txStrings);
    } catch (e) {
      debugPrint("Error saving transaction: $e");
    }
  }

  Future<void> _launchWhatsApp() async {
    final productTitle = widget.product['title'] as String? ?? 'produk ini';
    final message = Uri.encodeComponent(
      'Halo, saya tertarik dengan $productTitle. Boleh saya tanya lebih lanjut?',
    );
    final url = Uri.parse('https://wa.me/$_adminWhatsappNumber?text=$message');
    if (await canLaunchUrl(url)) {
      await _saveTransaction();
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch WhatsApp: $url');
    }
  }

  String _formatPrice(String priceStr) {
    final clean = priceStr.replaceAll('Rp ', '').replaceAll('.', '').trim();
    final amount = int.tryParse(clean) ?? 0;
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

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Diposting baru-baru ini';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays >= 30) {
        final months = (difference.inDays / 30).floor();
        return 'Diposting $months bulan lalu';
      } else if (difference.inDays >= 1) {
        return 'Diposting ${difference.inDays} hari lalu';
      } else if (difference.inHours >= 1) {
        return 'Diposting ${difference.inHours} jam lalu';
      } else if (difference.inMinutes >= 1) {
        return 'Diposting ${difference.inMinutes} menit lalu';
      } else {
        return 'Diposting baru saja';
      }
    } catch (e) {
      return 'Diposting baru-baru ini';
    }
  }

  void _openFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: _imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _fullProduct ?? widget.product;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final String description = product['description'] as String? ?? '';
    final specifications = product['specifications'] as List?;
    final String category = (product['category'] ?? product['category_name']) as String? ?? '';
    final String location = (product['location'] ?? product['location_name']) as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.midnightNavy.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldBorder, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.onSurface, size: 20),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.midnightNavy.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldBorder, width: 0.5),
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AppColors.sovereignGold : AppColors.onSurface,
                size: 20,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image area
                _buildHeroSection(product),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      if (category.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.sovereignGold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.goldBorder, width: 0.5),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.sovereignGold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Title
                      Text(
                        product['title'] as String? ?? '',
                        style: AppTextStyles.h2.copyWith(color: AppColors.onSurface),
                      ),

                      const SizedBox(height: 8),

                      // Price
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            _formatPrice(product['price']?.toString() ?? '0'),
                            style: AppTextStyles.priceLg
                                .copyWith(color: AppColors.sovereignGold),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '(Harga Khusus Member)',
                              style: AppTextStyles.labelSm
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Stock Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product['stock'] ?? 1} UNIT TERSEDIA',
                          style: AppTextStyles.labelSm.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location & Time card
                      if (location.trim().isNotEmpty || _getTimeAgo(product['created_at'] as String?).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.goldBorder.withOpacity(0.3), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (location.trim().isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.sovereignGold.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AppColors.sovereignGold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: AppTextStyles.bodySm.copyWith(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getTimeAgo(product['created_at'] as String?),
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (specifications != null && specifications.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(color: AppColors.outlineVariant.withOpacity(0.4), thickness: 0.5),
                        _buildSpecificationsRow(specifications),
                        Divider(color: AppColors.outlineVariant.withOpacity(0.4), thickness: 0.5),
                      ],

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Deskripsi',
                        style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description.isNotEmpty
                            ? description
                            : 'Hunian mahakarya arsitektur modern ini menawarkan kemewahan tiada tara di lokasi paling prestisius **[Sebutkan Lokasi]**, memadukan desain kontemporer nan megah dengan material premium seperti marmer impor dan sistem *smart home* mutakhir untuk kenyamanan hidup Anda yang maksimal. Berdiri di atas lahan seluas **[Luas Tanah]** m², properti eksklusif ini dilengkapi dengan **[Jumlah]** kamar tidur mewah, kolam renang pribadi yang menawan, serta area hiburan keluarga yang luas, menjadikannya pilihan sempurna bagi Anda yang mengutamakan privasi, gengsi, dan aksesibilitas cepat menuju pusat bisnis serta fasilitas internasional. Segera miliki aset investasi impian ini dengan menghubungi kami untuk sesi *private viewing* hari ini.',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant, height: 1.7),
                      ),

                      const SizedBox(height: 24),

                      Divider(
                        color: AppColors.outlineVariant.withOpacity(0.4),
                        thickness: 0.5,
                      ),

                      const SizedBox(height: 24),

                      // Seller Info (Styled like webview)
                      Text(
                        'INFORMASI PENJUAL',
                        style: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.goldBorder.withOpacity(0.3), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'ZL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        product['seller_name'] as String? ?? 'Zeth Lintin',
                                        style: AppTextStyles.labelLg.copyWith(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'VERIFIED OFFICIAL SELLER',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: Colors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom spacing for sticky bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky CTA Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
              decoration: BoxDecoration(
                color: AppColors.midnightNavy.withOpacity(0.97),
                border: Border(
                  top: BorderSide(
                    color: AppColors.sovereignGold.withOpacity(0.25),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Share/Info button
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                      color: AppColors.surfaceContainerLow,
                    ),
                    child: const Icon(Icons.share_outlined,
                        color: AppColors.onSurfaceVariant, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // CTA button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _launchWhatsApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sovereignGold,
                          foregroundColor: AppColors.midnightNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          shadowColor: AppColors.sovereignGold.withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Hubungi Penjual',
                              style: AppTextStyles.button
                                  .copyWith(color: AppColors.midnightNavy),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Map<String, dynamic> product) {
    return Container(
      height: 400,
      width: double.infinity,
      color: (product['color'] as Color? ?? AppColors.surfaceContainerLow).withOpacity(0.8),
      child: Stack(
        children: [
          _imageUrls.isNotEmpty
              ? PageView.builder(
                  controller: _heroPageController,
                  itemCount: _imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullScreenImage(context, index),
                      child: Image.network(
                        _imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            product['emoji'] as String? ?? '🏠',
                            style: const TextStyle(fontSize: 100),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    product['emoji'] as String? ?? '🏠',
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
          
          // Gradient overlay
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.midnightNavy.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Left Arrow
          if (_imageUrls.length > 1 && _currentImageIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    padding: const EdgeInsets.only(left: 6), // To center the iOS back icon
                    onPressed: () {
                      _heroPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),
            
          // Right Arrow
          if (_imageUrls.length > 1 && _currentImageIndex < _imageUrls.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                    onPressed: () {
                      _heroPageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),

          // Dots Indicator
          if (_imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? AppColors.sovereignGold
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          
          // Loading indicator if still loading assets and no images yet
          if (_isLoadingAssets && _imageUrls.isEmpty)
            const Center(
              child: CircularProgressIndicator(color: AppColors.sovereignGold),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsRow(List<dynamic> specs) {
    final validSpecs = specs.where((s) {
      if (s is! Map) return false;
      final k = s['key']?.toString().trim() ?? '';
      return k.isNotEmpty;
    }).toList();

    if (validSpecs.isEmpty) return const SizedBox.shrink();

    final preview = validSpecs.map((s) => s['key']?.toString() ?? '').join(', ');

    return InkWell(
      onTap: () => _showSpecificationsBottomSheet(context, validSpecs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(
              'Spesifikasi',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                preview,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSpecificationsBottomSheet(BuildContext context, List<dynamic> specs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.midnightNavy,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(color: AppColors.goldBorder, width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Spesifikasi',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 0.5, color: AppColors.goldBorder.withOpacity(0.5)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: specs.map<Widget>((spec) {
                        final key = spec['key']?.toString() ?? '';
                        final value = spec['value']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  key,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  value,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.sovereignGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sovereignGold,
                        foregroundColor: AppColors.midnightNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.midnightNavy,
                        ),
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

}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
            },
          ),
          
          // Left Arrow
          if (_currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
            
          // Right Arrow
          if (_currentIndex < widget.imageUrls.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
            
          // Counter
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
