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
        return Container(
          margin: const EdgeInsets.all(8.0),
          child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final imageUrl = pb.files.getUrl(items[index], items[index].data['image'] ?? '', thumb: "200x200").toString();
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(items[index].data['name'] ?? "No Name", style: const TextStyle(fontSize: 16)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('\$${items[index].data['price'] ?? "0.00"}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                ],
              ),
            );
          },
        )
        );
      },
    );
  }
}