import 'dart:developer';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_onboard/flutter_onboard.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tyto/dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  static String routeName = '/splash_screen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<OnBoardModel> onBoardData = [
    const OnBoardModel(
      title: "Welcome to TYTO",
      description: "Made for dynamic learners by dynamic developers",
      imgUrl: "assets/banners/welcome_tyto.png",
    ),
    const OnBoardModel(
      title: "Virtual classes made easier",
      description:
      "No more complex process to join your virtual class and take virtual exams.",
      imgUrl: 'assets/banners/virtual_class.png',
    ),
    const OnBoardModel(
      title: "Let's get started",
      description: "Tap the DONE Button below to get started.",
      imgUrl: 'assets/banners/lets_start.png',
    ),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkFirstTimeUseStatus();
  }

  final PageController _pageController = PageController();

  static void checkFirstTimeUseStatus () async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.getBool("isFirstTime") == false){
      prefs.getString('userEmail') == null || prefs.getString('userEmail').toString() == ''? redirectToLoginPage():Get.toNamed(Dashboard.routeName);
    }
    prefs.setBool("isFirstTime", true);
  }

  static void saveFirstTimeUseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("isFirstTime") == true) {
      prefs.setBool("isFirstTime", false);
    }
  }

  static void redirectToLoginPage() {
    saveFirstTimeUseStatus();
    Get.toNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1.0),
      body: OnBoard(
        onBoardData: onBoardData,
        pageController: _pageController,
        // Either Provide onSkip Callback or skipButton Widget to handle skip state
        onSkip: () {
          redirectToLoginPage();
        },
        // Either Provide onDone Callback or nextButton Widget to handle done state
        onDone: () {
          redirectToLoginPage();
        },
      ),
    );
  }
}

