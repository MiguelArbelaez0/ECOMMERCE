import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/cart_repository.dart';

class RemoveFromCart {
  final CartRepository repository;

  RemoveFromCart(this.repository);

  Future<Either<Failure, void>> call(int productId) {
    return repository.removeFromCart(productId);
  }
}
