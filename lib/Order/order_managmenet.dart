import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales/Order/order_list_controller.dart';
import 'package:sales/Home/home.dart';
import 'package:sales/Order/individual_order_details.dart';

class OrderManagement extends StatelessWidget {
  const OrderManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderListController());

    return WillPopScope(
      onWillPop: () async {
        Get.off(() => Home());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Order Management',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await controller.loadInitialItems();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(Get.context!).size.height - kToolbarHeight,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBar(controller),
                  _buildFilterChips(controller),
                  _buildListView(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(OrderListController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _buildFilterChips(OrderListController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        if (controller.isLoadingFilters.value) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
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
    OrderListController controller,
  ) {
    return FilterChip(
      label: Text('$label: $currentValue'),
      selected: currentValue != 'All',
      onSelected: (_) {
        print('Opening filter dialog for $label with options: $options');
        _showFilterDialog(label, currentValue, options, onChanged);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      checkmarkColor: const Color(0xFF2E3192),
    );
  }

  Widget _buildDateRangeChip(OrderListController controller) {
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
        backgroundColor: Colors.white,
        selectedColor: Colors.blue[100],
        checkmarkColor: const Color(0xFF2E3192),
      );
    });
  }

  Widget _buildClearFiltersChip(OrderListController controller) {
    return Obx(() {
      final hasActiveFilters =
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

  Future<void> _selectDateRange(OrderListController controller) async {
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
    String docId,
    OrderListController controller,
  ) {
    final statusColor = getStatusColor(data['status']);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.shopping_cart, color: Colors.green[700]),
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
                    data['order_status'] ?? 'N/A',
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
                    'Order',
                    style: TextStyle(
                      color: const Color(0xFF2E3192),
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
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToDetails(data, 'Order', docId),
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'cold':
        return Colors.lightBlue;
      case 'warm':
        return Colors.orange;
      case 'hot':
        return Colors.red;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _navigateToDetails(
    Map<String, dynamic> data,
    String type,
    String docId,
  ) {
    Get.to(() => IndividualOrderDetails(data: data, type: type, docId: docId));
  }

  Widget _buildListView(OrderListController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredItems.isEmpty && !controller.hasMore.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No orders found',
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
        controller: controller.scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount:
            controller.filteredItems.length +
            (controller.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.filteredItems.length &&
              controller.hasMore.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final item = controller.filteredItems[index];
          return _buildListTile(item, item['docId'], controller);
        },
      );
    });
  }
}
