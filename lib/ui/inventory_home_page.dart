import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'add_edit_item_screen.dart';
import 'inventory_dashboard_page.dart';
import 'login_screen.dart';

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirestoreService _service = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String _searchQuery = '';
  String? _selectedCategory;
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Firebase Messaging Setup
  Future<void> _setupFirebaseMessaging() async {
    // Request permissions (especially for iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe to a topic
    await _messaging.subscribeToTopic('messaging');

    // Get device token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground');
      print(message.notification?.title);
      print(message.notification?.body);

      if (message.notification?.body != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(message.notification?.title ?? 'Notification'),
            content: Text(message.notification!.body!),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );
      }
    });

    // When user taps a notification that opened the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
    });
  }

  // Sign Out
  void _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
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
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Realtime inventory stream
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _service.getItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final allItems = snapshot.data ?? [];
                if (allItems.isEmpty) {
                  return const Center(
                    child: Text('No items yet. Tap + to add one.'),
                  );
                }

                final categories = allItems
                    .map((item) => item.category)
                    .where((c) => c.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                // Apply search + filters
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
                    // Filter Chips
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
                              setState(() => _lowStockOnly = selected);
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
                          }),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Filtered List
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Text('No items match your filters.'),
                            )
                          : ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];

                                return Dismissible(
                                  key:
                                      ValueKey(item.id ?? 'item_$index'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 20),
                                    color: Colors.red,
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (_) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete item?'),
                                        content: Text(
                                          'Permanently delete "${item.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cancel'),
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                          ),
                                          TextButton(
                                            child: const Text('Delete'),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (_) async {
                                    if (item.id != null) {
                                      await _service.deleteItem(item.id!);
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
                                                AddEditItemScreen(item: item),
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
                                                      item: item),
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

      // Add Item Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}