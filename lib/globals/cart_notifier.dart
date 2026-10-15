import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gocart/models/cart_item.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:pocketbase/pocketbase.dart';

class CartNotifier extends AsyncNotifier<Map<String, List<RecordModel>>> {
  final Map<String, int> _cartItems = {}; // Map to hold item IDs and their quantities

  @override
  Future<Map<String, List<RecordModel>>> build() async {
    return fetchStoreMap();
  }

  int getQuantity(String itemId) {
    return _cartItems[itemId] ?? 0;
  }

  Future<RecordModel?> getCartItem(RecordModel item) async {
    final pb = ref.read(pbProvider);
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return null;
    }

    try {
      final cartItem = await pb.collection('cart_items').getFirstListItem(
        'item = "${item.id}"',
        expand: 'item'
      );
     
      return cartItem;
    } catch (e, st) {
      logger.e('Failed to get cart item with item id: ${item.id}: $e');
      return null;
    }
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
        final quantity = cartItemRM.get<int>('quantity');
        for (var expandedItem in expand) {
          final item = expandedItem.get<RecordModel>('item');
          final itemId = item.get<String>('id');
          final store = item.get<String>('store');
          storeItemsMap.putIfAbsent(store, () => []);
          storeItemsMap[store]!.add(cartItemRM);
          _cartItems[itemId] = quantity;
        }
      }

      return storeItemsMap;
    } catch (e) {
      logger.e('Error fetching cart items: $e');
      return {};
    }
  }

  Future<void> removeFromCart(RecordModel cartItem, String store) async {
    state = AsyncValue.loading();
    final pb = ref.read(pbProvider);
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot remove item from cart.');
      return;
    }

    try {
      final itemId = cartItem.get<String>('item');
      _cartItems.remove(itemId);
      await pb.collection('cart_items').delete(cartItem.id);
      logger.i('removing item: ${cartItem.id} from cart_items');
      Map<String, List<RecordModel>> currentStoreCartItems = state.value ?? {};
      if (currentStoreCartItems == null || currentStoreCartItems.isEmpty) {
        state = AsyncValue.data({});
        return;
      }

      List<RecordModel> currentCartItems = currentStoreCartItems[store] ?? [];
      currentCartItems.removeWhere((cItem) => cItem.id == cartItem.id);
      currentStoreCartItems[store] = currentCartItems;
      state = AsyncValue.data(currentStoreCartItems);
    } catch (e, st) {
      logger.e("Failed to remove cart item: $cartItem from cart: $e");
      state = AsyncValue.error(e, st);
      return;
    }
  }

  Future<void> addToCart(RecordModel item, int quantity) async {
    state = AsyncValue.loading();
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

      final store = item.get<String>('store');
      if (existingCartItems.items.isNotEmpty) {
        final existingCartItem = existingCartItems.items.first;
        final updatedCartItem = await pb.collection('cart_items').update(
          existingCartItem.id,
          body: {
            'quantity': quantity,
          },
          expand: 'item',
        );
        logger.i('Updating cart item ($existingCartItem) quantity to $quantity');
        Map<String, List<RecordModel>> storeItemsMap = state.value ?? {};
        List<RecordModel> cartItems = storeItemsMap[store] ?? [];
        final listIndex = cartItems.indexWhere((cartItem) => cartItem.id == updatedCartItem.id);
        if (listIndex >= 0) {
          cartItems[listIndex] = updatedCartItem;
        }
        state = AsyncValue.data(storeItemsMap);
      } else {
        final newCartItem = await pb.collection('cart_items').create(
          body: {
            'quantity': quantity,
            'item': item.id,
            'user': pb.authStore.record?.id,
          },
          expand: 'item',
        );
        logger.i('creating cart item');
        Map<String, List<RecordModel>> storeItemsMap = state.value ?? {};
        storeItemsMap.putIfAbsent(store, () => []).add(newCartItem);
        state = AsyncValue.data(storeItemsMap);
      }
      _cartItems[item.id] = quantity;
    } catch (e, st) {
      logger.e('Error adding item to cart: $e');
      state = AsyncValue.error(e, st);
      return;
    }
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Map<String, List<RecordModel>>>(() {
  return CartNotifier();
});