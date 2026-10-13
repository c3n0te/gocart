import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gocart/models/cart_item.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:pocketbase/pocketbase.dart';

class CartNotifier extends AsyncNotifier<Map<String, List<RecordModel>>> {
  @override
  Future<Map<String, List<RecordModel>>> build() async {
    return fetchStoreMap();
  }

  Future<List<CartItem>> _fetchCartItems() async {
    final pb = ref.read(pbProvider);
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return [];
    }
    
    try {
      final cartItems = await pb.collection('cart_items').getList(
        filter: 'user="${pb.authStore.record?.id}"',
      );

      return cartItems.items.map((r) => CartItem.fromRecord(r)).toList();
    } catch (e) {
      logger.e('Error fetching cart items: $e');
      return [];
    }

  }

  Future<Map<String, List<RecordModel>>> fetchStoreMap() async {
    final pb = ref.read(pbProvider);
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return {};
    }
    
    Map<String, List<RecordModel>> storeItemsMap = {};
    try {
      final cartItems = await pb.collection('cart_items').getList(
        filter: 'user="${pb.authStore.record?.id}"',
        expand: 'item',
      );

      for (var cartItemRM in cartItems.items) {
        final expand = cartItemRM.get<List<RecordModel>>('expand');
        for (var expandedItem in expand) {
          final item = expandedItem.get<RecordModel>('item');
          final store = item.get<String>('store');
          storeItemsMap.putIfAbsent(store, () => []);
          storeItemsMap[store]!.add(cartItemRM);
        }
      }

      return storeItemsMap;
    } catch (e) {
      logger.e('Error fetching cart items: $e');
      return {};
    }
  }

  Future<void> removeFromCart(RecordModel cartItem) async {
    final pb = ref.read(pbProvider);
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot remove item from cart.');
      return;
    }

    try {
      await pb.collection('cart_items').delete(cartItem.id);
      logger.i('removing item: ${cartItem.id} from cart_items');
    } catch (e) {
      logger.e("Failed to remove cart item: $cartItem from cart: $e");
      return;
    }
  }

  Future<void> addToCart(RecordModel item, int quantity) async {
    final pb = ref.read(pbProvider);
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot add item to cart.');
      return;
    }

    try { 
      // if the item is already in the cart, update the quantity instead of creating a new record
      final existingCartItems = await pb.collection('cart_items').getList(
        filter: 'user="${pb.authStore.record?.id}" && item="${item.id}"',
      );

      if (existingCartItems.items.isNotEmpty) {
        final existingCartItem = existingCartItems.items.first;
        await pb.collection('cart_items').update(
          existingCartItem.id,
          body: {
            'quantity': quantity,
          },
        );
        logger.i('Updating cart item ($existingCartItem) quantity to $quantity');
      } else {
        await pb.collection('cart_items').create(
          body: {
            'quantity': quantity,
            'item': item.id,
            'user': pb.authStore.record?.id,
          },
        );
        logger.i('creating cart item');
      }
    } catch (e) {
      logger.e('Error adding item to cart: $e');
      return;
    }
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Map<String, List<RecordModel>>>(() {
  return CartNotifier();
});