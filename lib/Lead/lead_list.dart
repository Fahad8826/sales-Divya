import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales/Lead/lead_list_controller.dart';
import 'package:sales/Home/home.dart';
import 'package:sales/Lead/individual_details.dart';

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
          leading: IconButton(
            onPressed: () {
              Get.off(() => Home());
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text('Leads & Orders'),
          centerTitle: true,
          backgroundColor: Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refreshData(),
            ),
            Obx(
              () =>
                  controller
                      .hasActiveFilters // Remove .value
                  ? IconButton(
                      icon: const Icon(Icons.filter_alt_off),
                      onPressed: () => controller.clearAllFilters(),
                    )
                  : SizedBox.shrink(),
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
        decoration: InputDecoration(
          hintText: 'Search by name, phone, address, ID...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: Obx(
            () =>
                controller
                    .searchQuery
                    .isNotEmpty // Remove .value
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => controller.clearAllFilters(),
                  )
                : SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(LeadListController controller) {
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
      onSelected: (_) =>
          _showFilterDialog(label, currentValue, options, onChanged),
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
      if (!controller.hasActiveFilters)
        return const SizedBox.shrink(); // Remove .value
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

  Widget _buildListView(LeadListController controller) {
    return Obx(() {
      if (controller.filteredItems.isEmpty && !controller.isLoading.value) {
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
        controller: controller.scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount:
            controller.filteredItems.length +
            (controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.filteredItems.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final item = controller.filteredItems[index];
          return _buildListTile(item, item['type'], item['id'], controller);
        },
      );
    });
  }

  Widget _buildListTile(
    Map<String, dynamic> data,
    String type,
    String docId,
    LeadListController controller,
  ) {
    final statusColor = _getStatusColor(data['status']);
    final isLead = type == 'Lead';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetails(data, type, docId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isLead ? Colors.orange[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isLead
                          ? Icons.person_add_outlined
                          : Icons.shopping_cart_outlined,
                      color: isLead ? Colors.orange[600] : Colors.green[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.formatDateShort(data['createdAt']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          data['status'] ?? 'N/A',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLead
                              ? Colors.orange[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isLead
                                ? Colors.orange[700]
                                : Colors.green[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      iconColor: Colors.blue[600]!,
                      label: 'Phone',
                      value: data['phone1'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      iconColor: Colors.red[600]!,
                      label: 'Location',
                      value: data['place'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.inventory_2_outlined,
                      iconColor: Colors.purple[600]!,
                      label: 'Product',
                      value:
                          '${data['productID'] ?? 'N/A'} (${data['nos'] ?? 'N/A'} items)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
}
