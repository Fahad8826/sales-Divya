import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales/Lead/lead_list_controller.dart';
import 'package:sales/Home/home.dart';
import 'package:sales/Lead/individual_details.dart';
import 'package:rxdart/rxdart.dart' as rxdart;

class LeadList extends StatelessWidget {
  const LeadList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeadListController());

    return WillPopScope(
      onWillPop: () async {
        Get.off(() => Home());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leads & Orders'),
          centerTitle: true,
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refreshFilterOptions(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(controller),
            _buildFilterChips(controller),
            const Divider(height: 1),
            Expanded(child: _buildListView(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(LeadListController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller.searchController,
        decoration: const InputDecoration(
          hintText: 'Search by name, phone, address, ID...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(LeadListController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        // Show loading indicator while filters are loading
        if (controller.isLoadingFilters.value) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              'Type',
              controller.selectedType,
              ['All', 'Lead', 'Order'],
              controller.setType,
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Status',
              controller.selectedStatus,
              controller.availableStatuses.toList(),
              controller.setStatus,
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Place',
              controller.selectedPlace,
              controller.availablePlaces.toList(),
              controller.setPlace,
              controller,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Product',
              controller.selectedProductNo,
              controller.availableProductNos.toList(),
              controller.setProductNo,
              controller,
            ),
            const SizedBox(width: 8),
            _buildDateRangeChip(controller),
            const SizedBox(width: 8),
            _buildClearFiltersChip(controller),
          ],
        );
      }),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
    LeadListController controller,
  ) {
    return FilterChip(
      label: Text('$label: $currentValue'),
      selected: currentValue != 'All',
      onSelected: (_) {
        // Add debug print
        print('Opening filter dialog for $label with options: $options');
        _showFilterDialog(label, currentValue, options, onChanged);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  Widget _buildDateRangeChip(LeadListController controller) {
    return Obx(() {
      final hasDateFilter = controller.selectedDateRange != null;
      return FilterChip(
        label: Text(
          hasDateFilter
              ? 'Date: ${DateFormat('dd/MM').format(controller.selectedDateRange!.start)} - ${DateFormat('dd/MM').format(controller.selectedDateRange!.end)}'
              : 'Date: All',
        ),
        selected: hasDateFilter,
        onSelected: (_) => _selectDateRange(controller),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
      );
    });
  }

  Widget _buildClearFiltersChip(LeadListController controller) {
    return Obx(() {
      final hasActiveFilters =
          controller.selectedType != 'All' ||
          controller.selectedStatus != 'All' ||
          controller.selectedPlace != 'All' ||
          controller.selectedProductNo != 'All' ||
          controller.selectedDateRange != null ||
          controller.searchQuery.isNotEmpty;

      if (!hasActiveFilters) return const SizedBox.shrink();

      return ActionChip(
        label: const Text('Clear All'),
        onPressed: controller.clearAllFilters,
        backgroundColor: Colors.red[100],
        avatar: const Icon(Icons.clear, size: 18),
      );
    });
  }

  void _showFilterDialog(
    String title,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    // Debug print
    print('Showing filter dialog for $title with ${options.length} options');

    Get.dialog(
      AlertDialog(
        title: Text('Filter by $title'),
        content: SizedBox(
          width: double.minPositive,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (options.isEmpty)
                const Text('No options available')
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: currentValue,
                        onChanged: (value) {
                          print('Selected filter option: $value');
                          onChanged(value!);
                          Get.back();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(LeadListController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: controller.selectedDateRange,
    );
    if (picked != null) {
      controller.setDateRange(picked);
    }
  }

  Widget _buildListTile(
    Map<String, dynamic> data,
    String type,
    String docId,
    LeadListController controller,
  ) {
    final statusColor = _getStatusColor(data['status']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: type == 'Lead'
              ? Colors.orange[100]
              : Colors.green[100],
          child: Icon(
            type == 'Lead' ? Icons.person_add : Icons.shopping_cart,
            color: type == 'Lead' ? Colors.orange[700] : Colors.green[700],
          ),
        ),
        title: Text(
          data['name'] ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    data['status'] ?? 'N/A',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '📞 ${data['phone1'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '📍 ${data['place'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '📦 Product: ${data['productID'] ?? 'N/A'} (${data['nos'] ?? 'N/A'} items)',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '📅 ${controller.formatDateShort(data['createdAt'])}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToDetails(data, type, docId),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'warm':
        return Colors.orange;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'hot':
        return Colors.red;
      case 'cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _navigateToDetails(
    Map<String, dynamic> data,
    String type,
    String docId,
  ) {
    Get.to(() => DetailPage(data: data, type: type, docId: docId));
  }

  Widget _buildListView(LeadListController controller) {
    return StreamBuilder<List<QuerySnapshot>>(
      stream:
          rxdart.Rx.combineLatest2<
            QuerySnapshot,
            QuerySnapshot,
            List<QuerySnapshot>
          >(
            FirebaseFirestore.instance
                .collection('Leads')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            FirebaseFirestore.instance
                .collection('Orders')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            (leadsSnapshot, ordersSnapshot) => [leadsSnapshot, ordersSnapshot],
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        return Obx(() {
          // Combine and filter data
          List<Map<String, dynamic>> allItems = [];

          // Add leads
          for (var doc in snapshot.data![0].docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (controller.matchesFilters(data, 'Lead')) {
              allItems.add({...data, 'type': 'Lead', 'docId': doc.id});
            }
          }

          // Add orders
          for (var doc in snapshot.data![1].docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (controller.matchesFilters(data, 'Order')) {
              allItems.add({...data, 'type': 'Order', 'docId': doc.id});
            }
          }

          // Sort by creation date (newest first)
          allItems.sort((a, b) {
            final aDate = a['createdAt'] as Timestamp?;
            final bDate = b['createdAt'] as Timestamp?;
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate);
          });

          // Debug print
          print('Total items after filtering: ${allItems.length}');

          if (allItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No items found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              return _buildListTile(
                item,
                item['type'],
                item['docId'],
                controller,
              );
            },
          );
        });
      },
    );
  }
}
