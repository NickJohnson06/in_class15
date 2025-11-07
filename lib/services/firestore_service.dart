import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class FirestoreService {
  // Create collection reference for 'items'
  final CollectionReference _itemsCollection =
      FirebaseFirestore.instance.collection('items');

  // Add: Create a new item in Firestore
  Future<void> addItem(Item item) async {
    await _itemsCollection.add(item.toMap());
  }

  // Get Items Stream: Return real-time list of items
  Stream<List<Item>> getItemsStream() {
    return _itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Update: Update existing item by ID
  Future<void> updateItem(Item item) async {
    await _itemsCollection.doc(item.id).update(item.toMap());
  }

  // Delete: Delete item by ID
  Future<void> deleteItem(String itemId) async {
    await _itemsCollection.doc(itemId).delete();
  }
}