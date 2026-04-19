import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();

  Future<Either<Failure, Product>> getProductById(int id);
}
