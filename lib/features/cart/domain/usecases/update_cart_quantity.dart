import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/cart_repository.dart';

class UpdateCartQuantity {
  final CartRepository repository;

  UpdateCartQuantity(this.repository);

  Future<Either<Failure, void>> call(int productId, int quantity) {
    return repository.updateQuantity(productId, quantity);
  }
}
