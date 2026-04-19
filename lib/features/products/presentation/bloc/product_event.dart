part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductsRequested extends ProductEvent {
  const ProductsRequested();
}

class ProductDetailRequested extends ProductEvent {
  final int id;

  const ProductDetailRequested(this.id);

  @override
  List<Object?> get props => [id];
}
