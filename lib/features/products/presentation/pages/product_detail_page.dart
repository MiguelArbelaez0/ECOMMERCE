import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../domain/entities/product.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        child: Scaffold(
      appBar: AppBar(title: const Text('Product Detail')),
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          final message = state.errorMessage ?? state.successMessage;
          if (message != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: SafeArea(child: _ProductDetailContent(product: product)),
      ),
    ));
  }
}

class _ProductDetailContent extends StatelessWidget {
  final Product product;

  const _ProductDetailContent({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      height: 240,
                      child: Image.network(product.image,
                          fit: BoxFit.contain,
                          semanticLabel: product.title,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported, size: 64)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.indigo,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(product.category)),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) => FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              context.read<CartBloc>().add(
                                    CartItemAdded(
                                      CartItem(
                                        productId: product.id,
                                        title: product.title,
                                        price: product.price,
                                        image: product.image,
                                        quantity: 1,
                                      ),
                                    ),
                                  );
                            },
                      icon: const Icon(Icons.add_shopping_cart),
                      label:
                          Text(state.isLoading ? 'Saving...' : 'Add to cart'),
                    )),
          ),
        ],
      ),
    );
  }
}
