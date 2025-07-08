import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  final ScrollController scrollController =
      ScrollController(); // Scroll controller for pagination

  // Reactive filter variables
  final _selectedStatus = 'All'.obs;
  final _selectedPlace = 'All'.obs;
  final _selectedProductNo = 'All'.obs;
  final _selectedDateRange = Rx<DateTimeRange?>(null);
  final _searchQuery = ''.obs;

  // Pagination variables
  var items = <Map<String, dynamic>>[].obs; // Reactive list of all items
  var filteredItems = <Map<String, dynamic>>[].obs; // Reactive filtered items
  var isLoading = false.obs; // Reactive loading state
  var isLoadingMore = false.obs; // Reactive state for loading more items
  var page = 1.obs; // Reactive page counter
  var hasMore = true.obs; // Reactive flag to indicate if more data is available
  final int itemsPerPage = 20;
  DocumentSnapshot? lastDocument; // To store the last document for pagination

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
    loadInitialItems(); // Load initial items for pagination
    _setupScrollListener(); // Setup scroll listener for pagination

    // Bind search query to controller text changes
    searchController.addListener(() {
      _searchQuery.value = searchController.text;
    });

    // Debounce search query to optimize performance
    debounce<String>(_searchQuery, (_) {
      print('Debounced search triggered for: ${_searchQuery.value}');
      _resetPagination();
      _loadMoreItems();
    }, time: Duration(milliseconds: 300));

    // Listen to filter changes to reset and reload items
    everAll(
      [_selectedStatus, _selectedPlace, _selectedProductNo, _selectedDateRange],
      (_) {
        _resetPagination();
        _loadMoreItems();
      },
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent * 0.9 &&
          !isLoadingMore.value &&
          hasMore.value) {
        _loadMoreItems();
      }
    });
  }

  void _resetPagination() {
    page.value = 1;
    items.clear();
    filteredItems.clear();
    lastDocument = null;
    hasMore.value = true;
  }

  Future<void> loadInitialItems() async {
    _resetPagination();
    await _loadMoreItems();
  }

  Future<void> _loadMoreItems() async {
    if (!hasMore.value || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      // Build Firestore query with pagination
      Query query = _firestore
          .collection('Orders')
          .orderBy('createdAt', descending: true)
          .limit(itemsPerPage);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        isLoadingMore.value = false;
        return;
      }

      // Process documents
      List<Map<String, dynamic>> newItems = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (matchesFilters(data, 'Order')) {
          newItems.add({...data, 'type': 'Order', 'docId': doc.id});
        }
      }

      lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      items.addAll(newItems);
      filteredItems.assignAll(items); // Update filtered items
      page.value++;

      if (snapshot.docs.length < itemsPerPage) {
        hasMore.value = false;
      }

      print(
        'Loaded ${newItems.length} items, total: ${items.length}, hasMore: ${hasMore.value}',
      );
    } catch (e) {
      debugPrint('Error loading items: $e');
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
      if (page.value == 1) isLoading.value = false;
    }
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
        if (data['order_status'] != null &&
            data['order_status'].toString().trim().isNotEmpty) {
          statuses.add(data['order_status'].toString().trim());
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('Error: No user is currently logged in.');
      return false;
    }

    final docUserId = data['salesmanID'] as String?;
    if (docUserId == null || docUserId != currentUser.uid) {
      debugPrint(
        'User ID filter failed: $docUserId does not match ${currentUser.uid}',
      );
      return false;
    }

    debugPrint('data:$docUserId');

    if (_selectedStatus.value != 'All') {
      final itemStatus = data['order_status']?.toString().trim() ?? '';
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
    _resetPagination();
    _loadMoreItems();
  }

  void refreshFilterOptions() {
    loadFilterOptions();
    _resetPagination();
    _loadMoreItems();
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class OrderListController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final searchController = TextEditingController();
//   final ScrollController scrollController =
//       ScrollController(); // Scroll controller for pagination

//   // Reactive filter variables
//   final _selectedStatus = 'All'.obs;
//   final _selectedPlace = 'All'.obs;
//   final _selectedProductNo = 'All'.obs;
//   final _selectedDateRange = Rx<DateTimeRange?>(null);
//   final _searchQuery = ''.obs;

//   // Pagination variables
//   var items = <Map<String, dynamic>>[].obs; // Reactive list of all items
//   var filteredItems = <Map<String, dynamic>>[].obs; // Reactive filtered items
//   var isLoading = false.obs; // Reactive loading state
//   var isLoadingMore = false.obs; // Reactive state for loading more items
//   var page = 1.obs; // Reactive page counter
//   var hasMore = true.obs; // Reactive flag to indicate if more data is available
//   final int itemsPerPage = 20;
//   DocumentSnapshot? lastDocument; // To store the last document for pagination

//   // Available filter options - make them reactive
//   final availableStatuses = <String>['All'].obs;
//   final availablePlaces = <String>['All'].obs;
//   final availableProductNos = <String>['All'].obs;
//   // Loading state
//   final isLoadingFilters = true.obs;

//   // Getters
//   String get selectedStatus => _selectedStatus.value;
//   String get selectedPlace => _selectedPlace.value;
//   String get selectedProductNo => _selectedProductNo.value;
//   DateTimeRange? get selectedDateRange => _selectedDateRange.value;
//   String get searchQuery => _searchQuery.value;

//   @override
//   void onInit() {
//     super.onInit();
//     loadFilterOptions();
//     loadInitialItems(); // Load initial items for pagination
//     _setupScrollListener(); // Setup scroll listener for pagination

//     // Bind search query to controller text changes
//     searchController.addListener(() {
//       _searchQuery.value = searchController.text;
//     });

//     // Debounce search query to optimize performance
//     debounce<String>(_searchQuery, (_) {
//       print('Debounced search triggered for: ${_searchQuery.value}');
//       _resetPagination();
//       _loadMoreItems();
//     }, time: Duration(milliseconds: 300));

//     // Listen to filter changes to reset and reload items
//     everAll(
//       [_selectedStatus, _selectedPlace, _selectedProductNo, _selectedDateRange],
//       (_) {
//         _resetPagination();
//         _loadMoreItems();
//       },
//     );
//   }

//   @override
//   void onClose() {
//     searchController.dispose();
//     scrollController.dispose();
//     super.onClose();
//   }

//   void _setupScrollListener() {
//     scrollController.addListener(() {
//       if (scrollController.position.pixels >=
//               scrollController.position.maxScrollExtent * 0.9 &&
//           !isLoadingMore.value &&
//           hasMore.value) {
//         _loadMoreItems();
//       }
//     });
//   }

//   void _resetPagination() {
//     page.value = 1;
//     items.clear();
//     filteredItems.clear();
//     lastDocument = null;
//     hasMore.value = true;
//   }

//   Future<void> loadInitialItems() async {
//     _resetPagination();
//     await _loadMoreItems();
//   }

//   Future<void> _loadMoreItems() async {
//     if (!hasMore.value || isLoadingMore.value) return;

//     isLoadingMore.value = true;
//     try {
//       // Build Firestore query with pagination
//       Query query = _firestore
//           .collection('Orders')
//           .orderBy('createdAt', descending: true)
//           .limit(itemsPerPage);

//       if (lastDocument != null) {
//         query = query.startAfterDocument(lastDocument!);
//       }

//       final snapshot = await query.get();

//       if (snapshot.docs.isEmpty) {
//         hasMore.value = false;
//         isLoadingMore.value = false;
//         return;
//       }

//       // Process documents
//       List<Map<String, dynamic>> newItems = [];
//       for (var doc in snapshot.docs) {
//         final data = doc.data() as Map<String, dynamic>;
//         // Exclude orders where Cancel is true
//         if (data['Cancel'] != true && matchesFilters(data, 'Order')) {
//           newItems.add({...data, 'type': 'Order', 'docId': doc.id});
//         }
//       }

//       lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
//       items.addAll(newItems);
//       filteredItems.assignAll(items); // Update filtered items
//       page.value++;

//       if (snapshot.docs.length < itemsPerPage) {
//         hasMore.value = false;
//       }

//       print(
//         'Loaded ${newItems.length} items, total: ${items.length}, hasMore: ${hasMore.value}',
//       );
//     } catch (e) {
//       debugPrint('Error loading items: $e');
//       hasMore.value = false;
//     } finally {
//       isLoadingMore.value = false;
//       if (page.value == 1) isLoading.value = false;
//     }
//   }

//   Future<void> loadFilterOptions() async {
//     try {
//       isLoadingFilters.value = true;

//       // Load unique statuses, places, and product numbers from Orders collection
//       final ordersSnapshot = await _firestore.collection('Orders').get();

//       Set<String> statuses = {'All'};
//       Set<String> places = {'All'};
//       Set<String> productNos = {'All'};

//       // Process orders
//       for (var doc in ordersSnapshot.docs) {
//         final data = doc.data();
//         if (data['order_status'] != null &&
//             data['order_status'].toString().trim().isNotEmpty) {
//           statuses.add(data['order_status'].toString().trim());
//         }
//         if (data['place'] != null &&
//             data['place'].toString().trim().isNotEmpty) {
//           places.add(data['place'].toString().trim());
//         }
//         if (data['productID'] != null &&
//             data['productID'].toString().trim().isNotEmpty) {
//           productNos.add(data['productID'].toString().trim());
//         }
//       }

//       // Update reactive lists
//       availableStatuses.assignAll(statuses.toList()..sort());
//       availablePlaces.assignAll(places.toList()..sort());
//       availableProductNos.assignAll(productNos.toList()..sort());

//       isLoadingFilters.value = false;

//       debugPrint('Loaded Statuses: ${availableStatuses}');
//       debugPrint('Loaded Places: ${availablePlaces}');
//       debugPrint('Loaded Products: ${availableProductNos}');
//     } catch (e) {
//       debugPrint('Error loading filter options: $e');
//       isLoadingFilters.value = false;
//     }
//   }

//   String formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     final date = timestamp.toDate();
//     return DateFormat('dd MMM yyyy, hh:mm a').format(date);
//   }

//   String formatDateShort(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     final date = timestamp.toDate();
//     return DateFormat('dd MMM yyyy').format(date);
//   }

//   bool matchesFilters(Map<String, dynamic> data, String type) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) {
//       debugPrint('Error: No user is currently logged in.');
//       return false;
//     }

//     final docUserId = data['salesmanID'] as String?;
//     if (docUserId == null || docUserId != currentUser.uid) {
//       debugPrint(
//         'User ID filter failed: $docUserId does not match ${currentUser.uid}',
//       );
//       return false;
//     }

//     debugPrint('data:$docUserId');

//     if (_selectedStatus.value != 'All') {
//       final itemStatus = data['order_status']?.toString().trim() ?? '';
//       if (itemStatus != _selectedStatus.value) return false;
//     }

//     if (_selectedPlace.value != 'All') {
//       final itemPlace = data['place']?.toString().trim() ?? '';
//       if (itemPlace != _selectedPlace.value) return false;
//     }

//     if (_selectedProductNo.value != 'All') {
//       final itemProductID = data['productID']?.toString().trim() ?? '';
//       if (itemProductID != _selectedProductNo.value) return false;
//     }

//     if (_selectedDateRange.value != null && data['createdAt'] != null) {
//       final createdDate = (data['createdAt'] as Timestamp).toDate();
//       final startDate = DateTime(
//         _selectedDateRange.value!.start.year,
//         _selectedDateRange.value!.start.month,
//         _selectedDateRange.value!.start.day,
//       );
//       final endDate = DateTime(
//         _selectedDateRange.value!.end.year,
//         _selectedDateRange.value!.end.month,
//         _selectedDateRange.value!.end.day,
//         23,
//         59,
//         59,
//       );

//       if (createdDate.isBefore(startDate) || createdDate.isAfter(endDate)) {
//         return false;
//       }
//     }

//     if (_searchQuery.value.isNotEmpty) {
//       final searchLower = _searchQuery.value.toLowerCase();
//       final name = (data['name'] ?? '').toString().toLowerCase();
//       final phone1 = (data['phone1'] ?? '').toString().toLowerCase();
//       final phone2 = (data['phone2'] ?? '').toString().toLowerCase();
//       final address = (data['address'] ?? '').toString().toLowerCase();
//       final place = (data['place'] ?? '').toString().toLowerCase();
//       final remark = (data['remark'] ?? '').toString().toLowerCase();
//       final orderId = (data['orderId'] ?? '').toString().toLowerCase();

//       if (!name.contains(searchLower) &&
//           !phone1.contains(searchLower) &&
//           !phone2.contains(searchLower) &&
//           !address.contains(searchLower) &&
//           !place.contains(searchLower) &&
//           !remark.contains(searchLower) &&
//           !orderId.contains(searchLower)) {
//         return false;
//       }
//     }

//     return true;
//   }

//   void setStatus(String value) {
//     _selectedStatus.value = value;
//     print('Status filter set to: $value');
//   }

//   void setPlace(String value) {
//     _selectedPlace.value = value;
//     print('Place filter set to: $value');
//   }

//   void setProductNo(String value) {
//     _selectedProductNo.value = value;
//     print('ProductNo filter set to: $value');
//   }

//   void setDateRange(DateTimeRange? range) {
//     _selectedDateRange.value = range;
//     print('Date range filter set to: $range');
//   }

//   void clearAllFilters() {
//     _selectedStatus.value = 'All';
//     _selectedPlace.value = 'All';
//     _selectedProductNo.value = 'All';
//     _selectedDateRange.value = null;
//     _searchQuery.value = '';
//     searchController.clear();
//     print('All filters cleared');
//     _resetPagination();
//     _loadMoreItems();
//   }

//   void refreshFilterOptions() {
//     loadFilterOptions();
//     _resetPagination();
//     _loadMoreItems();
//   }
// }
