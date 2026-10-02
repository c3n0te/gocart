import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/globals/pocketbase.dart';

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
          final listItemName = listItem.data['name'];
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
          return const Center(child: CircularProgressIndicator());
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
                    height: 250.0,
                    width: double.infinity,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: itemList.length,
                      itemBuilder: (context, listIdx) {
                        final itemName = itemList[listIdx].get<String>('name');
                        final itemPrice = itemList[listIdx].get<double>('price').toStringAsFixed(2);
                        final imageUrl = pb.files.getUrl(itemList[listIdx], itemList[listIdx].get<String>('image')).toString();
                        return SizedBox(
                          width: 250.0,
                          height: 250.0,
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: double.infinity, 
                                    fit: BoxFit.cover
                                  )
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(itemName, style: const TextStyle(fontSize: 16)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('\$$itemPrice', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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