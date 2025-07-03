import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeadListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final searchController = TextEditingController();

  // Reactive filter variables
  final _selectedType = 'All'.obs;
  final _selectedStatus = 'All'.obs;
  final _selectedPlace = 'All'.obs;
  final _selectedProductNo = 'All'.obs;
  final _selectedDateRange = Rx<DateTimeRange?>(null);
  final _searchQuery = ''.obs;

  // Available filter options
  final availableStatuses = <String>['All'].obs;
  final availablePlaces = <String>['All'].obs;
  final availableProductNos = <String>['All'].obs;

  // Loading state
  final isLoadingFilters = true.obs;

  // Getters
  String get selectedType => _selectedType.value;
  String get selectedStatus => _selectedStatus.value;
  String get selectedPlace => _selectedPlace.value;
  String get selectedProductNo => _selectedProductNo.value;
  DateTimeRange? get selectedDateRange => _selectedDateRange.value;
  String get searchQuery => _searchQuery.value;
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();

    // Debounce search query updates
    debounce(_searchQuery, (_) {
      // Trigger any action you want when user stops typing
      print('Search query: ${_searchQuery.value}');
      // If you are filtering displayed data, trigger UI update here
      update(); // If using GetBuilder
    }, time: Duration(milliseconds: 300));

    // Listener for text changes to update searchQuery
    searchController.addListener(() {
      _searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      final leadsSnapshot = await _firestore.collection('Leads').get();
      final ordersSnapshot = await _firestore.collection('Orders').get();

      Set<String> statuses = {'All'};
      Set<String> places = {'All'};
      Set<String> productNos = {'All'};

      for (var doc in leadsSnapshot.docs) {
        final data = doc.data();
        if (data['salesmanID'] != currentUserId)
          continue; // Filter by current user

        if (data['status']?.toString().trim().isNotEmpty == true) {
          statuses.add(data['status'].toString().trim());
        }
        if (data['place']?.toString().trim().isNotEmpty == true) {
          places.add(data['place'].toString().trim());
        }
        if (data['productID']?.toString().trim().isNotEmpty == true) {
          productNos.add(data['productID'].toString().trim());
        }
      }

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['userId'] != currentUserId) continue; // Filter by current user

        if (data['status']?.toString().trim().isNotEmpty == true) {
          statuses.add(data['status'].toString().trim());
        }
        if (data['place']?.toString().trim().isNotEmpty == true) {
          places.add(data['place'].toString().trim());
        }
        if (data['productID']?.toString().trim().isNotEmpty == true) {
          productNos.add(data['productID'].toString().trim());
        }
      }

      availableStatuses.assignAll(statuses.toList()..sort());
      availablePlaces.assignAll(places.toList()..sort());
      availableProductNos.assignAll(productNos.toList()..sort());

      isLoadingFilters.value = false;
    } catch (e) {
      print('Error loading filter options: $e');
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
    if (currentUserId == null || data['salesmanID'] != currentUserId) {
      return false;
    }

    if (_selectedType.value != 'All' && _selectedType.value != type) {
      return false;
    }

    if (_selectedStatus.value != 'All') {
      final itemStatus = data['status']?.toString().trim() ?? '';
      if (itemStatus != _selectedStatus.value) return false;
    }

    if (_selectedPlace.value != 'All') {
      final itemPlace = data['place']?.toString().trim() ?? '';
      if (itemPlace != _selectedPlace.value) return false;
    }

    if (_selectedProductNo.value != 'All') {
      final itemProductID = data['productID']?.toString().trim() ?? '';
      if (itemProductID != _selectedProductNo.value) return false;
    }

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

    if (_searchQuery.value.isNotEmpty) {
      final searchLower = _searchQuery.value.toLowerCase();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final phone1 = (data['phone1'] ?? '').toString().toLowerCase();
      final phone2 = (data['phone2'] ?? '').toString().toLowerCase();
      final address = (data['address'] ?? '').toString().toLowerCase();
      final place = (data['place'] ?? '').toString().toLowerCase();
      final remark = (data['remark'] ?? '').toString().toLowerCase();
      final leadId = (data['leadId'] ?? '').toString().toLowerCase();
      final orderId = (data['orderId'] ?? '').toString().toLowerCase();

      if (!name.contains(searchLower) &&
          !phone1.contains(searchLower) &&
          !phone2.contains(searchLower) &&
          !address.contains(searchLower) &&
          !place.contains(searchLower) &&
          !remark.contains(searchLower) &&
          !leadId.contains(searchLower) &&
          !orderId.contains(searchLower)) {
        return false;
      }
    }

    return true;
  }

  void setType(String value) {
    _selectedType.value = value;
    print('Type filter set to: $value');
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
    _selectedType.value = 'All';
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
