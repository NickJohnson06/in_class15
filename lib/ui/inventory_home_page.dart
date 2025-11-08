import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'add_edit_item_screen.dart';
import 'inventory_dashboard_page.dart';

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirestoreService _service = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InventoryDashboardPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar outside the StreamBuilder so it keeps focus
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // The rest depends on Firestore data
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _service.getItemsStream(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allItems = snapshot.data ?? [];

                if (allItems.isEmpty) {
                  return const Center(
                    child: Text('No items yet. Tap + to add one.'),
                  );
                }

                // Build unique category list
                final categories = allItems
                    .map((item) => item.category)
                    .where((c) => c.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                // Apply filters
                final filteredItems = allItems.where((item) {
                  final matchesSearch = item.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());

                  final matchesCategory = _selectedCategory == null
                      ? true
                      : item.category == _selectedCategory;

                  final matchesLowStock =
                      !_lowStockOnly ? true : item.quantity < 5;

                  return matchesSearch && matchesCategory && matchesLowStock;
                }).toList();

                return Column(
                  children: [
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected:
                                _selectedCategory == null && !_lowStockOnly,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = null;
                                _lowStockOnly = false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Low Stock (<5)'),
                            selected: _lowStockOnly,
                            onSelected: (selected) {
                              setState(() {
                                _lowStockOnly = selected;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ...categories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: _selectedCategory == cat &&
                                    !_lowStockOnly,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory =
                                        selected ? cat : null;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Filtered list
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                  'No items match your search/filters.'),
                            )
                          : ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];

                                return Dismissible(
                                  key: ValueKey(item.id ?? 'item_$index'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    color: Colors.red,
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (_) async {
                                    return await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete item?'),
                                        content: Text(
                                          'This will permanently delete "${item.name}".',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (_) async {
                                    if (item.id != null) {
                                      await _service
                                          .deleteItem(item.id!);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Deleted "${item.name}"'),
                                        ),
                                      );
                                    }
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    child: ListTile(
                                      title: Text(item.name),
                                      subtitle: Text(
                                        'Qty: ${item.quantity} • Price: \$${item.price.toStringAsFixed(2)} • ${item.category}',
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddEditItemScreen(
                                              item: item,
                                            ),
                                          ),
                                        );
                                      },
                                      trailing: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddEditItemScreen(
                                                item: item,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditItemScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}