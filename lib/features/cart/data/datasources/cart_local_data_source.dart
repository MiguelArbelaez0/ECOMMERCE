import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/cart_item_model.dart';

abstract class CartLocalDataSource {
  Future<List<CartItemModel>> getCartItems();

  Future<void> addToCart(CartItemModel item);

  Future<void> removeFromCart(int productId);

  Future<void> updateQuantity(int productId, int quantity);
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final Box<CartItemModel> box;

  CartLocalDataSourceImpl(this.box);

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      return box.values.toList(growable: false);
    } catch (e) {
      throw CacheException('Could not load cart items');
    }
  }

  @override
  Future<void> addToCart(CartItemModel item) async {
    try {
      final existingKey = box.keys.cast<dynamic>().firstWhere(
            (key) => box.get(key)?.productId == item.productId,
            orElse: () => null,
          );

      if (existingKey != null) {
        final existing = box.get(existingKey)!;
        await box.put(
          existingKey,
          CartItemModel(
            productId: existing.productId,
            title: existing.title,
            price: existing.price,
            image: existing.image,
            quantity: existing.quantity + item.quantity,
          ),
        );
      } else {
        await box.add(item);
      }
    } catch (e) {
      throw CacheException('Could not add item to cart');
    }
  }

  @override
  Future<void> removeFromCart(int productId) async {
    try {
      final key = box.keys.cast<dynamic>().firstWhere(
            (k) => box.get(k)?.productId == productId,
            orElse: () => null,
          );
      if (key != null) {
        await box.delete(key);
      }
    } catch (e) {
      throw CacheException('Could not remove item from cart');
    }
  }

  @override
  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      final key = box.keys.cast<dynamic>().firstWhere(
            (k) => box.get(k)?.productId == productId,
            orElse: () => null,
          );
      if (key == null) {
        return;
      }

      if (quantity <= 0) {
        await box.delete(key);
        return;
      }

      final current = box.get(key)!;
      await box.put(
        key,
        CartItemModel(
          productId: current.productId,
          title: current.title,
          price: current.price,
          image: current.image,
          quantity: quantity,
        ),
      );
    } catch (e) {
      throw CacheException('Could not update cart quantity');
    }
  }
}
