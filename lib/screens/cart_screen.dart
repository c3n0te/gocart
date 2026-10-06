import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final StreamController<RecordModel?> _cartStreamController = StreamController<RecordModel?>.broadcast();

  @override
  void initState() {
    super.initState();
    _subscribeToCart();
  }

   @override
   void dispose() {
    // Unsubscribe from PocketBase to prevent memory leaks or duplicate connections
    pb.collection('cart_items').unsubscribe('*');
    _cartStreamController.close();
    super.dispose();
  }

  Future<void> _subscribeToCart() async {
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return;
    }

    try{
      // Subscribe to the specific user's cart or a global cart collection
      await pb.collection('cart_items').subscribe('*', (ev) {
        // e.action can be 'create', 'update', or 'delete'
        // Feed the updated model event into our stream controller
        logger.i('real time event: $ev');
        _cartStreamController.add(ev.record);
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

  Future<Map<String, List<RecordModel>>> _fetchCartItems() async {
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

      for (var cartItem in cartItems.items) {
        final expand = cartItem.get<List<RecordModel>>('expand');
        for (var expandedItem in expand) {
          final item = expandedItem.get<RecordModel>('item');
          final store = item.get<String>('store');
          storeItemsMap.putIfAbsent(store, () => []);
          storeItemsMap[store]!.add(cartItem);
        }
      }

      return storeItemsMap;
    } catch (e) {
      logger.e('Error fetching cart items: $e');
      return {};
    }
  }

  @override 
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<RecordModel>>>(
      future: _fetchCartItems(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          logger.i('Syncing cart items...');
        } else if (snapshot.hasError) {
          logger.e('Error in FutureBuilder: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } 
        final cartItemsMap = snapshot.data ?? {};
        if (cartItemsMap.isEmpty) {
          return Center(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 1,
                itemBuilder: (context, index) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Your cart is empty.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
              ),
          ); 
        }
        return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: cartItemsMap.length,
            itemBuilder: (context, mapIndex) {
              final store = cartItemsMap.keys.elementAt(mapIndex);
              final cartItemsList = cartItemsMap[store] ?? [];
              return ExpansionTile(
                initiallyExpanded: true,
                shape: Border(),
                title: Text('$store ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: cartItemsList.length == 1 ? Text('(1 item)', style: const TextStyle(fontSize: 14, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis) : 
                  Text('(${cartItemsList.length} items)', style: const TextStyle(fontSize: 14, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                children: [
                  ListView.builder(
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: cartItemsList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, listIndex) {
                      final cartItem = cartItemsList[listIndex];
                      final item = cartItem.get<RecordModel>('expand').get<RecordModel>('item');
                      final imageUrl = pb.files.getUrl(item, item.get<String>('image')).toString();
                      final itemName = item.get<String>('name');
                      final itemPrice = item.get<double>('price').toStringAsFixed(2);
                      final itemQuantity = cartItem.get<int>('quantity');
                      if (itemQuantity == 0) return ListTile();
                      return ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32.0),
                            border: Border.all(color: Colors.black, width: 1.0)
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32.0),
                            child: Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(itemName, style: const TextStyle(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Quantity: $itemQuantity\nPrice: \$$itemPrice', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),                  
                      );
                    },
                  ),
                ],
              );
            },     
        );
      } 
    ); 
  }
}
