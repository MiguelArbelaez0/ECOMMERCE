part of 'cart_bloc.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  CartState({
    List<CartItem> items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  }) : items = List.unmodifiable(items);

  int get totalCents =>
      items.fold<int>(0, (sum, item) => sum + item.subtotalCents);

  double get totalPrice => totalCents / 100;

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [items, isLoading, errorMessage, successMessage];
}
