import 'dart:io';
import 'dart:async';
import 'package:cloud_store/cloudstorage.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudStorageMobile implements CloudStorage {
  ///Uploads the file at path (for android) or the file sourceFileBytes (for web)
  ///to the firebase bucket at the sinkDestination
  @override
  Future<UploadTask> uploadFileToFirebase(
    sinkDestination,
    sourceFileBytes,
    fileType,
    filePath,
  ) async {
    Reference storageLocation =
        FirebaseStorage.instance.ref().child(sinkDestination);
    UploadTask uploadTask;
    if (filePath == null) {
      final metadata = SettableMetadata(contentType: fileType);
      uploadTask = storageLocation.putData(sourceFileBytes, metadata);
    } else {
      File uploadFile = await File(filePath).create(recursive: true);
      uploadTask = storageLocation.putFile(uploadFile);
    }
    return uploadTask;
  }

  ///Downloads the shared files of the user 'user' downloads
  @override
  downloadFile(user, downloadPath) async {
    final storageRef =
        FirebaseStorage.instance.ref().child("sharedfiles/$user/files.zip");
    final file = File(downloadPath);

    final downloadTask = storageRef.writeToFile(file);
    downloadTask.snapshotEvents.listen((taskSnapshot) {
      switch (taskSnapshot.state) {
        case TaskState.running:
          break;
        case TaskState.paused:
          break;
        case TaskState.success:
          break;
        case TaskState.canceled:
          break;
        case TaskState.error:
          break;
      }
    });
  }
}

CloudStorage getManager() => CloudStorageMobile();
