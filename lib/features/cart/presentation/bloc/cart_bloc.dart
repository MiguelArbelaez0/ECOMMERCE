import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/add_to_cart.dart';
import '../../domain/usecases/get_cart_items.dart';
import '../../domain/usecases/remove_from_cart.dart';
import '../../domain/usecases/update_cart_quantity.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final GetCartItems getCartItems;
  final AddToCart addToCart;
  final RemoveFromCart removeFromCart;
  final UpdateCartQuantity updateCartQuantity;

  CartBloc({
    required this.getCartItems,
    required this.addToCart,
    required this.removeFromCart,
    required this.updateCartQuantity,
  }) : super(const CartState(isLoading: true)) {
    on<CartStarted>(_onStarted);
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartQuantityUpdated>(_onQuantityUpdated);
  }

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await getCartItems();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (items) => emit(CartState(items: items, isLoading: false)),
    );
  }

  Future<void> _onItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    final result = await addToCart(event.item);
    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (_) async => add(const CartStarted()),
    );
  }

  Future<void> _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    final result = await removeFromCart(event.productId);
    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (_) async => add(const CartStarted()),
    );
  }

  Future<void> _onQuantityUpdated(CartQuantityUpdated event, Emitter<CartState> emit) async {
    final result = await updateCartQuantity(event.productId, event.quantity);
    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (_) async => add(const CartStarted()),
    );
  }
}
