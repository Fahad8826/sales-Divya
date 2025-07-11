import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales/Auth/sign_in_controller.dart';
import 'package:sales/Home/home.dart';

class Signin extends StatelessWidget {
  final controller = Get.put(SigninController());

  Signin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Top decorative image
              Positioned(
                top: MediaQuery.of(context).size.height * -0.2,
                right: 0,
                left: 0,
                child: Image.asset(
                  'assets/images/top_up.png',
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height * 0.52,
                ),
              ),
              // Logo image - Adjusted size
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    .10, // Adjusted position slightly
                left:
                    MediaQuery.of(context).size.width *
                    0.25, // Center the logo horizontally
                right:
                    MediaQuery.of(context).size.width *
                    0.25, // Center the logo horizontally
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit
                      .contain, // Use contain to ensure the whole logo is visible
                  height:
                      MediaQuery.of(context).size.height * 0.4, // Made smaller
                  width:
                      MediaQuery.of(context).size.width *
                      0.5, // Added width constraint
                ),
              ),
              // Welcome text
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    0.35, // Adjusted position
                left: 30,
                right: 30,
                child: Column(
                  children: [
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.035,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF030047), // Dark blue
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "SALES",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.025,
                        color: const Color.fromARGB(
                          255,
                          63,
                          97,
                          209,
                        ), // A shade of blue
                      ),
                    ),
                  ],
                ),
              ),
              // Email or Phone Number TextField
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    0.48, // Adjusted position
                left: 30,
                right: 30,
                child: TextField(
                  controller: controller.emailOrPhoneController,
                  decoration: InputDecoration(
                    suffixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF030047), // Icon color
                    ),
                    labelText: "Email or Phone Number",
                    labelStyle: TextStyle(
                      color: const Color(0xFF030047).withOpacity(
                        0.6,
                      ), // Slightly lighter dark blue for label
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide
                          .none, // No border by default for filled field
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none, // No border when enabled
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(
                          0xFF030047,
                        ), // Dark blue for focused border
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(
                      0xFFC0D2EB,
                    ), // Lighter, desaturated blue for fill
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ), // Add padding
                  ),
                  style: const TextStyle(
                    color: Color(0xFF030047),
                  ), // Text input color
                ),
              ),
              // Password TextField
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    0.58, // Adjusted position
                left: 30,
                right: 30,
                child: Obx(
                  () => TextField(
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF030047), 
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      labelText: "Password",
                      labelStyle: TextStyle(
                        color: const Color(0xFF030047).withOpacity(
                          0.6,
                        ), // Slightly lighter dark blue for label
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide
                            .none, // No border by default for filled field
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none, // No border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(
                            0xFF030047,
                          ), // Dark blue for focused border
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(
                        0xFFC0D2EB,
                      ), // Lighter, desaturated blue for fill
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ), // Add padding
                    ),
                    style: const TextStyle(
                      color: Color(0xFF030047),
                    ), // Text input color
                  ),
                ),
              ),
              // Sign In Button
              Positioned(
                bottom:
                    MediaQuery.of(context).size.height *
                    0.2, // Adjusted position
                left: 30,
                right: 30,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * .07,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC3E), // Yellow button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // Match text field border radius
                      ),
                      elevation: 5, // Add a slight elevation for depth
                    ),

                    onPressed: () async {
                      final input = controller.emailOrPhoneController.text
                          .trim();
                      final password = controller.passwordController.text
                          .trim();

                      // 🔍 Empty field check
                      if (input.isEmpty || password.isEmpty) {
                        Get.snackbar(
                          "Missing Information",
                          "Please enter both email/phone and password.",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      // ✉️ Email or phone format check
                      if (!controller.isInputValid.value) {
                        Get.snackbar(
                          "Invalid Format",
                          "Please enter a valid email or phone number.",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      Get.dialog(
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF030047),
                          ),
                        ),
                        barrierDismissible: false,
                      );

                      final result = await controller.signIn(input, password);
                      Get.back(); // Dismiss loader

                      if (result == null) {
                        controller.emailOrPhoneController.clear();
                        controller.passwordController.clear();

                        Get.offAll(() => Home());
                        Get.snackbar(
                          "Welcome!",
                          "Signed in successfully.",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          "Login Failed",
                          result, // Use the specific message returned from controller
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      }
                    },

                    child: const Text(
                      "SIGN IN",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF030047), // Dark blue text
                        fontWeight: FontWeight.bold, // Make button text bold
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
