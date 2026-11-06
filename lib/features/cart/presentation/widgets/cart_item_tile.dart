import 'package:flutter/material.dart';

import '../../domain/entities/cart_item.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 70,
              child: Image.network(item.image,
                  fit: BoxFit.contain,
                  semanticLabel: item.title,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: \$${(item.subtotalCents / 100).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                          onPressed: onDecrement,
                          tooltip: 'Decrease quantity',
                          icon: const Icon(Icons.remove_circle_outline)),
                      Text('${item.quantity}'),
                      IconButton(
                          onPressed: onIncrement,
                          tooltip: 'Increase quantity',
                          icon: const Icon(Icons.add_circle_outline)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
                onPressed: onRemove,
                tooltip: 'Remove product',
                icon: const Icon(Icons.delete_outline)),
          ],
        ),
      ),
    );
  }
}
