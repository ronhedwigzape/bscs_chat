import 'package:bscs_chat/firebase_options.dart';
import 'package:bscs_chat/layouts/screen_layout.dart';
import 'package:bscs_chat/providers/user_provider.dart';
import 'package:bscs_chat/screens/login_screen.dart';
import 'package:bscs_chat/widgets/unknown_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as timezone;

void main() async {
  timezone.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Builder(builder: (context) {
        final theme = ThemeData.light();

        return OverlaySupport(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: theme.copyWith(
              textTheme: GoogleFonts.nunitoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            // showPerformanceOverlay: true,
            home: const AuthScreen(),
          ),
        );
      }),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  static bool runningOnMobile() {
    return !kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, userSnapshot) {
        if (userSnapshot.hasData) {
          // StreamBuilder for Firestore user document
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (ctx, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Check if document exists
              if (snapshot.hasData && snapshot.data!.exists) {
                if (runningOnMobile()) {
                  return const ScreenLayout();
                } else {
                  return const UnknownUser();
                }
              } else {
                // Handle case when the document does not exist
                if (runningOnMobile()) {
                  return const LoginScreen();
                } else {
                  return const Center(
                    child: Text('Unsupported Platform'),
                  );
                }
              }
            },
          );
        }
        if (runningOnMobile()) {
          return const LoginScreen();
        } else {
          return const Center(
            child: Text('Unsupported Platform'),
          );
        }
      },
    );
  }
}
