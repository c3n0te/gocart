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
  late Future<Map<String, List<RecordModel>>> _itemsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _itemsFuture = _fetchItems(); // Wait for the future to complete before rebuilding
    });
    await _itemsFuture; // Wait for the future to complete before rebuilding
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
                        final itemName = itemList[listIdx].get<String>('name');
                        final itemPrice = itemList[listIdx].get<double>('price').toStringAsFixed(2);
                        final itemStore = itemList[listIdx].get<String>('store');
                        final imageUrl = pb.files.getUrl(itemList[listIdx], itemList[listIdx].get<String>('image')).toString();
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
                                      child: Text('\$$itemPrice', style: const TextStyle(fontSize: 16, color: Colors.black)),
                                    ),
                                    Badge(
                                      backgroundColor: Colors.lightGreen.withValues(
                                        red: 0.0,
                                        green: 0.8,
                                        blue: 0.0,
                                        alpha: 0.3,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      label: Text(itemStore, style: const TextStyle(fontSize: 16, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),     
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 35), // Make the button take the full width of the card
                                  ),
                                  onPressed: () {
                                    // Handle "Add to Cart" button press
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