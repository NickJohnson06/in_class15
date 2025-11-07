import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'add_edit_item_screen.dart';

class InventoryHomePage extends StatelessWidget {
  const InventoryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: StreamBuilder<List<Item>>(
        stream: service.getItemsStream(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];

          // Empty state
          if (items.isEmpty) {
            return const Center(child: Text('No items yet. Tap + to add one.'));
          }

          // List view
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    'Qty: ${item.quantity} • \$${item.price.toStringAsFixed(2)} • ${item.category}',
                  ),
                  onTap: () async {
                    // Edit
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditItemScreen(item: item),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditItemScreen(item: item),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Add
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}