import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

// This class provides different Firebase configuration options for different platforms. 
class DefaultFirebaseOptions {
  // Firebase configuration for web platform

  // Firebase configuration for Android platform
  static FirebaseOptions get androidPlatform {
    return const FirebaseOptions(
      // Replace these with actual values from Firebase console when setting up Firebase for Android app
      apiKey: "AIzaSyCmes3OFjY2rZyZTj0Ir7gw4Jl7k61iISU",
      appId: "1:97362035713:android:33fe4bbda188a3140eac00",
      messagingSenderId: "97362035713",
      projectId: "bscs-android-chat",
    );
  }
  // Getter for current platform's Firebase configuration
  static FirebaseOptions get currentPlatform {
    // Checks on which platform the app currently runs and returns appropriate Firebase options
    if (Platform.isAndroid) {
      return androidPlatform;
    } else {
      // If the current platform is not web, nor Android, nor iOS, an UnsupportedError is thrown
      throw UnsupportedError('Unsupported platform');
    }
  }
}
