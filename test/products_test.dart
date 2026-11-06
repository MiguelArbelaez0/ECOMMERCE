import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_clean_app/core/error/failures.dart';
import 'package:ecommerce_clean_app/core/utils/either.dart';
import 'package:ecommerce_clean_app/features/products/data/datasources/product_remote_data_source.dart';
import 'package:ecommerce_clean_app/features/products/data/models/product_model.dart';
import 'package:ecommerce_clean_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:ecommerce_clean_app/features/products/domain/entities/product.dart';
import 'package:ecommerce_clean_app/features/products/domain/repositories/product_repository.dart';
import 'package:ecommerce_clean_app/features/products/domain/usecases/get_product_by_id.dart';
import 'package:ecommerce_clean_app/features/products/domain/usecases/get_products.dart';
import 'package:ecommerce_clean_app/features/products/presentation/bloc/product_bloc.dart';
import 'support/fixtures.dart';

class PendingRepository implements ProductRepository {
  final requests = <Completer<Either<Failure, List<Product>>>>[];
  final detail = Completer<Either<Failure, Product>>();
  @override
  Future<Either<Failure, List<Product>>> getProducts() {
    final c = Completer<Either<Failure, List<Product>>>();
    requests.add(c);
    return c.future;
  }

  @override
  Future<Either<Failure, Product>> getProductById(int id) => detail.future;
}

void main() {
  late FixtureAdapter adapter;
  late ProductRepositoryImpl repo;
  setUp(() {
    adapter = FixtureAdapter(data: jsonEncode([productJson]));
    repo = ProductRepositoryImpl(
        ProductRemoteDataSourceImpl(fixtureClient(adapter)));
  });
  test('HTTP catalog, detail and integer prices convert to entities', () async {
    expect((await GetProducts(repo)()).fold((f) => null, (p) => p.single.title),
        'Test shirt');
    adapter.data = jsonEncode({...productJson, 'price': 12});
    expect((await GetProductById(repo)(1)).fold((f) => null, (p) => p.price),
        12.0);
  });
  test('empty HTTP catalog is successful', () async {
    adapter.data = '[]';
    expect((await repo.getProducts()).fold((f) => null, (p) => p), isEmpty);
  });
  for (final status in [400, 404, 429, 500, 503]) {
    test('HTTP $status is a safe server failure and retry recovers', () async {
      adapter.status = status;
      adapter.data = jsonEncode({'secret': 'do not show raw response'});
      final failure = (await repo.getProducts()).fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure!.message, contains('$status'));
      expect(failure.message, isNot(contains('secret')));
      adapter.status = 200;
      adapter.data = jsonEncode([productJson]);
      expect((await repo.getProducts()).fold((f) => null, (p) => p.length), 1);
    });
  }
  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.connectionError
  ]) {
    test('$type maps to network failure for catalog and detail', () async {
      adapter.failure = type;
      expect((await repo.getProducts()).fold((f) => f, (_) => null),
          isA<NetworkFailure>());
      expect((await repo.getProductById(1)).fold((f) => f, (_) => null),
          isA<NetworkFailure>());
    });
  }
  for (final data in ['{}', '[null]', '[{"id":1}]', '[{"id":-1,"price":2}]']) {
    test('malformed catalog $data is a server failure', () async {
      adapter.data = data;
      expect((await repo.getProducts()).fold((f) => f, (_) => null),
          isA<ServerFailure>());
    });
  }
  test('model rejects unsafe numeric values and missing fields', () {
    for (final price in [-1, double.nan, double.infinity]) {
      expect(() => ProductModel.fromJson({...productJson, 'price': price}),
          throwsFormatException);
    }
    expect(() => ProductModel.fromJson({...productJson, 'title': null}),
        throwsFormatException);
  });
  test('new catalog response wins even when an older request finishes later',
      () async {
    final pending = PendingRepository();
    final bloc = ProductBloc(
        getProducts: GetProducts(pending),
        getProductById: GetProductById(pending));
    bloc.add(const ProductsRequested());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, isA<ProductLoading>());
    bloc.add(const ProductsRequested());
    await Future<void>.delayed(Duration.zero);
    final done = bloc.stream.firstWhere((s) => s is ProductsLoaded);
    pending.requests[1]
        .complete(Right([ProductModel.fromJson(productJson).toEntity()]));
    await done;
    pending.requests[0].complete(const Left(ServerFailure('obsolete')));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, isA<ProductsLoaded>());
    await bloc.close();
  });
  test('latest detail response supersedes a pending catalog request', () async {
    final pending = PendingRepository();
    final bloc = ProductBloc(
        getProducts: GetProducts(pending),
        getProductById: GetProductById(pending));
    bloc.add(const ProductsRequested());
    await Future<void>.delayed(Duration.zero);
    bloc.add(const ProductDetailRequested(1));
    await Future<void>.delayed(Duration.zero);
    final done = bloc.stream.firstWhere((s) => s is ProductDetailLoaded);
    pending.detail
        .complete(Right(ProductModel.fromJson(productJson).toEntity()));
    await done;
    pending.requests.single.complete(const Right([]));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, isA<ProductDetailLoaded>());
    await bloc.close();
  });
  test('bloc error then successful retry and immutable catalog state',
      () async {
    final bloc = ProductBloc(
        getProducts: GetProducts(repo), getProductById: GetProductById(repo));
    adapter.status = 500;
    var done = bloc.stream.firstWhere((s) => s is ProductError);
    bloc.add(const ProductsRequested());
    await done;
    adapter.status = 200;
    done = bloc.stream.firstWhere((s) => s is ProductsLoaded);
    bloc.add(const ProductsRequested());
    final state = await done as ProductsLoaded;
    expect(() => state.products.clear(), throwsUnsupportedError);
    await bloc.close();
  });
}
