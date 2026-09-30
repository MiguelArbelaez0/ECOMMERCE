import 'package:ecommerce_clean_app/core/error/failures.dart';
import 'package:ecommerce_clean_app/core/utils/either.dart';
import 'package:ecommerce_clean_app/features/products/domain/entities/product.dart';
import 'package:ecommerce_clean_app/features/products/domain/repositories/product_repository.dart';
import 'package:ecommerce_clean_app/features/products/domain/usecases/get_products.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delegates product loading to the repository contract', () async {
    final product = Product(
      id: 1,
      title: 'Test item',
      description: 'Item description',
      category: 'test',
      price: 12.5,
      image: 'https://example.com/item.png',
    );
    final repository = _FakeProductRepository(products: [product]);

    final result = await GetProducts(repository)();

    expect(repository.getProductsCalled, isTrue);
    expect(
        result.fold((failure) => failure, (products) => products), [product]);
  });
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository({required this.products});

  final List<Product> products;
  bool getProductsCalled = false;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    getProductsCalled = true;
    return Right(products);
  }

  @override
  Future<Either<Failure, Product>> getProductById(int id) async =>
      Left(const UnexpectedFailure('Not implemented'));
}
