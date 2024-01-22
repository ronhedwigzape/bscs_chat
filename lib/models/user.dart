import 'package:bscs_chat/models/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String? uid;
  String? userType;
  String? username;
  String? password;
  String? email;
  Profile? profile;
  final bool signedInWithGoogle;

  User({
    this.uid,
    this.userType,
    this.username,
    this.password,
    this.email,
    this.profile, 
    this.signedInWithGoogle = false
  });

  // Convert User object to JSON
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'userType': userType,
        'username': username,
        'password': password,
        'email': email,
        'profile': profile?.toJson(),
        'signedInWithGoogle': signedInWithGoogle,
      };

  // Create User object from DocumentSnapshot
  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    var profileSnap = snapshot['profile'] as Map<String, dynamic>;

    return User(
      uid: snapshot['uid'],
      userType: snapshot['userType'],
      username: snapshot['username'],
      password: snapshot['password'],
      email: snapshot['email'],
      profile: Profile.fromMap(profileSnap),
      signedInWithGoogle: snapshot['signedInWithGoogle'] ?? false,
    );
  }
}
