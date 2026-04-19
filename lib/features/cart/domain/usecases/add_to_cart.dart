import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class AddToCart {
  final CartRepository repository;

  AddToCart(this.repository);

  Future<Either<Failure, void>> call(CartItem item) {
    return repository.addToCart(item);
  }
}
