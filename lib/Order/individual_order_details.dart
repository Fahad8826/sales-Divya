// detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String status = (data['status'] ?? 'Unknown').toString();
    final String id = data['orderId'] ?? docId;
    final bool isLead = type.toLowerCase() == 'lead';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.shopping_cart,
                        color: Colors.blue.shade700,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$type ID: $id',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getStatusColor(status).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Information
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailCard(
              'Primary Phone',
              data['phone1'] ?? 'N/A',
              Icons.phone,
            ),
            if (data['phone2'] != null && data['phone2'].toString().isNotEmpty)
              _buildDetailCard(
                'Secondary Phone',
                data['phone2'],
                Icons.phone_outlined,
              ),
            _buildDetailCard(
              'Address',
              data['address'] ?? 'N/A',
              Icons.location_on,
            ),
            _buildDetailCard('Place', data['place'] ?? 'N/A', Icons.place),

            const SizedBox(height: 16),

            // Product Information
            const Text(
              'Product Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailCard(
              'Product Number',
              data['productID'] ?? 'N/A',
              Icons.inventory,
            ),
            _buildDetailCard(
              'Number of Items',
              data['nos']?.toString() ?? 'N/A',
              Icons.numbers,
            ),

            const SizedBox(height: 16),

            // Additional Information
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailCard('Remarks', data['remark'] ?? 'N/A', Icons.note),
            _buildDetailCard(
              'Created At',
              formatDate(data['createdAt']),
              Icons.calendar_today,
            ),

            if (isLead && data['followUpDate'] != null)
              _buildDetailCard(
                'Follow-Up Date',
                formatDate(data['followUpDate']),
                Icons.schedule,
              ),

            const SizedBox(height: 32),
            const Text(
              'Maker Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['makerId'])
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildDetailCard(
                    'Maker Name',
                    'Not Found',
                    Icons.person,
                  );
                }

                final makerData = snapshot.data!.data() as Map<String, dynamic>;
                final makerName = makerData['name'] ?? 'Unnamed';

                return _buildDetailCard('Maker Name', makerName, Icons.person);
              },
            ),

            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Orders')
                  .doc(docId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildDetailCard(
                    'Status',
                    'Not Found',
                    Icons.info_outline,
                  );
                }

                final docData = snapshot.data!.data() as Map<String, dynamic>;
                final liveStatus = docData['status']?.toString() ?? 'Unknown';

                return _buildDetailCard('Status', liveStatus, Icons.flag);
              },
            ),
          ],
        ),
      ),
    );
  }
}
