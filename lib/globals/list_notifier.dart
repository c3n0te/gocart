import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';

class ListNotifier extends AsyncNotifier<List<RecordModel>> {
  @override
  Future<List<RecordModel>> build() async {
    return _fetchListItems();
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
      logger.e('Error fetching items: $e');
      return [];
    }
  }

  Future<void> addItem(String itemName) async {
    final pb = ref.read(pbProvider);
    if (itemName.isEmpty) {
      logger.w('Attempted to add an empty item name.');
      return;
    }

    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return;
    }

    try {
      final newListItem = await pb.collection('list_items').create(
        body: {
          'name': itemName,
          'user_id': pb.authStore.record?.id,
        },
      );   
    } catch (e) {
        logger.e('Error adding item: $e');
        return;
    }
  }

  Future<void> removeItem(String itemId) async {
    final pb = ref.read(pbProvider);
    try {
      await pb.collection('list_items').delete(itemId);
    } catch (e) {
      logger.e('Error removing item: $e');
      return;
    }
  }

  Future<void> updateItem(String itemId, String newName) async {
    final pb = ref.read(pbProvider);
    try {
      await pb.collection('list_items').update(itemId, body: {'name': newName});
    } catch (e) {
      logger.e('Error updating item: $e');
      return;
    }
  }
}

final listProvider = AsyncNotifierProvider<ListNotifier, List<RecordModel>>(() {
  return ListNotifier();
});