// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class IndividualFollowUpController extends GetxController {
  final RxMap<String, dynamic> data = RxMap<String, dynamic>();
  final String type;
  final String docId;
  final RxString productName = 'N/A'.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  IndividualFollowUpController({
    required Map<String, dynamic> initialData,
    required this.type,
    required this.docId,
  }) {
    data.assignAll(initialData);
    _fetchProductName();
  }

  void _fetchProductName() async {
    final productID = data['productID'];
    if (productID != null && productID.isNotEmpty) {
      try {
        final querySnapshot = await _firestore
            .collection('products')
            .where('id', isEqualTo: productID)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          productName.value = querySnapshot.docs.first['name'] ?? 'N/A';
        } else {
          productName.value = 'Product Not Found';
        }
      } catch (e) {
        print('Error fetching product name: $e');
        productName.value = 'Error fetching product';
      }
    } else {
      productName.value = 'No Product ID';
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

  Future<void> convertLeadToOrder(BuildContext context) async {
    if (type != 'Lead') return;

    try {
      final newOrderId = await generateCustomOrderId();

      final orderData = {
        ...data,
        'orderId': newOrderId,
        'createdAt': Timestamp.now(),
        'status': 'Active',
      };

      await _firestore.collection('Orders').doc(newOrderId).set(orderData);
      await _firestore.collection('Leads').doc(docId).delete();

      data.assignAll(orderData);
      data.refresh();

      Get.snackbar(
        'Success',
        'Lead converted to Order successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error converting lead to order: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
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
}
