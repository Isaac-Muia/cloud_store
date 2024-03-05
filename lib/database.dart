import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class Database {
  ///Uploads a users ID(email) to the database
  static void uploadUser(userID) {
    FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
    final user = <String, String>{
      "users": "$userID",
    };

    firestoreInstance.collection("users").doc(userID).set(user);
  }

  ///Searches for the user with the userEmail
  ///Returns true if user exists false otherwise
  static Future<bool> seachForUser(userEmail) async {
    final documentRef =
        FirebaseFirestore.instance.collection("users").doc(userEmail);
    final snapshot = await documentRef.get();
    return snapshot.exists;
  }

  ///Updates the given users user filed in the database
  static Future<void> updateUser(userID, sharedUsers) async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .update({"users": sharedUsers});
  }

  ///Searches each user for users they have shared there files with
  ///Returns a list of all the users that userID has files shared from
  static Future<List<String>> getSharedUsers(userID) async {
    final collectionRef = FirebaseFirestore.instance.collection("users");
    final snapshot = await collectionRef.get();
    List<String> output = [];
    if (snapshot.docs.isNotEmpty) {
      for (var document in snapshot.docs) {
        for (var user in document.get("users")) {
          if (user == userID) {
            output.add(document.id);
          }
        }
      }
    }
    return (output);
  }
}
