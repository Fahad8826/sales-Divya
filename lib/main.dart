import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales/Auth/Signin.dart';
import 'package:sales/Screens/complaint.dart';
import 'package:sales/Screens/followup.dart';
import 'package:sales/Screens/lead_list.dart';
import 'package:sales/Screens/leadmanagement.dart';
import 'package:sales/Screens/order_managmenet.dart';
import 'package:sales/Screens/profile.dart';
import 'package:sales/Screens/review.dart';
import 'package:sales/firebase_options.dart';

import 'package:sales/Screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Divya Crafts',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AuthWrapper()),
        GetPage(name: "/leadmanagment", page: () => LeadManagement()),
        GetPage(name: "/followup", page: () => const FollowupPage()),
        GetPage(name: "/ordermanagement", page: () => OrderManagement()),
        GetPage(name: "/review", page: () => Review()),
        GetPage(name: "/complaint", page: () => Complaint()),
        GetPage(name: "/profile", page: () => Profile()),
        GetPage(name: "/login", page: () => Signin()),
        GetPage(name: '/leadlist', page: () => LeadList()),
      ],
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return Home(); // user is logged in
    } else {
      return Signin(); // user is not logged in
    }
  }
}
