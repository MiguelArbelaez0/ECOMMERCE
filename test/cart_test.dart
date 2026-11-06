import 'dart:io';
import 'package:ecommerce_clean_app/core/storage/open_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ecommerce_clean_app/core/error/exceptions.dart';
import 'package:ecommerce_clean_app/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:ecommerce_clean_app/features/cart/data/models/cart_item_model.dart';
import 'package:ecommerce_clean_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:ecommerce_clean_app/features/cart/domain/entities/cart_item.dart';
import 'package:ecommerce_clean_app/features/cart/domain/usecases/add_to_cart.dart';
import 'package:ecommerce_clean_app/features/cart/domain/usecases/clear_cart.dart';
import 'package:ecommerce_clean_app/features/cart/domain/usecases/get_cart_items.dart';
import 'package:ecommerce_clean_app/features/cart/domain/usecases/remove_from_cart.dart';
import 'package:ecommerce_clean_app/features/cart/domain/usecases/update_cart_quantity.dart';
import 'package:ecommerce_clean_app/features/cart/presentation/bloc/cart_bloc.dart';

const item = CartItem(
    productId: 1,
    title: 'Shirt',
    price: 0.1,
    image: 'https://example.com/a.png',
    quantity: 1);
CartBloc createCart(CartRepositoryImpl repo) => CartBloc(
    getCartItems: GetCartItems(repo),
    addToCart: AddToCart(repo),
    removeFromCart: RemoveFromCart(repo),
    updateCartQuantity: UpdateCartQuantity(repo),
    clearCart: ClearCart(repo));

void main() {
  late Directory dir;
  late Box<CartItemModel> box;
  late CartLocalDataSourceImpl source;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ecommerce_cart_test_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CartItemModelAdapter());
    }
    box = await openBoxSafely<CartItemModel>('cart_box');
    source = CartLocalDataSourceImpl(box);
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('empty cart and round trip entity conversion', () async {
    expect(await source.getCartItems(), isEmpty);
    expect(CartItemModel.fromEntity(item).toEntity(), item);
  });
  test('concurrent adds create one row and preserve every increment', () async {
    await Future.wait(List.generate(
        40, (_) => source.addToCart(CartItemModel.fromEntity(item))));
    expect(box.length, 1);
    expect((await source.getCartItems()).single.quantity, 40);
  });
  test('absolute quantity, zero removal, missing id and clear', () async {
    await source.addToCart(CartItemModel.fromEntity(item));
    await source.updateQuantity(1, 4);
    expect((await source.getCartItems()).single.quantity, 4);
    await source.updateQuantity(1, 0);
    await source.updateQuantity(77, 3);
    expect(await source.getCartItems(), isEmpty);
    await source.addToCart(CartItemModel.fromEntity(item));
    await source.removeFromCart(1);
    expect(await source.getCartItems(), isEmpty);
    await source.addToCart(CartItemModel.fromEntity(item));
    await source.clearCart();
    expect(await source.getCartItems(), isEmpty);
  });
  test('invalid input does not poison queue or overwrite existing data',
      () async {
    await source.addToCart(CartItemModel.fromEntity(item));
    for (final quantity in [-1, 10000]) {
      await expectLater(
          source.updateQuantity(1, quantity), throwsA(isA<CacheException>()));
    }
    for (final price in [double.nan, double.infinity, -1.0]) {
      await expectLater(
          source
              .addToCart(CartItemModel.fromEntity(item.copyWith(price: price))),
          throwsA(isA<CacheException>()));
    }
    expect((await source.getCartItems()).single.toEntity(), item);
  });
  test('reopen original adapter and legacy integer keys without migration',
      () async {
    await box.put(42, CartItemModel.fromEntity(item.copyWith(quantity: 3)));
    await box.close();
    box = await openBoxSafely<CartItemModel>('cart_box');
    source = CartLocalDataSourceImpl(box);
    expect((await source.getCartItems()).single.quantity, 3);
    await source.addToCart(CartItemModel.fromEntity(item));
    expect(box.keys.single, 42);
    expect((await source.getCartItems()).single.quantity, 4);
  });
  test(
      'invalid persisted rows and duplicates are preserved, not silently cleared',
      () async {
    await box.put(1, CartItemModel.fromEntity(item.copyWith(quantity: -1)));
    await expectLater(source.getCartItems(), throwsA(isA<CacheException>()));
    await expectLater(source.clearCart(), throwsA(isA<CacheException>()));
    expect(box.get(1)!.quantity, -1);
    await box.put(1, CartItemModel.fromEntity(item));
    await box.put(2, CartItemModel.fromEntity(item));
    await expectLater(source.getCartItems(), throwsA(isA<CacheException>()));
    await expectLater(source.addToCart(CartItemModel.fromEntity(item)),
        throwsA(isA<CacheException>()));
    expect(box.length, 2);
  });
  test('read and write errors become cache failures and later retry succeeds',
      () async {
    await box.close();
    final repo = CartRepositoryImpl(source);
    expect((await repo.getCartItems()).fold((f) => f.message, (_) => null),
        isNotNull);
    expect((await repo.addToCart(item)).fold((f) => f.message, (_) => null),
        isNotNull);
    box = await openBoxSafely<CartItemModel>('cart_box');
    source = CartLocalDataSourceImpl(box);
    await source.addToCart(CartItemModel.fromEntity(item));
    expect((await source.getCartItems()).single.toEntity(), item);
  });
  test(
      'physically damaged Hive file is not truncated when recovery is disabled',
      () async {
    await source.addToCart(CartItemModel.fromEntity(item));
    await box.close();
    final file = File('${dir.path}/cart_box.hive');
    await file.writeAsBytes([1, 2, 3], mode: FileMode.append);
    final before = await file.readAsBytes();
    await expectLater(
        openBoxSafely<CartItemModel>('cart_box'), throwsA(anything));
    expect(await file.readAsBytes(), before);
  });
  test('money rounds unit prices once and state lists are immutable', () {
    final input = [
      item.copyWith(quantity: 3),
      item.copyWith(productId: 2, price: 0.2)
    ];
    final state = CartState(items: input);
    input.clear();
    expect(state.totalCents, 50);
    expect(state.totalPrice, 0.5);
    expect(() => state.items.clear(), throwsUnsupportedError);
    expect(item.copyWith(price: 19.99, quantity: 3).subtotalCents, 5997);
  });
  test('bloc serializes different event types and relative quantity changes',
      () async {
    final bloc = createCart(CartRepositoryImpl(source));
    final done = bloc.stream.firstWhere((s) => !s.isLoading && s.items.isEmpty);
    bloc.add(const CartItemAdded(item));
    for (var i = 0; i < 10; i++) {
      bloc.add(const CartQuantityChanged(1, 1));
    }
    bloc.add(const CartItemRemoved(1));
    await done.timeout(const Duration(seconds: 5));
    expect(await source.getCartItems(), isEmpty);
    await bloc.close();
  });
  test('bloc confirms only persisted adds and recovers after quantity error',
      () async {
    final bloc = createCart(CartRepositoryImpl(source));
    var done = bloc.stream.firstWhere((s) => s.successMessage != null);
    bloc.add(const CartItemAdded(item));
    expect((await done).items.single.quantity, 1);
    done = bloc.stream.firstWhere((s) => s.errorMessage != null);
    bloc.add(const CartQuantityUpdated(productId: 1, quantity: -1));
    expect((await done).items.single.quantity, 1);
    done =
        bloc.stream.firstWhere((s) => !s.isLoading && s.errorMessage == null);
    bloc.add(const CartStarted());
    expect((await done).items.single, item);
    await bloc.close();
  });
}
