import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'product_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<dynamic> _products = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _loadingMore = false;
  String _role = 'RESELLER';


  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearch);
    _scrollController.addListener(_onScroll);
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
    final data = await ApiService.getProducts(limit: _limit, offset: nextOffset);

    if (mounted) {
      setState(() {
        _offset = nextOffset;
        final newItems = data.where((p) => p['status'] != 'SOLD').toList();
        if (newItems.length < _limit) {
          _hasMore = false;
        }
        _products.addAll(newItems);
        _onSearch();
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProducts(),
      _loadStats(),
    ]);
  }

  Future<void> _loadStats() async {
    final data = await ApiService.getStats();
    setState(() {
      _stats = data;
      if (data != null && data['role'] != null) {
        _role = data['role'];
      }
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _products
          : _products.where((p) => (p['title'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _offset = 0;
      _hasMore = true;
      _loadingMore = false;
    });
    final data = await ApiService.getProducts(limit: _limit, offset: 0);
    setState(() {
      _products = data.where((p) => p['status'] != 'SOLD').toList();
      _filtered = _products;
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.secondary,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
              : CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: _buildCompactHeader(),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchSection(),
                            const SizedBox(height: 20),
                            if (_filtered.isEmpty) 
                              SizedBox(height: 300, child: _buildEmpty())
                            else ...[
                              if (_filtered.isNotEmpty) ...[
                                _buildFeaturedCard(context, _filtered[0]),
                                const SizedBox(height: 20),
                              ],
                              if (_filtered.length > 1)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filtered.length - 1,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemBuilder: (ctx, i) => _buildSmallCard(ctx, _filtered[i + 1]),
                                ),
                              if (_loadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(color: AppColors.secondary),
                                  ),
                                ),
                              const SizedBox(height: 100),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final name = _stats?['name'] ?? 'User';
    final role = _stats?['role'] ?? 'GUEST';
    final balance = _stats?['available_balance'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.secondary,
                  child: Text(name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(role,
                        style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w900, color: AppColors.secondary, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('SALDO',
                  style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary.withOpacity(0.4), letterSpacing: 1)),
              Text(_formatRupiah(balance),
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 54,
      decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.outline),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: GoogleFonts.inter(color: AppColors.outline.withOpacity(0.6), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () { _searchController.clear(); },
              child: const Icon(Icons.close, color: AppColors.outline, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 60, color: AppColors.outline),
          const SizedBox(height: 16),
          Text('Belum ada produk tersedia', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, dynamic product) {
    final title = product['title'] ?? 'Produk';
    final price = product['price'] ?? 0;
    
    // Role-based commission
    final commission = (_role == 'MEMBER')
        ? (product['member_commission_amount'] ?? 0)
        : (product['reseller_commission_amount'] ?? 0);
    
    final description = product['description'] ?? '';

    // ListProducts returns thumbnail_url directly; GetProduct returns nested assets
    final thumbKey = (product['thumbnail_url'] ?? '').toString();
    final imageUrl = thumbKey.isNotEmpty ? ApiService.getImageUrl(thumbKey) : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 16))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder())
                        : _imagePlaceholder(),
                  ),
                  if (product['status'] == 'SOLD')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SOLD OUT',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('KOMISI: ${_formatRupiah(commission)}',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900,
                            color: AppColors.tertiary, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  Text(title,
                      style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppColors.primary, height: 1.1)),
                  const SizedBox(height: 8),
                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatRupiah(price),
                          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), elevation: 0),
                        child: Row(children: [
                          Text('Detail', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(BuildContext context, dynamic product) {
    final title = product['title'] ?? 'Produk';
    final price = product['price'] ?? 0;
    
    // Role-based commission
    final commission = (_role == 'MEMBER')
        ? (product['member_commission_amount'] ?? 0)
        : (product['reseller_commission_amount'] ?? 0);
    
    final thumbKey = (product['thumbnail_url'] ?? '').toString();

    final imageUrl = thumbKey.isNotEmpty ? ApiService.getImageUrl(thumbKey) : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder())
                        : _imagePlaceholder(),
                  ),
                  if (product['status'] == 'SOLD')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SOLD OUT',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Komisi: ${_formatRupiah(commission)}',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                  const SizedBox(height: 4),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text(_formatRupiah(price),
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(child: Icon(Icons.image_outlined, size: 40, color: AppColors.outline)),
    );
  }
}
