import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeController extends GetxController {
  var selectedIndex = (-1).obs; // -1 means no selection
  var isMenuOpen = false.obs;
  var isLoading = false.obs;
  var monthlyLeads = <double>[].obs; // Leads per month
  var monthLabels = <String>[].obs;

  var count = "0".obs; // Consider removing if unused
  var totalLeads = 0.obs;
  var totalOrders = 0.obs;
  var totalPostSaleFollowUp = 0.obs;
  var targetTotal = 1000.obs; // Set your own target

  // Location variables
  var currentLocation = ''.obs;
  var currentLatitude = 0.0.obs;
  var currentLongitude = 0.0.obs;
  var isLocationLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    // Ensure user is authenticated before fetching data
    if (_auth.currentUser != null) {
      fetchCounts();
      getCurrentLocation();
    } else {
      debugPrint("No user logged in during onInit");
      Get.snackbar(
        'Authentication Error',
        'Please log in to view data',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Location permission and fetching
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Service Disabled',
        'Please enable location services.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Location Permission Denied',
          'Location permissions are denied',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Location Permission Denied Forever',
        'Location permissions are permanently denied, we cannot request permissions.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    isLocationLoading.value = true;

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        isLocationLoading.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;

      // Get address from coordinates
      await _getAddressFromLatLng(position.latitude, position.longitude);

      // Save location to Firestore
      await _saveLocationToFirestore(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
      Get.snackbar(
        'Location Error',
        'Failed to get current location: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLocationLoading.value = false;
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentLocation.value =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      currentLocation.value =
          "Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}";
    }
  }

  Future<void> _saveLocationToFirestore(
    double latitude,
    double longitude,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint("Location saved to Firestore");
    } catch (e) {
      debugPrint("Error saving location: $e");
    }
  }

  void selectMenuItem(int index) {
    selectedIndex.value = index;
    // Reset selection after navigation simulation
    Future.delayed(const Duration(milliseconds: 100), () {
      selectedIndex.value = -1;
    });
  }

  void toggleMenu() {
    isMenuOpen.value = !isMenuOpen.value;
  }

  int get totalActivity => totalLeads.value + totalOrders.value;

  double get progressValue =>
      (totalActivity / targetTotal.value).clamp(0.0, 1.0);

  Future<void> fetchCounts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint("User not logged in");
      Get.snackbar(
        'Authentication Error',
        'Please log in to view data',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true; // Indicate loading state
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

      // Fetch Leads created this month
      final leadsSnapshot = await _firestore
          .collection('Leads')
          .where('salesmanID', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .where(
            'createdAt',
            isLessThan: Timestamp.fromDate(firstDayOfNextMonth),
          )
          .get();
      totalLeads.value = leadsSnapshot.size;
      debugPrint("Fetched Leads: ${leadsSnapshot.size}");

      // Fetch Orders created this month
      final ordersSnapshot = await _firestore
          .collection('Orders')
          .where('salesmanID', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .where(
            'createdAt',
            isLessThan: Timestamp.fromDate(firstDayOfNextMonth),
          )
          .get();
      totalOrders.value = ordersSnapshot.size;
      debugPrint("Fetched Orders: ${ordersSnapshot.size}");

      // Fetch Post Sale Follow-Up (delivered orders)
      final postSaleFollowUpSnapshot = await _firestore
          .collection('Orders')
          .where('salesmanID', isEqualTo: userId) // Added salesmanID filter
          .where('order_status', isEqualTo: 'delivered')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .where(
            'createdAt',
            isLessThan: Timestamp.fromDate(firstDayOfNextMonth),
          )
          .get();
      totalPostSaleFollowUp.value = postSaleFollowUpSnapshot.size;
      debugPrint(
        "Fetched Post Sale Follow-Up: ${postSaleFollowUpSnapshot.size}",
      );

      debugPrint(
        "Fetched Counts - Leads: ${totalLeads.value}, Orders: ${totalOrders.value}, PostSaleFollowUp: ${totalPostSaleFollowUp.value}",
      );
    } catch (e, stackTrace) {
      debugPrint("Error fetching counts: $e\n$stackTrace");
      Get.snackbar(
        'Error',
        'Failed to fetch data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Guest';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? 'User';
      } else {
        return 'User';
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
      return 'User';
    }
  }

  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }
}
