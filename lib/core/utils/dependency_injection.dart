import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/cart/data/datasources/cart_local_data_source.dart';
import '../../features/cart/data/models/cart_item_model.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/add_to_cart.dart';
import '../../features/cart/domain/usecases/get_cart_items.dart';
import '../../features/cart/domain/usecases/remove_from_cart.dart';
import '../../features/cart/domain/usecases/update_cart_quantity.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_product_by_id.dart';
import '../../features/products/domain/usecases/get_products.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../network/api_client.dart';

final GetIt getIt = GetIt.instance;

Future<void> initDependencies() async {
  final dio = ApiClient.createDio();
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(dio));

  await Hive.initFlutter();
  Hive.registerAdapter(CartItemModelAdapter());
  final cartBox = await Hive.openBox<CartItemModel>('cart_box');
  getIt.registerLazySingleton<Box<CartItemModel>>(() => cartBox);

  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt<ProductRemoteDataSource>()),
  );

  getIt.registerLazySingleton(() => GetProducts(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => GetProductById(getIt<ProductRepository>()));

  getIt.registerFactory(
    () => ProductBloc(
      getProducts: getIt<GetProducts>(),
      getProductById: getIt<GetProductById>(),
    ),
  );

  getIt.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(getIt<Box<CartItemModel>>()),
  );
  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(getIt<CartLocalDataSource>()),
  );

  getIt.registerLazySingleton(() => GetCartItems(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => AddToCart(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => RemoveFromCart(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => UpdateCartQuantity(getIt<CartRepository>()));

  getIt.registerFactory(
    () => CartBloc(
      getCartItems: getIt<GetCartItems>(),
      addToCart: getIt<AddToCart>(),
      removeFromCart: getIt<RemoveFromCart>(),
      updateCartQuantity: getIt<UpdateCartQuantity>(),
    ),
  );
}
