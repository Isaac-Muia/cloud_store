// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_store/cloudstorage.dart';
import 'package:cloud_store/pages/login_register_page.dart';
import 'package:cloud_store/pages/file_share_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_store/auth.dart';
import 'package:cloud_store/database.dart';

import 'dart:async';

String? downloadDirectory = '';
List<PlatformFile> pickedFiles = [];
CloudStorage cloudManager = CloudStorage();
List<String> sharedUsers = [];
List<Widget> selectedUsers = [];
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //initialising firebase app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    var externalDirectoryPath = await getExternalStorageDirectory();
    downloadDirectory = externalDirectoryPath?.path;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Cloud Store',
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  final User? user = Auth().currentUser;
  String? errorMessage = '';
  bool isLogin = true;
  final mainColor = const Color.fromARGB(255, 30, 155, 11);

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  @override
  void initState() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    _progressController.forward();
    super.initState();
    _progressController.value = 0.0;
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
          email: _controllerEmail.text, password: _controllerPassword.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
          email: _controllerEmail.text, password: _controllerPassword.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _signOutButton() {
    return Container(
      color: mainColor,
      child: ElevatedButton(
        style: ButtonStyle( 
          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              return mainColor;
            },
          ),
        ),
        onPressed: signOut,
        child: const Text("Sign out"),
      ),
    );
  }

  void downloadFilesFromUser(
    user,
  ) {
    cloudManager.downloadFile(user, "$downloadDirectory/downloadedFiles.zip");
    Navigator.of(context).pop();
  }

  void _downloadButton() async {
    List<String> usersShared = await Database.getSharedUsers(
        user?.email); //Users that have files shared with local user
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              //height: MediaQuery.of(context).size.height,
              height: 100,
              alignment: Alignment.center,
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: usersShared.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => downloadFilesFromUser((usersShared[index])),
                      child: ListTile(
                        title: Text(usersShared[index]),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        });
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  ///Opens a new page for the user to choose who to share the files with
  void chooseUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => FileSharePage(
              email: user?.email, downloadPath: downloadDirectory)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoginPage();
          } else {
            return Scaffold(
                backgroundColor: const Color.fromARGB(255, 109, 141, 141),
                appBar: AppBar(
                  title: const Text("Cloud Store"),
                  backgroundColor: mainColor,
                ),
                body: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Column(
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[_signOutButton()],
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ElevatedButton(
                              style: ButtonStyle(
                                fixedSize:
                                    MaterialStateProperty.resolveWith<Size?>(
                                        (Set<MaterialState> states) {
                                  return const Size(125, 40);
                                }),
                                padding: MaterialStateProperty.resolveWith<
                                        EdgeInsetsGeometry?>(
                                    (Set<MaterialState> states) {
                                  return const EdgeInsets.fromLTRB(5, 5, 5, 5);
                                }),
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    return mainColor;
                                  },
                                ),
                              ),
                              child: const Text('Share Files'),
                              onPressed: () {
                                chooseUsers();
                              },
                            ),
                            ElevatedButton(
                              style: ButtonStyle(
                                fixedSize:
                                    MaterialStateProperty.resolveWith<Size?>(
                                        (Set<MaterialState> states) {
                                  return const Size(125, 40);
                                }),
                                padding: MaterialStateProperty.resolveWith<
                                        EdgeInsetsGeometry?>(
                                    (Set<MaterialState> states) {
                                  return const EdgeInsets.fromLTRB(5, 5, 5, 5);
                                }),
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    return mainColor;
                                  },
                                ),
                              ),
                              child: const Text('Download Files'),
                              onPressed: () {
                                _downloadButton();
                              },
                            ),
                          ]),
                      Container(
                          padding: const EdgeInsets.fromLTRB(5, 8, 5, 5),
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            value: _progressController.value,
                          ))
                    ],
                  ),
                ));
          }
        });
  }
}
