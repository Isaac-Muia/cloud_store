// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_store/cloudstorage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_store/database.dart';
import 'package:archive/archive_io.dart';
import 'package:cloud_store/main.dart';

import 'dart:async';
import 'dart:io';

String? downloadDirectory = '';
List<PlatformFile> pickedFiles = [];
CloudStorage cloudManager = CloudStorage();
List<String> sharedUsers = [];
List<Widget> selectedUsers = [];
String userEmail = '';

class FileSharePage extends StatelessWidget {
  final email;
  final downloadPath;
  const FileSharePage({Key? key, this.email, this.downloadPath})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    userEmail = email;
    downloadDirectory = downloadPath;
    return const MaterialApp(
      title: 'Cloud Store',
      home: FileShare(),
    );
  }
}

class FileShare extends StatefulWidget {
  const FileShare({super.key});

  @override
  State<FileShare> createState() => _FileShareState();
}

class _FileShareState extends State<FileShare> {
  final mainColor = const Color.fromARGB(255, 30, 155, 11);

  startFilePicker() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (var element in result.files) {
        setState(() {
          pickedFiles.add(element);
        });
      }
    }
    uploadFiles();
  }

  ///Uploads the files in the picked files list returns a message
  ///to the user when done
  Future<AlertDialog?> uploadFiles() async {
    final archive = Archive();
    int filesnum = pickedFiles.length;
    //Put files in list
    List<File> filelist = [];
    for (var e in pickedFiles) {
      if (!kIsWeb) {
        filelist.add(File(e.path!));
      } else {
        final htmlData = e.bytes!;
        final archiveFile = ArchiveFile(e.name, htmlData.length, htmlData);
        archive.addFile(archiveFile);
      }
    }
    //Upload zip file
    if (!kIsWeb) {
      final zipBytes = await compressFilesToZip(filelist);
      //Upload from android using path
      cloudManager.uploadFileToFirebase('sharedfiles/$userEmail/files.zip',
          null, '/zip', '$downloadDirectory/files.zip');
    } else {
      //Upload from web app using bytes
      final zipData = ZipEncoder().encode(archive);
      final zipBytes = await Uint8List.fromList(zipData!);
      cloudManager.uploadFileToFirebase(
          'sharedfiles/$userEmail/files.zip', zipBytes, '/zip', null);
    }
    pickedFiles.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()),
    );
    if (filesnum != 0) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                content: Container(
              height: 100,
              alignment: Alignment.center,
              child: Column(children: [
                Container(
                  alignment: Alignment.center,
                  width: 200,
                  child: const Text("File upload complete :)\n"),
                ),
                MaterialButton(
                  //Sets showRating variable ot false
                  child: const Text("Close"),
                  onPressed: () {
                    if (!kIsWeb) {
                      File('$downloadDirectory/files.zip').delete();
                    }
                    //             _progressController.value = 0;
                    Navigator.of(context).pop();
                  },
                )
              ]),
            ));
          });
    }
    return null;
  }

  Future<Uint8List> compressFilesToZip(files) async {
    // Create a new Archive
    final archive = Archive();

    // Add files to the archive
    if (!kIsWeb) {
      for (final file in files) {
        final filename = file.path.split('/').last;
        final data = file.readAsBytesSync();

        archive.addFile(ArchiveFile(
          filename,
          data.length,
          data,
        ));
        //     _progressController.value += 1 / files.length;
      }
    }
    final zipData = ZipEncoder().encode(archive);
    final zpBytes = await Uint8List.fromList(zipData!);
    final savePath = '$downloadDirectory/files.zip';
    await File(savePath).writeAsBytes(Uint8List.fromList(zpBytes));

    return (zpBytes);
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _controllerUserSearch = TextEditingController();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 109, 141, 141),
      appBar: AppBar(
        title: const Text("Cloud Store"),
        backgroundColor: mainColor,
      ),
      body: Column(
        children: [
          TextField(
              controller: _controllerUserSearch,
              decoration:
                  const InputDecoration(hintText: "Enter a users email")),
          ElevatedButton(
              onPressed: () async {
                if (_controllerUserSearch.text != '') {
                  if (await Database.seachForUser(_controllerUserSearch.text)) {
                    setState(() {
                      sharedUsers.add(_controllerUserSearch.text);
                      selectedUsers.add(Text(_controllerUserSearch.text));
                    });
                  } else {
                    setState(() {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const AlertDialog(
                                content: Text(
                              "User doesn't exist",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ));
                          });
                    });
                  }
                  _controllerUserSearch.clear();
                }
              },
              child: const Text("Add")),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (selectedUsers.isNotEmpty) {
                      selectedUsers.removeAt(selectedUsers.length - 1);
                      sharedUsers.removeAt(sharedUsers.length - 1);
                    }
                  });
                },
                child: const Text("Remove"),
              ),
              Column(children: selectedUsers),
              ElevatedButton(
                  onPressed: () {
                    if (sharedUsers.isEmpty) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                content: Container(
                              height: 100,
                              alignment: Alignment.center,
                              child: Column(children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: 200,
                                  child: const Text(
                                      "Only share files with yourself?"),
                                ),
                                Row(
                                  children: [
                                    MaterialButton(
                                      child: const Text("Yes"),
                                      onPressed: () {
                                        Database.updateUser(
                                            userEmail, sharedUsers);
                                        Navigator.of(context).pop();
                                        startFilePicker();
                                      },
                                    ),
                                    MaterialButton(
                                      child: const Text("No"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                )
                              ]),
                            ));
                          });
                    } else {
                      Database.updateUser(userEmail, sharedUsers);
                      startFilePicker();
                    }
                  },
                  child: const Text("Select Files"))
            ],
          )
        ],
      ),
    );
  }
}
