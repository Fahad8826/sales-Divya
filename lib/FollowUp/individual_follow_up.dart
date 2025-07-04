import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales/FollowUp/individual_followup_controller.dart';
import 'package:url_launcher/url_launcher.dart';

/// Standard Individual Follow Up screen with all details in a single card
class IndividualFollowUp extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;
  final String docId;

  const IndividualFollowUp({
    super.key,
    required this.data,
    required this.type,
    required this.docId,
  });

  ButtonStyle elevatedButtonStyle(
    Color color,
    double cardPadding,
    double baseFontSize,
  ) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: color,
      elevation: 2,
      padding: EdgeInsets.symmetric(vertical: cardPadding * 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardPadding * 0.3),
      ),
      textStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: baseFontSize * 0.9,
      ),
    );
  }

  // ------------------------------------------------------------------------
  // Helper Methods
  // ------------------------------------------------------------------------
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

  // ------------------------------------------------------------------------
  // UI Build Method
  // ------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      IndividualFollowUpController(initialData: data, type: type, docId: docId),
    );

    // Get screen size and orientation using MediaQuery
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double baseFontSize = screenWidth * 0.035;
    final double iconSize = screenWidth * 0.05;
    final double avatarRadius = screenWidth * 0.07;
    final double cardPadding = screenWidth * 0.04;
    final double containerPadding = screenWidth * 0.03;

    return Obx(() {
      final isLead = controller.type == 'Lead';
      final id = isLead
          ? controller.data['leadId']
          : controller.data['orderId'];
      final status = controller.data['status'] ?? 'N/A';

      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            '${controller.type} Details',
            style: TextStyle(fontSize: baseFontSize * 1.2),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
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
                              isLead ? Icons.person_add : Icons.shopping_cart,
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
                                  controller.data['name'] ?? 'No Name',
                                  style: TextStyle(
                                    fontSize: baseFontSize * 1.3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: baseFontSize * 0.3),
                                if (id != null)
                                  Text(
                                    '${controller.type} ID: $id',
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
                        value: controller.data['phone1'] ?? 'N/A',
                        icon: Icons.phone,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      if ((controller.data['phone2'] ?? '')
                          .toString()
                          .isNotEmpty)
                        _buildInfoRow(
                          label: 'Secondary Phone',
                          value: controller.data['phone2'],
                          icon: Icons.phone_callback,
                          fontSize: baseFontSize,
                          iconSize: iconSize,
                        ),
                      _buildInfoRow(
                        label: 'Address',
                        value: controller.data['address'] ?? 'N/A',
                        icon: Icons.location_on,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      _buildInfoRow(
                        label: 'Place',
                        value: controller.data['place'] ?? 'N/A',
                        icon: Icons.place,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),

                      // Product Information
                      _buildSectionDivider('PRODUCT INFORMATION', baseFontSize),
                      _buildInfoRow(
                        label: 'Product ID',
                        value: controller.data['productID'] ?? 'N/A',
                        icon: Icons.inventory_2,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      // Obx(
                      //   () => _buildInfoRow(
                      //     label: 'Product Name',
                      //     value: controller.productName.value,
                      //     icon: Icons.label,
                      //     fontSize: baseFontSize,
                      //     iconSize: iconSize,
                      //   ),
                      // ),
                      _buildInfoRow(
                        label: 'Quantity',
                        value: controller.data['nos']?.toString() ?? 'N/A',
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
                        value: controller.data['remark'] ?? 'N/A',
                        icon: Icons.note_alt,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      _buildInfoRow(
                        label: 'Created Date',
                        value: controller.formatDate(
                          controller.data['createdAt'],
                        ),
                        icon: Icons.calendar_today,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                      if (isLead && controller.data['followUpDate'] != null)
                        _buildInfoRow(
                          label: 'Follow-up Date',
                          value: controller.formatDate(
                            controller.data['followUpDate'],
                          ),
                          icon: Icons.schedule,
                          fontSize: baseFontSize,
                          iconSize: iconSize,
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: cardPadding),

              // Common button style for reuse

              // Action Buttons
              Wrap(
                spacing: cardPadding * 0.5,
                runSpacing: cardPadding * 0.5,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  // Edit Follow-up
                  SizedBox(
                    width: screenWidth * 0.4,
                    child: ElevatedButton.icon(
                      onPressed: () => controller.updateFollowUpDate(context),
                      icon: Icon(Icons.edit_calendar, size: iconSize),
                      label: Text('Edit Follow-up'),
                      style: elevatedButtonStyle(
                        Colors.blue,
                        cardPadding,
                        baseFontSize,
                      ),
                    ),
                  ),

                  // Convert to Order (only for Leads)
                  if (isLead)
                    SizedBox(
                      width: screenWidth * 0.4,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.swap_horiz, size: iconSize),
                        label: const Text('Convert to Order'),
                        style: elevatedButtonStyle(
                          Colors.purple,
                          cardPadding,
                          baseFontSize,
                        ),
                        onPressed: () async {
                          final controller =
                              Get.find<IndividualFollowUpController>();

                          final confirmed = await showConvertDialog(
                            context,
                            controller,
                          );

                          if (confirmed) {
                            final makerMap = controller.makerList.firstWhere(
                              (m) =>
                                  m['id'] == controller.selectedMakerId.value,
                            );

                            await controller.convertLeadToOrder(
                              context,
                              makerId: makerMap['id']!,
                              makerName: makerMap['name']!,
                              nos: makerMap['nos']!,
                            );
                            // After success we already show a snackbar in the controller,
                            // but you can still close your details screen if needed:
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),

                  // Archive Button
                  SizedBox(
                    width: screenWidth * 0.4,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        bool confirmed = await showConfirmationDialog(
                          context,
                          'Archive Lead',
                          'Do you want to archive this lead?',
                        );
                        if (confirmed) {
                          controller.archiveDocument(context);
                          Navigator.of(context).pop();
                        }
                      },
                      icon: Icon(Icons.archive, size: iconSize),
                      label: Text('Archive'),
                      style: elevatedButtonStyle(
                        Colors.grey[700]!,
                        cardPadding,
                        baseFontSize,
                      ),
                    ),
                  ),

                  // Call Now
                  SizedBox(
                    width: screenWidth * 0.4,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final String? phoneNumber = controller.data['phone1'];
                        if (phoneNumber != null &&
                            phoneNumber.trim().isNotEmpty &&
                            phoneNumber != 'N/A') {
                          final cleanedNumber = phoneNumber.replaceAll(
                            RegExp(r'[^0-9+]'),
                            '',
                          );
                          final Uri phoneUri = Uri.parse('tel:$cleanedNumber');

                          log('Phone URI: $phoneUri');
                          final canLaunchDialer = await canLaunchUrl(phoneUri);
                          log('Can launch: $canLaunchDialer');

                          if (canLaunchDialer) {
                            final success = await launchUrl(
                              phoneUri,
                              mode: LaunchMode.externalApplication,
                            );
                            log('Launch success: $success');
                          } else {
                            Get.snackbar('Error', 'Could not open dialer app');
                          }
                        } else {
                          Get.snackbar(
                            'Invalid Number',
                            'Phone number is missing or invalid',
                          );
                        }
                      },
                      icon: Icon(Icons.call, size: iconSize),
                      label: Text('Call Now'),
                      style: elevatedButtonStyle(
                        Colors.green,
                        cardPadding,
                        baseFontSize,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: cardPadding),
            ],
          ),
        ),
      );
    });
  }

  Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton(
                child: Text("Yes"),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog dismissed
  }

  Future<bool> showConvertDialog(
    BuildContext context,
    IndividualFollowUpController c,
  ) async {
    // Ensure makers are loaded first
    await c.fetchMakers();
    if (c.makerList.isEmpty) return false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Convert Lead'),
        content: Obx(
          () => DropdownButtonFormField<String>(
            isExpanded: true,
            value: c.selectedMakerId.value.isEmpty
                ? null
                : c.selectedMakerId.value,
            decoration: const InputDecoration(
              labelText: 'Select Maker',
              border: OutlineInputBorder(),
            ),
            items: c.makerList
                .map(
                  (m) => DropdownMenuItem<String>(
                    value: m['id'],
                    child: Text(m['name']!),
                  ),
                )
                .toList(),
            onChanged: (val) => c.selectedMakerId.value = val ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: c.selectedMakerId.value.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Convert'),
            ),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }
}
