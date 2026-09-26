import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/globals/pocketbase.dart';

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
          return Center(child: Text('Error loading items'));
        }

        final items = snapshot.data ?? [];
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final imageUrl = pb.files.getUrl(items[index], items[index].data['image'] ?? '', thumb: "100x100").toString();
            return ListTile(
              title: Text(items[index].data['name'] ?? "No Name"),
              subtitle: Text('\$${items[index].data['price'] ?? "0.00"}'),
              leading: Image.network(imageUrl),
            );
          },
        );
      },
    );
  }
}