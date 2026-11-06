import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _selectedCategory = 'Todas';
  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              final itemCount =
                  state.items.fold<int>(0, (sum, item) => sum + item.quantity);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Open cart',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<ProductBloc>()
                        .add(const ProductsRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProductsLoaded) {
            final categories = <String>{
              'Todas',
              ...state.products.map((e) => e.category)
            }.toList();
            final selectedCategory = categories.contains(_selectedCategory)
                ? _selectedCategory
                : 'Todas';
            final filteredProducts = selectedCategory == 'Todas'
                ? state.products
                : state.products
                    .where((p) => p.category == selectedCategory)
                    .toList();

            return Column(
              children: [
                _CategoryChips(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
                Expanded(
                  child: _ProductsGrid(products: filteredProducts),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final List<Product> products;

  const _ProductsGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('No products found in this category'));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / 240).floor().clamp(1, 6);
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent:
              340 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.8),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductDetailPage(product: product),
                ),
              );
            },
          );
        },
      );
    });
  }
}
