import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/cart_item_model.dart';

abstract class CartLocalDataSource {
  Future<List<CartItemModel>> getCartItems();

  Future<void> addToCart(CartItemModel item);

  Future<void> removeFromCart(int productId);

  Future<void> updateQuantity(int productId, int quantity);

  Future<void> clearCart();
}

/// Serializes reads and writes through one queue, including after failures.
/// Keeps the original Hive keys and adapter schema; never rewrites legacy data.
class CartLocalDataSourceImpl implements CartLocalDataSource {
  final Box<CartItemModel> box;
  Future<void> _pending = Future<void>.value();

  CartLocalDataSourceImpl(this.box);

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  void _validate(CartItemModel item) {
    if (item.productId <= 0 ||
        item.title.trim().isEmpty ||
        !item.price.isFinite ||
        item.price < 0 ||
        item.price > 1000000000 ||
        item.quantity < 1 ||
        item.quantity > 9999) {
      throw CacheException('Cart data is invalid. Stored data was preserved.');
    }
  }

  List<CartItemModel> _read() {
    final items = box.values.toList(growable: false);
    final ids = <int>{};
    for (final item in items) {
      _validate(item);
      if (!ids.add(item.productId)) {
        throw CacheException('Duplicate cart data. Stored data was preserved.');
      }
    }
    return items;
  }

  Future<T> _guard<T>(Future<T> Function() operation) => _serialized(() async {
        try {
          return await operation();
        } on CacheException {
          rethrow;
        } catch (_) {
          throw CacheException('Unable to access cart storage. Please retry.');
        }
      });

  dynamic _key(int id) {
    for (final key in box.keys) {
      if (box.get(key)?.productId == id) return key;
    }
    return null;
  }

  @override
  Future<List<CartItemModel>> getCartItems() => _guard(() async => _read());

  @override
  Future<void> addToCart(CartItemModel item) => _guard(() async {
        _validate(item);
        _read();
        final key = _key(item.productId);
        if (key == null) {
          await box.add(item);
        } else {
          final current = box.get(key)!;
          final updated = CartItemModel.fromEntity(current.toEntity().copyWith(
                quantity: current.quantity + item.quantity,
              ));
          _validate(updated);
          await box.put(key, updated);
        }
      });

  @override
  Future<void> removeFromCart(int productId) => _guard(() async {
        _read();
        final key = _key(productId);
        if (key != null) await box.delete(key);
      });

  @override
  Future<void> updateQuantity(int productId, int quantity) => _guard(() async {
        if (quantity < 0 || quantity > 9999) {
          throw CacheException('Quantity must be between 0 and 9999.');
        }
        _read();
        final key = _key(productId);
        if (key == null) return;
        if (quantity == 0) {
          await box.delete(key);
        } else {
          final current = box.get(key)!;
          await box.put(
              key,
              CartItemModel.fromEntity(
                current.toEntity().copyWith(quantity: quantity),
              ));
        }
      });

  @override
  Future<void> clearCart() => _guard(() async {
        _read();
        await box.clear();
      });
}
