import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tyto/dashboard.dart';

class Classroom extends StatefulWidget {
  const Classroom({Key? key}) : super(key: key);
  static String routeName = '/classroom';

  @override
  _ClassroomState createState() => _ClassroomState();
}

class _ClassroomState extends State<Classroom> {
  final serverText = TextEditingController();
  final roomText = TextEditingController(text: "plugintestroom");
  final subjectText = TextEditingController(text: "My Plugin Test Meeting");
  final nameText = TextEditingController(text: "Plugin Test User");
  final emailText = TextEditingController(text: "fake@email.com");
  final iosAppBarRGBAColor =
      TextEditingController(text: "#0080FF80"); //transparent blue
  bool? isAudioOnly = false;
  bool? isAudioMuted = true;
  bool? isVideoMuted = true;
  bool? isExamPageOpen = false;
  bool? isPopupQuizPageOpen = false;
  bool? isRecitationTimePageOpen = false;
  bool? isTriggerWatcherActive = false;
  @override
  void initState() {
    super.initState();
    JitsiMeet.addListener(
      JitsiMeetingListener(
        onConferenceWillJoin: _onConferenceWillJoin,
        onConferenceJoined: _onConferenceJoined,
        onConferenceTerminated: _onConferenceTerminated,
        onError: _onError,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    JitsiMeet.removeAllListeners();
    _examTriggerWatcher(false);
    _popupQuizTriggerWatcher(false);
    _recitationTimeTriggerWatcher(false);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        child: kIsWeb
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: width * 0.30,
                    child: meetConfig(),
                  ),
                  SizedBox(
                    width: width * 0.60,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        color: Colors.white54,
                        child: SizedBox(
                          width: width * 0.60 * 0.70,
                          height: width * 0.60 * 0.70,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              JitsiMeetConferencing(
                                extraJS: const [
                                  // extraJs setup example
                                  '<script>function echo(){console.log("echo!!!")};</script>',
                                  '<script src="https://code.jquery.com/jquery-3.5.1.slim.js" integrity="sha256-DrT5NfxfbHvMHux31Lkhxg42LY6of8TaYyK50jnxRnM=" crossorigin="anonymous"></script>'
                                ],
                              ),
                              Container(
                                height: MediaQuery.of(context).size.height,
                                width: MediaQuery.of(context).size.width,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                ),
                                child: const Text('test',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            : meetConfig(),
      ),
    );
  }

  Widget meetConfig() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(
            height: 14.0,
          ),
          const Text(
            'Default Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          const Text(
            'Configure the default settings before enter the call.',
            style: TextStyle(
              fontSize: 11.0,
              color: Colors.black45,
            ),
          ),
          const SizedBox(
            height: 28.0,
          ),
          CheckboxListTile(
            title: const Text("Audio Muted"),
            value: isAudioMuted,
            onChanged: _onAudioMutedChanged,
            activeColor: Colors.cyan,
          ),
          const SizedBox(
            height: 14.0,
          ),
          CheckboxListTile(
            title: const Text("Video Muted"),
            value: isVideoMuted,
            onChanged: _onVideoMutedChanged,
            activeColor: Colors.cyan,
          ),
          const Divider(
            height: 48.0,
            thickness: 2.0,
          ),
          SizedBox(
            height: 40.0,
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: () {
                _joinMeeting();
              },
              child: const Text(
                "Join Meeting",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(
            height: 48.0,
          ),
        ],
      ),
    );
  }

  void _examTriggerWatcher(bool alive) async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('exams')
        .doc(prefs.getString('schedule_id'))
        .collection('exam_data');
    // listen for the is_active value because it will act as a trigger for the exam page to open and load the data
    final examData = examsDataRef
        .where("room_id", isEqualTo: prefs.getString('room_id'))
        .limit(1)
        .snapshots()
        .listen(
      (event) {
        for (var doc in event.docs) {
          bool isExamActive = doc.data()['is_active'];
          debugPrint("isExamActive: " + isExamActive.toString());
          // if the is_active trigger is true and the exam page is closed, call the _openExamRoom()
          if (isExamActive == true && isExamPageOpen == false) {
            Navigator.of(context).pop();
            _openExamRoom();
          }
          // else if the is_active is false and the exam page is open, close it by using navigator pop and reset the state of isExamPageOpen to false
          else if (isExamActive == false && isExamPageOpen == true) {
            Navigator.of(context).pop();
            setState(() {
              isExamPageOpen = false;
            });
            _openStillInAMeetingWarning();
          }
          // anything can be done in this else block but mostly it wont be used.
          else {}
        }
      },
      onError: (error) {
        debugPrint(error);
      },
    );
    if (alive == false) {
      examData.cancel();
      debugPrint('DISABLING_WATCHER');
    }
  }

  void _popupQuizTriggerWatcher(bool alive) async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('quiz')
        .doc(prefs.getString('schedule_id'))
        .collection('quiz_data');
    // listen for the is_active value because it will act as a trigger for the exam page to open and load the data
    final examData = examsDataRef
        .where("room_id", isEqualTo: prefs.getString('room_id'))
        .limit(1)
        .snapshots()
        .listen(
      (event) {
        for (var doc in event.docs) {
          bool isPopupQuizActive = doc.data()['is_active'];
          debugPrint("isPopupQuizActive: " + isPopupQuizActive.toString());
          // if the is_active trigger is true and the exam page is closed, call the _openPopupQuiz()
          if (isPopupQuizActive == true && isPopupQuizPageOpen == false) {
            Navigator.of(context).pop();
            _openPopupQuiz();
          }
          // else if the is_active is false and the exam page is open, close it by using navigator pop and reset the state of isPopupQuizPageOpen to false
          else if (isPopupQuizActive == false && isPopupQuizPageOpen == true) {
            Navigator.of(context).pop();
            setState(() {
              isPopupQuizPageOpen = false;
            });
            _openStillInAMeetingWarning();
          }
          // anything can be done in this else block but mostly it wont be used.
          else {}
        }
      },
      onError: (error) {
        debugPrint(error);
      },
    );
    if (alive == false) {
      examData.cancel();
      debugPrint('DISABLING_WATCHER');
    }
  }

  void _recitationTimeTriggerWatcher(bool alive) async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('recitation')
        .doc(prefs.getString('schedule_id'))
        .collection('recitation_data');
    // listen for the is_active value because it will act as a trigger for the exam page to open and load the data
    final examData = examsDataRef
        .where("room_id", isEqualTo: prefs.getString('room_id'))
        .limit(1)
        .snapshots()
        .listen(
          (event) {
        for (var doc in event.docs) {
          bool isRecitationTimeActive = doc.data()['is_active'];
          String isMyStudentEmail = doc.data()['student_email'];
          debugPrint("isRecitationTimeActive: " + isRecitationTimeActive.toString());
          // if the is_active trigger is true and the exam page is closed, call the _openPopupQuiz()
          if (isRecitationTimeActive == true && isRecitationTimePageOpen == false && isMyStudentEmail == prefs.getString('userEmail')) {
            Navigator.of(context).pop();
            _openRecitationTime();
          }
          // else if the is_active is false and the exam page is open, close it by using navigator pop and reset the state of isPopupQuizPageOpen to false
          else if (isRecitationTimeActive == false && isRecitationTimePageOpen == true || isMyStudentEmail != prefs.getString('userEmail')) {
            Navigator.of(context).pop();
            setState(() {
              isRecitationTimePageOpen = false;
            });
            _openStillInAMeetingWarning();
          }
          // anything can be done in this else block but mostly it wont be used.
          else {}
        }
      },
      onError: (error) {
        debugPrint(error);
      },
    );
    if (alive == false) {
      examData.cancel();
      debugPrint('DISABLING_WATCHER');
    }
  }

  Widget _popupQuizContents() {
    return const PopupQuizContents();
  }

  Widget _recitationTimeContents(){
    return const RecitationTimeContents();
  }

  Widget _examRoomContents() {
    return const ExamRoomContents();
  }

  void _openStillInAMeetingWarning() {
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      enableDrag: false,
      isDismissible: false,
      builder: (context) {
        return SingleChildScrollView(
          child: WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Image(image: AssetImage('assets/banners/still_in_call.png')),
                  Text(
                    'You are still on a meeting\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  Text(
                    'To go back on the Dashboard, please leave the meeting first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openExamRoom() {
    setState(() {
      isExamPageOpen = true;
    });
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      enableDrag: false,
      isDismissible: false,
      builder: (context) {
        return SingleChildScrollView(
          child: WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: _examRoomContents(),
          ),
        );
      },
    );
  }

  void _openPopupQuiz(){
    setState(() {
      isPopupQuizPageOpen = true;
    });
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      enableDrag: false,
      isDismissible: false,
      builder: (context) {
        return SingleChildScrollView(
          child: WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: _popupQuizContents(),
          ),
        );
      },
    );
  }

  void _openRecitationTime(){
    setState(() {
      isRecitationTimePageOpen = true;
    });
    showMaterialModalBottomSheet(
      context: context,
      expand: true,
      enableDrag: false,
      isDismissible: false,
      builder: (context) {
        return SingleChildScrollView(
          child: WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: _recitationTimeContents(),
          ),
        );
      },
    );
  }

  _onAudioMutedChanged(bool? value) {
    setState(() {
      isAudioMuted = value;
    });
  }

  _onVideoMutedChanged(bool? value) {
    setState(() {
      isVideoMuted = value;
    });
  }

  _joinMeeting() async {
    String? serverUrl = serverText.text.trim().isEmpty ? null : serverText.text;
    final _prefs = await SharedPreferences.getInstance();
    // Enable or disable any feature flag here
    // If feature flag are not provided, default values will be used
    // Full list of feature flags (and defaults) available in the README
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
      FeatureFlagEnum.ADD_PEOPLE_ENABLED: false,
      FeatureFlagEnum.CALL_INTEGRATION_ENABLED: false,
      FeatureFlagEnum.MEETING_PASSWORD_ENABLED: false,
      FeatureFlagEnum.LIVE_STREAMING_ENABLED: false,
      FeatureFlagEnum.CALENDAR_ENABLED: false,
      FeatureFlagEnum.INVITE_ENABLED: false,
    };
    if (!kIsWeb) {
      // Here is an example, disabling features for each platform
      if (Platform.isAndroid) {
        // Disable ConnectionService usage on Android to avoid issues (see README)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        // Disable PIP on iOS as it looks weird
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      }
    }
    // Define meetings options here
    var roomName = "${_prefs.getString('room_id').toString()}${_prefs.getString('subject_name').toString()}";

    var options =
        JitsiMeetingOptions(room: roomName)
          ..serverURL = serverUrl
          // ..subject = _prefs.getString('subject_name') == ''
          //     ? 'HOST\'S ROOM'
          //     : _prefs.getString('subject_name')
          ..userDisplayName = _prefs.getString('userName')
          ..userEmail = _prefs.getString('userEmail')
          ..audioOnly = isAudioOnly
          ..audioMuted = isAudioMuted
          ..videoMuted = isVideoMuted
          ..featureFlags.addAll(featureFlags)
          ..webOptions = {
            "roomName": roomName,
            "width": "100%",
            "height": "100%",
            "enableWelcomePage": false,
            "chromeExtensionBanner": null,
            "userInfo": {"displayName": _prefs.getString('userName')}
          };

    debugPrint("JitsiMeetingOptions: $options");
    await JitsiMeet.joinMeeting(
      options,
      listener: JitsiMeetingListener(
          onConferenceWillJoin: (message) {
            debugPrint("${options.room} will join with message: $message");
            _openStillInAMeetingWarning();
            _examTriggerWatcher(true);
            _popupQuizTriggerWatcher(true);
          },
          onConferenceJoined: (message) async {
            debugPrint("${options.room} joined with message: $message");
          },
          onConferenceTerminated: (message) async {
            debugPrint("${options.room} terminated with message: $message");
            _examTriggerWatcher(false);
            _popupQuizTriggerWatcher(false);
            Navigator.of(context).pop();
            final _prefs = await SharedPreferences.getInstance();
            _prefs
                .setString('subject_name', '')
                .then((value) => Get.toNamed(Dashboard.routeName));
          },
          genericListeners: [
            JitsiGenericListener(
                eventName: 'readyToClose',
                callback: (dynamic message) {
                  debugPrint("readyToClose callback");
                }),
          ]),
    );
  }

  void _onConferenceWillJoin(message) {
    debugPrint("_onConferenceWillJoin broadcasted with message: $message");
    _examTriggerWatcher(true);
    _popupQuizTriggerWatcher(true);
    _recitationTimeTriggerWatcher(true);
  }

  void _onConferenceJoined(message) {
    debugPrint("_onConferenceJoined broadcasted with message: $message");
  }

  void _onConferenceTerminated(message) async {
    debugPrint("_onConferenceTerminated broadcasted with message: $message");
    _examTriggerWatcher(false);
    _popupQuizTriggerWatcher(false);
    _recitationTimeTriggerWatcher(false);
    Navigator.of(context).pop();
    final _prefs = await SharedPreferences.getInstance();
    _prefs
        .setString('subject_name', '')
        .then((value) => Get.toNamed(Dashboard.routeName));
  }

  _onError(error) {
    debugPrint("_onError broadcasted: $error");
  }
}

class AnswerModel {
  String? answer, question;
  int? itemIndex;
  bool? isCorrect;

  AnswerModel({this.answer, this.question, this.isCorrect, this.itemIndex});
}

class ExamRoomContents extends StatefulWidget {
  const ExamRoomContents({Key? key}) : super(key: key);

  @override
  State<ExamRoomContents> createState() => _ExamRoomContentsState();
}

class _ExamRoomContentsState extends State<ExamRoomContents> {
  var examQuestions = [];
  var examAnswerOptions = [];
  var examAnswerIndex = [];
  var examName = '';
  var itemsAnswered = [];
  List<AnswerModel> answers = [];
  AudioCache? _audioCache;
  AudioPlayer? _audioPlayer;
  var isExamSubmitted = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkIfExamIsTaken();
    if (!isExamSubmitted) {
      _fetchExamitems();
      _playBGSFX();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void _checkIfExamIsTaken() async {
    EasyLoading.show(status: 'Checking Access..');
    try {
      final prefs = await SharedPreferences.getInstance();
      final examsDataRef = FirebaseFirestore.instance
          .collection('exams')
          .doc(prefs.getString('schedule_id'))
          .collection('exam_answer');
      final examData = await examsDataRef
          .where("student_email", isEqualTo: prefs.getString('userEmail'))
          .limit(1)
          .get();
      if (examData.docs.isEmpty) {
        var _chars =
            'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
        Random _rnd = Random();

        String getRandomString(int length) =>
            String.fromCharCodes(Iterable.generate(
                length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

        final examData = examsDataRef.doc(getRandomString(20));
        examData.set({
          "exam_name": examName,
          "number_answered": 0,
          "room_id": prefs.getString('room_id'),
          "schedule_id": prefs.getString('schedule_id'),
          "student_name": prefs.getString('userName'),
          "student_email": prefs.getString('userEmail'),
          "score":0,
          "exam_submitted": false,
          "exam_results": FieldValue.arrayUnion([]),
        }).onError((error, stackTrace) => null);
        EasyLoading.dismiss();
      } else {
        for (var element in examData.docs) {
          for (var answer in answers) {
            var studentExamData = await examsDataRef.doc(element.id).get();
            setState(() {
              isExamSubmitted = studentExamData.data()!['exam_submitted'];
              EasyLoading.dismiss();
            });
          }
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError(
        e.toString(),
        duration: const Duration(
          seconds: 15,
        ),
      );
    }
  }

  void _fetchExamitems() async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('exams')
        .doc(prefs.getString('schedule_id'))
        .collection('exam_data');
    final examData = await examsDataRef
        .where("room_id", isEqualTo: prefs.getString('room_id'))
        .limit(1)
        .get();
    for (var element in examData.docs) {
      for (var data in element['items']) {
        setState(() {
          examAnswerOptions.add([
            data['itemA'],
            data['itemB'],
            data['itemC'],
            data['itemD'],
          ]);
          examQuestions.add(data['question']);
          examAnswerIndex.add(data['index']);
        });
      }
      setState(() {
        examName = element['exam_name'];
      });
    }
    _prePopulateAnswersList();
  }

  void _prePopulateAnswersList() {
    for (var data in examQuestions) {
      answers.add(AnswerModel(
          answer: "", isCorrect: false, itemIndex: 0, question: ""));
    }
  }

  void _storeAnswers(String itemQuestion, String pickedAnswerDescription,
      int questionIndex, int pickedAnswerIndex, int correctAnswerIndex) {
    answers[questionIndex].itemIndex = questionIndex;
    answers[questionIndex].question = itemQuestion;
    answers[questionIndex].answer = pickedAnswerDescription;
    answers[questionIndex].isCorrect = pickedAnswerIndex == correctAnswerIndex;
  }

  void _updateNumberItemsAnswered(
      int itemsAnsweredCount, int examQuestionIndex, int answerIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('exams')
        .doc(prefs.getString('schedule_id'))
        .collection('exam_answer');
    final examData = await examsDataRef
        .where("student_email", isEqualTo: prefs.getString('userEmail'))
        .limit(1)
        .get();
    for (var element in examData.docs) {
      examsDataRef
          .doc(element.id)
          .update({"number_answered": itemsAnsweredCount});
    }
  }

  void _submitExamResults() async {
    EasyLoading.show(status: 'Submitting your exam...');
    _stopAudio();
    int correctAnswers = answers.where((element) => element.isCorrect == true).toList().length;
    try {
      final prefs = await SharedPreferences.getInstance();
      final examsDataRef = FirebaseFirestore.instance
          .collection('exams')
          .doc(prefs.getString('schedule_id'))
          .collection('exam_answer');
      final examData = await examsDataRef
          .where("student_email", isEqualTo: prefs.getString('userEmail'))
          .limit(1)
          .get();
      if (examData.isBlank!) {
        var _chars =
            'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
        Random _rnd = Random();

        String getRandomString(int length) =>
            String.fromCharCodes(Iterable.generate(
                length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

        final examData = examsDataRef.doc(getRandomString(20));

        for (var answer in answers) {
          examData.set({
            "exam_name": examName,
            "number_answered": examQuestions.length,
            "room_id": prefs.getString('room_id'),
            "schedule_id": prefs.getString('schedule_id'),
            "student_name": prefs.getString('userName'),
            "exam_submitted": true,
            "score":correctAnswers,
            "exam_results": FieldValue.arrayUnion([
              {
                "answer": answer.answer,
                "item_index": answer.itemIndex,
                "is_correct": answer.isCorrect,
                "question": answer.question,
              }
            ]),
          });
        }
      } else {
        for (var element in examData.docs) {
          for (var answer in answers) {
            examsDataRef.doc(element.id).update({
              "exam_name": examName,
              "number_answered": examQuestions.length,
              "room_id": prefs.getString('room_id'),
              "schedule_id": prefs.getString('schedule_id'),
              "student_name": prefs.getString('userName'),
              "exam_submitted": true,
              "score":correctAnswers,
              "exam_results": FieldValue.arrayUnion([
                {
                  "answer": answer.answer,
                  "item_index": answer.itemIndex,
                  "is_correct": answer.isCorrect,
                  "question": answer.question,
                }
              ]),
            });
          }
        }
      }
      setState(() {
        isExamSubmitted = true;
        _playSubmitSFX();
        EasyLoading.dismiss();
        AwesomeDialog(
          context: context,
          dialogType: DialogType.SUCCES,
          animType: AnimType.SCALE,
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          title: 'SCORE: ${correctAnswers.toString()}/${examQuestions.length}',
          desc: 'Your exam has been successfully submitted.',
          btnOkOnPress: () {
          },
        ).show();
      });
    } catch (e) {
      EasyLoading.showError(
        'There was a problem on submitting your exam. Please screenshot this message and present it to your teacher.',
        duration: const Duration(
          seconds: 15,
        ),
      );
    }
  }

  void _playSubmitSFX()async {
    _audioCache = AudioCache(
        prefix: 'assets/audio/',
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
    AudioPlayer player = await _audioCache!.play('submit_success.mp4');
  }

  void _playBGSFX()async{
    _audioCache = AudioCache(
        prefix: 'assets/audio/',
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
    _audioPlayer = await _audioCache!.play('exam_room_sfx.mp4');
  }

  void _stopAudio()async{
    await _audioPlayer?.stop();
  }

  Widget _asnwerButtons(int containerIndex) {
    int? _selectedButton;
    var answerIndicators = ['A', 'B', 'C', 'D'];
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter stateSetter) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: 4,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, buttonIndex) {
            return MaterialButton(
              onPressed: () async {
                SystemSound.play(SystemSoundType.click);
                stateSetter(() {
                  _selectedButton = buttonIndex;
                  itemsAnswered.contains(containerIndex)
                      ? debugPrint('Answer updated for item $containerIndex')
                      : itemsAnswered.add(containerIndex);

                  _storeAnswers(
                    examQuestions[containerIndex],
                    examAnswerOptions[containerIndex][buttonIndex],
                    containerIndex,
                    buttonIndex,
                    examAnswerIndex[containerIndex],
                  );

                  _updateNumberItemsAnswered(
                    itemsAnswered.length,
                    containerIndex,
                    buttonIndex,
                  );
                });
              },
              color:
                  _selectedButton == buttonIndex ? Colors.cyan : Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      "${answerIndicators[buttonIndex]}. ${examAnswerOptions[containerIndex][buttonIndex]}",
                      style: TextStyle(
                        color: _selectedButton == buttonIndex
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _examSubmitted() {
    return SingleChildScrollView(
      child: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Image(image: AssetImage('assets/banners/exam_submitted.png')),
              Text(
                'Exam Submitted\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              Text(
                'Your exam is submitted successfully.\nYou may now return to your meeting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.cyan,
            ),
            padding: const EdgeInsets.all(
              20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "EXAM ROOM",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23.0,
                    color: Colors.white,
                  ),
                ),
                Text(
                  examName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              20.0,
              20.0,
              20.0,
              50.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                isExamSubmitted
                    ? _examSubmitted()
                    : Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: examQuestions.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, containerIndex) {
                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 50.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 10.0,
                                          bottom: 20.0,
                                        ),
                                        child: Text(
                                          '${containerIndex + 1}. ${examQuestions[containerIndex]}',
                                          style: const TextStyle(
                                            fontSize: 15.0,
                                          ),
                                        ),
                                      ),
                                      _asnwerButtons(containerIndex),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            MaterialButton(
                              onPressed: () {
                                if (itemsAnswered.length ==
                                    examQuestions.length) {
                                  _submitExamResults();
                                } else {
                                  EasyLoading.showInfo(
                                    'Please answer all the items\n Progress: ${itemsAnswered.length}/${examQuestions.length}',
                                    duration: const Duration(
                                      seconds: 3,
                                    ),
                                  );
                                }
                              },
                              color: Colors.cyan,
                              padding: const EdgeInsets.all(20.0),
                              child: const Text(
                                'SUBMIT EXAM',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PopupQuizContents extends StatefulWidget {
  const PopupQuizContents({Key? key}) : super(key: key);

  @override
  State<PopupQuizContents> createState() => _PopupQuizContentsState();
}

class _PopupQuizContentsState extends State<PopupQuizContents> {
  var examQuestions = [];
  var examAnswerOptions = [];
  var examAnswerIndex = [];
  var examName = '';
  var itemsAnswered = [];
  List<AnswerModel> answers = [];
  AudioCache? _audioCache;
  AudioPlayer? _audioPlayer;
  var isQuizSubmitted = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkIfExamIsTaken();
    if (!isQuizSubmitted) {
      _fetchExamitems();
      _playBGSFX();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _stopAudio();
  }

  void _checkIfExamIsTaken() async {
    EasyLoading.show(status: 'Checking Access..');
    try {
      final prefs = await SharedPreferences.getInstance();
      final examsDataRef = FirebaseFirestore.instance
          .collection('quiz')
          .doc(prefs.getString('schedule_id'))
          .collection('quiz_answer');
      final examData = await examsDataRef
          .where("student_email", isEqualTo: prefs.getString('userEmail'))
          .limit(1)
          .get();
      if (examData.docs.isEmpty) {
        var _chars =
            'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
        Random _rnd = Random();

        String getRandomString(int length) =>
            String.fromCharCodes(Iterable.generate(
                length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

        final examData = examsDataRef.doc(getRandomString(20));
        examData.set({
          "quiz_name": examName,
          "number_answered": 0,
          "room_id": prefs.getString('room_id'),
          "schedule_id": prefs.getString('schedule_id'),
          "student_name": prefs.getString('userName'),
          "student_email": prefs.getString('userEmail'),
          "quiz_submitted": false,
          "score":0,
          "quiz_results": FieldValue.arrayUnion([]),
        }).onError((error, stackTrace) => null);
        EasyLoading.dismiss();
      } else {
        for (var element in examData.docs) {
          for (var answer in answers) {
            var studentExamData = await examsDataRef.doc(element.id).get();
            setState(() {
              isQuizSubmitted = studentExamData.data()!['quiz_submitted'];
              EasyLoading.dismiss();
            });
          }
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError(
        e.toString(),
        duration: const Duration(
          seconds: 15,
        ),
      );
    }
  }

  void _fetchExamitems() async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('quiz')
        .doc(prefs.getString('schedule_id'))
        .collection('quiz_data');
    final examData = await examsDataRef
        .where("room_id", isEqualTo: prefs.getString('room_id'))
        .limit(1)
        .get();
    for (var element in examData.docs) {
      for (var data in element['items']) {
        setState(() {
          examAnswerOptions.add([
            data['itemA'],
            data['itemB'],
            data['itemC'],
            data['itemD'],
          ]);
          examQuestions.add(data['question']);
          examAnswerIndex.add(data['index']);
        });
      }
      setState(() {
        examName = element['quiz_name'];
      });
    }
    _prePopulateAnswersList();
  }

  void _prePopulateAnswersList() {
    for (var data in examQuestions) {
      answers.add(AnswerModel(
          answer: "", isCorrect: false, itemIndex: 0, question: ""));
    }
    debugPrint(answers.toString());
  }

  void _storeAnswers(String itemQuestion, String pickedAnswerDescription,
      int questionIndex, int pickedAnswerIndex, int correctAnswerIndex) {
    answers[questionIndex].itemIndex = questionIndex;
    answers[questionIndex].question = itemQuestion;
    answers[questionIndex].answer = pickedAnswerDescription;
    answers[questionIndex].isCorrect = pickedAnswerIndex == correctAnswerIndex;
  }

  void _updateNumberItemsAnswered(
      int itemsAnsweredCount, int examQuestionIndex, int answerIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('quiz')
        .doc(prefs.getString('schedule_id'))
        .collection('quiz_answer');
    final examData = await examsDataRef
        .where("student_email", isEqualTo: prefs.getString('userEmail'))
        .limit(1)
        .get();
    for (var element in examData.docs) {
      examsDataRef
          .doc(element.id)
          .update({"number_answered": itemsAnsweredCount});
    }
  }

  void _submitExamResults() async {
    EasyLoading.show(status: 'Submitting your answer...');
    _stopAudio();
    int correctAnswers = answers.where((element) => element.isCorrect == true).toList().length;
    try {
      final prefs = await SharedPreferences.getInstance();
      final examsDataRef = FirebaseFirestore.instance
          .collection('quiz')
          .doc(prefs.getString('schedule_id'))
          .collection('quiz_answer');
      final examData = await examsDataRef
          .where("student_email", isEqualTo: prefs.getString('userEmail'))
          .limit(1)
          .get();
      if (examData.isBlank!) {
        var _chars =
            'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
        Random _rnd = Random();

        String getRandomString(int length) =>
            String.fromCharCodes(Iterable.generate(
                length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

        final examData = examsDataRef.doc(getRandomString(20));

        for (var answer in answers) {
          examData.set({
            "quiz_name": examName,
            "number_answered": examQuestions.length,
            "room_id": prefs.getString('room_id'),
            "schedule_id": prefs.getString('schedule_id'),
            "student_name": prefs.getString('userName'),
            "quiz_submitted": true,
            "score":correctAnswers,
            "quiz_results": FieldValue.arrayUnion([
              {
                "answer": answer.answer,
                "item_index": answer.itemIndex,
                "is_correct": answer.isCorrect,
                "question": answer.question,
              }
            ]),
          });
        }
      } else {
        for (var element in examData.docs) {
          for (var answer in answers) {
            examsDataRef.doc(element.id).update({
              "quiz_name": examName,
              "number_answered": examQuestions.length,
              "room_id": prefs.getString('room_id'),
              "schedule_id": prefs.getString('schedule_id'),
              "student_name": prefs.getString('userName'),
              "quiz_submitted": true,
              "score":correctAnswers,
              "quiz_results": FieldValue.arrayUnion([
                {
                  "answer": answer.answer,
                  "item_index": answer.itemIndex,
                  "is_correct": answer.isCorrect,
                  "question": answer.question,
                }
              ]),
            });
          }
        }
      }
      setState(() {
        isQuizSubmitted = true;
        _playSubmitSFX();
        EasyLoading.dismiss();
        AwesomeDialog(
          context: context,
          dialogType: DialogType.SUCCES,
          animType: AnimType.SCALE,
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          title: 'SCORE: ${correctAnswers.toString()}/${examQuestions.length}',
          desc: 'Your answers and score has been successfully submitted.',
          btnOkOnPress: () {
          },
        ).show();
      });
    } catch (e) {
      EasyLoading.showError(
        'There was a problem on submitting your exam. Please screenshot this message and present it to your teacher.',
        duration: const Duration(
          seconds: 15,
        ),
      );
    }
  }

  void _playSubmitSFX() {
    _audioCache = AudioCache(
        prefix: 'assets/audio/',
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
    _audioCache!.play('submit_success.mp4');
  }

  void _playBGSFX()async{
    _audioCache = AudioCache(
        prefix: 'assets/audio/',
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
    _audioPlayer = await _audioCache!.play('exam_room_sfx.mp4');
  }

  void _stopAudio()async{
    await _audioPlayer?.stop();
  }
  Widget _asnwerButtons(int containerIndex) {
    int? _selectedButton;
    var answerIndicators = ['A', 'B', 'C', 'D'];
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter stateSetter) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: 4,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, buttonIndex) {
            return MaterialButton(
              onPressed: () async {
                SystemSound.play(SystemSoundType.click);
                stateSetter(() {
                  _selectedButton = buttonIndex;
                  itemsAnswered.contains(containerIndex)
                      ? debugPrint('Answer updated for item $containerIndex')
                      : itemsAnswered.add(containerIndex);

                  _storeAnswers(
                    examQuestions[containerIndex],
                    examAnswerOptions[containerIndex][buttonIndex],
                    containerIndex,
                    buttonIndex,
                    examAnswerIndex[containerIndex],
                  );

                  _updateNumberItemsAnswered(
                    itemsAnswered.length,
                    containerIndex,
                    buttonIndex,
                  );
                });
              },
              color:
                  _selectedButton == buttonIndex ? Colors.cyan : Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      "${answerIndicators[buttonIndex]}. ${examAnswerOptions[containerIndex][buttonIndex]}",
                      style: TextStyle(
                        color: _selectedButton == buttonIndex
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _examSubmitted() {
    return SingleChildScrollView(
      child: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Image(image: AssetImage('assets/banners/exam_submitted.png')),
              Text(
                'Answer Submitted\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              Text(
                'Your answer is submitted successfully.\nYou may now return to your meeting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.cyan,
            ),
            padding: const EdgeInsets.all(
              20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "POPUP QUIZ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23.0,
                    color: Colors.white,
                  ),
                ),
                Text(
                  examName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              20.0,
              20.0,
              20.0,
              50.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                isQuizSubmitted
                    ? _examSubmitted()
                    : Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: examQuestions.length,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, containerIndex) {
                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 50.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 10.0,
                                          bottom: 20.0,
                                        ),
                                        child: Text(
                                          '${containerIndex + 1}. ${examQuestions[containerIndex]}',
                                          style: const TextStyle(
                                            fontSize: 15.0,
                                          ),
                                        ),
                                      ),
                                      _asnwerButtons(containerIndex),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            MaterialButton(
                              onPressed: () {
                                if (itemsAnswered.length ==
                                    examQuestions.length) {
                                  _submitExamResults();
                                } else {
                                  EasyLoading.showInfo(
                                    'Please answer all the items\n Progress: ${itemsAnswered.length}/${examQuestions.length}',
                                    duration: const Duration(
                                      seconds: 3,
                                    ),
                                  );
                                }
                              },
                              color: Colors.cyan,
                              padding: const EdgeInsets.all(20.0),
                              child: const Text(
                                'SUBMIT ANSWER',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecitationTimeContents extends StatefulWidget {
  const RecitationTimeContents({Key? key}) : super(key: key);

  @override
  State<RecitationTimeContents> createState() => _RecitationTimeContentsState();
}

class _RecitationTimeContentsState extends State<RecitationTimeContents> {
  var examQuestions = [];
  var examAnswerOptions = [];
  var examAnswerIndex = [];
  var examName = '';
  var itemsAnswered = [];
  List<AnswerModel> answers = [];
  AudioCache? _audioCache;
  AudioPlayer? _audioPlayer;
  var isQuizSubmitted = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkIfExamIsTaken();
    if (!isQuizSubmitted) {
      _fetchExamitems();
      _playBGSFX();
    }
  }

  void _checkIfExamIsTaken() async {
    EasyLoading.show(status: 'Checking Access..');

    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('recitation')
        .doc(prefs.getString('schedule_id'))
        .collection('recitation_answer');
    final examData = await examsDataRef
        .where("student_email", isEqualTo: prefs.getString('userEmail'))
        .limit(1)
        .get();
    if (examData.docs.isEmpty) {
      var _chars =
          'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
      Random _rnd = Random();

      String getRandomString(int length) =>
          String.fromCharCodes(Iterable.generate(
              length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

      final examData = examsDataRef.doc(getRandomString(20));
      examData.set({
        "recitation_name": examName,
        "number_answered": 0,
        "room_id": prefs.getString('room_id'),
        "schedule_id": prefs.getString('schedule_id'),
        "student_name": prefs.getString('userName'),
        "student_email": prefs.getString('userEmail'),
        "recitation_submitted": false,
        "score":0,
        "recitation_results": FieldValue.arrayUnion([]),
      }).onError((error, stackTrace) => null);
      EasyLoading.dismiss();
    } else {
      for (var element in examData.docs) {
        for (var answer in answers) {
          var studentExamData = await examsDataRef.doc(element.id).get();
          setState(() {
            isQuizSubmitted = studentExamData.data()!['recitation_submitted'];
            EasyLoading.dismiss();
          });
        }
      }
    }
  }

  void _fetchExamitems() async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('recitation')
        .doc(prefs.getString('schedule_id'))
        .collection('recitation_data');
    final examData = await examsDataRef
        .where("room_id", isEqualTo: prefs.getString('room_id'))
        .limit(1)
        .get();
    for (var element in examData.docs) {
      for (var data in element['items']) {
        setState(() {
          examAnswerOptions.add([
            data['itemA'],
            data['itemB'],
            data['itemC'],
            data['itemD'],
          ]);
          examQuestions.add(data['question']);
          examAnswerIndex.add(data['index']);
        });
      }
      setState(() {
        examName = element['recitation_name'];
      });
    }
    _prePopulateAnswersList();
  }

  void _prePopulateAnswersList() {
    for (var data in examQuestions) {
      answers.add(AnswerModel(
          answer: "", isCorrect: false, itemIndex: 0, question: ""));
    }
    debugPrint(answers.toString());
  }

  void _storeAnswers(String itemQuestion, String pickedAnswerDescription,
      int questionIndex, int pickedAnswerIndex, int correctAnswerIndex) {
    answers[questionIndex].itemIndex = questionIndex;
    answers[questionIndex].question = itemQuestion;
    answers[questionIndex].answer = pickedAnswerDescription;
    answers[questionIndex].isCorrect = pickedAnswerIndex == correctAnswerIndex;
  }

  void _updateNumberItemsAnswered(
      int itemsAnsweredCount, int examQuestionIndex, int answerIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final examsDataRef = FirebaseFirestore.instance
        .collection('quiz')
        .doc(prefs.getString('schedule_id'))
        .collection('quiz_answer');
    final examData = await examsDataRef
        .where("student_email", isEqualTo: prefs.getString('userEmail'))
        .limit(1)
        .get();
    for (var element in examData.docs) {
      examsDataRef
          .doc(element.id)
          .update({"number_answered": itemsAnsweredCount});
    }
  }

  void _submitExamResults() async {
    EasyLoading.show(status: 'Submitting your answer...');
    int correctAnswers = answers.where((element) => element.isCorrect == true).toList().length;
    _stopAudio();
    try {
      final prefs = await SharedPreferences.getInstance();
      final examsDataRef = FirebaseFirestore.instance
          .collection('recitation')
          .doc(prefs.getString('schedule_id'))
          .collection('recitation_answer');
      final examData = await examsDataRef
          .where("student_email", isEqualTo: prefs.getString('userEmail'))
          .limit(1)
          .get();
      if (examData.isBlank!) {
        var _chars =
            'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
        Random _rnd = Random();

        String getRandomString(int length) =>
            String.fromCharCodes(Iterable.generate(
                length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

        final examData = examsDataRef.doc(getRandomString(20));

        for (var answer in answers) {
          examData.set({
            "recitation_name": examName,
            "number_answered": examQuestions.length,
            "room_id": prefs.getString('room_id'),
            "schedule_id": prefs.getString('schedule_id'),
            "student_name": prefs.getString('userName'),
            "recitation_submitted": true,
            "score":correctAnswers,
            "recitation_results": FieldValue.arrayUnion([
              {
                "answer": answer.answer,
                "item_index": answer.itemIndex,
                "is_correct": answer.isCorrect,
                "question": answer.question,
              }
            ]),
          });
        }
      } else {
        for (var element in examData.docs) {
          for (var answer in answers) {
            examsDataRef.doc(element.id).update({
              "recitation_name": examName,
              "number_answered": examQuestions.length,
              "room_id": prefs.getString('room_id'),
              "schedule_id": prefs.getString('schedule_id'),
              "student_name": prefs.getString('userName'),
              "recitation_submitted": true,
              "score":correctAnswers,
              "recitation_results": FieldValue.arrayUnion([
                {
                  "answer": answer.answer,
                  "item_index": answer.itemIndex,
                  "is_correct": answer.isCorrect,
                  "question": answer.question,
                }
              ]),
            });
          }
        }
      }
      setState(() {
        isQuizSubmitted = true;
        _playSubmitSFX();
        EasyLoading.dismiss();
        AwesomeDialog(
          context: context,
          dialogType: DialogType.SUCCES,
          animType: AnimType.SCALE,
          dismissOnTouchOutside: false,
          dismissOnBackKeyPress: false,
          title: 'SCORE: ${correctAnswers.toString()}/${examQuestions.length}',
          desc: 'Your answer and score has been successfully submitted.',
          btnOkOnPress: () {
          },
        ).show();
      });
    } catch (e) {
      EasyLoading.showError(
        'There was a problem on submitting your exam. Please screenshot this message and present it to your teacher.',
        duration: const Duration(
          seconds: 15,
        ),
      );
    }
  }

  void _playSubmitSFX() {
    _audioCache = AudioCache(
        prefix: 'assets/audio/',
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
    _audioCache!.play('submit_success.mp4');
  }

  void _playBGSFX()async{
    _audioCache = AudioCache(
        prefix: 'assets/audio/',
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
    _audioPlayer = await _audioCache!.play('exam_room_sfx.mp4');
  }

  void _stopAudio()async{
    await _audioPlayer?.stop();
  }

  Widget _asnwerButtons(int containerIndex) {
    int? _selectedButton;
    var answerIndicators = ['A', 'B', 'C', 'D'];
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter stateSetter) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: 4,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, buttonIndex) {
            return MaterialButton(
              onPressed: () async {
                SystemSound.play(SystemSoundType.click);
                stateSetter(() {
                  _selectedButton = buttonIndex;
                  itemsAnswered.contains(containerIndex)
                      ? debugPrint('Answer updated for item $containerIndex')
                      : itemsAnswered.add(containerIndex);

                  _storeAnswers(
                    examQuestions[containerIndex],
                    examAnswerOptions[containerIndex][buttonIndex],
                    containerIndex,
                    buttonIndex,
                    examAnswerIndex[containerIndex],
                  );

                  _updateNumberItemsAnswered(
                    itemsAnswered.length,
                    containerIndex,
                    buttonIndex,
                  );
                });
              },
              color:
              _selectedButton == buttonIndex ? Colors.cyan : Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      "${answerIndicators[buttonIndex]}. ${examAnswerOptions[containerIndex][buttonIndex]}",
                      style: TextStyle(
                        color: _selectedButton == buttonIndex
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _examSubmitted() {
    return SingleChildScrollView(
      child: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Image(image: AssetImage('assets/banners/exam_submitted.png')),
              Text(
                'Answer Submitted\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              Text(
                'Your answer is submitted successfully.\nYou may now return to your meeting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.cyan,
            ),
            padding: const EdgeInsets.all(
              20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "RECITATION TIME",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23.0,
                    color: Colors.white,
                  ),
                ),
                Text(
                  examName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              20.0,
              20.0,
              20.0,
              50.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                isQuizSubmitted
                    ? _examSubmitted()
                    : Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: examQuestions.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, containerIndex) {
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 50.0,
                            ),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 10.0,
                                    bottom: 20.0,
                                  ),
                                  child: Text(
                                    '${containerIndex + 1}. ${examQuestions[containerIndex]}',
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ),
                                _asnwerButtons(containerIndex),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      MaterialButton(
                        onPressed: () {
                          if (itemsAnswered.length ==
                              examQuestions.length) {
                            _submitExamResults();
                          } else {
                            EasyLoading.showInfo(
                              'Please answer all the items\n Progress: ${itemsAnswered.length}/${examQuestions.length}',
                              duration: const Duration(
                                seconds: 3,
                              ),
                            );
                          }
                        },
                        color: Colors.cyan,
                        padding: const EdgeInsets.all(20.0),
                        child: const Text(
                          'SUBMIT ANSWER',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
