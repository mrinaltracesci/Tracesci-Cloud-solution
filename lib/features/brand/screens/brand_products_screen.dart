import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/brand_models.dart';
import '../providers/brand_provider.dart';
import 'brand_product_detail_screen.dart';

class BrandProductsScreen extends StatefulWidget {
  final bool embedded;

  const BrandProductsScreen({super.key, this.embedded = false});

  @override
  State<BrandProductsScreen> createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends State<BrandProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrandProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: provider.setSearch,
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
        ),
      ),
      body: PagedListView<BrandProduct>(
        items: provider.products,
        status: provider.status,
        errorMessage: provider.errorMessage,
        isNetworkError: provider.isNetworkError,
        loadingMore: provider.loadingMore,
        hasMore: provider.hasMoreProducts,
        onRefresh: () => provider.loadProducts(refresh: true),
        onLoadMore: provider.loadMoreProducts,
        onRetry: () => provider.loadProducts(),
        emptyState: const EmptyState(
          icon: Icons.widgets_rounded,
          title: 'No products',
          message: 'Products created in the web dashboard will appear here.',
        ),
        itemBuilder: (context, product, index) => _card(product),
      ),
    );
  }

  Widget _card(BrandProduct product) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BrandProductDetailScreen(productId: product.id),
        ),
      ),
      child: Row(
        children: [
          AppImage(url: product.image, width: 58, height: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  product.brand ?? product.price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusChip.forStatus(product.status),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${product.codes} codes · ${product.batches} batches',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
