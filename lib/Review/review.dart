import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sales/Review/individual_review.dart';

class Review extends StatefulWidget {
  const Review({super.key});

  @override
  State<Review> createState() => _ReviewState();
}

class _ReviewState extends State<Review> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _futureOrders;
  late TabController _tabController;
  Timer? _debounce;

  // Filter variables
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Changed from 3 to 4 to match the number of tabs
    _tabController = TabController(length: 4, vsync: this);
    _futureOrders = _fetchFilteredOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredOrders() async {
    try {
      // Build Firestore query - filter for delivered orders only
      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .where('order_status', isEqualTo: 'delivered')
          .orderBy('createdAt', descending: true);

      // Apply status filter
      if (_selectedStatus != 'All') {
        query = query.where('reviewStatus', isEqualTo: _selectedStatus);
      }

      // Apply search filter (client-side for now, as Firestore text search is limited)
      final querySnapshot = await query.limit(50).get(); // Paginate with limit
      var filtered = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      // Client-side search filtering
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        filtered = filtered.where((data) {
          final customerName = (data['customerName'] ?? '').toLowerCase();
          final orderId = (data['orderId'] ?? '').toLowerCase();
          final customerEmail = (data['customerEmail'] ?? '').toLowerCase();
          return customerName.contains(searchLower) ||
              orderId.contains(searchLower) ||
              customerEmail.contains(searchLower);
        }).toList();
      }

      return filtered;
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  void _refreshData() {
    setState(() {
      _futureOrders = _fetchFilteredOrders();
    });
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
        _futureOrders = _fetchFilteredOrders();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Post Sale Follow-up',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _SearchBar(onChanged: _onSearchChanged),
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              isScrollable: true, // Added this to handle 4 tabs better
              tabs: const [
                Tab(text: 'All Orders'),
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
                Tab(text: 'Follow-up Required'),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureOrders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorWidget(error: snapshot.error);
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return _EmptyWidget(tabIndex: _tabController.index);
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OrdersList(orders: orders, tabIndex: 0),
                    _OrdersList(
                      orders: orders
                          .where(
                            (o) =>
                                (o['reviewStatus'] ?? 'Pending Review') ==
                                'Pending Review',
                          )
                          .toList(),
                      tabIndex: 1,
                    ),
                    _OrdersList(
                      orders: orders
                          .where(
                            (o) =>
                                (o['reviewStatus'] ?? 'Pending Review') ==
                                'Reviewed',
                          )
                          .toList(),
                      tabIndex: 2,
                    ),
                    _OrdersList(
                      orders: orders
                          .where(
                            (o) =>
                                (o['reviewStatus'] ?? 'Pending Review') ==
                                'Follow-up Required',
                          )
                          .toList(),
                      tabIndex: 3,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by customer name or order ID...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final Object? error;

  const _ErrorWidget({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Error loading orders',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => (context.findAncestorStateOfType<_ReviewState>())
                ?._refreshData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final int tabIndex;

  const _EmptyWidget({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final emptyMessage = switch (tabIndex) {
      1 => 'No pending reviews',
      2 => 'No completed reviews',
      3 => 'No follow-up required orders',
      _ => 'No orders found',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final int tabIndex;

  const _OrdersList({required this.orders, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) =>
          _OrderCard(order: orders[index], index: index),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final int index;

  const _OrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    // Safely handle deliveryDate
    final deliveryDate = order['deliveryDate'] is Timestamp
        ? (order['deliveryDate'] as Timestamp).toDate()
        : DateTime.now(); // Fallback to current date if null
    final formattedDate = DateFormat('dd MMM yyyy').format(deliveryDate);
    final daysSinceDelivery = DateTime.now().difference(deliveryDate).inDays;
    final reviewStatus = order['reviewStatus'] ?? 'Pending Review';

    final (statusColor, statusIcon) = switch (reviewStatus) {
      'Reviewed' => (Colors.green, Icons.check_circle),
      'Follow-up Required' => (Colors.orange, Icons.priority_high),
      _ => (Colors.red, Icons.pending),
    };

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order['orderId'] ?? 'Order #${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 12,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    reviewStatus,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['phone1'] ?? 'Customer Name',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    order['deliveryDate'] != null
                        ? 'Delivered: $formattedDate'
                        : 'Delivery Date: Not Available',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Spacer(),
                  if (order['deliveryDate'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: daysSinceDelivery > 14
                            ? Colors.red[50]
                            : Colors.blue[50],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '$daysSinceDelivery days ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: daysSinceDelivery > 14
                              ? Colors.red
                              : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// 