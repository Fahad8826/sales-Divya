import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:sales/Home/home_controller.dart';

class Home extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());

  Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
        onPressed: () => controller.toggleMenu(),
      ),
      title: const Text(
        'Dashboard',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.account_circle,
            color: Color(0xFF3B82F6),
            size: 32,
          ),
          onPressed: () {
            Get.toNamed('/profile');
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<String>(
      future: controller.fetchUserName(), // Fetches name from Firebase
      builder: (context, snapshot) {
        String userName = '...';
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          userName = snapshot.data!;
        }
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $userName',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here\'s what\'s happening with your business today',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Location Display Section
              const SizedBox(height: 16),
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Current Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const Spacer(),
                          if (controller.isLocationLoading.value)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF3B82F6),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => controller.refreshLocation(),
                              child: Icon(
                                Icons.refresh,
                                size: 16,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (controller.isLocationLoading.value)
                        Text(
                          'Fetching location...',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else if (controller.currentLocation.value.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.currentLocation.value,
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF334155),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${controller.currentLatitude.value.toStringAsFixed(6)}, '
                              'Lng: ${controller.currentLongitude.value.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Location not available',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Obx(
                      () => Text(
                        '${controller.totalActivity}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'leads + orders',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Obx(
                          () => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: controller.progressValue,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Get.offAllNamed('/leadlist');
                    },
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3B82F6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final menuItems = [
      {
        'title': 'New Lead',
        'subtitle': 'Manage your leads',
        'icon': 'assets/svg/lead_management.svg',
        'color': const Color(0xFF3B82F6),
        'count': '',
        'route': '/leadmanagment',
      },
      {
        'title': 'Follow Up',
        'subtitle': 'Pending follow-ups',
        'icon': 'assets/svg/follow_up.svg',
        'color': const Color(0xFF3B82F6),
        'count': controller.totalLeads.toString(),
        'route': '/followup',
      },
      {
        'title': 'Order Management',
        'subtitle': 'Track orders',
        'icon': 'assets/svg/order_management.svg',
        'color': const Color(0xFF3B82F6),
        'count': controller.totalOrders.toString(),
        'route': '/ordermanagement',
      },
      {
        'title': 'Post Sale Follow Up',
        'subtitle': 'Customer feedback',
        'icon': 'assets/svg/review.svg',
        'color': const Color(0xFF3B82F6),
        'count': controller.totalPostSaleFollowUp.toString(),
        'route': '/review',
      },
      {
        'title': 'Complaint',
        'subtitle': 'Support tickets',
        'icon': 'assets/svg/complaint.svg',
        'color': const Color(0xFF3B82F6),
        'count': '',
        'route': '/complaint',
      },
    ];

    return Column(
      children: menuItems.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> item = entry.value;

        return Obx(
          () => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  controller.selectMenuItem(index);
                  // Navigation using GetX
                  Future.delayed(const Duration(milliseconds: 120), () {
                    Get.toNamed(item['route'] as String);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: controller.selectedIndex.value == index
                        ? const Color(0xFFF8FAFC)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.selectedIndex.value == index
                          ? (item['color'] as Color)
                          : const Color(0xFFE2E8F0),
                      width: controller.selectedIndex.value == index ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,

                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            item['icon'] as String,
                            color: item['color'] as Color,
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),

                            child: Text(
                              item['count'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: item['color'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF94A3B8),
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
