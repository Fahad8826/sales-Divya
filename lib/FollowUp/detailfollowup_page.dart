import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sales/FollowUp/detailsfollowup_controller.dart';
import 'package:url_launcher/url_launcher.dart';
// Changed controller import

class LeadDetailsPage extends StatelessWidget {
  final String? leadId; // Make leadId nullable for new leads

  const LeadDetailsPage({super.key, this.leadId});

  @override
  Widget build(BuildContext context) {
    // Initialize controller with leadId if provided
    final controller = Get.put(LeadDetailsController(leadId: leadId));
    final screenHeight = MediaQuery.of(context).size.height;

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        title: Obx(
          () => Text(
            controller.isUpdateMode.value ? "Edit Lead" : "Add New Lead",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        actions: [
          RawMaterialButton(
            onPressed: () async {
              final String? phoneNumber = controller.phoneController.text;
              if (phoneNumber != null &&
                  phoneNumber.trim().isNotEmpty &&
                  phoneNumber != 'N/A') {
                final cleanedNumber = phoneNumber.replaceAll(
                  RegExp(r'[^0-9+]'),
                  '',
                );
                final Uri phoneUri = Uri.parse('tel:$cleanedNumber');

                final canLaunchDialer = await canLaunchUrl(phoneUri);

                if (canLaunchDialer) {
                  await launchUrl(
                    phoneUri,
                    mode: LaunchMode.externalApplication,
                  );
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
            elevation: 2.0,
            fillColor: const Color(0xFF10B981), // green color
            shape: const CircleBorder(),
            constraints: const BoxConstraints.tightFor(
              width: 30.0,
              height: 30.0,
            ),
            child: const Icon(Icons.call, size: 20.0, color: Colors.white),
          ),

          RawMaterialButton(
            elevation: 2.0,
            fillColor: Colors.yellow, // green color
            shape: const CircleBorder(),
            constraints: const BoxConstraints.tightFor(
              width: 30.0,
              height: 30.0,
            ),
            child: const Icon(Icons.archive, size: 20.0, color: Colors.black),
            onPressed: () {
              final controller = Get.find<LeadDetailsController>();

              if (controller.leadId != null) {
                Get.defaultDialog(
                  title: 'Confirm Archive',
                  middleText: 'Are you sure you want to archive this lead?',
                  textConfirm: 'Yes',
                  textCancel: 'No',
                  onConfirm: () {
                    controller.archiveDocument(controller.leadId!);
                    Get.back(); // Close the dialog
                  },
                  onCancel: () {},
                  confirmTextColor: Colors.white,
                );
              } else {
                Get.snackbar('Error', 'No Lead ID found to archive');
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF3B82F6),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(), // Ensures ordered focus traversal
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  buildSectionTitle("Personal Information"),
                  const SizedBox(height: 12),

                  Obx(
                    () => FocusTraversalOrder(
                      order: const NumericFocusOrder(0),
                      child: buildTextField(
                        "Full Name",
                        controller: controller.nameController,
                        validator: controller.validateName,
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        isEnabled: controller.isEditing.value,
                      ),
                    ),
                  ),

                  Obx(
                    () => FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
                      child: buildTextField(
                        "Place",
                        controller: controller.placeController,
                        validator: controller.validatePlace,
                        icon: Icons.location_on_outlined,
                        textInputAction: TextInputAction.next,
                        isEnabled: controller.isEditing.value,
                      ),
                    ),
                  ),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: buildTextField(
                      "Address",
                      controller: controller.addressController,
                      validator: controller.validateAddress,
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      textInputAction: TextInputAction.next,
                      isEnabled: controller.isEditing.value,
                    ),
                  ),

                  // Contact Information Section
                  const SizedBox(height: 16),
                  buildSectionTitle("Contact Information"),
                  const SizedBox(height: 12),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: buildTextField(
                      "Primary Phone",
                      controller: controller.phoneController,
                      validator: controller.validatePhone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      isEnabled: controller.isEditing.value,
                    ),
                  ),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: buildTextField(
                      "Secondary Phone (Optional)",
                      controller: controller.phone2Controller,
                      validator: controller.validatePhone2,
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      isEnabled: controller.isEditing.value,
                    ),
                  ),

                  // Product Information Section
                  const SizedBox(height: 16),
                  buildSectionTitle("Product Information"),
                  const SizedBox(height: 12),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(5),
                    child: Obx(
                      () => buildDropdownField(
                        label: "Select Product",
                        value: controller.selectedProductId.value,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text("-- Select Product --"),
                          ),
                          ...controller.productIdList.map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          controller.selectedProductId.value = value;
                          if (value != null) {
                            controller.fetchProductImage(value);
                          } else {
                            controller.productImageUrl.value = null;
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Product is required' : null,
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: Obx(() {
                      final imageUrl = controller.productImageUrl.value;
                      if (imageUrl == null || imageUrl.isEmpty) {
                        return Container(
                          width: screenHeight * 0.25,
                          height: screenHeight * 0.25,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 32,
                                  color: Color(0xFF9CA3AF),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No Image Available',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: screenHeight * 0.25,
                          height: screenHeight * 0.25,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: screenHeight * 0.25,
                            height: screenHeight * 0.25,
                            color: const Color(0xFFF9FAFB),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: screenHeight * 0.25,
                            height: screenHeight * 0.25,
                            color: const Color(0xFFF9FAFB),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFF9CA3AF),
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  Obx(() {
                    final productId = controller.selectedProductId.value;
                    if (productId == null) return const SizedBox();
                    return buildStockStatus(
                      productId,
                      screenHeight,
                      controller,
                    );
                  }),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(6),
                    child: buildTextFieldForNumber(
                      "Quantity (NOS)",
                      controller: controller.nosController,
                      validator: controller.validateNos,
                      textInputAction: TextInputAction.next,
                      isEnabled: controller.isEditing.value,
                    ),
                  ),

                  // New Balance field
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(8),
                    child: buildTextField(
                      "Remarks (Optional)",
                      controller: controller.remarkController,
                      icon: Icons.note_outlined,
                      maxLines: 2,
                      textInputAction: TextInputAction.next,
                      isEnabled: controller.isEditing.value,
                    ),
                  ),

                  // Order Status Section
                  const SizedBox(height: 16),
                  buildSectionTitle("Order Status"),
                  const SizedBox(height: 12),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(9),
                    child: buildDropdownField(
                      label: "Status",
                      value: controller.selectedStatus.value,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("-- Select Status --"),
                        ),
                        ...controller.statusList.map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        ),
                      ],
                      onChanged:
                          controller.isEditing.value &&
                              controller.selectedProductId.value != null
                          ? (value) => controller.selectedStatus.value =
                                value as String?
                          : null,
                      validator: (value) =>
                          value == null ? 'Status is required' : null,
                      icon: Icons.flag_outlined,
                      isEnabled:
                          controller.isEditing.value &&
                          controller.selectedProductId.value != null,
                      disabledHint: "Select a product first",
                    ),
                  ),

                  Obx(() {
                    final isMakerEnabled =
                        controller.isEditing.value &&
                        controller.selectedProductId.value != null &&
                        controller.selectedStatus.value == 'HOT';
                    final isLoadingMakers =
                        controller.makerList.isEmpty &&
                        !controller.makerList.isNull &&
                        controller.selectedStatus.value == 'HOT';

                    if (isLoadingMakers) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      );
                    }

                    return FocusTraversalOrder(
                      order: const NumericFocusOrder(10),
                      child: buildDropdownField(
                        label: "Maker",
                        value: controller.selectedMakerId.value,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text("-- Select Maker --"),
                          ),
                          ...controller.makerList.map((maker) {
                            return DropdownMenuItem<String>(
                              value: maker['id'],
                              child: Text(maker['name']),
                            );
                          }).toList(),
                        ],
                        onChanged: isMakerEnabled
                            ? (value) => controller.selectedMakerId.value =
                                  value as String?
                            : null,
                        validator: (value) =>
                            value == null &&
                                controller.selectedStatus.value == 'HOT'
                            ? 'Please select a maker'
                            : null,
                        icon: Icons.engineering_outlined,
                        isEnabled: isMakerEnabled,
                        disabledHint: controller.selectedProductId.value == null
                            ? "Select a product first"
                            : "Maker is only needed for HOT status",
                      ),
                    );
                  }),

                  Obx(() {
                    final selectedStatus = controller.selectedStatus.value;
                    final isDisabled =
                        !controller.isEditing.value ||
                        selectedStatus == null ||
                        selectedStatus.isEmpty ||
                        selectedStatus == "HOT";

                    return FocusTraversalOrder(
                      order: const NumericFocusOrder(11),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          focusColor: Colors.transparent,
                          onTap: isDisabled
                              ? null
                              : () async {
                                  DateTime today = DateTime.now();
                                  DateTime onlyDate = DateTime(
                                    today.year,
                                    today.month,
                                    today.day,
                                  );

                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        controller.followUpDate.value ??
                                        onlyDate,
                                    firstDate: onlyDate,
                                    lastDate: DateTime(2030),
                                  );

                                  if (picked != null) {
                                    controller.followUpDate.value = picked;
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? const Color(0xFFF3F4F6)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDisabled
                                    ? const Color(0xFFE5E7EB)
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: isDisabled
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.followUpDate.value == null
                                        ? "Select Follow-up Date"
                                        : DateFormat('dd-MM-yyyy').format(
                                            controller.followUpDate.value!,
                                          ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          controller.followUpDate.value == null
                                          ? const Color(0xFF6B7280)
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                if (controller.followUpDate.value != null &&
                                    !isDisabled)
                                  GestureDetector(
                                    onTap: () =>
                                        controller.followUpDate.value = null,
                                    child: const Icon(
                                      Icons.clear,
                                      color: Color(0xFF9CA3AF),
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.toggleEditing, // Toggle editing
                          icon: Icon(
                            controller.isEditing.value
                                ? Icons.save_outlined
                                : Icons.edit_outlined,
                            size: 18,
                          ),
                          label: Text(
                            controller.isEditing.value
                                ? "Save Lead"
                                : "Edit Lead",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.isEditing.value
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => ElevatedButton.icon(
                            onPressed:
                                controller.isOrderButtonEnabled() &&
                                    leadId != null
                                ? () => controller
                                      .placeOrder(leadId!) // Use the passed ID
                                : null,
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                            ),
                            label: const Text("Order Now"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget buildStockStatus(
    String productId,
    double screenHeight,
    dynamic controller,
  ) {
    final stock = controller.productStockMap[productId] ?? 0;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (stock > 10) {
      statusText = '$stock in Stock';
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_outline;
    } else if (stock > 0) {
      statusText = 'Only $stock left!';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusText = 'Out of Stock';
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
    String label, {
    TextEditingController? controller,
    String? Function(String?)? validator,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextInputAction? textInputAction,
    bool isEnabled = true, // Added isEnabled parameter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction: textInputAction ?? TextInputAction.next,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        enabled: isEnabled, // Use isEnabled here
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: isEnabled
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF),
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: isEnabled
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isEnabled
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          filled: true,
          fillColor: isEnabled
              ? const Color(0xFFF9FAFB)
              : const Color(0xFFF3F4F6),
        ),
      ),
    );
  }

  Widget buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
    IconData? icon,
    bool isEnabled = true,
    String? disabledHint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: isEnabled ? onChanged : null,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          color: isEnabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: isEnabled
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF),
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: isEnabled
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isEnabled
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          filled: true,
          fillColor: isEnabled
              ? const Color(0xFFF9FAFB)
              : const Color(0xFFF3F4F6),
        ),
        disabledHint: disabledHint != null
            ? Text(
                disabledHint,
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              )
            : null,
        dropdownColor: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget buildTextFieldForNumber(
    String label, {
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    bool isEnabled = true, // Added isEnabled parameter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        keyboardType: TextInputType.number,
        controller: controller,
        validator: validator,
        textInputAction: textInputAction ?? TextInputAction.next,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        enabled: isEnabled, // Use isEnabled here
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: isEnabled
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF),
          ),
          prefixIcon: const Icon(
            Icons.numbers_outlined,
            size: 20,
            color: Color(0xFF6B7280),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isEnabled
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          filled: true,
          fillColor: isEnabled
              ? const Color(0xFFF9FAFB)
              : const Color(0xFFF3F4F6),
        ),
      ),
    );
  }
}
