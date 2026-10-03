import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';


class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final List<RecordModel> _items = [];
  final TextEditingController _newListItemController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getControllerForItem(dynamic item) {
    return _controllers.putIfAbsent(item.id, () {
      return TextEditingController(text: item.get<String>('name'));
    });
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
      logger.e('Error fetching items: $e');
      return [];
    }
  }

  Future<void> _addItem(String itemName) async {
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
      
      setState(() {
        _items.add(newListItem);
      });      
    } catch (e) {
        logger.e('Error adding item: $e');
        return;
    }
  }

  Future<void> _removeItem(String itemId) async {
    try {
      await pb.collection('list_items').delete(itemId);
      
      setState(() {
        _items.removeWhere((item) => item.id == itemId);
      });

    } catch (e) {
      logger.e('Error removing item: $e');
      return;
    }
  }

  Future<void> _updateItem(String itemId, String newName) async {
    try {
      await pb.collection('list_items').update(itemId, body: {'name': newName});
      
      setState(() {
        final index = _items.indexWhere((item) => item.id == itemId);
        if (index != -1 && index < _items.length) {
          _items[index].set('name', newName);
        }
      });

    } catch (e) {
      logger.e('Error updating item: $e');
      return;
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _newListItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchListItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          logger.i('Syncing list items...');
        }

        if (snapshot.hasError) {
          logger.e('Error syncing list items: ${snapshot.error}');
          return Center(child: Text('Error loading list items'));
        }
        
        if (snapshot.hasData) {
          _items.clear();
          _items.addAll(snapshot.data as List<RecordModel>);
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (pb.authStore.isValid) {
                logger.i('User is logged in, showing add item dialog.');
              } else {
                logger.w('User is not logged in, cannot add item.');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You must be logged in to add items.')),
                );
                return;
              }

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Add new list item'),
                    content: TextField(
                      controller: _newListItemController,
                      decoration: InputDecoration(
                        hintText: "Enter item name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          _newListItemController.clear(); // Clear the text field
                          Navigator.of(context).pop(); // Closes the popup
                        },
                      ),
                      TextButton(
                        child: const Text('Ok'),
                        onPressed: () {
                          _addItem(_newListItemController.text); // adds item to list
                          _newListItemController.clear(); // Clear the text field
                          Navigator.of(context).pop(); // Closes the popup
                        },
                      )
                    ],
                  );
                },
              );
            },
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
          body: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return Dismissible(
                key: Key(_items[index].id),
                background: Container(color: Colors.red),
                onDismissed: (direction) {
                  _removeItem(_items[index].id);
                },
                child: ListTile(
                  leading: const Icon(Icons.fiber_manual_record, color: Colors.black),
                  title: TextField(
                    maxLines: null, // Allows the text field to expand vertically
                    controller: _getControllerForItem(_items[index]),
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
                    ),
                    onChanged: (value) {
                      _items[index].set('name', value); // Update the state when the text changes
                    }, 
                    onSubmitted: (value) {
                      _updateItem(_items[index].id, value);
                    },
                    onTapOutside: (event) {
                      _updateItem(_items[index].id, _getControllerForItem(_items[index]).text);
                      FocusScope.of(context).unfocus(); // Dismiss the keyboard when tapping outside
                    },
                  ),
                  selectedTileColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),  // Rounds the corners of the tile
                  ),
                ),
              );
            },
          ),
        );
      },
    ); 
  }      
}