import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<Map<String, List<RecordModel>>> _fetchCartItems() async {
    Map<String, List<RecordModel>> storeItemsMap = {};
    try {
      final cartItems = await pb.collection('cart_items').getFullList(
        expand: 'item',
      );

      for (var cartItem in cartItems) {
        final store = cartItem.get<String>('store');
        storeItemsMap.putIfAbsent(store, () => []);
        storeItemsMap[store]!.add(cartItem);
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
    return FutureBuilder(
      future: _fetchCartItems(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SpinKitWave(color: Colors.black, size: 30.0));
        } else if (snapshot.hasError) {
          logger.e('Error in FutureBuilder: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Your cart is empty.'));
        } else {
          final cartItemsMap = snapshot.data ?? {};
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                // Trigger a rebuild to refresh the cart items
              });
            },
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: cartItemsMap.length,
              itemBuilder: (context, index) {
                final store = cartItemsMap.keys.elementAt(index);
                final items = cartItemsMap[store] ?? [];
                return ExpansionTile(
                  title: Text(store),
                  children: items.map((item) {
                    return ListTile(
                      title: Text(item.get<String>('name')),
                      subtitle: Text('Quantity: ${item.get<int>('quantity')}'),
                    );
                  }).toList(),
                );
              },
            ), 
          );
        }
      }
    );
  }
}
