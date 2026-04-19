import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/cart_item.dart';

abstract class CartRepository {
  Future<Either<Failure, List<CartItem>>> getCartItems();

  Future<Either<Failure, void>> addToCart(CartItem item);

  Future<Either<Failure, void>> removeFromCart(int productId);

  Future<Either<Failure, void>> updateQuantity(int productId, int quantity);
}
