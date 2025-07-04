// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class FollowupController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final searchController = TextEditingController();

//   // Reactive filter variables
//   final RxString selectedStatus = 'All'.obs;
//   final RxString selectedPlace = 'All'.obs;
//   final RxString selectedProductNo = 'All'.obs;
//   final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
//   final Rx<DateTime?> selectedFollowUpDate = Rx<DateTime?>(null);
//   final RxString searchQuery = ''.obs;

//   // Available filter options
//   final RxList<String> availableStatuses = ['All'].obs;
//   final RxList<String> availablePlaces = ['All'].obs;
//   final RxList<String> availableProductNos = ['All'].obs;

//   // Cache filter options to avoid redundant queries
//   bool _isFilterOptionsLoaded = false;

//   @override
//   void onInit() {
//     super.onInit();
//     loadFilterOptions();

//     // Update searchQuery whenever the text field changes
//     searchController.addListener(() {
//       searchQuery.value = searchController.text.trim();
//     });

//     // Debounce search query to avoid running filter logic too frequently
//     debounce<String>(searchQuery, (_) {
//       // This block runs 300ms after the user stops typing
//       print('Debounced search triggered for: ${searchQuery.value}');
//       update(); // Use this if your UI is built using GetBuilder
//       // If using Obx, no need for update()
//     }, time: Duration(milliseconds: 300));
//   }

//   Future<void> loadFilterOptions() async {
//     if (_isFilterOptionsLoaded) return;

//     try {
//       final leadsSnapshot = await _firestore
//           .collection('Leads')
//           .where('isArchived', isEqualTo: true)
//           .get();

//       final statuses = {'All'};
//       final places = {'All'};
//       final productNos = {'All'};

//       for (var doc in leadsSnapshot.docs) {
//         final data = doc.data();
//         final status = data['status']?.toString().trim();
//         final place = data['place']?.toString().trim();
//         final productID = data['productID']?.toString().trim();

//         if (status != null && status.isNotEmpty) statuses.add(status);
//         if (place != null && place.isNotEmpty) places.add(place);
//         if (productID != null && productID.isNotEmpty)
//           productNos.add(productID);
//       }

//       availableStatuses.assignAll(statuses.toList()..sort());
//       availablePlaces.assignAll(places.toList()..sort());
//       availableProductNos.assignAll(productNos.toList()..sort());
//       _isFilterOptionsLoaded = true;

//       print('Loaded filter options:');
//       print('Statuses: $availableStatuses');
//       print('Places: $availablePlaces');
//       print('Product IDs: $availableProductNos');
//     } catch (e, stackTrace) {
//       print('Error loading filter options: $e\n$stackTrace');
//       Get.snackbar(
//         'Error',
//         'Failed to load filter options: $e',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }

//   String formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     try {
//       final date = timestamp.toDate();
//       return DateFormat('dd MMM yyyy, hh:mm a').format(date);
//     } catch (e) {
//       print('Error formatting date: $e');
//       return 'N/A';
//     }
//   }

//   String formatDateShort(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     try {
//       final date = timestamp.toDate();
//       return DateFormat('dd MMM yyyy').format(date);
//     } catch (e) {
//       print('Error formatting short date: $e');
//       return 'N/A';
//     }
//   }

//   bool matchesFilters(Map<String, dynamic> data) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) {
//       print('No user logged in.');
//       return false;
//     }

//     final docUserId = data['salesmanID']?.toString();
//     if (docUserId != currentUser.uid) {
//       print('User ID filter failed: $docUserId != ${currentUser.uid}');
//       return false;
//     }

//     if (selectedStatus.value != 'All') {
//       final docStatus = data['status']?.toString().trim();
//       if (docStatus != selectedStatus.value) {
//         print('Status filter failed: $docStatus != ${selectedStatus.value}');
//         return false;
//       }
//     }

//     if (selectedPlace.value != 'All') {
//       final docPlace = data['place']?.toString().trim();
//       if (docPlace != selectedPlace.value) {
//         print('Place filter failed: $docPlace != ${selectedPlace.value}');
//         return false;
//       }
//     }

//     if (selectedProductNo.value != 'All') {
//       final docProductID = data['productID']?.toString().trim();
//       if (docProductID != selectedProductNo.value) {
//         print(
//           'Product filter failed: $docProductID != ${selectedProductNo.value}',
//         );
//         return false;
//       }
//     }

//     if (selectedDateRange.value != null && data['createdAt'] != null) {
//       try {
//         final createdDate = (data['createdAt'] as Timestamp).toDate();
//         final startDate = DateTime(
//           selectedDateRange.value!.start.year,
//           selectedDateRange.value!.start.month,
//           selectedDateRange.value!.start.day,
//         );
//         final endDate = DateTime(
//           selectedDateRange.value!.end.year,
//           selectedDateRange.value!.end.month,
//           selectedDateRange.value!.end.day,
//           23,
//           59,
//           59,
//         );

//         if (createdDate.isBefore(startDate) || createdDate.isAfter(endDate)) {
//           print(
//             'Date range filter failed: $createdDate not in range $startDate - $endDate',
//           );
//           return false;
//         }
//       } catch (e) {
//         print('Error in date range filter: $e');
//         return false;
//       }
//     }

//     if (selectedFollowUpDate.value != null && data['followUpDate'] != null) {
//       try {
//         final followUpDate = (data['followUpDate'] as Timestamp).toDate();
//         final selectedDate = selectedFollowUpDate.value!;
//         final followUpDateOnly = DateTime(
//           followUpDate.year,
//           followUpDate.month,
//           followUpDate.day,
//         );
//         final selectedDateOnly = DateTime(
//           selectedDate.year,
//           selectedDate.month,
//           selectedDate.day,
//         );

//         if (!followUpDateOnly.isAtSameMomentAs(selectedDateOnly)) {
//           print(
//             'Follow-up date filter failed: $followUpDateOnly != $selectedDateOnly',
//           );
//           return false;
//         }
//       } catch (e) {
//         print('Error in follow-up date filter: $e');
//         return false;
//       }
//     }

//     if (searchQuery.value.isNotEmpty) {
//       final searchLower = searchQuery.value.toLowerCase().trim();
//       final fieldsToSearch = [
//         data['name']?.toString().toLowerCase() ?? '',
//         data['phone1']?.toString().toLowerCase() ?? '',
//         data['phone2']?.toString().toLowerCase() ?? '',
//         data['address']?.toString().toLowerCase() ?? '',
//         data['place']?.toString().toLowerCase() ?? '',
//         data['remark']?.toString().toLowerCase() ?? '',
//         data['leadId']?.toString().toLowerCase() ?? '',
//       ];

//       if (!fieldsToSearch.any((field) => field.contains(searchLower))) {
//         print('Search filter failed: No match for "$searchLower"');
//         return false;
//       }
//     }

//     return true;
//   }

//   List<QueryDocumentSnapshot> sortLeadsByFollowUpDate(
//     List<QueryDocumentSnapshot> leads,
//   ) {
//     final today = DateTime.now();
//     final todayDateOnly = DateTime(today.year, today.month, today.day);

//     return leads..sort((a, b) {
//       final aData = a.data() as Map<String, dynamic>;
//       final bData = b.data() as Map<String, dynamic>;
//       final aFollowUp = aData['followUpDate'] as Timestamp?;
//       final bFollowUp = bData['followUpDate'] as Timestamp?;

//       if (aFollowUp == null && bFollowUp == null) return 0;
//       if (aFollowUp == null) return 1;
//       if (bFollowUp == null) return -1;

//       final aDate = aFollowUp.toDate();
//       final bDate = bFollowUp.toDate();
//       final aDateOnly = DateTime(aDate.year, aDate.month, aDate.day);
//       final bDateOnly = DateTime(bDate.year, bDate.month, bDate.day);

//       final aIsToday = aDateOnly.isAtSameMomentAs(todayDateOnly);
//       final bIsToday = bDateOnly.isAtSameMomentAs(todayDateOnly);

//       if (aIsToday && !bIsToday) return -1;
//       if (!aIsToday && bIsToday) return 1;

//       return aDate.compareTo(bDate);
//     });
//   }

//   void setStatus(String value) => selectedStatus.value = value;
//   void setPlace(String value) => selectedPlace.value = value;
//   void setProductNo(String value) => selectedProductNo.value = value;
//   void setDateRange(DateTimeRange? range) => selectedDateRange.value = range;
//   void setFollowUpDate(DateTime? date) => selectedFollowUpDate.value = date;

//   void clearStatusFilter() => selectedStatus.value = 'All';
//   void clearPlaceFilter() => selectedPlace.value = 'All';
//   void clearProductFilter() => selectedProductNo.value = 'All';
//   void clearDateRangeFilter() => selectedDateRange.value = null;
//   void clearFollowUpDateFilter() => selectedFollowUpDate.value = null;
//   void clearSearchFilter() {
//     searchQuery.value = '';
//     searchController.clear();
//   }

//   void clearAllFilters() {
//     selectedStatus.value = 'All';
//     selectedPlace.value = 'All';
//     selectedProductNo.value = 'All';
//     selectedDateRange.value = null;
//     selectedFollowUpDate.value = null;
//     searchQuery.value = '';
//     searchController.clear();
//   }

//   @override
//   void onClose() {
//     searchController.dispose();
//     super.onClose();
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FollowupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final searchController = TextEditingController();

  // Reactive filter variables
  final RxString selectedStatus = 'All'.obs;
  final RxString selectedPlace = 'All'.obs;
  final RxString selectedProductNo = 'All'.obs;
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);
  final Rx<DateTime?> selectedFollowUpDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;

  // Reactive list of leads
  final RxList<QueryDocumentSnapshot> leads = <QueryDocumentSnapshot>[].obs;

  // Available filter options
  final RxList<String> availableStatuses = ['All'].obs;
  final RxList<String> availablePlaces = ['All'].obs;
  final RxList<String> availableProductNos = ['All'].obs;

  // Cache filter options to avoid redundant queries
  bool _isFilterOptionsLoaded = false;

  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();
    fetchLeads();

    // Update searchQuery whenever the text field changes
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
    });

    // Debounce search query to avoid running filter logic too frequently
    debounce<String>(searchQuery, (_) {
      print('Debounced search triggered for: ${searchQuery.value}');
    }, time: const Duration(milliseconds: 300));
  }

  // Fetch leads from Firestore and bind to reactive list
  void fetchLeads() {
    _firestore
        .collection('Leads')
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      leads.assignAll(snapshot.docs);
      print('Fetched ${leads.length} leads');
    }, onError: (e) {
      print('Error fetching leads: $e');
      Get.snackbar(
        'Error',
        'Failed to load leads: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  Future<void> loadFilterOptions() async {
    if (_isFilterOptionsLoaded) return;

    try {
      final leadsSnapshot = await _firestore
          .collection('Leads')
          .where('isArchived', isEqualTo: false) // Fixed to false
          .get();

      final statuses = {'All'};
      final places = {'All'};
      final productNos = {'All'};

      for (var doc in leadsSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().trim();
        final place = data['place']?.toString().trim();
        final productID = data['productID']?.toString().trim();

        if (status != null && status.isNotEmpty) statuses.add(status);
        if (place != null && place.isNotEmpty) places.add(place);
        if (productID != null && productID.isNotEmpty) productNos.add(productID);
      }

      availableStatuses.assignAll(statuses.toList()..sort());
      availablePlaces.assignAll(places.toList()..sort());
      availableProductNos.assignAll(productNos.toList()..sort());
      _isFilterOptionsLoaded = true;

      print('Loaded filter options:');
      print('Statuses: $availableStatuses');
      print('Places: $availablePlaces');
      print('Product IDs: $availableProductNos');
    } catch (e, stackTrace) {
      print('Error loading filter options: $e\n$stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load filter options: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return 'N/A';
    }
  }

  String formatDateShort(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      print('Error formatting short date: $e');
      return 'N/A';
    }
  }

  bool matchesFilters(Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No user logged in.');
      return false;
    }

    final docUserId = data['salesmanID']?.toString();
    if (docUserId != currentUser.uid) {
      print('User ID filter failed: $docUserId != ${currentUser.uid}');
      return false;
    }

    if (selectedStatus.value != 'All') {
      final docStatus = data['status']?.toString().trim();
      if (docStatus != selectedStatus.value) {
        print('Status filter failed: $docStatus != ${selectedStatus.value}');
        return false;
      }
    }

    if (selectedPlace.value != 'All') {
      final docPlace = data['place']?.toString().trim();
      if (docPlace != selectedPlace.value) {
        print('Place filter failed: $docPlace != ${selectedPlace.value}');
        return false;
      }
    }

    if (selectedProductNo.value != 'All') {
      final docProductID = data['productID']?.toString().trim();
      if (docProductID != selectedProductNo.value) {
        print(
            'Product filter failed: $docProductID != ${selectedProductNo.value}');
        return false;
      }
    }

    if (selectedDateRange.value != null && data['createdAt'] != null) {
      try {
        final createdDate = (data['createdAt'] as Timestamp).toDate();
        final startDate = DateTime(
          selectedDateRange.value!.start.year,
          selectedDateRange.value!.start.month,
          selectedDateRange.value!.start.day,
        );
        final endDate = DateTime(
          selectedDateRange.value!.end.year,
          selectedDateRange.value!.end.month,
          selectedDateRange.value!.end.day,
          23,
          59,
          59,
        );

        if (createdDate.isBefore(startDate) || createdDate.isAfter(endDate)) {
          print(
              'Date range filter failed: $createdDate not in range $startDate - $endDate');
          return false;
        }
      } catch (e) {
        print('Error in date range filter: $e');
        return false;
      }
    }

    if (selectedFollowUpDate.value != null && data['followUpDate'] != null) {
      try {
        final followUpDate = (data['followUpDate'] as Timestamp).toDate();
        final selectedDate = selectedFollowUpDate.value!;
        final followUpDateOnly =
            DateTime(followUpDate.year, followUpDate.month, followUpDate.day);
        final selectedDateOnly =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

        if (!followUpDateOnly.isAtSameMomentAs(selectedDateOnly)) {
          print(
              'Follow-up date filter failed: $followUpDateOnly != $selectedDateOnly');
          return false;
        }
      } catch (e) {
        print('Error in follow-up date filter: $e');
        return false;
      }
    }

    if (searchQuery.value.isNotEmpty) {
      final searchLower = searchQuery.value.toLowerCase().trim();
      final fieldsToSearch = [
        data['name']?.toString().toLowerCase() ?? '',
        data['phone1']?.toString().toLowerCase() ?? '',
        data['phone2']?.toString().toLowerCase() ?? '',
        data['address']?.toString().toLowerCase() ?? '',
        data['place']?.toString().toLowerCase() ?? '',
        data['remark']?.toString().toLowerCase() ?? '',
        data['leadId']?.toString().toLowerCase() ?? '',
      ];

      if (!fieldsToSearch.any((field) => field.contains(searchLower))) {
        print('Search filter failed: No match for "$searchLower"');
        return false;
      }
    }

    return true;
  }

  List<QueryDocumentSnapshot> sortLeadsByFollowUpDate(
      List<QueryDocumentSnapshot> leads) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    return leads
      ..sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aFollowUp = aData['followUpDate'] as Timestamp?;
        final bFollowUp = bData['followUpDate'] as Timestamp?;

        if (aFollowUp == null && bFollowUp == null) return 0;
        if (aFollowUp == null) return 1;
        if (bFollowUp == null) return -1;

        final aDate = aFollowUp.toDate();
        final bDate = bFollowUp.toDate();
        final aDateOnly = DateTime(aDate.year, aDate.month, aDate.day);
        final bDateOnly = DateTime(bDate.year, bDate.month, bDate.day);

        final aIsToday = aDateOnly.isAtSameMomentAs(todayDateOnly);
        final bIsToday = bDateOnly.isAtSameMomentAs(todayDateOnly);

        if (aIsToday && !bIsToday) return -1;
        if (!aIsToday && bIsToday) return 1;

        return aDate.compareTo(bDate);
      });
  }

  void setStatus(String value) => selectedStatus.value = value;
  void setPlace(String value) => selectedPlace.value = value;
  void setProductNo(String value) => selectedProductNo.value = value;
  void setDateRange(DateTimeRange? range) => selectedDateRange.value = range;
  void setFollowUpDate(DateTime? date) => selectedFollowUpDate.value = date;

  void clearStatusFilter() => selectedStatus.value = 'All';
  void clearPlaceFilter() => selectedPlace.value = 'All';
  void clearProductFilter() => selectedProductNo.value = 'All';
  void clearDateRangeFilter() => selectedDateRange.value = null;
  void clearFollowUpDateFilter() => selectedFollowUpDate.value = null;
  void clearSearchFilter() {
    searchQuery.value = '';
    searchController.clear();
  }

  void clearAllFilters() {
    selectedStatus.value = 'All';
    selectedPlace.value = 'All';
    selectedProductNo.value = 'All';
    selectedDateRange.value = null;
    selectedFollowUpDate.value = null;
    searchQuery.value = '';
    searchController.clear();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}