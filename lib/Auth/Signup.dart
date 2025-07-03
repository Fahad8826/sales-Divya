// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sales/Auth/Signin.dart';
// import 'package:sales/Controller/sign_up_controller.dart';

// class Signup extends StatelessWidget {
//   const Signup({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(SignupController());
//     final screenHeight = MediaQuery.of(context).size.height;

//     return WillPopScope(
//       onWillPop: () async {
//         Get.off(() => Signin());
//         return false;
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         body: SingleChildScrollView(
//           child: SizedBox(
//             height: screenHeight,
//             child: Stack(
//               children: [
//                 // Top circles
//                 Positioned(
//                   top: MediaQuery.of(context).size.height * -0.15,
//                   left: 0,
//                   right: 0,
//                   child: SizedBox(
//                     height:
//                         MediaQuery.of(context).size.height *
//                         0.52, // Adjust as needed
//                     width: MediaQuery.of(context).size.width,
//                     child: Image.asset(
//                       'assets/images/top_up.png',
//                       fit: BoxFit.cover, // Makes image fill box completely
//                     ),
//                   ),
//                 ),
//                 // Logo
//                 Positioned(
//                   top: screenHeight * 0.04,
//                   left: 0,
//                   right: 0,
//                   child: SizedBox(
//                     height: screenHeight * 0.45,
//                     width: MediaQuery.of(context).size.width,
//                     child: Image.asset(
//                       'assets/images/logo.png',
//                       fit: BoxFit.fill,
//                     ),
//                   ),
//                 ),
//                 // Welcome text
//                 Positioned(
//                   top: screenHeight * .35,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Text(
//                     "LET'S GET STARTED",
//                     style: TextStyle(
//                       fontSize: screenHeight * .03,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF030047),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 // Sign up text
//                 Positioned(
//                   top: screenHeight * .38,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Text(
//                     'SIGN UP',
//                     style: TextStyle(
//                       fontSize: 25,
//                       color: Color.fromARGB(255, 63, 97, 209),
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 // Email text field
//                 Positioned(
//                   top: screenHeight * .45,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: TextField(
//                     controller: controller.emailController,
//                     decoration: InputDecoration(
//                       suffixIcon: Icon(
//                         Icons.email_outlined,
//                         color: Color(0xFF030047),
//                       ),
//                       labelText: 'Email',
//                       labelStyle: TextStyle(
//                         color: Color.fromARGB(255, 193, 204, 240),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Colors.transparent,
//                           width: 2,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Color(0xFF030047),
//                           width: 2,
//                         ),
//                       ),
//                       filled: true,
//                       fillColor: Color(0xFFE1E5F2),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 15,
//                       ),
//                     ),
//                     style: TextStyle(fontSize: 18),
//                     keyboardType: TextInputType.emailAddress,
//                   ),
//                 ),
//                 // Phone text field
//                 Positioned(
//                   top: screenHeight * .53,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: TextField(
//                     controller: controller.phoneController,
//                     decoration: InputDecoration(
//                       suffixIcon: Icon(Icons.phone, color: Color(0xFF030047)),
//                       labelText: 'Phone Number',
//                       labelStyle: TextStyle(
//                         color: Color.fromARGB(255, 193, 204, 240),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Colors.transparent,
//                           width: 2,
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide(
//                           color: Color(0xFF030047),
//                           width: 2,
//                         ),
//                       ),
//                       filled: true,
//                       fillColor: Color(0xFFE1E5F2),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 15,
//                       ),
//                     ),
//                     style: TextStyle(fontSize: 18),
//                     keyboardType: TextInputType.phone,
//                   ),
//                 ),
//                 // Password text field
//                 Positioned(
//                   top: screenHeight * .61,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Obx(
//                     () => TextField(
//                       controller: controller.passwordController,
//                       obscureText: !controller.isPasswordVisible.value,
//                       decoration: InputDecoration(
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             controller.isPasswordVisible.value
//                                 ? Icons.visibility_outlined
//                                 : Icons.visibility_off_outlined,
//                             color: Color(0xFF030047),
//                           ),
//                           onPressed: controller.togglePasswordVisibility,
//                         ),
//                         labelText: 'Password',
//                         labelStyle: TextStyle(
//                           color: Color.fromARGB(255, 193, 204, 240),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Colors.transparent,
//                             width: 2,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Color(0xFF030047),
//                             width: 2,
//                           ),
//                         ),
//                         filled: true,
//                         fillColor: Color(0xFFE1E5F2),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 15,
//                         ),
//                       ),
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ),
//                 ),
//                 // Confirm Password text field
//                 Positioned(
//                   top: screenHeight * .69,
//                   left: screenHeight * .04,
//                   right: screenHeight * .04,
//                   child: Obx(
//                     () => TextField(
//                       controller: controller.confirmPasswordController,
//                       obscureText: !controller.isConfirmPasswordVisible.value,
//                       decoration: InputDecoration(
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             controller.isConfirmPasswordVisible.value
//                                 ? Icons.visibility_outlined
//                                 : Icons.visibility_off_outlined,
//                             color: Color(0xFF030047),
//                           ),
//                           onPressed: controller.toggleConfirmPasswordVisibility,
//                         ),
//                         labelText: 'Confirm Password',
//                         labelStyle: TextStyle(
//                           color: Color.fromARGB(255, 193, 204, 240),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Colors.transparent,
//                             width: 2,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(30),
//                           borderSide: BorderSide(
//                             color: Color(0xFF030047),
//                             width: 2,
//                           ),
//                         ),
//                         filled: true,
//                         fillColor: Color(0xFFE1E5F2),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 15,
//                         ),
//                       ),
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ),
//                 ),
//                 // Signup Button
//                 Positioned(
//                   bottom: screenHeight * .15,
//                   left: 0,
//                   right: 0,
//                   child: Center(
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.8,
//                       height: 60,
//                       child: ElevatedButton(
//                         onPressed: controller.signUp,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xFFFFCC3E),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         child: Text(
//                           "SIGN UP",
//                           style: TextStyle(
//                             color: Color(0xFF030047),
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Login link
//                 Positioned(
//                   bottom: screenHeight * .06,
//                   left: 0,
//                   right: 0,
//                   child: Center(
//                     child: SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.9,
//                       height: 60,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Already have an account? ",
//                             style: TextStyle(
//                               color: Color(0xFF030047),
//                               fontSize: 20,
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: () => Get.offAll(() => Signin()),
//                             child: Text(
//                               "Login",
//                               style: TextStyle(
//                                 color: Color(0xFFFFCC3E),
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
