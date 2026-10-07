import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final StreamController<RecordModel?> _cartStreamController = StreamController<RecordModel?>.broadcast();
  late Future<Map<String, List<RecordModel>>> _itemsFuture;
  late Future<Map<String, int>> _cartItemsFuture;
  Map<String, int> _cartItems = {}; // Map to hold item IDs and their quantities
  Future<void>? _pendingCartOp;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _subscribeToCart();
    _itemsFuture = _fetchItems();
    _cartItemsFuture = _fetchCartItems();
    return;
  }

  @override
  void dispose() {
    // Unsubscribe from PocketBase to prevent memory leaks or duplicate connections
    pb.collection('cart_items').unsubscribe('*');
    _cartStreamController.close();
    super.dispose();
  }

  int _getQuantity(String itemId) {
    return _cartItems[itemId] ?? 0;
  }

  Future<void> _subscribeToCart() async {
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return;
    }

    try{
      // Subscribe to the specific user's cart collection
      await pb.collection('cart_items').subscribe('*', (ev) {
        // e.action can be 'create', 'update', or 'delete'
        // Feed the updated model event into our stream controller
        logger.i('HomeScreen real time event: $ev');
        _cartStreamController.add(ev.record);
        final itemId = ev.record?.get<String>('item');
        final quantity = ev.record?.get<int>('quantity');
        if (itemId != null && quantity != null) {
            _cartItems[itemId] = quantity;
        }

        setState(() {}); // trigger widget rebuild
      },
        filter: 'user = "${pb.authStore.record?.id}"',
      );

      logger.i('Subscribed to cart item table events');
    } catch (e) {
      logger.e('Failed to subscribe to cart items table events: $e');
      return;
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _itemsFuture = _fetchItems();
      _cartItemsFuture = _fetchCartItems(); 
    });
    await _itemsFuture; // Wait for the future to complete before rebuilding
    await _cartItemsFuture;
  }

  Future<List<RecordModel>> _fetchListItems() async {
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return [];
    }

    try {
      final result = await pb.collection('list_items').getList(
        filter: 'user_id="${pb.authStore.record?.id}"',
      );
      return result.items;
    } catch (e) {
      logger.e('Error fetching list items: $e');
      return [];
    }
  }


  Future<Map<String, List<RecordModel>>> _fetchItems() async {
    final initItems = ["bananas", "milk", "peanut butter", "bread", "eggs", "steak", "chicken", "olive oil", "rice", "cheese"];
    Map<String, List<RecordModel>> itemsMap = {};

    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');

      try{
        for (var itemName in initItems) {
          final result = await pb.collection('items').getList(
            page: 1,
            perPage: 20,
            filter: 'name ~ "$itemName"',
            sort: '+price'
          );

          itemsMap[itemName] = result.items;
        }

        logger.i(itemsMap);
        return itemsMap;
      } catch (e) {
        logger.e("Failed to create map of all items");
        return {};
      } 
    }

    try {
      final listItems = await _fetchListItems();
      if (listItems.isEmpty) {
         for (var itemName in initItems) {
          final result = await pb.collection('items').getList(
            page: 1,
            perPage: 20,
            filter: 'name ~ "$itemName"',
            sort: '+price'
          );

          itemsMap[itemName] = result.items;
        }
      } else {
        for (var listItem in listItems) {
          final listItemName = listItem.get<String>('name');
          final result = await pb.collection('items').getList(
            page: 1,
            perPage: 20,
            filter: 'name ~ "$listItemName"',
            sort: '+price'
          );

          itemsMap[listItemName] = result.items;   
        }
      }

      logger.i(itemsMap);
      return itemsMap;
    } catch (e) {
      logger.e('Error fetching items: $e');
      return {};
    }
  }

  Future<void> _removeFromCart(RecordModel item) async {
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot remove item to cart.');
      return;
    }

    setState(() {
      _cartItems[item.id] = 0;
    });

    // Wait for the creation network request to finish completely first
    if (_pendingCartOp != null) {
      await _pendingCartOp;
    }

    try {
      final cartItem = await pb.collection('cart_items').getFirstListItem(
        'item = "${item.id}"',
        expand: 'item'
      );

      await pb.collection('cart_items').delete(cartItem.id);
      logger.i('removing item: ${cartItem.id} from cart_items');
    } catch (e) {
      logger.e("Failed to remove cart item with item id: ${item.id} from cart: $e");
      return;
    }
  }

  Future<void> _addToCart(RecordModel item, int quantity) async {
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot add item to cart.');
      return;
    }

    setState(() {
      _cartItems[item.id] = quantity;
    });

    Future<void> currentOp() async {
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

    // Wait for any previous click to finish, then execute this one
    if (_pendingCartOp != null) {
      await _pendingCartOp;
    }
    _pendingCartOp = currentOp();
    await _pendingCartOp;
  }

  Future<Map<String, int>> _fetchCartItems() async {
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve cart items.');
      return {};
    }

    Map<String, int> cartItemsMap = {};
    try {
      final cartItems = await pb.collection('cart_items').getList(
        filter: 'user="${pb.authStore.record?.id}"',
      );

      for (var cartItem in cartItems.items) {
        final itemId = cartItem.get<String>('item');
        final quantity = cartItem.get<int>('quantity');
        cartItemsMap[itemId] = quantity;
      }

      setState(() {
        _cartItems = cartItemsMap;
      });
      
      return cartItemsMap;
    } catch (e) {
      logger.e('Error fetching cart items: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // This is required for AutomaticKeepAliveClientMixin
    return FutureBuilder<Map<String, List<RecordModel>>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SpinKitWave(color: Colors.black, size: 30.0));
        }
        
        if (snapshot.hasError) {
          logger.e('Error fetching items: ${snapshot.error}');
          return const Center(child: Text('Error loading items'));
        }

        final itemsMap = snapshot.data ?? {};
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: itemsMap.length,
            itemBuilder: (context, mapIdx) {
              final searchItemName = itemsMap.entries.elementAt(mapIdx).key;
              final itemList = itemsMap.entries.elementAt(mapIdx).value;
              if (searchItemName.isEmpty) return const SizedBox();
              if (itemList.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '"$searchItemName"',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  SizedBox(
                    height: 300.0,
                    width: double.infinity,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: itemList.length,
                      itemBuilder: (context, listIdx) {
                        final item = itemList[listIdx];
                        final itemName =  item.get<String>('name');
                        final itemPrice = item.get<double>('price').toStringAsFixed(2);
                        final itemStore = item.get<String>('store');
                        final imageUrl = pb.files.getUrl(item, item.get<String>('image')).toString();
                        return SizedBox(
                          width: 250.0,
                          height: 300.0,
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: 
                                    Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: double.infinity, 
                                      fit: BoxFit.cover,
                                    ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(itemName, style: const TextStyle(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(height: 8.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 105.0, minWidth: 0.0), 
                                        child: Text('\$$itemPrice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 105.0, minWidth: 0.0), // Set a fixed width for the badge
                                        child: Badge(
                                          backgroundColor: Colors.lightGreen.withValues(
                                            red: 0.0,
                                            green: 0.8,
                                            blue: 0.0,
                                            alpha: 0.3,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          label: Text(itemStore, style: const TextStyle(fontSize: 16, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ),     
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                _getQuantity(item.id) > 0 ?  Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.black),
                                      onPressed: () async {
                                        if (_getQuantity(item.id) > 1) {
                                          await _addToCart(item, _getQuantity(item.id) - 1);
                                        } else {
                                          await _removeFromCart(item);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      height: 35,
                                      width: 75,
                                      child: Center(
                                        child: Text('${_getQuantity(item.id)}', 
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis
                                        )
                                      )
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.black),
                                      onPressed: () async {
                                        await _addToCart(item, _getQuantity(item.id) + 1);
                                      },
                                    ),
                                  ],
                                ) : ElevatedButton.icon(
                                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 35), // Make the button take the full width of the card
                                  ),
                                  onPressed: () async {
                                    if (pb.authStore.record == null) {
                                      logger.w('User is not logged in, cannot add item to cart.');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please log in to add items to your cart.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    await _addToCart(item, 1); // Add the item to the cart with a quantity of 1
                                  },
                                  label: const Text('Add to cart', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ]
              );
            }
          )
        );
      },
    );
  }
}