import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);
  static String routeName = '/login';
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(),
      _passwordController = TextEditingController();
  static Future<bool> _validateEmail(String email) async {
    final emailRef = FirebaseFirestore.instance.collection('accounts_student');
    final emailDoc = await emailRef.doc(email).get();
    return emailDoc.exists;
  }

  static Future<bool> _validatePassword(String email, String password) async {
    final emailRef = FirebaseFirestore.instance.collection('accounts_student');
    final emailDoc = await emailRef.doc(email).get();
    return emailDoc.data()?['password'] == password;
  }

  static Future<bool> _validateLogin(String email, String password) async {
    return await _validateEmail(email) &&
        await _validatePassword(email, password);
  }

  static void _cacheEmail(String email) async{
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userEmail', email);
  }

  Widget _loginForm() {
    return Form(
      key: _loginFormKey,
      onWillPop: () async {
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Student Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required.';
              }

              if (!GetUtils.isEmail(value)) {
                return 'Invalid Email Format';
              }

              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required.';
              }

              return null;
            },
          ),
          SizedBox(
            height: 20.0,
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate returns true if the form is valid, or false otherwise.
              if (_loginFormKey.currentState!.validate() &&
                  await _validateLogin(
                      _emailController.text, _passwordController.text)) {
                // If the form is valid, display a snackbar. In the real world,
                // you'd often call a server or save the information in a database.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Processing Sign In')),
                );
                _cacheEmail(_emailController.text);
                Get.toNamed('/dashboard');
              }
              else{
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account does not exist in our records.')),
                );
              }
            },
            child: const Text(
              'SIGN IN',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'SIGN IN\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.height * 0.05,
              color: Colors.black,
            ),
          ),
          TextSpan(
            text: 'Fill out the form to continue.',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.02,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentSupport() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        children: [
          TextSpan(
            text: '\n\nHaving trouble signing in? \n\n',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          TextSpan(
            text: 'Student Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(
                  height: 30.0,
                ),
                _loginForm(),
                _studentSupport(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
