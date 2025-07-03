import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SigninController extends GetxController {
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isInputEmpty = true.obs;
  var isInputValid = false.obs;

  @override
  void onInit() {
    super.onInit();

    emailOrPhoneController.addListener(() {
      final input = emailOrPhoneController.text.trim();
      isInputEmpty.value = input.isEmpty;
      isInputValid.value = _isValidEmail(input) || _isValidPhone(input);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<String?> getEmailFromPhone(String phone) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.get('email');
      }
    } catch (_) {}
    return null;
  }

  Future<String?> signIn(String input, String password) async {
    try {
      print("Attempting to sign in with input: $input"); // Debug log

      String? email;
      String? uid;

      // Check if input is an email or phone number
      if (_isValidEmail(input)) {
        // Input is an email
        email = input;
      } else if (_isValidPhone(input)) {
        // Input is a phone number, query Firestore to find matching email
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          email = query.docs.first.get('email') as String;
          uid = query.docs.first.get('uid') as String;
          print("Found email for phone: $email"); // Debug log
        } else {
          return 'No account found for this phone number.';
        }
      } else {
        return 'Invalid email or phone number format.';
      }

      // Sign in with Firebase Auth using the email
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      uid ??= userCredential.user!.uid;
      print("Sign in successful, UID: $uid"); // Debug log

      // Verify Sales role in Firestore
      DocumentSnapshot salesDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (salesDoc.exists) {
        Map<String, dynamic> saleData = salesDoc.data() as Map<String, dynamic>;

        if (saleData['role'] == "salesmen") {
          if (saleData['isActive'] == true) {
            print("Salesperson login verified.");
            return null; // Allow login
          } else {
            await FirebaseAuth.instance.signOut();
            return 'Access denied. Your account is inactive.';
          }
        } else {
          await FirebaseAuth.instance.signOut();
          return 'Access denied. You are not a Sales.';
        }
      } else {
        await FirebaseAuth.instance.signOut();
        return 'No SalesPerson record found.';
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
