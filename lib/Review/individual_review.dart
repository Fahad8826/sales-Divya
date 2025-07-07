// // Order Details Screen
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class OrderDetailsScreen extends StatefulWidget {
//   final Map<String, dynamic> order;

//   const OrderDetailsScreen({super.key, required this.order});

//   @override
//   State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
// }

// class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _notesController = TextEditingController();
//   String _selectedStatus = 'Pending Review';
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _selectedStatus = widget.order['reviewStatus'] ?? 'Pending Review';
//     _notesController.text = widget.order['followUpNotes'] ?? '';
//   }

//   @override
//   void dispose() {
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _updateOrderStatus() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await _firestore.collection('Orders').doc(widget.order['docId']).update({
//         'reviewStatus': _selectedStatus,
//         'followUpNotes': _notesController.text,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Order updated successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context, true); // Return true to indicate update
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error updating order: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final deliveryDate = (widget.order['deliveryDate'] as Timestamp).toDate();
//     final formattedDate = DateFormat('dd MMMM yyyy').format(deliveryDate);
//     final daysSinceDelivery = DateTime.now().difference(deliveryDate).inDays;

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text(widget.order['orderId'] ?? 'Order Details'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 0,
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(height: 1, color: Colors.grey[200]),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Order Summary Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.receipt_long,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                         const SizedBox(width: 12),
//                         const Text(
//                           'Order Summary',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     _buildInfoRow('Order ID', widget.order['orderId'] ?? 'N/A'),
//                     _buildInfoRow('Customer', widget.order['name'] ?? 'N/A'),
//                     _buildInfoRow('Phone', widget.order['phone1'] ?? 'N/A'),
//                     _buildInfoRow('Delivery Date', formattedDate),
//                     _buildInfoRow(
//                       'Days Since Delivery',
//                       '$daysSinceDelivery days',
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Product Details Card
//             if (widget.order['products'] != null) ...[
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.inventory_2,
//                             color: Theme.of(context).primaryColor,
//                           ),
//                           const SizedBox(width: 12),
//                           const Text(
//                             'Products',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       ...((widget.order['products'] as List?) ?? []).map<
//                         Widget
//                       >((product) {
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 12),
//                           child: Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.grey[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         product['name'] ?? 'Product',
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       Text(
//                                         'Qty: ${product['quantity'] ?? 'N/A'}',
//                                         style: TextStyle(
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Text(
//                                   '₹${product['price'] ?? 'N/A'}',
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],

//             // Follow-up Actions Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.follow_the_signs,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                         const SizedBox(width: 12),
//                         const Text(
//                           'Follow-up Actions',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     const Text(
//                       'Review Status',
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     const SizedBox(height: 8),
//                     DropdownButtonFormField<String>(
//                       value: _selectedStatus,
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                       ),
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'Pending Review',
//                           child: Text('Pending Review'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Reviewed',
//                           child: Text('Reviewed'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'Follow-up Required',
//                           child: Text('Follow-up Required'),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedStatus = value!;
//                         });
//                       },
//                     ),

//                     const SizedBox(height: 16),

//                     const Text(
//                       'Notes',
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: _notesController,
//                       maxLines: 4,
//                       decoration: InputDecoration(
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         hintText:
//                             'Add follow-up notes, customer feedback, or action items...',
//                         contentPadding: const EdgeInsets.all(12),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Action Buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text('Cancel'),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _updateOrderStatus,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : const Text('Update Order'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           const Text(': '),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// Order Details Screen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _notesController = TextEditingController();
  String _selectedStatus = 'Pending Review';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order['reviewStatus'] ?? 'Pending Review';
    _notesController.text = widget.order['followUpNotes'] ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('Orders').doc(widget.order['docId']).update({
        'reviewStatus': _selectedStatus,
        'followUpNotes': _notesController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryDate = widget.order['deliveryDate'] is Timestamp
    ? (widget.order['deliveryDate'] as Timestamp).toDate()
    : DateTime.now(); // or show 'N/A'

final formattedDate = DateFormat('dd MMMM yyyy').format(deliveryDate);
final daysSinceDelivery = DateTime.now().difference(deliveryDate).inDays;


    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.order['orderId'] ?? 'Order Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Order ID', widget.order['orderId'] ?? 'N/A'),
                    _buildInfoRow('Customer', widget.order['name'] ?? 'N/A'),
                    _buildInfoRow('Phone', widget.order['phone1'] ?? 'N/A'),
                    _buildInfoRow('Delivery Date', formattedDate),
                    _buildInfoRow(
                      'Days Since Delivery',
                      '$daysSinceDelivery days',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Product Details Card
            if (widget.order['products'] != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...((widget.order['products'] as List?) ?? []).map<
                        Widget
                      >((product) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] ?? 'Product',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${product['quantity'] ?? 'N/A'}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${product['price'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Follow-up Actions Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.follow_the_signs,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Follow-up Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Review Status',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending Review',
                          child: Text('Pending Review'),
                        ),
                        DropdownMenuItem(
                          value: 'Reviewed',
                          child: Text('Reviewed'),
                        ),
                        DropdownMenuItem(
                          value: 'Follow-up Required',
                          child: Text('Follow-up Required'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Notes',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText:
                            'Add follow-up notes, customer feedback, or action items...',
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateOrderStatus,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}