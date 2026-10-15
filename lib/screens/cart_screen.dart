import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/globals/cart_notifier.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override 
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);

    return cartItems.when(
          loading: () {
          logger.i('Syncing cart items...');
            return SpinKitWave(size: 30.0, color: Colors.black);
          },
        error: (e, st) {
          logger.e('Error: $e');
          return Center(child: Text('Error: $e'));
        },
        data: (cartItemsMap) {
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
                    final pb = ref.read(pbProvider);
                    final cartItem = cartItemsList[listIndex];
                    final item = cartItem.get<RecordModel>('expand').get<RecordModel>('item');
                    final imageUrl = pb.files.getUrl(item, item.get<String>('image')).toString();
                    final itemName = item.get<String>('name');
                    final itemQuantity = cartItem.get<int>('quantity');
                    final itemPrice = (item.get<double>('price') * itemQuantity.toDouble()).toStringAsFixed(2);
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
                      isThreeLine: true,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Aligns subtitles to the left
                        children: [
                          Text('Price: \$$itemPrice', style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 35,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30), // Rounded corners
                                ),
                              ),                             
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.remove, color: Colors.white),
                                    onPressed: () async {
                                      final currentQty = ref.read(cartProvider.notifier).getQuantity(item.id);
                                      final targetQty = currentQty - 1;
                                      if (currentQty > 1) {
                                        await ref.read(cartProvider.notifier).addToCart(item, targetQty);
                                      } else {
                                        await ref.read(cartProvider.notifier).removeFromCart(cartItem, store);
                                      }
                                    },
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        '${ref.read(cartProvider.notifier).getQuantity(item.id)}', 
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis
                                      )
                                    )
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    onPressed: () async {
                                      final currentQty = ref.read(cartProvider.notifier).getQuantity(item.id);
                                      final targetQty = currentQty + 1;
                                      await ref.read(cartProvider.notifier).addToCart(item, targetQty);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),                  
                      trailing: IconButton(
                        onPressed: () async {
                          await ref.read(cartProvider.notifier).removeFromCart(cartItem, store);
                        },
                        icon: const Icon(Icons.delete), 
                        color: Colors.black
                      ),
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
