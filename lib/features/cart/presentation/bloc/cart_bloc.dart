import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/add_to_cart.dart';
import '../../domain/usecases/clear_cart.dart';
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
  final ClearCart clearCart;

  CartBloc({
    required this.getCartItems,
    required this.addToCart,
    required this.removeFromCart,
    required this.updateCartQuantity,
    required this.clearCart,
  }) : super(CartState(isLoading: true)) {
    // A single event bucket preserves ordering across all cart event types.
    on<CartEvent>(_onEvent,
        transformer: (events, mapper) => events.asyncExpand(mapper));
  }

  Future<void> _onEvent(CartEvent event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true));
    if (event is CartStarted) {
      await _load(emit);
      return;
    }
    final Either<Failure, void> result;
    if (event is CartItemAdded) {
      result = await addToCart(event.item);
    } else if (event is CartItemRemoved) {
      result = await removeFromCart(event.productId);
    } else if (event is CartQuantityUpdated) {
      result = await updateCartQuantity(event.productId, event.quantity);
    } else if (event is CartQuantityChanged) {
      final item =
          state.items.where((i) => i.productId == event.productId).firstOrNull;
      if (item == null) {
        emit(state.copyWith(isLoading: false));
        return;
      }
      result = await updateCartQuantity(
          event.productId, item.quantity + event.delta);
    } else if (event is CartCleared) {
      result = await clearCart();
    } else {
      emit(state.copyWith(isLoading: false));
      return;
    }
    await result.fold(
      (failure) async =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) =>
          _load(emit, message: event is CartItemAdded ? 'Added to cart' : null),
    );
  }

  Future<void> _load(Emitter<CartState> emit, {String? message}) async {
    final result = await getCartItems();
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (items) => emit(CartState(items: items, successMessage: message)),
    );
  }
}
