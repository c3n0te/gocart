import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dart:io' show Platform;
import '../utils/logger.dart';

final pb = Platform.isAndroid ? PocketBase('http://10.0.2.2:8090') : PocketBase('http://127.0.0.1:8090');

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<List<RecordModel>> _fetchItems() async {
    final items = await pb.collection('items').getFullList();
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecordModel>>(
      future: _fetchItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          logger.e('Error fetching items: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(items[index].data['name'] ?? 'No Name'),
            );
          },
        );
      },
    );
  }
}