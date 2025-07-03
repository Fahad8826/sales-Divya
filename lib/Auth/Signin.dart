import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales/Controller/sign_in_controller.dart';
import 'package:sales/Screens/home.dart';

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
              Positioned(
                top: MediaQuery.of(context).size.height * .08,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height * 0.45,
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.38,
                left: 30,
                right: 30,
                child: Column(
                  children: [
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF030047),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "SALES",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.025,
                        color: Color.fromARGB(255, 63, 97, 209),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5,
                left: 30,
                right: 30,
                child: TextField(
                  controller: controller.emailOrPhoneController,
                  decoration: InputDecoration(
                    suffixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFF030047),
                    ),
                    labelText: "Email or Phone Number",
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 193, 204, 240),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Color(0xFF030047),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Color(0xFFE1E5F2),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.6,
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
                          color: Color(0xFF030047),
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      labelText: "Password",
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 193, 204, 240),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Color(0xFF030047),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFFE1E5F2),
                    ),
                  ),
                ),
              ),
              // Positioned(
              //   bottom: MediaQuery.of(context).size.height * 0.3,
              //   right: 30,
              //   child: Obx(
              //     () => TextButton(
              //       onPressed:
              //           (controller.isInputValid.value &&
              //               !controller.isInputEmpty.value)
              //           ? () async {
              //               final input =
              //                   controller.emailOrPhoneController.text;
              //               String? email;
              //               if (input.isEmail) {
              //                 email = input;
              //               } else if (input.isPhoneNumber) {
              //                 email = await controller.getEmailFromPhone(input);
              //                 if (email == null) {
              //                   Get.snackbar(
              //                     "Error",
              //                     "No account found for this phone number",
              //                   );
              //                   return;
              //                 }
              //               } else {
              //                 Get.snackbar(
              //                   "Error",
              //                   "Invalid email or phone number",
              //                 );
              //                 return;
              //               }

              //               Get.to() => ForgotPasswordPage();
              //             }
              //           : null,
              //       child: Text(
              //         "Forgot Password?",
              //         style: TextStyle(
              //           fontSize: MediaQuery.of(context).size.width * .036,
              //           color: Colors.blue,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.22,
                left: 30,
                right: 30,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * .07,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFCC3E),
                    ),
                    onPressed: () async {
                      final input = controller.emailOrPhoneController.text
                          .trim();
                      final password = controller.passwordController.text
                          .trim();

                      if (input.isEmpty || password.isEmpty) {
                        Get.snackbar("Error", "Please fill in both fields");
                        return;
                      }

                      Get.dialog(
                        Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );

                      final result = await controller.signIn(input, password);
                      Get.back();

                      if (result == null) {
                        // ✅ Clear fields after successful login
                        controller.emailOrPhoneController.clear();
                        controller.passwordController.clear();

                        Get.offAll(() => Home());
                        Get.snackbar(
                          "Success",
                          "Signed in successfully",
                          backgroundColor: Colors.yellow,
                        );
                      } else {
                        Get.snackbar(
                          "Login Failed",
                          "Please Enter valid email, phone number, or password",
                        );
                      }
                    },
                    child: Text(
                      "SIGN IN",
                      style: TextStyle(fontSize: 18, color: Color(0xFF030047)),
                    ),
                  ),
                ),
              ),
              // Positioned(
              //   bottom: MediaQuery.of(context).size.height * 0.15,
              //   left: 0,
              //   right: 0,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Text(
              //         "Don't have an account?",
              //         style: TextStyle(
              //           color: Color(0xFF030047),
              //           fontSize: MediaQuery.of(context).size.width * .04,
              //         ),
              //       ),
              //       TextButton(
              //         onPressed: () => Get.offAll(() => Signup()),
              //         child: Text(
              //           "Create one now",
              //           style: TextStyle(
              //             color: Color(0xFFFFCC3E),
              //             fontWeight: FontWeight.bold,
              //             fontSize: MediaQuery.of(context).size.width * .04,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
