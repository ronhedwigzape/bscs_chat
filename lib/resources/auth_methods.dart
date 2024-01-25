import 'package:bscs_chat/models/profile.dart' as model;
import 'package:bscs_chat/models/user.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  // Initialize Firebase Auth and Firebase Firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user details
  Future<model.User?> getCurrentUserDetails() async {
    User currentUser = _auth.currentUser!;
    DocumentSnapshot snap = await _firestore.collection('users').doc(currentUser.uid).get();
    return model.User.fromSnap(snap);
  }

  // Get current user type
  Future<String> getCurrentUserType() async {
    final User currentUser = _auth.currentUser!;
    final DocumentSnapshot snap =
        await _firestore.collection('users').doc(currentUser.uid).get();
    return (snap.data() as Map<String, dynamic>)['userType'];
  }

  Future<String> signUp({
    required String email,
    required String password,
    String? username,
    required String userType,
    model.Profile? profile
  }) async {
    String res = "Enter valid credentials";
    try {
      // Check if all necessary information provided
      if (email.isNotEmpty && password.isNotEmpty && userType.isNotEmpty && profile != null) {

        // Create user in Firebase Auth
        UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        // Create user object for storing credentials in Firebase Firestore
        model.User user = model.User(
          uid: credential.user!.uid,
          email: email,
          username: username,
          userType: userType,
          profile: profile,
          password: password,
        );
        // Set user details in Firebase Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set(user.toJson());

        // Return success response
        res = "Success";
      } 
    } catch (err) {
      // Handle different error types from FirebaseAuth
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

  // Sign in user (Admin, Student, SASO Staff, Organization Officer)
  Future<String> signIn({required String email, required String password}) async {
    String response = "Enter valid credentials";
    Map<String, String>? deviceTokens = {};
    try {
      // Check if email and password is not empty
      if (email.isNotEmpty || password.isNotEmpty) {

        // Sign in with Firebase Authentication
        UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);

        // Initialize deviceToken with empty map
        await _firestore.collection('users').doc(credential.user!.uid).update({'deviceTokens': deviceTokens});

        // Return success response
        response = "Success";
      } else {
        response = "Please enter both email and password.";
      }
    } catch (err) {
      // Handle different error types from FirebaseAuth
      if (err is FirebaseAuthException) {
        if (err.code == 'user-not-found') {
          response = 'No user found for that email.';
        } else if (err.code == 'wrong-password') {
          response = 'Wrong password provided for that user.';
        }
      } else {
        response = err.toString();
      }
    }
    return response;
  }

  // Sign in with Google account
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out the existing user
      await signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      DocumentReference docRef = _firestore.collection('users').doc(userCredential.user!.uid);
      DocumentSnapshot docSnap = await docRef.get();
      if (docSnap.exists) {
        await docRef.update({
          'signedInWithGoogle': true,
        });
      } else {
        // Split the displayName into parts
        List<String> nameParts = userCredential.user!.displayName!.split(' ');

        // The first part is the first name
        String firstName = nameParts.first;

        // The last part is the last name
        String lastName = nameParts.last;

        // Create a new user object with the Google user's details
        model.User user = model.User(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          password: "",
          username: userCredential.user!.displayName,
          profile: model.Profile(
            fullName: userCredential.user!.displayName,
            firstName: firstName, // First name from Google
            middleInitial: "", // Not provided by Google
            lastName: lastName, // Last name from Google
            profileImage: userCredential.user!.photoURL, // Provided by Google
          ),
          signedInWithGoogle: true,
        );
        // Set the new user's details in Firestore
        await docRef.set(user.toJson());

      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(e.message ?? "FirebaseAuth error occurred");
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return null;
    }
    return null;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }


  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
    
  }
}
