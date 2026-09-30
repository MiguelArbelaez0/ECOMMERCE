import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/cart_repository.dart';

class ClearCart {
  final CartRepository repository;

  const ClearCart(this.repository);

  Future<Either<Failure, void>> call() => repository.clearCart();
}
