import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResponseDetailPage extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final String documentId;

  const ResponseDetailPage({
    super.key,
    required this.responseData,
    required this.documentId,
  });

  @override
  State<ResponseDetailPage> createState() => _ResponseDetailPageState();
}

class _ResponseDetailPageState extends State<ResponseDetailPage> {
  String adminEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchAdminEmail();
  }

  Future<void> _fetchAdminEmail() async {
    try {
      final adminId = widget.responseData['respondedBy'];
      print('Fetching admin email for ID: $adminId');

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .get();

      print('Admin doc exists: ${adminDoc.exists}');

      if (adminDoc.exists && mounted) {
        final data = adminDoc.data() as Map<String, dynamic>?;
        print('Admin doc data: $data');

        // Try different possible field names for email
        String? email =
            data?['email'] ??
            data?['Email'] ??
            data?['emailAddress'] ??
            data?['userEmail'] ??
            data?['adminEmail'];

        print('Found email: $email');

        setState(() {
          adminEmail = email ?? 'Admin Email Not Found';
        });
      } else if (mounted) {
        setState(() {
          adminEmail = 'Admin Not Found';
        });
      }
    } catch (e) {
      print('Error fetching admin email: $e');
      if (mounted) {
        setState(() {
          adminEmail = 'Error loading admin email';
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'in-progress':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.indigo).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor ?? Colors.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Response Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF2196F3),
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(widget.responseData['newStatus']),
                    _getStatusColor(
                      widget.responseData['newStatus'],
                    ).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(
                      widget.responseData['newStatus'],
                    ).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(widget.responseData['newStatus']),
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.responseData['newStatus'].toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Complaint Status",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Information Cards
            _buildInfoCard(
              icon: Icons.confirmation_number,
              title: "COMPLAINT",
              content: widget.responseData['complaint'] ?? 'N/A',
            ),

            _buildInfoCard(
              icon: Icons.message,
              title: "RESPONSE MESSAGE",
              content:
                  widget.responseData['response'] ?? 'No response provided',
            ),

            _buildInfoCard(
              icon: Icons.person,
              title: "RESPONDED BY",
              content: adminEmail,
              iconColor: Colors.green[600],
            ),

            _buildInfoCard(
              icon: Icons.access_time,
              title: "RESPONSE TIME",
              content: _formatTimestamp(widget.responseData['timestamp']),
              iconColor: Colors.blue[600],
            ),

            _buildInfoCard(
              icon: Icons.update,
              title: "STATUS CHANGED",
              content: widget.responseData['statusChanged'] ? 'Yes' : 'No',
              iconColor: widget.responseData['statusChanged']
                  ? Colors.green
                  : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
