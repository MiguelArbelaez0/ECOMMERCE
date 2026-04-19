import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import '../../domain/usecases/get_product_by_id.dart';
import '../../domain/usecases/get_products.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts getProducts;
  final GetProductById getProductById;

  ProductBloc({required this.getProducts, required this.getProductById})
      : super(const ProductInitial()) {
    on<ProductsRequested>(_onProductsRequested);
    on<ProductDetailRequested>(_onProductDetailRequested);
  }

  Future<void> _onProductsRequested(
    ProductsRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    final result = await getProducts();
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  Future<void> _onProductDetailRequested(
    ProductDetailRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    final result = await getProductById(event.id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }
}
