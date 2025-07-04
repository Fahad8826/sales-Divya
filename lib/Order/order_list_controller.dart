import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final searchController = TextEditingController();

  // Reactive filter variables
  final _selectedStatus = 'All'.obs;
  final _selectedPlace = 'All'.obs;
  final _selectedProductNo = 'All'.obs;
  final _selectedDateRange = Rx<DateTimeRange?>(null);
  final _searchQuery = ''.obs;

  // Available filter options - make them reactive
  final availableStatuses = <String>['All'].obs;
  final availablePlaces = <String>['All'].obs;
  final availableProductNos = <String>['All'].obs;

  // Loading state
  final isLoadingFilters = true.obs;

  // Getters
  String get selectedStatus => _selectedStatus.value;
  String get selectedPlace => _selectedPlace.value;
  String get selectedProductNo => _selectedProductNo.value;
  DateTimeRange? get selectedDateRange => _selectedDateRange.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();

    // Bind search query to controller text changes
    searchController.addListener(() {
      _searchQuery.value = searchController.text;
    });

    // Debounce search query to optimize performance
    debounce<String>(_searchQuery, (_) {
      print('Debounced search triggered for: ${_searchQuery.value}');
      update(); // Only if using GetBuilder — safe to include
    }, time: Duration(milliseconds: 300));
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      // Load unique statuses, places, and product numbers from Orders collection
      final ordersSnapshot = await _firestore.collection('Orders').get();

      Set<String> statuses = {'All'};
      Set<String> places = {'All'};
      Set<String> productNos = {'All'};

      // Process orders
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['status'] != null &&
            data['status'].toString().trim().isNotEmpty) {
          statuses.add(data['status'].toString().trim());
        }
        if (data['place'] != null &&
            data['place'].toString().trim().isNotEmpty) {
          places.add(data['place'].toString().trim());
        }
        if (data['productID'] != null &&
            data['productID'].toString().trim().isNotEmpty) {
          productNos.add(data['productID'].toString().trim());
        }
      }

      // Update reactive lists
      availableStatuses.assignAll(statuses.toList()..sort());
      availablePlaces.assignAll(places.toList()..sort());
      availableProductNos.assignAll(productNos.toList()..sort());

      isLoadingFilters.value = false;

      // Debug print to check loaded options
      debugPrint('Loaded Statuses: ${availableStatuses}');
      debugPrint('Loaded Places: ${availablePlaces}');
      debugPrint('Loaded Products: ${availableProductNos}');
    } catch (e) {
      debugPrint('Error loading filter options: $e');
      isLoadingFilters.value = false;
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String formatDateShort(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(date);
  }

  bool matchesFilters(Map<String, dynamic> data, String type) {
    // Get the current user from Firebase Authentication
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('Error: No user is currently logged in.');
      return false;
    }

    // Safely retrieve salesmanID from data with null check
    final docUserId = data['salesmanID'] as String?;
    if (docUserId == null || docUserId != currentUser.uid) {
      debugPrint(
        'User ID filter failed: $docUserId does not match ${currentUser.uid}',
      );
      return false;
    }

    debugPrint('data:$docUserId');

    // Debug print for troubleshooting
    if (_selectedStatus.value != 'All' ||
        _selectedPlace.value != 'All' ||
        _selectedProductNo.value != 'All') {
      print(
        'Filtering order: ${data['name']} - Status: ${data['status']}, Place: ${data['place']}, ProductID: ${data['productID']}',
      );
      print(
        'Selected filters - Status: ${_selectedStatus.value}, Place: ${_selectedPlace.value}, ProductID: ${_selectedProductNo.value}',
      );
    }

    // Status filter - make case-insensitive and handle null values
    if (_selectedStatus.value != 'All') {
      final itemStatus = data['status']?.toString().trim() ?? '';
      if (itemStatus != _selectedStatus.value) {
        return false;
      }
    }

    // Place filter - make case-insensitive and handle null values
    if (_selectedPlace.value != 'All') {
      final itemPlace = data['place']?.toString().trim() ?? '';
      if (itemPlace != _selectedPlace.value) {
        return false;
      }
    }

    // Product No filter - handle null values
    if (_selectedProductNo.value != 'All') {
      final itemProductID = data['productID']?.toString().trim() ?? '';
      if (itemProductID != _selectedProductNo.value) {
        return false;
      }
    }

    // Date range filter
    if (_selectedDateRange.value != null && data['createdAt'] != null) {
      final createdDate = (data['createdAt'] as Timestamp).toDate();
      final startDate = DateTime(
        _selectedDateRange.value!.start.year,
        _selectedDateRange.value!.start.month,
        _selectedDateRange.value!.start.day,
      );
      final endDate = DateTime(
        _selectedDateRange.value!.end.year,
        _selectedDateRange.value!.end.month,
        _selectedDateRange.value!.end.day,
        23,
        59,
        59,
      );

      if (createdDate.isBefore(startDate) || createdDate.isAfter(endDate)) {
        return false;
      }
    }

    // Search filter
    if (_searchQuery.value.isNotEmpty) {
      final searchLower = _searchQuery.value.toLowerCase();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final phone1 = (data['phone1'] ?? '').toString().toLowerCase();
      final phone2 = (data['phone2'] ?? '').toString().toLowerCase();
      final address = (data['address'] ?? '').toString().toLowerCase();
      final place = (data['place'] ?? '').toString().toLowerCase();
      final remark = (data['remark'] ?? '').toString().toLowerCase();
      final orderId = (data['orderId'] ?? '').toString().toLowerCase();

      if (!name.contains(searchLower) &&
          !phone1.contains(searchLower) &&
          !phone2.contains(searchLower) &&
          !address.contains(searchLower) &&
          !place.contains(searchLower) &&
          !remark.contains(searchLower) &&
          !orderId.contains(searchLower)) {
        return false;
      }
    }

    return true;
  }

  void setStatus(String value) {
    _selectedStatus.value = value;
    print('Status filter set to: $value');
  }

  void setPlace(String value) {
    _selectedPlace.value = value;
    print('Place filter set to: $value');
  }

  void setProductNo(String value) {
    _selectedProductNo.value = value;
    print('ProductNo filter set to: $value');
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange.value = range;
    print('Date range filter set to: $range');
  }

  void clearAllFilters() {
    _selectedStatus.value = 'All';
    _selectedPlace.value = 'All';
    _selectedProductNo.value = 'All';
    _selectedDateRange.value = null;
    _searchQuery.value = '';
    searchController.clear();
    print('All filters cleared');
  }

  void refreshFilterOptions() {
    loadFilterOptions();
  }
}
