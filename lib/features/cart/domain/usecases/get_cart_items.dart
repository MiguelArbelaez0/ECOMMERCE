import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class GetCartItems {
  final CartRepository repository;

  GetCartItems(this.repository);

  Future<Either<Failure, List<CartItem>>> call() {
    return repository.getCartItems();
  }
}
