// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sales/Auth/Signin.dart';

// class SignupController extends GetxController {
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();

//   final isPasswordVisible = false.obs;
//   final isConfirmPasswordVisible = false.obs;

//   void togglePasswordVisibility() =>
//       isPasswordVisible.value = !isPasswordVisible.value;
//   void toggleConfirmPasswordVisibility() =>
//       isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

//   Future<void> signUp() async {
//     String email = emailController.text.trim();
//     String phone = phoneController.text.trim();
//     String password = passwordController.text;
//     String confirmPassword = confirmPasswordController.text;

//     if (email.isEmpty ||
//         password.isEmpty ||
//         confirmPassword.isEmpty ||
//         phone.isEmpty) {
//       Get.snackbar(
//         "Error",
//         "Please fill all fields",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     if (password != confirmPassword) {
//       Get.snackbar(
//         "Error",
//         "Passwords do not match",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     if (await isPhoneRegisteredAnywhere(phone)) {
//       Get.snackbar(
//         "Error",
//         "Phone number is already registered",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     if (await isEmailRegisteredAnywhere(email)) {
//       Get.snackbar(
//         "Error",
//         "Email is already registered",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);

//       User? user = userCredential.user;

//       await FirebaseFirestore.instance.collection('Sales').doc(user!.uid).set({
//         'email': email,
//         'phone': phone,
//         'uid': user.uid,
//         'role': 'Sales',
//         'createdAt': Timestamp.now(),
//       });

//       Get.snackbar(
//         "Success",
//         "Signup successful!",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       Get.offAll(() => Signin());
//     } on FirebaseAuthException catch (e) {
//       String message = 'Signup failed';
//       if (e.code == 'email-already-in-use') message = 'Email is already in use';
//       if (e.code == 'weak-password') message = 'Password is too weak';
//       if (e.code == 'invalid-email') message = 'Invalid email address';
//       Get.snackbar("Error", message, snackPosition: SnackPosition.BOTTOM);
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         "Unexpected error: $e",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }

//   Future<bool> isPhoneRegisteredAnywhere(String phone) async {
//     final firestore = FirebaseFirestore.instance;
//     final collections = ['admins', 'Sales', 'Makers'];
//     for (final collection in collections) {
//       final query = await firestore
//           .collection(collection)
//           .where('phone', isEqualTo: phone)
//           .limit(1)
//           .get();
//       if (query.docs.isNotEmpty) return true;
//     }
//     return false;
//   }

//   Future<bool> isEmailRegisteredAnywhere(String email) async {
//     final firestore = FirebaseFirestore.instance;
//     final collections = ['admins', 'Sales', 'Makers'];
//     for (final collection in collections) {
//       final query = await firestore
//           .collection(collection)
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();
//       if (query.docs.isNotEmpty) return true;
//     }
//     return false;
//   }

//   @override
//   void onClose() {
//     emailController.dispose();
//     phoneController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     super.onClose();
//   }
// }
