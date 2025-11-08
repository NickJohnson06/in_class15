import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';

class InventoryDashboardPage extends StatelessWidget {
  const InventoryDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
      ),
      body: StreamBuilder<List<Item>>(
        stream: service.getItemsStream(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('No data available yet.'),
            );
          }

          final totalItems = items.length;
          final totalValue = items.fold<double>(
            0.0,
            (sum, item) => sum + (item.quantity * item.price),
          );
          final outOfStockItems =
              items.where((item) => item.quantity == 0).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Total items
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Total Unique Items'),
                  subtitle: Text('$totalItems'),
                ),
              ),
              const SizedBox(height: 12),

              // Total value
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Total Inventory Value'),
                  subtitle: Text('\$${totalValue.toStringAsFixed(2)}'),
                ),
              ),
              const SizedBox(height: 12),

              // Out-of-stock list
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: const Text('Out-of-Stock Items'),
                  subtitle: Text(
                    outOfStockItems.isEmpty
                        ? 'All items in stock'
                        : '${outOfStockItems.length} item(s) out of stock',
                  ),
                  children: outOfStockItems.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Nice! No items are out of stock.'),
                          ),
                        ]
                      : outOfStockItems
                          .map(
                            (item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text('Category: ${item.category}'),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}