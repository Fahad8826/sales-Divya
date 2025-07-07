import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class IndividualFollowUpController extends GetxController {
  final RxMap<String, dynamic> data = RxMap<String, dynamic>();
  final String type; // 'Lead' or 'Order'
  final String docId; // Document ID for the current Lead/Order
  final RxString productName =
      'N/A'.obs; // For Leads, might represent a target product
  final RxList<Map<String, dynamic>> orderProducts = <Map<String, dynamic>>[]
      .obs; // For Orders: {'productId': id, 'name': name, 'quantity': qty}
  final RxString orderMakerName = 'N/A'.obs; // For Orders

  /// Loaded from Firestore before the dialog opens
  final RxList<Map<String, String>> makerList = <Map<String, String>>[].obs;

  /// Holds the maker currently chosen in the dialog
  final RxString selectedMakerId = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<String> availableMakers = <String>[].obs;
  final RxList<String> availableProducts = <String>[].obs;

  IndividualFollowUpController({
    required Map<String, dynamic> initialData,
    required this.type,
    required this.docId,
  }) {
    data.assignAll(initialData);
    // _fetchProductName(); // Fetches product name for 'productID' if present
    _loadOrderSpecificData(); // Load products and maker for orders
  }


  Future<void> loadDropdownOptions() async {
    final productSnap = await FirebaseFirestore.instance
        .collection('Products')
        .get();
    availableProducts.assignAll(
      productSnap.docs.map((doc) => doc['name'].toString()).toList(),
    );

    final makerSnap = await FirebaseFirestore.instance
        .collection('Makers')
        .get();
    availableMakers.assignAll(
      makerSnap.docs.map((doc) => doc['name'].toString()).toList(),
    );
  }

  Future<void> updateLeadData(
    String docId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore.collection('Leads').doc(docId).update(updatedData);
      Get.back(); // Close the edit page
      Get.snackbar('Success', 'Lead updated successfully');
    } catch (e) {
      print('Update failed: $e');
      Get.snackbar('Error', 'Failed to update lead');
    }
  }

  // Load product details and maker for 'Order' type documents
  void _loadOrderSpecificData() async {
    if (type == 'Order') {
      // Load Products and Quantities
      final List<dynamic>? productsData = data['products'];
      if (productsData != null) {
        List<Map<String, dynamic>> fetchedProducts = [];
        for (var item in productsData) {
          final productId = item['productId'];
          final quantity = item['quantity'];
          if (productId != null && quantity != null) {
            try {
              final productDoc = await _firestore
                  .collection('products')
                  .where('id', isEqualTo: productId)
                  .limit(1)
                  .get();
              if (productDoc.docs.isNotEmpty) {
                fetchedProducts.add({
                  'productId': productId,
                  'name': productDoc.docs.first['name'] ?? 'Unknown Product',
                  'quantity': quantity,
                });
              } else {
                fetchedProducts.add({
                  'productId': productId,
                  'name': 'Product Not Found',
                  'quantity': quantity,
                });
              }
            } catch (e) {
              print('Error fetching product details for ID $productId: $e');
              fetchedProducts.add({
                'productId': productId,
                'name': 'Error fetching details',
                'quantity': quantity,
              });
            }
          }
        }
        orderProducts.assignAll(fetchedProducts);
      }

      // Load Maker Name
      final makerId = data['makerId'];
      if (makerId != null && makerId.isNotEmpty) {
        try {
          final makerDoc = await _firestore
              .collection('Users')
              .doc(makerId)
              .get();
          if (makerDoc.exists) {
            orderMakerName.value = makerDoc.data()?['name'] ?? 'Unknown Maker';
          } else {
            orderMakerName.value = 'Maker Not Found';
          }
        } catch (e) {
          print('Error fetching maker name for ID $makerId: $e');
          orderMakerName.value = 'Error fetching maker';
        }
      } else {
        orderMakerName.value = 'No Maker Assigned';
      }
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  Future<void> updateFollowUpDate(BuildContext context) async {
    final now = DateTime.now();
    // Use the follow-up date if it exists and is not before now; otherwise, use now
    final initialDate = data['followUpDate'] != null
        ? (data['followUpDate'] as Timestamp).toDate()
        : now;
    final validInitialDate = initialDate.isBefore(now) ? now : initialDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      try {
        final Timestamp newFollowUpDate = Timestamp.fromDate(pickedDate);

        await _firestore
            .collection(type == 'Lead' ? 'Leads' : 'Orders')
            .doc(docId)
            .update({'followUpDate': newFollowUpDate});

        data['followUpDate'] = newFollowUpDate;
        data.refresh();

        Get.snackbar(
          'Success',
          'Follow-up date updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Error updating follow-up date: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<String> generateCustomOrderId() async {
    final snapshot = await _firestore
        .collection('Orders')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;

    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['orderId'] as String?;
      if (lastId != null && lastId.startsWith('ORD')) {
        final numberPart = int.tryParse(lastId.replaceAll('ORD', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'ORD${newNumber.toString().padLeft(5, '0')}';
  }

  Future<void> fetchMakers() async {
    try {
      makerList.clear();
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'maker')
          .get();

      makerList.assignAll(
        snapshot.docs.map(
          (d) => {'id': d.id, 'name': (d['name'] ?? 'Unknown') as String},
        ),
      );
      if (makerList.isEmpty) {
        Get.snackbar('Warning', 'No makers found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load makers: $e');
    }
  }

  Future<void> convertLeadToOrder(
    BuildContext context, {
    required String makerId,
    required String makerName,
    required String nos, // passed as string
  }) async {
    if (type != 'Lead') return;

    try {
      final productId = data['productID'];
      if (productId == null || productId.isEmpty) {
        Get.snackbar('Error', 'Product ID not found in Lead');
        return;
      }

      final productQuery = await _firestore
          .collection('products')
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (productQuery.docs.isEmpty) {
        Get.snackbar('Error', 'Product not found');
        return;
      }

      final productDoc = productQuery.docs.first;
      final docId = productDoc.id;
      final currentStock = productDoc['stock'];

      final orderedQuantity = int.tryParse(data['nos']?.toString() ?? '') ?? 0;
      if (orderedQuantity <= 0) {
        Get.snackbar('Error', 'Invalid quantity');
        return;
      }

      if (orderedQuantity > currentStock) {
        Get.snackbar('Error', 'Not enough stock available');
        return;
      }

      // ✅ Update stock
      final updatedStock = currentStock - orderedQuantity;
      await _firestore.collection('products').doc(docId).update({
        'stock': updatedStock,
      });

      final newOrderId = await generateCustomOrderId();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'User not logged in');
        return;
      }

      final userId = currentUser.uid;

      // ✅ Create new order with top-level fields
      await _firestore.collection('Orders').doc(newOrderId).set({
        'orderId': newOrderId,
        'name': data['name'],
        'place': data['place'],
        'address': data['address'],
        'phone1': data['phone1'],
        'phone2': data['phone2'],
        'productID': productId,
        'nos': orderedQuantity,
        'remark': data['remark'],
        'status': data['status'],
        'makerId': makerId,
        'makerName': makerName,
        'followUpDate': data['followUpDate'],
        'salesmanID': userId,
        'createdAt': Timestamp.now(),
        'order_status': 'pending',
      });

      // ✅ Delete the Lead
      await _firestore.collection('Leads').doc(docId).delete();

      Get.snackbar('Success', 'Lead converted to Order');
      Navigator.of(Get.context!).pop();
    } catch (e) {
      Get.snackbar('Error', 'Error converting lead: $e');
    }
  }

  Future<void> archiveDocument(BuildContext context) async {
    try {
      await _firestore
          .collection(type == 'Lead' ? 'Leads' : 'Orders')
          .doc(docId)
          .update({'isArchived': true, 'archivedAt': Timestamp.now()});

      data['isArchived'] = true;
      data['archivedAt'] = Timestamp.now();
      data.refresh();

      Get.snackbar(
        'Success',
        '${type} archived successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error archiving ${type.toLowerCase()}: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ----------------------- NEW EDIT ORDER FUNCTION -----------------------
  Future<void> editOrder({
    required BuildContext context, // Pass context for potential dialogs
    List<Map<String, dynamic>>?
    newProductsAndQuantities, // List of {'productId': 'id', 'quantity': count}
    String? newMakerId,
  }) async {
    if (type != 'Order') {
      Get.snackbar(
        'Info',
        'This document is not an Order. Cannot edit order details.',
        backgroundColor: Colors.blueGrey,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final orderRef = _firestore
          .collection('Orders')
          .doc(docId); // Use controller's docId

      Map<String, dynamic> updateData = {};

      if (newProductsAndQuantities != null) {
        // Validate products: ensure IDs are valid and quantities are positive
        List<Map<String, dynamic>> validatedProducts = [];
        for (var item in newProductsAndQuantities) {
          final productId = item['productId'];
          final quantity = item['quantity'];

          if (productId == null || productId.isEmpty) {
            Get.snackbar(
              'Error',
              'Product ID cannot be empty.',
              backgroundColor: Colors.red,
            );
            return;
          }
          if (quantity == null || quantity <= 0) {
            Get.snackbar(
              'Error',
              'Quantity for product $productId must be positive.',
              backgroundColor: Colors.red,
            );
            return;
          }
          // Optional: Check if product exists in 'products' collection
          final productDoc = await _firestore
              .collection('products')
              .where('id', isEqualTo: productId)
              .limit(1)
              .get();
          if (productDoc.docs.isEmpty) {
            Get.snackbar(
              'Error',
              'Product with ID $productId not found.',
              backgroundColor: Colors.red,
            );
            return;
          }

          validatedProducts.add({'productId': productId, 'quantity': quantity});
        }
        updateData['products'] = validatedProducts;
      }

      if (newMakerId != null) {
        // Validate maker: check if newMakerId exists and has 'role' = 'maker'
        final makerDoc = await _firestore
            .collection('Users')
            .doc(newMakerId)
            .get();
        if (!makerDoc.exists) {
          Get.snackbar(
            'Error',
            'Selected maker not found.',
            backgroundColor: Colors.red,
          );
          return;
        }
        if (makerDoc.data()?['role'] != 'maker') {
          Get.snackbar(
            'Error',
            'Selected user is not a maker.',
            backgroundColor: Colors.red,
          );
          return;
        }
        updateData['makerId'] = newMakerId;
      }

      if (updateData.isEmpty) {
        Get.snackbar(
          'Info',
          'No changes provided for the order.',
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await orderRef.update(updateData);

      // Update local RxMap to reflect changes and trigger UI rebuild
      updateData.forEach((key, value) {
        data[key] = value;
      });
      data.refresh();
      _loadOrderSpecificData(); // Re-load product names and maker name for display

      Get.snackbar(
        'Success',
        'Order updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ----------------------- HELPER FUNCTIONS FOR UI SELECTION -----------------------

  /// Fetches a list of all available products.
  /// Used to populate a dropdown or selection list in your UI.
  Future<List<Map<String, dynamic>>> getAvailableProducts() async {
    try {
      final querySnapshot = await _firestore.collection('products').get();
      return querySnapshot.docs
          .map(
            (doc) => {
              'id':
                  doc['id'], // Assuming 'id' is a field in your product documents
              'name': doc['name'],
              'stock':
                  doc['Stock'], // Assuming 'Stock' is the field for stock quantity
              // Add other relevant product fields if needed
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching available products: $e');
      return [];
    }
  }

  /// Fetches a list of all users with the role 'maker'.
  /// Used to populate a dropdown or selection list for assigning a maker.
  Future<List<Map<String, dynamic>>> getAvailableMakers() async {
    try {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'maker')
          .get();
      return querySnapshot.docs
          .map(
            (doc) => {
              'id': doc.id, // Use doc.id for the document ID of the user
              'name':
                  doc['name'], // Assuming 'name' is a field in your user documents
              // Add other relevant maker fields if needed
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching available makers: $e');
      return [];
    }
  }
}
