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
  Future<Map<String, List<RecordModel>>> _fetchCartItems() async {
    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return {};
    }
    
    Map<String, List<RecordModel>> storeItemsMap = {};
    try {
      final cartItems = await pb.collection('cart_items').getFullList(
        expand: 'item',
      );

      for (var cartItem in cartItems) {
        final expand = cartItem.get<List<RecordModel>>('expand');
        for (var expandedItem in expand) {
          final item = expandedItem.get<RecordModel>('item');
          final store = item.get<String>('store'); // Assuming 'item' is the store name for simplicity
          storeItemsMap.putIfAbsent(store, () => []);
          storeItemsMap[store]!.add(cartItem);
        }
      }

      logger.i('Fetched cart items: $storeItemsMap');
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
          return const Center(child: SpinKitWave(color: Colors.black, size: 30.0));
        } else if (snapshot.hasError) {
          logger.e('Error in FutureBuilder: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final cartItemsMap = snapshot.data ?? {};
          if (cartItemsMap.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  // Trigger a rebuild to refresh the cart items
                });
              },
              child: Center(
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
              )
            ); 
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                // Trigger a rebuild to refresh the cart items
              });
            },
            child: ListView.builder(
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
                        final imageUrl =  pb.files.getUrl(item, item.get<String>('image')).toString();
                        final itemName = item.get<String>('name');
                        final itemPrice = item.get<double>('price').toStringAsFixed(2);
                        final itemQuantity = cartItem.get<int>('quantity');
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
            ),     
          );
        }
      } 
    ); 
  }
}
