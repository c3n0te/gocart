import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gocart/globals/cart_notifier.dart';
import 'package:gocart/globals/items_notifier.dart';
import 'package:gocart/globals/list_notifier.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  final Map<String, Timer> _cartDebounceTimers = {};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // This is required for AutomaticKeepAliveClientMixin
    final itemsAsync = ref.watch(itemsProvider);
    ref.watch(listProvider);
    ref.watch(cartProvider);

    return itemsAsync.when(
       loading: () {
          return const Center(child: SpinKitWave(color: Colors.black, size: 30.0));
        },
        error: (e, st) {
          logger.e('Error fetching items: $e');
          return Center(child: Text('Error loading items: $e'));
        },
        data: (itemsMap) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(itemsProvider.notifier).build();
            },
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
                          final pb = ref.read(pbProvider);
                          final item = itemList[listIdx];
                          final itemName =  item.get<String>('name');
                          final itemPrice = item.get<double>('price').toStringAsFixed(2);
                          final itemStore = item.get<String>('store');
                          final imageUrl = pb.files.getUrl(item, item.get<String>('image')).toString();
                          return SizedBox(
                            width: 250.0,
                            height: 300.0,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Colors.black, // Border color
                                  width: 1.0,          // Border thickness
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
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
                                  ref.read(cartProvider.notifier).getQuantity(item.id) > 0 ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, color: Colors.black),
                                        onPressed: () async {
                                          final currentQty = ref.read(cartProvider.notifier).getQuantity(item.id);
                                          final targetQty = currentQty - 1;

                                          if (currentQty <= 0) return;

                                          _cartDebounceTimers[item.id]?.cancel();
                                          _cartDebounceTimers[item.id] = Timer(const Duration(milliseconds: 350), () async {
                                            try {
                                              if (targetQty > 0) {
                                                await ref.read(cartProvider.notifier).addToCart(item, targetQty);
                                              } else {
                                                final store = item.get<String>('store');
                                                await ref.read(cartProvider.notifier).removeFromCart(item, store);
                                              }
                                            } catch (e) {
                                              logger.e('Network sync failed: $e');
                                            } finally {  
                                              setState(() {
                                                _cartDebounceTimers.remove(item.id);
                                            }); 
                                            }
                                          });
                                          
                                        }  
                                      ),
                                      SizedBox(
                                        height: 35,
                                        width: 75,
                                        child: Center(
                                          child: Text('${ref.read(cartProvider.notifier).getQuantity(item.id)}', 
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
                                            maxLines: 1, 
                                            overflow: TextOverflow.ellipsis
                                          )
                                        )
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, color: Colors.black),
                                        onPressed: () async {
                                          final targetQty = ref.read(cartProvider.notifier).getQuantity(item.id) + 1;

                                          _cartDebounceTimers[item.id]?.cancel();
                                          _cartDebounceTimers[item.id] = Timer(const Duration(milliseconds: 350), () async {
                                            try{
                                              await ref.read(cartProvider.notifier).addToCart(item, targetQty);
                                            } catch (e) {
                                              logger.e('Network sync failed: $e');
                                            } finally {
                                              _cartDebounceTimers.remove(item.id);
                                            }
                                          });
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
                                        
                                      _cartDebounceTimers[item.id]?.cancel();
                                      _cartDebounceTimers[item.id] = Timer(const Duration(milliseconds: 350), () async {
                                        try {
                                          await ref.read(cartProvider.notifier).addToCart(item, 1);
                                        } catch (e) {
                                          logger.e('Network sync failed: $e');
                                        } finally {
                                          _cartDebounceTimers.remove(item.id);
                                        }
                                      });
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
            ),
          );
        },
    );
  }
}