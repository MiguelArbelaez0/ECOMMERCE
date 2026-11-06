import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/cart_bloc.dart';
import '../widgets/cart_item_tile.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          IconButton(
            tooltip: 'Clear cart',
            onPressed: () => context.read<CartBloc>().add(const CartCleared()),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: () => context
                                .read<CartBloc>()
                                .add(const CartStarted()),
                            child: const Text('Retry')),
                      ],
                    )));
          }

          if (state.items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Column(
            children: [
              if (state.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return CartItemTile(
                      item: item,
                      onRemove: () => context
                          .read<CartBloc>()
                          .add(CartItemRemoved(item.productId)),
                      onIncrement: () => context
                          .read<CartBloc>()
                          .add(CartQuantityChanged(item.productId, 1)),
                      onDecrement: () => context
                          .read<CartBloc>()
                          .add(CartQuantityChanged(item.productId, -1)),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: \$${state.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    FilledButton(
                        onPressed: state.isLoading
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                      title: const Text('Demo checkout'),
                                      content: const Text(
                                          'This is a demo. No payment is taken and no order is placed.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'))
                                      ],
                                    )),
                        child: const Text('Demo checkout')),
                  ],
                ),
              ),
            ],
          );
        },
      )),
    );
  }
}
