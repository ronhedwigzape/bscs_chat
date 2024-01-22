import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

// This class provides different Firebase configuration options for different platforms. 
class DefaultFirebaseOptions {
  // Firebase configuration for web platform

  // Firebase configuration for Android platform
  static FirebaseOptions get androidPlatform {
    return const FirebaseOptions(
      // Replace these with actual values from Firebase console when setting up Firebase for Android app
      apiKey: "AIzaSyDDGkg8ZG26GT2j_wTlOR5Xj2JjLZh8AY0",
      appId: "1:777878936021:android:980072560145bcc0df855c",
      messagingSenderId: "777878936021",
      projectId: "student-event-calendar-dce10",
    );
  }

  // Firebase configuration for iOS platform
  static FirebaseOptions get iosPlatform {
    return const FirebaseOptions(
      // Replace these with actual values from Firebase console when setting up Firebase for iOS app
      apiKey: "AIzaSyDDGkg8ZG26GT2j_wTlOR5Xj2JjLZh8AY0",
      appId: "1:777878936021:ios:d06f0a15a482fe84df855c",
      messagingSenderId: "777878936021",
      projectId: "student-event-calendar-dce10",
    );
  }

  // Getter for current platform's Firebase configuration
  static FirebaseOptions get currentPlatform {
    // Checks on which platform the app currently runs and returns appropriate Firebase options
    if (Platform.isAndroid) {
      return androidPlatform;
    } else if (Platform.isIOS) {
      return iosPlatform;
    } else {
      // If the current platform is not web, nor Android, nor iOS, an UnsupportedError is thrown
      throw UnsupportedError('Unsupported platform');
    }
  }
}
