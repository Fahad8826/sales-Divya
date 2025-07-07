// // detail_page.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class IndividualOrderDetails extends StatelessWidget {
//   final Map<String, dynamic> data;
//   final String type;
//   final String docId;

//   const IndividualOrderDetails({
//     super.key,
//     required this.data,
//     required this.type,
//     required this.docId,
//   });

//   String formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     final date = timestamp.toDate();
//     return DateFormat('dd MMM yyyy, hh:mm a').format(date);
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'active':
//       case 'completed':
//         return Colors.green;
//       case 'warm':
//         return Colors.orange;
//       case 'cancelled':
//       case 'hot':
//         return Colors.red;
//       case 'cold':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildDetailCard(String title, String value, IconData icon) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.blue.shade700),
//         title: Text(
//           title,
//           style: const TextStyle(fontSize: 12, color: Colors.grey),
//         ),
//         subtitle: Text(
//           value,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String status = (data['status'] ?? 'Unknown').toString();
//     final String id = data['orderId'] ?? docId;
//     final bool isLead = type.toLowerCase() == 'lead';

//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text('Order Details'),
//         backgroundColor: Colors.blue.shade700,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Card
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.blue.shade100,
//                       child: Icon(
//                         Icons.shopping_cart,
//                         color: Colors.blue.shade700,
//                         size: 30,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             data['name'] ?? 'No Name',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '$type ID: $id',
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _getStatusColor(status).withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(
//                                 color: _getStatusColor(status).withOpacity(0.3),
//                               ),
//                             ),
//                             child: Text(
//                               status,
//                               style: TextStyle(
//                                 color: _getStatusColor(status),
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Contact Information
//             const Text(
//               'Contact Information',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             _buildDetailCard(
//               'Primary Phone',
//               data['phone1'] ?? 'N/A',
//               Icons.phone,
//             ),
//             if (data['phone2'] != null && data['phone2'].toString().isNotEmpty)
//               _buildDetailCard(
//                 'Secondary Phone',
//                 data['phone2'],
//                 Icons.phone_outlined,
//               ),
//             _buildDetailCard(
//               'Address',
//               data['address'] ?? 'N/A',
//               Icons.location_on,
//             ),
//             _buildDetailCard('Place', data['place'] ?? 'N/A', Icons.place),

//             const SizedBox(height: 16),

//             // Product Information
//             const Text(
//               'Product Information',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             _buildDetailCard(
//               'Product Number',
//               data['productID'] ?? 'N/A',
//               Icons.inventory,
//             ),
//             _buildDetailCard(
//               'Number of Items',
//               data['nos']?.toString() ?? 'N/A',
//               Icons.numbers,
//             ),

//             const SizedBox(height: 16),

//             // Additional Information
//             const Text(
//               'Additional Information',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             _buildDetailCard('Remarks', data['remark'] ?? 'N/A', Icons.note),
//             _buildDetailCard(
//               'Created At',
//               formatDate(data['createdAt']),
//               Icons.calendar_today,
//             ),

//             if (isLead && data['followUpDate'] != null)
//               _buildDetailCard(
//                 'Follow-Up Date',
//                 formatDate(data['followUpDate']),
//                 Icons.schedule,
//               ),

//             const SizedBox(height: 32),
//             const Text(
//               'Maker Info',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),

//             FutureBuilder<DocumentSnapshot>(
//               future: FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(data['makerId'])
//                   .get(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const CircularProgressIndicator();
//                 }
//                 if (!snapshot.hasData || !snapshot.data!.exists) {
//                   return _buildDetailCard(
//                     'Maker Name',
//                     'Not Found',
//                     Icons.person,
//                   );
//                 }

//                 final makerData = snapshot.data!.data() as Map<String, dynamic>;
//                 final makerName = makerData['name'] ?? 'Unnamed';

//                 return _buildDetailCard('Maker Name', makerName, Icons.person);
//               },
//             ),

//             FutureBuilder<DocumentSnapshot>(
//               future: FirebaseFirestore.instance
//                   .collection('Orders')
//                   .doc(docId)
//                   .get(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || !snapshot.data!.exists) {
//                   return _buildDetailCard(
//                     'Status',
//                     'Not Found',
//                     Icons.info_outline,
//                   );
//                 }

//                 final docData = snapshot.data!.data() as Map<String, dynamic>;
//                 final liveStatus = docData['status']?.toString() ?? 'Unknown';

//                 return _buildDetailCard('Status', liveStatus, Icons.flag);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:sales/Home/home.dart';
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

  @override
  Widget build(BuildContext context) {
    final String status = (data['status'] ?? 'Unknown').toString();
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
                              docData['status']?.toString() ?? 'Unknown';

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
            ],
          ),
        ),
      ),
    );
  }
}
