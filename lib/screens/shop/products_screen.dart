import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'customize_select_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  bool _lowToHigh = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await ShopService.instance.getProducts();
      if (mounted) setState(() => _products = products);
    } catch (_) {
      // Keep previous state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Product> get _sorted {
    final list = [..._products];
    list.sort((a, b) => _lowToHigh ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: Icon(_lowToHigh ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _lowToHigh ? 'Price: Low to High' : 'Price: High to Low',
            onPressed: () => setState(() => _lowToHigh = !_lowToHigh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _products.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [EmptyState(icon: Icons.credit_card_outlined, message: 'No products available right now.')],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _sorted.length,
                      itemBuilder: (context, i) {
                        final product = _sorted[i];
                        return _ProductCard(product: product);
                      },
                    ),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomizeSelectScreen(product: product)),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: AppColors.inputBackground,
                child: product.imageFront != null
                    ? Image.network('https://demo.taplerr.com${product.imageFront}', fit: BoxFit.cover)
                    : const Icon(Icons.credit_card, size: 40, color: AppColors.placeholder),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('RM ${product.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
