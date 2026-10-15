import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';

class ItemsNotifier extends AsyncNotifier<Map<String, List<RecordModel>>> {
  @override
  Future<Map<String, List<RecordModel>>> build() async {
    return _fetchItems();
  }

  Future<List<RecordModel>> _fetchListItems() async {
    final pb = ref.read(pbProvider);
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
    state = AsyncValue.loading();
    final initItems = ["bananas", "milk", "peanut butter", "bread", "eggs", "steak", "chicken", "olive oil", "rice", "cheese"];
    Map<String, List<RecordModel>> itemsMap = {};
    final pb = ref.read(pbProvider);

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
        state = AsyncValue.data(itemsMap);
        return itemsMap;
      } catch (e, st) {
        logger.e("Failed to create map of all items");
        state = AsyncValue.error(e, st);
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
      state = AsyncValue.data(itemsMap);
      return itemsMap;
    } catch (e, st) {
      logger.e('Error fetching items: $e');
      state = AsyncValue.error(e, st);
      return {};
    }
  }
}

final itemsProvider = AsyncNotifierProvider<ItemsNotifier, Map<String, List<RecordModel>>>(() {
  return ItemsNotifier();
});