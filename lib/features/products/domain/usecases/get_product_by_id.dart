import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductById {
  final ProductRepository repository;

  GetProductById(this.repository);

  Future<Either<Failure, Product>> call(int id) {
    return repository.getProductById(id);
  }
}
