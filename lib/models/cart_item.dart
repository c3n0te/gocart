import 'package:pocketbase/pocketbase.dart';

class CartItem {
  final String id;        // PocketBase Record ID
  final String itemId;
  final String userId;
  final int quantity;
  final DateTime updatedAt;

  CartItem({
    required this.id, 
    required this.itemId, 
    required this.userId,
    required this.quantity,
    required this.updatedAt,
  });

  CartItem copyWith({int? quantity, DateTime? updatedAt}) {
    return CartItem(
      id: id,
      itemId: itemId,
      userId: userId,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CartItem.fromRecord(RecordModel record) {
    return CartItem(
      id: record.id,
      itemId: record.get<String>('item'),
      userId: record.get<String>('user'),
      quantity: record.get<int>('quantity'),
      updatedAt: DateTime.parse(record.get<String>('updated')),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'item': itemId, 'user': userId, 'quantity': quantity, 'updated':updatedAt};
  Map<String, dynamic> newToJson() => {'item': itemId, 'user': userId, 'quantity': quantity};
}