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

  Future<RecordModel?> addItem(String itemName) async {
    state = AsyncValue.loading();
    final pb = ref.read(pbProvider);
    if (itemName.isEmpty) {
      logger.w('Attempted to add an empty item name.');
      return null;
    }

    if (pb.authStore.record == null) {
      logger.w('User is not logged in, cannot retrieve user_id.');
      return null;
    }

    try {
      final newListItem = await pb.collection('list_items').create(
        body: {
          'name': itemName,
          'user_id': pb.authStore.record?.id,
        },
      ); 

      state = AsyncValue.data([...state.value ?? [], newListItem]);
      return newListItem;
    } catch (e, st) {
        logger.e('Error adding item: $e');
        state = AsyncValue.error(e, st);
        return null;
    }
  }

  Future<void> removeItem(String itemId) async {
    state = AsyncValue.loading();
    final pb = ref.read(pbProvider);
    try {
      await pb.collection('list_items').delete(itemId);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((item) => item.id != itemId).toList());
      }
    } catch (e, st) {
      logger.e('Error removing item: $e');
      state = AsyncValue.error(e, st);
      return;
    }
  }

  Future<RecordModel?> updateItem(String itemId, String newName) async {
    state = AsyncValue.loading();
    final pb = ref.read(pbProvider);
    try {
      final updatedListItem = await pb.collection('list_items').update(itemId, body: {'name': newName});
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.map((item) => item.id == itemId ? updatedListItem : item).toList());
      }
      return updatedListItem;
    } catch (e, st) {
      logger.e('Error updating item: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final listProvider = AsyncNotifierProvider<ListNotifier, List<RecordModel>>(() {
  return ListNotifier();
});