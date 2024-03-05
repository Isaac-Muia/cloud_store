import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'cloudstub.dart'
    if (dart.library.html) 'cloudstorageweb.dart'
    if (dart.library.io) 'cloudstoragemobile.dart';

abstract class CloudStorage {
  factory CloudStorage() => getManager();

  Future<UploadTask> uploadFileToFirebase(
    sinkDestination,
    sourceFileBytes,
    fileType,
    filePath,
  ) {
    throw UnimplementedError();
  }

  downloadFile(user, downloadPath) {
    throw UnimplementedError();
  }
}
