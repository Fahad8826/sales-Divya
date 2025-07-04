// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:sales/FollowUp/detailfollowup_page.dart';
// import 'package:sales/FollowUp/followup_controller.dart';
// import 'package:sales/Home/home.dart';

// import 'package:sales/Lead/leadmanagement.dart';

// class FollowupPage extends StatelessWidget {
//   const FollowupPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(FollowupController(), tag: 'followup');
//     final size = MediaQuery.of(context).size;
//     final isTablet = size.width > 600;

//     return WillPopScope(
//       onWillPop: () async {
//         Get.off(() => Home());
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: Colors.grey[50],
//         appBar: _buildAppBar(),
//         body: Column(
//           children: [
//             _buildSearchAndFilters(controller, size),
//             _buildSummaryCards(controller, size, isTablet),
//             Expanded(child: _buildListView(controller, size, isTablet)),
//           ],
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: const Text(
//         'Lead Follow-ups',
//         style: TextStyle(
//           fontWeight: FontWeight.w600,
//           fontSize: 20,
//           color: Colors.white,
//         ),
//       ),
//       centerTitle: true,
//       backgroundColor: Color(0xFF3B82F6),
//       foregroundColor: Colors.white,
//       elevation: 0,
//     );
//   }

//   Widget _buildSummaryCards(
//     FollowupController controller,
//     Size size,
//     bool isTablet,
//   ) {
//     final cardPadding = isTablet ? 16.0 : 10.0;
//     final cardHeight = isTablet ? 70.0 : 60.0;

//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: size.width * 0.04,
//         vertical: size.height * 0.01,
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('Leads').snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return SizedBox(height: cardHeight);
//           }

//           final docs = snapshot.data!.docs;
//           final overdue = docs.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return _isFollowUpOverdue(data['followUpDate']);
//           }).length;

//           final today = docs.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return _isFollowUpToday(data['followUpDate']);
//           }).length;

//           final hot = docs.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data['status']?.toString().toLowerCase() == 'hot';
//           }).length;

//           return SizedBox(
//             height: cardHeight,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _buildSummaryCard(
//                     'Overdue',
//                     overdue.toString(),
//                     Icons.warning_amber_rounded,
//                     Colors.red,
//                     Colors.red[50]!,
//                     cardPadding,
//                     isTablet,
//                   ),
//                 ),
//                 SizedBox(width: size.width * 0.02),
//                 Expanded(
//                   child: _buildSummaryCard(
//                     'Today',
//                     today.toString(),
//                     Icons.today,
//                     Colors.blue[600]!,
//                     Colors.blue[50]!,
//                     cardPadding,
//                     isTablet,
//                   ),
//                 ),
//                 SizedBox(width: size.width * 0.02),
//                 Expanded(
//                   child: _buildSummaryCard(
//                     'Hot Leads',
//                     hot.toString(),
//                     Icons.local_fire_department,
//                     Colors.blue[600]!,
//                     Colors.blue[50]!,
//                     cardPadding,
//                     isTablet,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSummaryCard(
//     String title,
//     String count,
//     IconData icon,
//     Color color,
//     Color backgroundColor,
//     double padding,
//     bool isTablet,
//   ) {
//     final iconSize = isTablet ? 20.0 : 16.0;
//     final countFontSize = isTablet ? 20.0 : 16.0;
//     final titleFontSize = isTablet ? 11.0 : 9.0;

//     return Container(
//       padding: EdgeInsets.all(padding),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   count,
//                   style: TextStyle(
//                     fontSize: countFontSize,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: titleFontSize,
//                     color: color,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//           Icon(icon, color: color, size: iconSize),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchAndFilters(FollowupController controller, Size size) {
//     return Container(
//       color: Colors.white,
//       padding: EdgeInsets.symmetric(
//         horizontal: size.width * 0.04,
//         vertical: size.height * 0.015,
//       ),
//       child: Column(
//         children: [
//           _buildSearchBar(controller, size),
//           SizedBox(height: size.height * 0.015),
//           _buildFilterChips(controller, size),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar(FollowupController controller, Size size) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!),
//       ),
//       child: Obx(
//         () => TextField(
//           controller: controller.searchController,
//           decoration: InputDecoration(
//             hintText: 'Search leads...',
//             hintStyle: TextStyle(color: Colors.grey[600]),
//             prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
//             suffixIcon: controller.searchQuery.isNotEmpty
//                 ? IconButton(
//                     icon: Icon(Icons.clear, color: Colors.grey[600]),
//                     onPressed: controller.clearSearchFilter,
//                   )
//                 : null,
//             border: InputBorder.none,
//             contentPadding: EdgeInsets.symmetric(
//               horizontal: size.width * 0.04,
//               vertical: size.height * 0.018,
//             ),
//           ),
//           onChanged: (value) => controller.searchQuery.value = value,
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterChips(FollowupController controller, Size size) {
//     final chipHeight = size.height * 0.045;

//     return SizedBox(
//       height: chipHeight,
//       child: Obx(
//         () => ListView(
//           scrollDirection: Axis.horizontal,
//           children: [
//             _buildFilterChip(
//               'Status',
//               controller.selectedStatus,
//               controller.availableStatuses,
//               controller.setStatus,
//               controller,
//               size,
//             ),
//             SizedBox(width: size.width * 0.02),
//             _buildFilterChip(
//               'Place',
//               controller.selectedPlace,
//               controller.availablePlaces,
//               controller.setPlace,
//               controller,
//               size,
//             ),
//             SizedBox(width: size.width * 0.02),
//             _buildFilterChip(
//               'Product',
//               controller.selectedProductNo,
//               controller.availableProductNos,
//               controller.setProductNo,
//               controller,
//               size,
//             ),
//             SizedBox(width: size.width * 0.02),
//             _buildDateRangeChip(controller, size),
//             SizedBox(width: size.width * 0.02),
//             _buildFollowUpDateChip(controller, size),
//             SizedBox(width: size.width * 0.02),
//             _buildClearFiltersChip(controller, size),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterChip(
//     String label,
//     RxString currentValue,
//     List<String> options,
//     Function(String) onChanged,
//     FollowupController controller,
//     Size size,
//   ) {
//     final isSelected = currentValue.value != 'All';
//     final fontSize = size.width > 600 ? 12.0 : 11.0;

//     return Container(
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.blue[600] : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
//         ),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(20),
//           onTap: () =>
//               _showFilterDialog(label, currentValue.value, options, onChanged),
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: size.width * 0.03,
//               vertical: size.height * 0.008,
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   '$label: ${currentValue.value}',
//                   style: TextStyle(
//                     color: isSelected ? Colors.white : Colors.grey[700],
//                     fontSize: fontSize,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 if (isSelected) ...[
//                   SizedBox(width: size.width * 0.015),
//                   GestureDetector(
//                     onTap: () => _clearIndividualFilter(label, controller),
//                     child: Container(
//                       padding: const EdgeInsets.all(2),
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.close,
//                         size: 12,
//                         color: Colors.blue[600],
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDateRangeChip(FollowupController controller, Size size) {
//     final fontSize = size.width > 600 ? 12.0 : 11.0;

//     return Obx(() {
//       final hasDateFilter = controller.selectedDateRange.value != null;
//       return Container(
//         decoration: BoxDecoration(
//           color: hasDateFilter ? Colors.blue[600] : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: hasDateFilter ? Colors.blue[600]! : Colors.grey[300]!,
//           ),
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(20),
//             onTap: () => _selectDateRange(controller),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: size.width * 0.03,
//                 vertical: size.height * 0.008,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     hasDateFilter
//                         ? 'Date: ${DateFormat('dd/MM').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd/MM').format(controller.selectedDateRange.value!.end)}'
//                         : 'Date: All',
//                     style: TextStyle(
//                       color: hasDateFilter ? Colors.white : Colors.grey[700],
//                       fontSize: fontSize,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (hasDateFilter) ...[
//                     SizedBox(width: size.width * 0.015),
//                     GestureDetector(
//                       onTap: controller.clearDateRangeFilter,
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.close,
//                           size: 12,
//                           color: Colors.blue[600],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildFollowUpDateChip(FollowupController controller, Size size) {
//     final fontSize = size.width > 600 ? 12.0 : 11.0;

//     return Obx(() {
//       final hasFollowUpDateFilter =
//           controller.selectedFollowUpDate.value != null;
//       return Container(
//         decoration: BoxDecoration(
//           color: hasFollowUpDateFilter ? Colors.blue[600] : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: hasFollowUpDateFilter
//                 ? Colors.blue[600]!
//                 : Colors.grey[300]!,
//           ),
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(20),
//             onTap: () => _selectFollowUpDate(controller),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: size.width * 0.03,
//                 vertical: size.height * 0.008,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     hasFollowUpDateFilter
//                         ? 'Follow-Up: ${DateFormat('dd/MM').format(controller.selectedFollowUpDate.value!)}'
//                         : 'Follow-Up: All',
//                     style: TextStyle(
//                       color: hasFollowUpDateFilter
//                           ? Colors.white
//                           : Colors.grey[700],
//                       fontSize: fontSize,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (hasFollowUpDateFilter) ...[
//                     SizedBox(width: size.width * 0.015),
//                     GestureDetector(
//                       onTap: controller.clearFollowUpDateFilter,
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.close,
//                           size: 12,
//                           color: Colors.blue[600],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildClearFiltersChip(FollowupController controller, Size size) {
//     final fontSize = size.width > 600 ? 12.0 : 11.0;

//     return Obx(() {
//       final hasActiveFilters =
//           controller.selectedStatus.value != 'All' ||
//           controller.selectedPlace.value != 'All' ||
//           controller.selectedProductNo.value != 'All' ||
//           controller.selectedDateRange.value != null ||
//           controller.selectedFollowUpDate.value != null ||
//           controller.searchQuery.value.isNotEmpty;

//       if (!hasActiveFilters) return const SizedBox.shrink();

//       return Container(
//         decoration: BoxDecoration(
//           color: Colors.grey[600],
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(20),
//             onTap: controller.clearAllFilters,
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: size.width * 0.03,
//                 vertical: size.height * 0.008,
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.clear_all, size: 14, color: Colors.white),
//                   SizedBox(width: size.width * 0.01),
//                   Text(
//                     'Clear All',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: fontSize,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   void _clearIndividualFilter(
//     String filterType,
//     FollowupController controller,
//   ) {
//     switch (filterType) {
//       case 'Status':
//         controller.clearStatusFilter();
//         break;
//       case 'Place':
//         controller.clearPlaceFilter();
//         break;
//       case 'Product':
//         controller.clearProductFilter();
//         break;
//     }
//   }

//   void _showFilterDialog(
//     String title,
//     String currentValue,
//     List<String> options,
//     Function(String) onChanged,
//   ) {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text(
//           'Filter by $title',
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         content: SizedBox(
//           width: double.minPositive,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: options.length,
//             itemBuilder: (context, index) {
//               final option = options[index];
//               final isSelected = option == currentValue;
//               return Container(
//                 margin: const EdgeInsets.symmetric(vertical: 2),
//                 decoration: BoxDecoration(
//                   color: isSelected ? Colors.blue[50] : null,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: RadioListTile<String>(
//                   title: Text(
//                     option,
//                     style: TextStyle(
//                       fontWeight: isSelected
//                           ? FontWeight.w600
//                           : FontWeight.normal,
//                     ),
//                   ),
//                   value: option,
//                   groupValue: currentValue,
//                   activeColor: Colors.blue[600],
//                   onChanged: (value) {
//                     onChanged(value!);
//                     Get.back();
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _selectDateRange(FollowupController controller) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: Get.context!,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//       initialDateRange: controller.selectedDateRange.value,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(primary: Colors.blue[600]!),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       controller.setDateRange(picked);
//     }
//   }

//   Future<void> _selectFollowUpDate(FollowupController controller) async {
//     final DateTime? picked = await showDatePicker(
//       context: Get.context!,
//       initialDate: controller.selectedFollowUpDate.value ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(primary: Colors.blue[600]!),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       controller.setFollowUpDate(picked);
//     }
//   }

//   Widget _buildListTile(
//     BuildContext context,
//     Map<String, dynamic> data,
//     String docId,
//     FollowupController controller,
//     Size size,
//     bool isTablet,
//   ) {
//     final bool isOverdue = _isFollowUpOverdue(data['followUpDate']);
//     final bool isToday = _isFollowUpToday(data['followUpDate']);
//     final avatarSize = isTablet ? 52.0 : 48.0;
//     final fontSize = isTablet ? 18.0 : 16.0;
//     final smallFontSize = isTablet ? 12.0 : 11.0;
//     final statusColor = isOverdue ? Colors.red : Colors.blue[600]!;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         horizontal: size.width * 0.04,
//         vertical: size.height * 0.006,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//         border: isOverdue
//             ? Border.all(color: Colors.red[300]!, width: 2)
//             : isToday
//             ? Border.all(color: Colors.blue[300]!, width: 2)
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => LeadDetailsPage(leadId: docId),
//             ),
//           ),
//           child: Padding(
//             padding: EdgeInsets.all(size.width * 0.04),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Stack(
//                       children: [
//                         Container(
//                           width: avatarSize,
//                           height: avatarSize,
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 statusColor.withOpacity(0.7),
//                                 statusColor,
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(avatarSize / 2),
//                           ),
//                           child: Icon(
//                             Icons.person,
//                             color: Colors.white,
//                             size: avatarSize * 0.5,
//                           ),
//                         ),
//                         if (isOverdue || isToday)
//                           Positioned(
//                             top: -2,
//                             right: -2,
//                             child: Container(
//                               width: 16,
//                               height: 16,
//                               decoration: BoxDecoration(
//                                 color: isOverdue ? Colors.red : Colors.blue,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.white,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: Icon(
//                                 isOverdue ? Icons.warning : Icons.schedule,
//                                 size: 8,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     SizedBox(width: size.width * 0.03),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             data['name'] ?? 'Unknown Lead',
//                             style: TextStyle(
//                               fontSize: fontSize,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           SizedBox(height: size.height * 0.005),
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: size.width * 0.02,
//                               vertical: size.height * 0.002,
//                             ),
//                             decoration: BoxDecoration(
//                               color: statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: statusColor.withOpacity(0.3),
//                               ),
//                             ),
//                             child: Text(
//                               (data['status'] ?? 'Unknown').toUpperCase(),
//                               style: TextStyle(
//                                 color: statusColor,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: size.width * 0.02,
//                         vertical: size.height * 0.005,
//                       ),
//                       decoration: BoxDecoration(
//                         color: isOverdue
//                             ? Colors.red[50]
//                             : isToday
//                             ? Colors.blue[50]
//                             : Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: isOverdue
//                               ? Colors.red[200]!
//                               : isToday
//                               ? Colors.blue[200]!
//                               : Colors.grey[300]!,
//                         ),
//                       ),
//                       child: Text(
//                         controller.formatDateShort(data['followUpDate']),
//                         style: TextStyle(
//                           fontSize: smallFontSize,
//                           fontWeight: FontWeight.w600,
//                           color: isOverdue
//                               ? Colors.red[700]
//                               : isToday
//                               ? Colors.blue[700]
//                               : Colors.grey[700],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: size.height * 0.015),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildQuickInfo(
//                         Icons.phone,
//                         data['phone1'] ?? 'N/A',
//                         Colors.blue[600]!,
//                         size,
//                       ),
//                     ),
//                     SizedBox(width: size.width * 0.02),
//                     Expanded(
//                       child: _buildQuickInfo(
//                         Icons.location_on,
//                         data['place'] ?? 'N/A',
//                         Colors.blue[600]!,
//                         size,
//                       ),
//                     ),
//                     SizedBox(width: size.width * 0.02),
//                     Expanded(
//                       child: _buildQuickInfo(
//                         Icons.inventory,
//                         '${data['nos'] ?? '0'} items',
//                         Colors.blue[600]!,
//                         size,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickInfo(IconData icon, String text, Color color, Size size) {
//     final fontSize = size.width > 600 ? 12.0 : 11.0;

//     return Container(
//       padding: EdgeInsets.symmetric(
//         vertical: size.height * 0.008,
//         horizontal: size.width * 0.02,
//       ),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           SizedBox(width: size.width * 0.01),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontSize: fontSize,
//                 color: color,
//                 fontWeight: FontWeight.w500,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   bool _isFollowUpOverdue(dynamic followUpDate) {
//     if (followUpDate == null) return false;
//     try {
//       DateTime date;
//       if (followUpDate is Timestamp) {
//         date = followUpDate.toDate();
//       } else if (followUpDate is String) {
//         date = DateTime.parse(followUpDate);
//       } else {
//         return false;
//       }
//       return date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
//     } catch (e) {
//       print('Error checking overdue: $e');
//       return false;
//     }
//   }

//   bool _isFollowUpToday(dynamic followUpDate) {
//     if (followUpDate == null) return false;
//     try {
//       DateTime date;
//       if (followUpDate is Timestamp) {
//         date = followUpDate.toDate();
//       } else if (followUpDate is String) {
//         date = DateTime.parse(followUpDate);
//       } else {
//         return false;
//       }
//       final now = DateTime.now();
//       return date.year == now.year &&
//           date.month == now.month &&
//           date.day == now.day;
//     } catch (e) {
//       print('Error checking today: $e');
//       return false;
//     }
//   }

//   void _navigateToDetails(
//     Map<String, dynamic> data,
//     String type,
//     String docId,
//   ) {
//     Get.to(() => LeadManagement());
//   }

//   Widget _buildListView(
//     FollowupController controller,
//     Size size,
//     bool isTablet,
//   ) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('Leads')
//           .orderBy("createdAt", descending: true)
//           .where("isArchived", isEqualTo: false)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No leads available',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Start by adding your first lead',
//                   style: TextStyle(color: Colors.grey[500]),
//                 ),
//               ],
//             ),
//           );
//         }

//         return Obx(() {
//           List<QueryDocumentSnapshot> filteredLeads = snapshot.data!.docs
//               .where(
//                 (doc) => controller.matchesFilters(
//                   doc.data() as Map<String, dynamic>,
//                 ),
//               )
//               .toList();

//           final sortedLeads = controller.sortLeadsByFollowUpDate(filteredLeads);

//           if (sortedLeads.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
//                   const SizedBox(height: 16),
//                   Text(
//                     'No leads found',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Try adjusting your search or filters',
//                     style: TextStyle(color: Colors.grey[500]),
//                   ),
//                 ],
//               ),
//             );
//           }
//           return ListView.builder(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             itemCount: sortedLeads.length,
//             itemBuilder: (context, index) {
//               final lead = sortedLeads[index];
//               final data = lead.data() as Map<String, dynamic>;
//               return _buildListTile(
//                 context,
//                 data,
//                 lead.id,
//                 controller,
//                 size,
//                 isTablet,
//               );
//             },
//           );
//         });
//       },
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales/FollowUp/detailfollowup_page.dart';
import 'package:sales/FollowUp/followup_controller.dart';
import 'package:sales/Home/home.dart';
import 'package:sales/Lead/leadmanagement.dart';

class FollowupPage extends StatelessWidget {
  const FollowupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FollowupController(), tag: 'followup');
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return WillPopScope(
      onWillPop: () async {
        Get.off(() => Home());
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchAndFilters(controller, size),
            _buildSummaryCards(controller, size, isTablet),
            Expanded(child: _buildListView(controller, size, isTablet)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Lead Follow-ups',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildSummaryCards(
    FollowupController controller,
    Size size,
    bool isTablet,
  ) {
    final cardPadding = isTablet ? 16.0 : 10.0;
    final cardHeight = isTablet ? 70.0 : 60.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      child: Obx(() {
        final leads = controller.leads;

        final overdue = leads.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _isFollowUpOverdue(data['followUpDate']);
        }).length;

        final today = leads.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _isFollowUpToday(data['followUpDate']);
        }).length;

        final hot = leads.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status']?.toString().toLowerCase() == 'hot';
        }).length;

        return SizedBox(
          height: cardHeight,
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Overdue',
                  overdue.toString(),
                  Icons.warning_amber_rounded,
                  Colors.red,
                  Colors.red[50]!,
                  cardPadding,
                  isTablet,
                ),
              ),
              SizedBox(width: size.width * 0.02),
              Expanded(
                child: _buildSummaryCard(
                  'Today',
                  today.toString(),
                  Icons.today,
                  Colors.blue[600]!,
                  Colors.blue[50]!,
                  cardPadding,
                  isTablet,
                ),
              ),
              SizedBox(width: size.width * 0.02),
              Expanded(
                child: _buildSummaryCard(
                  'Hot Leads',
                  hot.toString(),
                  Icons.local_fire_department,
                  Colors.blue[600]!,
                  Colors.blue[50]!,
                  cardPadding,
                  isTablet,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    IconData icon,
    Color color,
    Color backgroundColor,
    double padding,
    bool isTablet,
  ) {
    final iconSize = isTablet ? 20.0 : 16.0;
    final countFontSize = isTablet ? 20.0 : 16.0;
    final titleFontSize = isTablet ? 11.0 : 9.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: countFontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(icon, color: color, size: iconSize),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(FollowupController controller, Size size) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.015,
      ),
      child: Column(
        children: [
          _buildSearchBar(controller, size),
          SizedBox(height: size.height * 0.015),
          _buildFilterChips(controller, size),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FollowupController controller, Size size) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Obx(
        () => TextField(
          controller: controller.searchController,
          decoration: InputDecoration(
            hintText: 'Search leads...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: controller.searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: controller.clearSearchFilter,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.018,
            ),
          ),
          onChanged: (value) => controller.searchQuery.value = value,
        ),
      ),
    );
  }

  Widget _buildFilterChips(FollowupController controller, Size size) {
    final chipHeight = size.height * 0.045;

    return SizedBox(
      height: chipHeight,
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              'Status',
              controller.selectedStatus,
              controller.availableStatuses,
              controller.setStatus,
              controller,
              size,
            ),
            SizedBox(width: size.width * 0.02),
            _buildFilterChip(
              'Place',
              controller.selectedPlace,
              controller.availablePlaces,
              controller.setPlace,
              controller,
              size,
            ),
            SizedBox(width: size.width * 0.02),
            _buildFilterChip(
              'Product',
              controller.selectedProductNo,
              controller.availableProductNos,
              controller.setProductNo,
              controller,
              size,
            ),
            SizedBox(width: size.width * 0.02),
            _buildDateRangeChip(controller, size),
            SizedBox(width: size.width * 0.02),
            _buildFollowUpDateChip(controller, size),
            SizedBox(width: size.width * 0.02),
            _buildClearFiltersChip(controller, size),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    RxString currentValue,
    List<String> options,
    Function(String) onChanged,
    FollowupController controller,
    Size size,
  ) {
    final isSelected = currentValue.value != 'All';
    final fontSize = size.width > 600 ? 12.0 : 11.0;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[600] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              _showFilterDialog(label, currentValue.value, options, onChanged),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.03,
              vertical: size.height * 0.008,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label: ${currentValue.value}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(width: size.width * 0.015),
                  GestureDetector(
                    onTap: () => _clearIndividualFilter(label, controller),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeChip(FollowupController controller, Size size) {
    final fontSize = size.width > 600 ? 12.0 : 11.0;

    return Obx(() {
      final hasDateFilter = controller.selectedDateRange.value != null;
      return Container(
        decoration: BoxDecoration(
          color: hasDateFilter ? Colors.blue[600] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDateFilter ? Colors.blue[600]! : Colors.grey[300]!,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _selectDateRange(controller),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.008,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasDateFilter
                        ? 'Date: ${DateFormat('dd/MM').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd/MM').format(controller.selectedDateRange.value!.end)}'
                        : 'Date: All',
                    style: TextStyle(
                      color: hasDateFilter ? Colors.white : Colors.grey[700],
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasDateFilter) ...[
                    SizedBox(width: size.width * 0.015),
                    GestureDetector(
                      onTap: controller.clearDateRangeFilter,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFollowUpDateChip(FollowupController controller, Size size) {
    final fontSize = size.width > 600 ? 12.0 : 11.0;

    return Obx(() {
      final hasFollowUpDateFilter =
          controller.selectedFollowUpDate.value != null;
      return Container(
        decoration: BoxDecoration(
          color: hasFollowUpDateFilter ? Colors.blue[600] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFollowUpDateFilter
                ? Colors.blue[600]!
                : Colors.grey[300]!,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _selectFollowUpDate(controller),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.008,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasFollowUpDateFilter
                        ? 'Follow-Up: ${DateFormat('dd/MM').format(controller.selectedFollowUpDate.value!)}'
                        : 'Follow-Up: All',
                    style: TextStyle(
                      color: hasFollowUpDateFilter
                          ? Colors.white
                          : Colors.grey[700],
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasFollowUpDateFilter) ...[
                    SizedBox(width: size.width * 0.015),
                    GestureDetector(
                      onTap: controller.clearFollowUpDateFilter,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildClearFiltersChip(FollowupController controller, Size size) {
    final fontSize = size.width > 600 ? 12.0 : 11.0;

    return Obx(() {
      final hasActiveFilters =
          controller.selectedStatus.value != 'All' ||
          controller.selectedPlace.value != 'All' ||
          controller.selectedProductNo.value != 'All' ||
          controller.selectedDateRange.value != null ||
          controller.selectedFollowUpDate.value != null ||
          controller.searchQuery.value.isNotEmpty;

      if (!hasActiveFilters) return const SizedBox.shrink();

      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: controller.clearAllFilters,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.008,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.clear_all, size: 14, color: Colors.white),
                  SizedBox(width: size.width * 0.01),
                  Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _clearIndividualFilter(
    String filterType,
    FollowupController controller,
  ) {
    switch (filterType) {
      case 'Status':
        controller.clearStatusFilter();
        break;
      case 'Place':
        controller.clearPlaceFilter();
        break;
      case 'Product':
        controller.clearProductFilter();
        break;
    }
  }

  void _showFilterDialog(
    String title,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Filter by $title',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == currentValue;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RadioListTile<String>(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  value: option,
                  groupValue: currentValue,
                  activeColor: Colors.blue[600],
                  onChanged: (value) {
                    onChanged(value!);
                    Get.back();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(FollowupController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: controller.selectedDateRange.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue[600]!),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.setDateRange(picked);
    }
  }

  Future<void> _selectFollowUpDate(FollowupController controller) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: controller.selectedFollowUpDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue[600]!),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.setFollowUpDate(picked);
    }
  }

  Widget _buildListTile(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    FollowupController controller,
    Size size,
    bool isTablet,
  ) {
    final bool isOverdue = _isFollowUpOverdue(data['followUpDate']);
    final bool isToday = _isFollowUpToday(data['followUpDate']);
    final avatarSize = isTablet ? 52.0 : 48.0;
    final fontSize = isTablet ? 18.0 : 16.0;
    final smallFontSize = isTablet ? 12.0 : 11.0;
    final statusColor = isOverdue ? Colors.red : Colors.blue[600]!;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.006,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isOverdue
            ? Border.all(color: Colors.red[300]!, width: 2)
            : isToday
            ? Border.all(color: Colors.blue[300]!, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => LeadDetailsPage(leadId: docId)),
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withOpacity(0.7),
                                statusColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(avatarSize / 2),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: avatarSize * 0.5,
                          ),
                        ),
                        if (isOverdue || isToday)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isOverdue ? Colors.red : Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                isOverdue ? Icons.warning : Icons.schedule,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Unknown Lead',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: size.height * 0.005),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.02,
                              vertical: size.height * 0.002,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              (data['status'] ?? 'Unknown').toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.02,
                        vertical: size.height * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red[50]
                            : isToday
                            ? Colors.blue[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOverdue
                              ? Colors.red[200]!
                              : isToday
                              ? Colors.blue[200]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        controller.formatDateShort(data['followUpDate']),
                        style: TextStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: isOverdue
                              ? Colors.red[700]
                              : isToday
                              ? Colors.blue[700]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.015),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickInfo(
                        Icons.phone,
                        data['phone1'] ?? 'N/A',
                        Colors.blue[600]!,
                        size,
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Expanded(
                      child: _buildQuickInfo(
                        Icons.location_on,
                        data['place'] ?? 'N/A',
                        Colors.blue[600]!,
                        size,
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Expanded(
                      child: _buildQuickInfo(
                        Icons.inventory,
                        '${data['nos'] ?? '0'} items',
                        Colors.blue[600]!,
                        size,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text, Color color, Size size) {
    final fontSize = size.width > 600 ? 12.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.008,
        horizontal: size.width * 0.02,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: size.width * 0.01),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _isFollowUpOverdue(dynamic followUpDate) {
    if (followUpDate == null) return false;
    try {
      DateTime date;
      if (followUpDate is Timestamp) {
        date = followUpDate.toDate();
      } else if (followUpDate is String) {
        date = DateTime.parse(followUpDate);
      } else {
        return false;
      }
      return date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    } catch (e) {
      print('Error checking overdue: $e');
      return false;
    }
  }

  bool _isFollowUpToday(dynamic followUpDate) {
    if (followUpDate == null) return false;
    try {
      DateTime date;
      if (followUpDate is Timestamp) {
        date = followUpDate.toDate();
      } else if (followUpDate is String) {
        date = DateTime.parse(followUpDate);
      } else {
        return false;
      }
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (e) {
      print('Error checking today: $e');
      return false;
    }
  }

  Widget _buildListView(
    FollowupController controller,
    Size size,
    bool isTablet,
  ) {
    return Obx(() {
      final leads = controller.leads;

      if (leads.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No leads available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start by adding your first lead',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      final filteredLeads = leads
          .where(
            (doc) =>
                controller.matchesFilters(doc.data() as Map<String, dynamic>),
          )
          .toList();
      final sortedLeads = controller.sortLeadsByFollowUpDate(filteredLeads);

      if (sortedLeads.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No leads found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedLeads.length,
        itemBuilder: (context, index) {
          final lead = sortedLeads[index];
          final data = lead.data() as Map<String, dynamic>;
          return _buildListTile(
            context,
            data,
            lead.id,
            controller,
            size,
            isTablet,
          );
        },
      );
    });
  }
}
