import 'package:bscs_chat/models/user.dart' as model;
import 'package:bscs_chat/models/profile.dart' as model;
import 'package:bscs_chat/resources/storage_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FireStoreUserMethods {
  // Reference to the 'users' collection in Firestore
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  // Reference to the 'trashedUsers' collection in Firestore
  final CollectionReference _trashedUsersCollection = FirebaseFirestore.instance.collection('trashedUsers');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<model.User> getUserById(String userId) async {
    DocumentSnapshot userSnapshot = await _usersCollection.doc(userId).get();
    if (!userSnapshot.exists) {
      throw Exception('No user found with id $userId');
    }
    // Create a User object from the document snapshot
    model.User user = model.User.fromSnap(userSnapshot);
    // Return the User object
    return user;
  }

  Future<model.User?> getCurrentUserData() async {
    model.User? user;
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    final documentSnapshot = await _usersCollection.doc(currentUser.uid).get();
    if (documentSnapshot.exists) {
      // Convert DocumentSnapshot to User
      user = model.User.fromSnap(documentSnapshot);
    }
    return user;
  }

  Stream<model.User?> getCurrentUserDataStream() async* {
    final currentUser = _auth.currentUser;
    if (currentUser == null) yield null;
    final documentSnapshot = await _usersCollection.doc(currentUser!.uid).get();
    if (documentSnapshot.exists) {
      // Convert DocumentSnapshot to User
      final user = model.User.fromSnap(documentSnapshot);
      yield user;
    }
  }

  Future<void> updateCurrentUserData(model.User user) async {
    await _usersCollection
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
  }

  Future<String> updateProfileImage(Uint8List? file, String currentUserUid) async {      
    String downloadUrl = '';
    if (file != null) {
      downloadUrl = await StorageMethods()
          .uploadImageToStorage('profileImages', file, false);

      // Get a reference to the user's document in Firestore
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUserUid);

      // Update the profileImage field in the user's document
      await userDocRef.update({
        'profile.profileImage': downloadUrl,
      });
    }

    return downloadUrl; // Return the URL of the uploaded image
  }

  Stream<String> getCurrentUserProfileImageStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(''); // Return an empty string if the user is not logged in
    }

    // Return a stream that listens to changes in the user's document
    return _usersCollection.doc(currentUser.uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('profile') && data['profile']['profileImage'] != null) {
          return data['profile']['profileImage'] as String;
        }
      }
      return ''; // Return an empty string if there's no profile image
    });
  }

  /* Add user account */
  Future<String> addUser({
    required String email,
    required String password,
    String? username,
    required String userType,
    model.Profile? profile
  }) async {
    String res = "Enter valid credentials";
    try {
      if (email.isNotEmpty && password.isNotEmpty && userType.isNotEmpty && profile != null) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        model.User user = model.User(
          uid: credential.user!.uid,
          email: email,
          username: username,
          userType: userType,
          profile: profile,
          password: password,
        );
        await _usersCollection.doc(credential.user!.uid).set(user.toJson());
        res = "Success";
      } 
    } catch (err) {
      
      if (err is FirebaseAuthException) {  
        if (err.code == 'invalid-email') {
          res = 'The email is badly formatted.';
        } else if (err.code == 'weak-password') {
          res = 'The password must be 6 characters long or more.';
        } else if (err.code == 'email-already-in-use') {
          res = 'The account already exists for that email.';
        }
      } else {
        res = err.toString();
      }
    }
    return res;
  }

  // Method to reauthenticate user
  Future<bool> reauthenticateUser(String email, String currentPassword) async {
    try {
      // Obtain the user's current authentication credentials
      User? user = _auth.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: currentPassword);

      // Reauthenticate
      await user?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in reauthentication: $e');
      }
      return false;
    }
  }

  // Updated updateUser function
  Future<String> updateUser({
    required String uid,
    required String email,
    required String password,
    String? username,
    required String userType,
    model.Profile? profile,
    required String currentPassword // Add current password parameter
  }) async {

    String res = "Enter valid credentials";
    try {

      // Reauthenticate before performing sensitive operations
      bool reauthResult = await reauthenticateUser(email, currentPassword);
      if (!reauthResult) {
        if (kDebugMode) {
          print('Reauthentication failed');
        }
        return 'Reauthentication required';
      }

      // Validate if all required fields are provided
      if (email.isEmpty || password.isEmpty || userType.isEmpty) {
        if (kDebugMode) {
          print('Error: Email, Password, or UserType is empty');
        }
        return res;
      }

      // If all validations pass
      model.User user = model.User(
        uid: uid,
        email: email,
        username: username,
        userType: userType,
        profile: profile,
        password: password,
      );

      // Updating Firebase user
      await _auth.currentUser!.updateEmail(email);
      await _auth.currentUser!.updatePassword(password);
      await _usersCollection.doc(uid).update(user.toJson());
      res = "Success";
      if (kDebugMode) {
        print('User updated successfully: $res');
      }
    } catch (err) {
      if (kDebugMode) {
        print('Error in try-catch block: $err');
      }
      if (err is FirebaseAuthException) {  
        if (err.code == 'invalid-email') {
          res = 'The email is badly formatted.';
        } else if (err.code == 'weak-password') {
          res = 'The password must be 6 characters long or more.';
        } else if (err.code == 'email-already-in-use') {
          res = 'The account already exists for that email.';
        }
      } else {
        res = err.toString();
      }
    }
    return res;
  }

  Future<String> updateUserPassword({
    required String uid,
    required String newPassword,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        // Update the password
        await user.updatePassword(newPassword);
        return "Success";
      } else {
        return "User not found or UID mismatch.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return "The password provided is too weak.";
      } else {
        return "An error occurred while updating the password: ${e.message}";
      }
    }
  }

  /* Delete current user account */
  Future<String> deleteUser({
    required String uid,
    required String email,
    required String password,
  }) async {
    String res = "Enter valid credentials";
    try {
      if (email.isNotEmpty && uid.isNotEmpty) {
        // Delete the user
        await _usersCollection.doc(uid).delete();
        await _auth.currentUser!.delete();
        await StorageMethods().deleteImageFromStorage('profileImages/$uid');
        res = "Success";
      } 
    } catch (err) {
      if (err is FirebaseAuthException) {  
        if (err.code == 'invalid-email') {
          res = 'The email is badly formatted.';
        } else if (err.code == 'weak-password') {
          res = 'The password must be 6 characters long or more.';
        } else if (err.code == 'email-already-in-use') {
          res = 'The account already exists for that email.';
        }
      } else {
        res = err.toString();
        if (kDebugMode) {
          print(res);
        }
      }
    }
    return res;
  }

  Future<String> updateUserProfile({
    required String uid,
    String? username,
    required String userType,
    String? email,
    String? password,
    Map<String, String>? deviceTokens,
    model.Profile? profile
  }) async {
    String res = "Enter valid credentials";
    try {
      if (userType.isNotEmpty && profile != null) {
        
        model.User user = model.User(
          uid: uid,
          username: username,
          userType: userType,
          email: email,
          password: password,
          profile: profile,
        );
        await _usersCollection.doc(uid).update(user.toJson());
        res = "Success";
      } 
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> updateUserProfileDetails({
    required String uid,
    required String userType,
    required String program,
    required String department,
    required String year,
    required String section,
    String? officerPosition,
    String? organization,
  }) async {
    try {
      // Create a map of the profile data to update
      Map<String, dynamic> profileData = {
        'profile.program': program,
        'profile.department': department,
        'profile.year': year,
        'profile.section': section,
      };

      // If the user is an Officer, add additional fields
      if (userType == 'Officer') {
        profileData.addAll({
          'profile.officerPosition': officerPosition,
          'profile.organization': organization,
        });
      }

      // Update the user's profile in Firestore
      await _usersCollection.doc(uid).update(profileData);
      return "Success";
    } on FirebaseException catch (e) {
      return "Failed to update profile: ${e.message}";
    }
  }


  // Stream function to get all users
  Stream<List<model.User>> getAllUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => model.User.fromSnap(doc)).toList();
    });
  }

  // Stream function to get all user's userType
  Stream<List<String>> getUniqueUserTypes() {
    return getAllUsers().map((users) {
      Set<String> userTypes = <String>{};
      for (var user in users) {
        userTypes.add(user.userType!);
      }
      List<String> userTypesList = userTypes.toList();
      userTypesList.removeWhere((item) => item == 'Admin' || item == 'SuperAdmin' || item == 'Guest');
      return userTypesList;
    });
  }

  // Get all users by user type
  Stream<List<model.User>> getUsersByUserType(String userType) {
    return _usersCollection
      .where('userType', isEqualTo: userType)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => model.User.fromSnap(doc)).toList();
      });
  }

  Future<List<model.User>> getAllInvitableUsers() async {
    List<model.User> users = [];
    List<String> userTypes = ['Student', 'Officer', 'Staff'];

    for (String userType in userTypes) {
      List<model.User> usersOfType = await getUsersByUserType(userType).first;
      users.addAll(usersOfType);
    }

    return users;
  }

  // Method to trash a user (move to 'trashedUsers' collection, set 'dateUpdated', and set 'disabled' flag)
  Future<String> trashUser(String userId) async {
    String response = 'Some error occurred';
    try {
      // Reference to the user document in Firestore
      DocumentReference userDocRef = _usersCollection.doc(userId);

      // Fetch the user details
      DocumentSnapshot userSnapshot = await userDocRef.get();
      if (!userSnapshot.exists) {
        throw Exception('No user found with id $userId');
      }
      model.User user = model.User.fromSnap(userSnapshot);

      // Set the 'disabled' flag to true in the user's Firestore document
      await userDocRef.update({'disabled': true});

      // Add the user to the 'trashedUsers' collection with the current date and time
      await _trashedUsersCollection.doc(userId).set({
        ...user.toJson(),
        'dateUpdated': FieldValue.serverTimestamp(), // Set the current date and time
      });

      // Remove the user from the 'users' collection
      await userDocRef.delete();

      response = 'Success';
    } on FirebaseException catch (err) {
      response = err.toString();
    }
    return response;
  }

  // Method to restore a trashed user (move back to 'users' collection, set 'dateUpdated', and clear 'disabled' flag)
  Future<String> restoreUser(String userId) async {
    String response = 'Some error occurred';
    try {
      // Reference to the trashed user document in Firestore
      DocumentReference trashedUserDocRef = _trashedUsersCollection.doc(userId);

      // Fetch the trashed user details
      DocumentSnapshot trashedUserSnapshot = await trashedUserDocRef.get();
      if (!trashedUserSnapshot.exists) {
        throw Exception('No trashed user found with id $userId');
      }
      model.User user = model.User.fromSnap(trashedUserSnapshot);

      // Clear the 'disabled' flag in the user's Firestore document
      await _usersCollection.doc(userId).update({'disabled': false});

      // Restore the user to the 'users' collection with the current date and time
      await _usersCollection.doc(userId).set({
        ...user.toJson(),
        'dateUpdated': FieldValue.serverTimestamp(), // Set the current date and time
      });

      // Remove the user from the 'trashedUsers' collection
      await trashedUserDocRef.delete();

      response = 'Success';
    } on FirebaseException catch (err) {
      response = err.toString();
    }
    return response;
  }

  // Method to permanently remove a trashed user
  Future<String> removeUserPermanently(String userId) async {
    String response = 'Some error occurred';
    try {
      // Reference to the trashed user document in Firestore
      DocumentReference trashedUserDocRef = _trashedUsersCollection.doc(userId);

      // Fetch the trashed user details
      DocumentSnapshot trashedUserSnapshot = await trashedUserDocRef.get();
      if (!trashedUserSnapshot.exists) {
        throw Exception('No trashed user found with id $userId');
      }
      model.User user = model.User.fromSnap(trashedUserSnapshot);

      // Delete the user's Firestore document
      await trashedUserDocRef.delete();

      // Delete the user's image from storage if necessary
      await StorageMethods().deleteImageFromStorage('profileImages/$userId');

      // Delete the user's account
      String deleteUserResponse = await deleteUser(
        uid: user.uid!,
        email: user.email!,
        password: user.password!,
      );

      if (deleteUserResponse == "Success") {
        response = 'User permanently removed';
      } else {
        response = deleteUserResponse;
      }
    } on FirebaseException catch (err) {
      response = err.toString();
    }
    return response;
  }

  // Method to get a stream of all trashed users
  Stream<List<model.User>> getTrashedUsers() {
    return _trashedUsersCollection.snapshots().map((QuerySnapshot query) {
      List<model.User> trashedUsers = [];
      for (var doc in query.docs) {
        model.User user = model.User.fromSnap(doc);
        trashedUsers.add(user);
      }
      return trashedUsers;
    });
  }

  // Add this method to the FireStoreUserMethods class
  Future<bool> isUserTrashed(String userId) async {
    DocumentSnapshot trashedUserSnapshot = await _trashedUsersCollection.doc(userId).get();
    return trashedUserSnapshot.exists;
  }


}
