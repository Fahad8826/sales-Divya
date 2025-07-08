import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales/Order/order_managmenet.dart';

class IndividualOrderDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;
  final String docId;

  const IndividualOrderDetails({
    super.key,
    required this.data,
    required this.type,
    required this.docId,
  });

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
        return Colors.green;
      case 'warm':
        return Colors.orange;
      case 'cancelled':
      case 'hot':
        return Colors.red;
      case 'cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required double fontSize,
    required double iconSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: fontSize * 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: Colors.grey[600]),
          SizedBox(width: iconSize * 0.6),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(top: fontSize, bottom: fontSize * 0.5),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fontSize * 0.8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize * 0.8,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        ],
      ),
    );
  }



  Future<void> _cancelOrder(BuildContext context) async {
    try {
      if (docId == null || docId.isEmpty) {
        throw Exception("Order document ID is null or empty.");
      }

      if (data['productID'] == null || data['productID'].toString().isEmpty) {
        throw Exception("Product ID (data['productID']) is null or empty.");
      }

      final orderRef = FirebaseFirestore.instance
          .collection('Orders')
          .doc(docId);

      // Fetch product document by 'id' field using data['productID']
      final productQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('id', isEqualTo: data['productID'])
          .limit(1)
          .get();

      if (productQuery.docs.isEmpty) {
        throw Exception("Product with id '${data['productID']}' not found.");
      }

      final productRef = productQuery.docs.first.reference;

      // Run transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final orderSnapshot = await transaction.get(orderRef);
        final productSnapshot = await transaction.get(productRef);

        if (!orderSnapshot.exists || !productSnapshot.exists) {
          throw Exception("Order or Product document does not exist.");
        }

        final currentNos = orderSnapshot['nos'] ?? 0;
        final currentStock = productSnapshot['stock'] ?? 0;
        final currentStatus =
            orderSnapshot['order_status']?.toString().trim() ?? '';

        // Check if order_status is "pending" before allowing cancellation
        if (currentStatus != 'pending') {
          throw Exception(
            "Only orders with status 'pending' can be cancelled.",
          );
        }

        transaction.update(orderRef, {'Cancel': true});
        transaction.update(productRef, {'stock': currentStock + currentNos});
      });

      Get.snackbar(
        'Order Cancelled',
        'The order has been successfully cancelled and stock updated.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );

      Get.off(() => OrderManagement());
    } catch (e) {
      print('Error cancelling order: $e');
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = (data['order_status'] ?? 'Unknown').toString();
    final String id = data['orderId'] ?? docId;
    final bool isLead = type.toLowerCase() == 'lead';

    // Get screen size and orientation using MediaQuery
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double baseFontSize = screenWidth * 0.035;
    final double iconSize = screenWidth * 0.05;
    final double avatarRadius = screenWidth * 0.07;
    final double cardPadding = screenWidth * 0.04;
    final double containerPadding = screenWidth * 0.03;

    return WillPopScope(
      onWillPop: () async {
        Get.off(() => OrderManagement());
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Order Details',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderManagement()),
              );
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF3B82F6),
          elevation: 1,
          foregroundColor: Colors.black87,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            children: [
              // Single Card with All Details
              Card(
                color: Colors.white,
                margin: EdgeInsets.symmetric(vertical: cardPadding * 0.5),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardPadding * 0.6),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.blue[50],
                            child: Icon(
                              Icons.shopping_cart,
                              size: avatarRadius * 1.2,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(width: cardPadding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'No Name',
                                  style: TextStyle(
                                    fontSize: baseFontSize * 1.3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: baseFontSize * 0.3),
                                Text(
                                  '$type ID: $id',
                                  style: TextStyle(
                                    fontSize: baseFontSize * 0.9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: containerPadding * 1.2,
                              vertical: containerPadding * 0.6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                containerPadding * 1.2,
                              ),
                              border: Border.all(
                                color: _getStatusColor(status).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: baseFontSize * 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Contact Information
                      _buildSectionDivider('CONTACT INFORMATION', baseFontSize),
                      _buildInfoRow(
                        label: 'Primary Phone',
                        value: data['phone1'] ?? 'N/A',
                        icon: Icons.phone,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      if (data['phone2'] != null &&
                          data['phone2'].toString().isNotEmpty)
                        _buildInfoRow(
                          label: 'Secondary Phone',
                          value: data['phone2'],
                          icon: Icons.phone_callback,
                          fontSize: baseFontSize,
                          iconSize: iconSize,
                        ),
                      _buildInfoRow(
                        label: 'Address',
                        value: data['address'] ?? 'N/A',
                        icon: Icons.location_on,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      _buildInfoRow(
                        label: 'Place',
                        value: data['place'] ?? 'N/A',
                        icon: Icons.place,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),

                      // Product Information
                      _buildSectionDivider('PRODUCT INFORMATION', baseFontSize),
                      _buildInfoRow(
                        label: 'Product Number',
                        value: data['productID'] ?? 'N/A',
                        icon: Icons.inventory,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      _buildInfoRow(
                        label: 'Number of Items',
                        value: data['nos']?.toString() ?? 'N/A',
                        icon: Icons.numbers,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),

                      // Additional Information
                      _buildSectionDivider(
                        'ADDITIONAL INFORMATION',
                        baseFontSize,
                      ),
                      _buildInfoRow(
                        label: 'Remarks',
                        value: data['remark'] ?? 'N/A',
                        icon: Icons.note,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      _buildInfoRow(
                        label: 'Created At',
                        value: formatDate(data['createdAt']),
                        icon: Icons.calendar_today,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),

                      if (isLead && data['followUpDate'] != null)
                        _buildInfoRow(
                          label: 'Follow-Up Date',
                          value: formatDate(data['followUpDate']),
                          icon: Icons.schedule,
                          fontSize: baseFontSize,
                          iconSize: iconSize,
                        ),

                      // Maker Info Section
                      _buildSectionDivider('MAKER INFO', baseFontSize),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(data['makerId'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: baseFontSize * 0.4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: iconSize,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: iconSize * 0.6),
                                  Text(
                                    'Loading maker info...',
                                    style: TextStyle(
                                      fontSize: baseFontSize * 0.9,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return _buildInfoRow(
                              label: 'Maker Name',
                              value: 'Not Found',
                              icon: Icons.person,
                              fontSize: baseFontSize,
                              iconSize: iconSize,
                            );
                          }

                          final makerData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final makerName = makerData['name'] ?? 'Unnamed';

                          return _buildInfoRow(
                            label: 'Maker Name',
                            value: makerName,
                            icon: Icons.person,
                            fontSize: baseFontSize,
                            iconSize: iconSize,
                          );
                        },
                      ),

                      // Live Status
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Orders')
                            .doc(docId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: baseFontSize * 0.4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: iconSize,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: iconSize * 0.6),
                                  Text(
                                    'Loading status...',
                                    style: TextStyle(
                                      fontSize: baseFontSize * 0.9,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return _buildInfoRow(
                              label: 'Status',
                              value: 'Not Found',
                              icon: Icons.info_outline,
                              fontSize: baseFontSize,
                              iconSize: iconSize,
                            );
                          }

                          final docData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final liveStatus =
                              docData['order_status']?.toString() ?? 'Unknown';

                          return _buildInfoRow(
                            label: 'Status',
                            value: liveStatus,
                            icon: Icons.flag,
                            fontSize: baseFontSize,
                            iconSize: iconSize,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: cardPadding),
              ElevatedButton.icon(
                onPressed: () async {
                  await _cancelOrder(context);
                },
                icon: Icon(Icons.cancel),
                label: Text('Cancel Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadding * 2,
                    vertical: cardPadding * 0.8,
                  ),
                  textStyle: TextStyle(fontSize: baseFontSize),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cardPadding * 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
