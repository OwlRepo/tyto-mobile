import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tyto/classroom.dart';
import 'package:tyto/login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);
  static String routeName = '/dashboard';
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var _scheduleList = [];

  var _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Widget _newMeeting() {
    return GestureDetector(
      onTap: () {
        String room_id = getRandomString(100);
        final _newMeetingFormKey = GlobalKey<FormState>();
        final _roomNameController = TextEditingController();
        showMaterialModalBottomSheet(
            context: context,
            expand: true,
            builder: (context) {
              return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 50.0,),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Room Setup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Form(
                        key: _newMeetingFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              decoration: InputDecoration(labelText: 'Room ID'),
                              initialValue: room_id,
                              readOnly: true,
                            ),
                            TextFormField(
                              controller: _roomNameController,
                              autofocus: true,
                              decoration: InputDecoration(labelText: 'Room Name'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required.';
                                }
                                return null;
                              },
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue
                              ),
                              onPressed: () async {
                                // Validate returns true if the form is valid, or false otherwise.
                                if (_newMeetingFormKey.currentState!.validate()) {
                                  // If the form is valid, display a snackbar. In the real world,
                                  // you'd often call a server or save the information in a database
                                Clipboard.setData(ClipboardData(text: room_id));

                                }
                              },
                              child: const Text(
                                'Copy room ID',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                // Validate returns true if the form is valid, or false otherwise.
                                final _prefs = await SharedPreferences.getInstance();
                                _prefs.setString('room_id', room_id);
                                _prefs.setString('subject_name', _roomNameController.text);
                                if (_newMeetingFormKey.currentState!.validate()) {
                                  // If the form is valid, display a snackbar. In the real world,
                                  // you'd often call a server or save the information in a database.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Creating Room')),
                                  );

                                  Get.toNamed(Classroom.routeName);
                                }
                                else{
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account does not exist in our records.')),
                                  );
                                }
                              },
                              child: const Text(
                                'Start new meeting',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
      },
      child: Column(
        children: [
          Container(
            child: const Icon(
              Icons.video_call_rounded,
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(
              15.0,
              10.0,
              15.0,
              10.0,
            ),
            decoration: const BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          Text(
            'New Meeting',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.015,
            ),
          ),
        ],
      ),
    );
  }

  Widget _joinMeeting() {
    return GestureDetector(
      onTap: (){
        final _newMeetingFormKey = GlobalKey<FormState>();
        final _roomIDController = TextEditingController();
        showMaterialModalBottomSheet(
            context: context,
            expand: true,
            builder: (context) {
              return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 50.0,),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Room Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Form(
                        key: _newMeetingFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller:_roomIDController,
                              autofocus: true,
                              decoration: InputDecoration(labelText: 'Room ID'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field is required.';
                                }
                                return null;
                              },
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                // Validate returns true if the form is valid, or false otherwise.
                                final _prefs = await SharedPreferences.getInstance();
                                _prefs.setString('room_id', _roomIDController.text);
                                if (_newMeetingFormKey.currentState!.validate()) {
                                  // If the form is valid, display a snackbar. In the real world,
                                  // you'd often call a server or save the information in a database.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Joining Room')),
                                  );

                                  Get.toNamed(Classroom.routeName);
                                }
                                else{
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account does not exist in our records.')),
                                  );
                                }
                              },
                              child: const Text(
                                'Join Meeting',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
      },
      child: Column(
        children: [
          Container(
            child: const Icon(
              Icons.join_full_rounded,
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(
              15.0,
              10.0,
              15.0,
              10.0,
            ),
            decoration: const BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          Text(
            'Join Meeting',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.015,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appSettings() {
    return GestureDetector(
      onTap: ()async{
        final _pref = await SharedPreferences.getInstance();
        _pref.setString('userEmail', '');
        _pref.setString('userName', '');
        _pref.setBool('isFirstTime', false);
        Get.toNamed(Login.routeName);
      },
      child: Column(
        children: [
          Container(
            child: const Icon(
              Icons.exit_to_app_rounded,
              color: Colors.white,
            ),
            padding: const EdgeInsets.fromLTRB(
              15.0,
              10.0,
              15.0,
              10.0,
            ),
            decoration: const BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          Text(
            'Sign Out',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.015,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20.0,
        bottom: 20.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _newMeeting(),
          _joinMeeting(),
          _appSettings(),
        ],
      ),
    );
  }

  void _fetchSchedule() async {
    _scheduleList.clear();
    final _prefs = await SharedPreferences.getInstance();
    final _accountRef =
        FirebaseFirestore.instance.collection('accounts_student');
    final _accountDoc =
        await _accountRef.doc(_prefs.getString('userEmail')).get();
    final _accountData = _accountDoc.data();

    _prefs.setString('userName', _accountData?['fullname']);

    final _scheduleRef = FirebaseFirestore.instance.collection('schedules');
    final _scheduleDoc =
        await _scheduleRef.doc(_accountData?['schedule_id']).get();
    final _scheduleData = _scheduleDoc.data()?['subjects'];

    setState(() {
      _scheduleList = _scheduleData;
    });
  }

  void _enterRoom(var scheduleData) async {
    final _prefs = await SharedPreferences.getInstance();
    _prefs.setString('room_id', scheduleData['room_id']);
    _prefs.setString('subject_name', scheduleData['name']);
    Get.toNamed(Classroom.routeName);
  }

  Widget _schedules() {
    return Padding(
      padding: const EdgeInsets.all(
        20.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Meetings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          const SizedBox(
            height: 5.0,
          ),
          const Text(
            'Tap a schedule to enter the room',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11.0,
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.575,
            margin: EdgeInsets.only(
              top: 10.0,
            ),
            child: _scheduleList.isEmpty
                ? Text('Loading...')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _scheduleList.length,
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () {
                          _enterRoom(_scheduleList[i]);
                        },
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.11,
                          margin: const EdgeInsets.only(
                            top: 15.0,
                            bottom: 15.0,
                            left: 10.0,
                            right: 10.0,
                          ),
                          padding: const EdgeInsets.only(
                            left: 10.0,
                          ),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.cyan[200],
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3.0,
                                spreadRadius: 1.0,
                              )
                            ],
                            borderRadius: const BorderRadius.all(
                              Radius.circular(
                                10.0,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.cyan,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                20.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _scheduleList[i]['name'] + "\n",
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _scheduleList[i]['time'],
                                          style: TextStyle(
                                            fontSize: 11.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white,
                                      size: 25.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      body: SafeArea(
        child: WillPopScope(
            onWillPop: () async {
              return false;
            },
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: const Text(
                    'Meet & Chat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _actionButtons(),
                        _schedules(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


