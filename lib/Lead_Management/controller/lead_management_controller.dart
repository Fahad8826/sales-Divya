import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeadManagementController extends GetxController {
  final nameController = TextEditingController();
  final placeController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final phone2Controller = TextEditingController();
  final nosController = TextEditingController();
  final remarkController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  var selectedProductId = Rxn<String>();
  var selectedStatus = Rxn<String>();
  var followUpDate = Rxn<DateTime>();
  var productImageUrl = Rxn<String>();
  var productIdList = <String>[].obs;
  final makerList =
      <Map<String, dynamic>>[].obs; // each map: {id: ..., name: ...}
  final selectedMakerId = RxnString();
  final statusList = ['HOT', 'WARM', 'COOL'].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var productStockMap = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();

    fetchProducts();
    fetchMakers();
  }

  Future<void> fetchMakers() async {
    try {
      // Add loading state
      makerList.clear(); // Clear existing data
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'maker')
          .get();

      makerList.value = snapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['name'] ?? 'Unknown'};
      }).toList();

      if (makerList.isEmpty) {
        Get.snackbar('Warning', 'No makers found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load makers: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();

      final products = <String>[];
      final stockMap = <String, int>{};

      for (var doc in snapshot.docs) {
        final id = doc.data()['id']?.toString() ?? doc.id;
        final stock = doc.data()['stock'] ?? 0;
        products.add(id);
        stockMap[id] = stock;
      }

      productIdList.assignAll(products);
      productStockMap.assignAll(stockMap);

      debugPrint('Fetched product IDs: $products');
      debugPrint('Fetched product stock: $stockMap');
    } catch (e) {
      Get.snackbar('Error', 'Error fetching products: $e');
    }
  }

  Future<void> fetchProductImage(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No document found for product ID: $productId');
        productImageUrl.value = null;
        return;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final imageUrl = data['imageUrl'] as String?;
      debugPrint('Fetched imageUrl for $productId: $imageUrl');

      productImageUrl.value = imageUrl;
    } catch (e) {
      debugPrint('Error fetching image for $productId: $e');
      productImageUrl.value = null;
      Get.snackbar('Error', 'Error loading image: $e');
    }
  }

  Future<String> _generateLeadsId() async {
    final snapshot = await _firestore
        .collection('Leads')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;

    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['leadId'] as String?;
      if (lastId != null && lastId.startsWith('LEA')) {
        final numberPart = int.tryParse(lastId.replaceAll('LEA', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'LEA${newNumber.toString().padLeft(5, '0')}';
  }

  Future<void> saveLead() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar('Error', 'Please fill all required fields correctly');
      return;
    }

    if (followUpDate.value == null) {
      Get.snackbar('Error', 'Please select follow-up date');
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: selectedProductId.value)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar('Error', 'Selected product not found');
        return;
      }

      final productDoc = querySnapshot.docs.first;
      final docId = productDoc.id; // This is the Firestore document ID
      final productId =
          productDoc['id']; // This is the 'id' field inside the document
      debugPrint("Document ID: $docId");
      debugPrint("Product ID field: $productId");

      final leadId = await _generateLeadsId();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'User not logged in');
        return;
      }
      final userId = currentUser.uid;

      final newDocRef = _firestore.collection('Leads').doc();
      await newDocRef.set({
        'leadId': leadId,
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'productID': productId,
        'nos': nosController.text,
        'remark': remarkController.text.isNotEmpty
            ? remarkController.text
            : null,
        'status': selectedStatus.value,
        'followUpDate': Timestamp.fromDate(followUpDate.value!),
        'createdAt': Timestamp.now(),
        'salesmanID': userId,
        'isArchived': false,
      });

      Get.snackbar('Success', 'Lead saved successfully');
      clearForm();
      Navigator.of(Get.context!).pop();
    } catch (e) {
      Get.snackbar('Error', 'Error saving lead: $e');
    }
  }

  Future<void> placeOrder() async {
    if (!formKey.currentState!.validate() || selectedMakerId.value == null) {
      Get.snackbar('Error', 'Please fill all required fields correctly');
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: selectedProductId.value)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar('Error', 'Selected product not found');
        return;
      }

      final productDoc = querySnapshot.docs.first;
      final docId = productDoc.id;
      final productId = productDoc['id'];
      final currentStock =
          productDoc['stock']; // stock must be int in Firestore

      final orderedQuantity = int.tryParse(nosController.text) ?? 0;
      if (orderedQuantity <= 0) {
        Get.snackbar('Error', 'Invalid number of items ordered');
        return;
      }

      final newOrderId = await generateCustomOrderId();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'User not logged in');
        return;
      }

      final userId = currentUser.uid;

      // Save the order
      await _firestore.collection('Orders').add({
        'orderId': newOrderId,
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'productID': productId,
        'nos': orderedQuantity,
        'remark': remarkController.text.isNotEmpty
            ? remarkController.text
            : null,
        'status': selectedStatus.value,
        'makerId': selectedMakerId.value,
        'followUpDate': followUpDate.value != null
            ? Timestamp.fromDate(followUpDate.value!)
            : null,
        'salesmanID': userId,
        'createdAt': Timestamp.now(),
        'order_status': "pending",
      });

      // Update stock (won't go negative because of previous check)
      if (currentStock > 0) {
        final updatedStock = currentStock - orderedQuantity;
        await _firestore.collection('products').doc(docId).update({
          'stock': updatedStock,
        });
      }
      Get.snackbar('Success', 'Order placed successfully');
      clearForm();
      Navigator.of(Get.context!).pop();
    } catch (e) {
      Get.snackbar('Error', 'Error placing order: $e');
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

  bool isSaveButtonEnabled() {
    if (selectedStatus.value == null)
      return false; // Disable if status is -- Select --
    return selectedStatus.value != 'HOT';
  }

  bool isOrderButtonEnabled() {
    if (selectedStatus.value == null)
      return false; // Disable if status is -- Select --
    // final enteredNos = int.tryParse(nosController.text) ?? 0;
    // final availableStock = productStockMap[selectedProductId.value] ?? 0;

    return selectedStatus.value == 'HOT' && followUpDate.value == null;
  }

  void clearForm() {
    nameController.clear();
    placeController.clear();
    addressController.clear();
    phoneController.clear();
    phone2Controller.clear();
    nosController.clear();
    remarkController.clear();
    selectedProductId.value = null;
    selectedStatus.value = null;
    selectedMakerId.value = null; // Reset maker selection
    followUpDate.value = null;
    productImageUrl.value = null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? validatePlace(String? value) {
    if (value == null || value.isEmpty) return 'Place is required';
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Address is required';
    if (value.length < 5) return 'Address must be at least 5 characters';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone is required';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter valid 10-digit phone number';
    }
    return null;
  }

  String? validatePhone2(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field

    if (value == phoneController.text) {
      return 'Phone 2 should be different from Phone 1';
    }

    // Add other validations if needed
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  String? validateNos(String? value) {
    if (value == null || value.isEmpty) return 'NOS is required';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Enter valid number';

    // final enteredNos = int.tryParse(value);
    // final selectedProductId = this.selectedProductId.value;
    // final availableStock = productStockMap[selectedProductId] ?? 0;

    // if (enteredNos != null && enteredNos > availableStock) {
    //   return 'Only $availableStock in stock';
    // }

    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    placeController.dispose();
    addressController.dispose();
    phoneController.dispose();
    phone2Controller.dispose();
    nosController.dispose();
    remarkController.dispose();
    super.onClose();
  }
}
