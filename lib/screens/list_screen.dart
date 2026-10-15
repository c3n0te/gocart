import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gocart/globals/list_notifier.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final TextEditingController _newListItemController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getControllerForItem(dynamic item) {
    return _controllers.putIfAbsent(item.id, () {
      return TextEditingController(text: item.get<String>('name'));
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _newListItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(listProvider);

    return listAsync.when(
        loading: () {
          logger.i('Syncing list items...');
          return SpinKitWave(size: 30.0, color: Colors.black);
        },
        error: (e, st) {
          logger.e('Error syncing list items: $e');
          return Center(child: Text('Error loading list items: $e'));
        },      
        data: (listItems) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                final pb = ref.read(pbProvider);
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
                          onPressed: () async {
                            await ref.read(listProvider.notifier).addItem(_newListItemController.text); // adds item to list
                            _newListItemController.clear(); // Clear the text field
                            if (!context.mounted) return;
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
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(listItems[index].id),
                  background: Container(color: Colors.red),
                  onDismissed: (direction) async {
                    final itemId = listItems[index].id;
                    await ref.read(listProvider.notifier).removeItem(itemId);
                  },
                  child: ListTile(
                    leading: const Icon(Icons.fiber_manual_record, color: Colors.black),
                    title: TextField(
                      maxLines: null, // Allows the text field to expand vertically
                      controller: _getControllerForItem(listItems[index]),
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
                      ),
                      onChanged: (value) {
                        listItems[index].set('name', value); // Update the state when the text changes
                      }, 
                      onSubmitted: (value) async {
                        if (_getControllerForItem(listItems[index]).text.isEmpty) {
                          await ref.read(listProvider.notifier).removeItem(listItems[index].id);
                          return;
                        }

                       await ref.read(listProvider.notifier).updateItem(listItems[index].id, value);
                      },
                      onTapOutside: (event) async {
                        if (_getControllerForItem(listItems[index]).text.isEmpty) {
                          await ref.read(listProvider.notifier).removeItem(listItems[index].id);

                          if (!context.mounted) return;
                          FocusScope.of(context).unfocus(); // Dismiss the keyboard when tapping outside
                          return;
                        }
                        
                        await ref.read(listProvider.notifier).updateItem(listItems[index].id, _getControllerForItem(listItems[index]).text);
                        if (!context.mounted) return;
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