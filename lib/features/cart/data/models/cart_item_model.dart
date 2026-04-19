import 'package:hive/hive.dart';

import '../../domain/entities/cart_item.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 0)
class CartItemModel extends HiveObject {
  @HiveField(0)
  final int productId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String image;

  @HiveField(4)
  final int quantity;

  CartItemModel({
    required this.productId,
    required this.title,
    required this.price,
    required this.image,
    required this.quantity,
  });

  factory CartItemModel.fromEntity(CartItem entity) {
    return CartItemModel(
      productId: entity.productId,
      title: entity.title,
      price: entity.price,
      image: entity.image,
      quantity: entity.quantity,
    );
  }

  CartItem toEntity() {
    return CartItem(
      productId: productId,
      title: title,
      price: price,
      image: image,
      quantity: quantity,
    );
  }
}
