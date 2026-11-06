import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_clean_app/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:ecommerce_clean_app/features/cart/data/models/cart_item_model.dart';
import 'package:ecommerce_clean_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:ecommerce_clean_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:ecommerce_clean_app/core/error/failures.dart';
import 'package:ecommerce_clean_app/core/utils/either.dart';
import 'package:ecommerce_clean_app/features/products/domain/entities/product.dart';
import 'package:ecommerce_clean_app/features/products/domain/repositories/product_repository.dart';
import 'package:ecommerce_clean_app/features/products/data/models/product_model.dart';
import 'package:ecommerce_clean_app/features/products/domain/usecases/get_product_by_id.dart';
import 'package:ecommerce_clean_app/features/products/domain/usecases/get_products.dart';
import 'package:ecommerce_clean_app/features/products/presentation/bloc/product_bloc.dart';
import 'package:ecommerce_clean_app/features/products/presentation/pages/products_page.dart';
import 'cart_test.dart' show createCart;
import 'support/fixtures.dart';

void main() {
  late CartBloc cart;
  late ProductBloc products;
  late FixtureAdapter adapter;
  setUp(() async {
    adapter = FixtureAdapter(
        data: jsonEncode([
      productJson,
      {
        ...productJson,
        'id': 2,
        'title': 'Test ring',
        'category': 'jewelry',
        'price': 0.2
      }
    ]));
  });
  tearDown(() async {
    await cart.close();
    await products.close();
  });
  Future<void> mount(WidgetTester tester, Size size, {double scale = 1}) async {
    cart = createCart(CartRepositoryImpl(MemoryCartSource()));
    final repo = WidgetProductRepository(adapter);
    products = ProductBloc(
        getProducts: GetProducts(repo), getProductById: GetProductById(repo));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cart),
          BlocProvider.value(value: products),
        ],
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: const ProductsPage())));
    products.add(const ProductsRequested());
    cart.add(const CartStarted());
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 640),
    const Size(800, 900),
    const Size(1440, 900)
  ]) {
    testWidgets('catalog, category, detail, cart and checkout at $size',
        (tester) async {
      await mount(tester, size);
      expect(find.text('Test shirt'), findsOneWidget);
      await tester.ensureVisible(find.text('jewelry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('jewelry'));
      await tester.pumpAndSettle();
      expect(find.text('Test shirt'), findsNothing);
      await tester.tap(find.text('Test ring'));
      await tester.pumpAndSettle();
      expect(find.text('Product Detail'), findsOneWidget);
      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();
      expect(find.text('Added to cart'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Test shirt'), findsNothing);
      await tester.tap(find.byTooltip('Open cart'));
      await tester.pumpAndSettle();
      expect(find.text('Total: \$0.20'), findsOneWidget);
      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pumpAndSettle();
      expect(find.text('Total: \$0.40'), findsOneWidget);
      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pumpAndSettle();
      expect(find.text('Total: \$0.20'), findsOneWidget);
      await tester.tap(find.text('Demo checkout'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'This is a demo. No payment is taken and no order is placed.'),
          findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove product'));
      await tester.pumpAndSettle();
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('large text on narrow screen has no overflow in cart',
      (tester) async {
    await mount(tester, const Size(320, 740), scale: 2);
    await tester.tap(find.text('Test shirt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open cart'));
    await tester.pumpAndSettle();
    expect(find.text('Total: \$0.10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('server error retry and empty catalog are visible',
      (tester) async {
    adapter.status = 503;
    await mount(tester, const Size(390, 844));
    expect(find.text('Retry'), findsOneWidget);
    adapter.status = 200;
    adapter.data = '[]';
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No products found in this category'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class MemoryCartSource implements CartLocalDataSource {
  final items = <int, CartItemModel>{};
  @override
  Future<List<CartItemModel>> getCartItems() async => items.values.toList();
  @override
  Future<void> addToCart(CartItemModel item) async {
    final current = items[item.productId];
    items[item.productId] = CartItemModel.fromEntity(item
        .toEntity()
        .copyWith(quantity: (current?.quantity ?? 0) + item.quantity));
  }

  @override
  Future<void> removeFromCart(int id) async {
    items.remove(id);
  }

  @override
  Future<void> updateQuantity(int id, int quantity) async {
    if (quantity == 0) {
      items.remove(id);
      return;
    }
    items[id] = CartItemModel.fromEntity(
        items[id]!.toEntity().copyWith(quantity: quantity));
  }

  @override
  Future<void> clearCart() async => items.clear();
}

class WidgetProductRepository implements ProductRepository {
  final FixtureAdapter adapter;
  WidgetProductRepository(this.adapter);
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    if (adapter.status != 200) {
      return const Left(ServerFailure('Server unavailable'));
    }
    final rows = jsonDecode(adapter.data.toString()) as List;
    return Right(rows
        .map((row) =>
            ProductModel.fromJson(Map<String, dynamic>.from(row as Map))
                .toEntity())
        .toList());
  }

  @override
  Future<Either<Failure, Product>> getProductById(int id) async =>
      Right(ProductModel.fromJson(productJson).toEntity());
}
