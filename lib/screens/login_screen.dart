
import 'package:bscs_chat/layouts/screen_layout.dart';
import 'package:bscs_chat/resources/auth_methods.dart';
import 'package:bscs_chat/screens/sign_up_screen.dart';
import 'package:bscs_chat/widgets/cs_signin_button.dart';
import 'package:bscs_chat/widgets/login_divider.dart';
import 'package:bscs_chat/widgets/sign_up_navigation.dart';
import 'package:bscs_chat/widgets/text_field_input.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(); // Controller for the email input field
  final TextEditingController _passwordController = TextEditingController(); // Controller for the password input field
  bool _isLoading = false; // State variable for loading status

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose(); // Dispose email controller
    _passwordController.dispose(); // Dispose password controller
  }

  Future<void> signIn() async {
    // Show a loading dialog
    BuildContext? dialogContext;
    showDialog(
      context: context,
      builder: (context) {
        dialogContext = context;
        return const Center(child: CircularProgressIndicator());
      },
    );

    // Add a slight delay to ensure the dialog has displayed
    await Future.delayed(const Duration(milliseconds: 100));

    String res = await AuthMethods().signIn(
      email: _emailController.text.trim(), // Trimmed email input
      password: _passwordController.text.trim(), // Trimmed password input
    );

    // Handle sign-in result
    if (dialogContext != null) {
      // ignore: use_build_context_synchronously
      Navigator.of(dialogContext!).pop();
    }

    if (res == 'Success') {
      onSignInSuccess(res);
    } else {
      onSignInFailure(res);
    }
  }

  void navigateToSignup() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const SignUpScreen()
        )
      );
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential? userCredential = await AuthMethods().signInWithGoogle();
      if (userCredential != null) {
        // Handle successful sign-in
        mounted ? Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ScreenLayout())) : '';
      } else {
        // Handle sign-in failure
        onSignInFailure("Sign in failed");
      }
    } catch (e) {
      onSignInFailure(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  void onSignInSuccess(String message) async {
    // Handle successful sign-in
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ScreenLayout()));
  
  }

  void onSignInFailure(String message) {
    // Handle sign-in failure
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Build the login screen UI
      return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      flex: 1,
                      child: Container(),
                    ),
                    // Logo
                    const Padding(
                      padding: EdgeInsets.only(top: 25),
                    ),
                    // School name and address
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    // text field input for email
                    const Text('Log in',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 24.0),
                    // Text field input for email address
                    TextFieldInput(
                      prefixIcon: const Icon(Icons.email_outlined),
                      textEditingController: _emailController,
                      labelText: 'Email',
                      textInputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16.0),
                    // Text field input for password
                    TextFieldInput(
                      prefixIcon: const Icon(Icons.lock_outline),
                      textEditingController: _passwordController,
                      labelText: 'Password',
                      textInputType: TextInputType.visiblePassword,
                      isRegistration: false,
                      isPass: true,
                    ),
                    const SizedBox(height: 16.0),
                    // Sign in button
                    CSSignInButton(signIn: signIn),
                    const SizedBox(height: 12.0),
                    Flexible(
                      flex: 2,
                      child: Container(),
                    ),
                    SignUpNavigation(navigateToSignup: navigateToSignup),
                    const SizedBox(
                      height: 10,
                    ),
                    // Login Divider
                    const LoginDivider(),
                    const SizedBox(
                      height: 10,
                    ),
                    SignInButton(
                      Buttons.Google,
                      text: _isLoading ? "Loading..." : "Sign up with Google",
                      onPressed: () async {
                        if (!_isLoading) {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await signInWithGoogle();
                          } catch(e) {
                            if(e is FirebaseAuthException){
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e.message!),
                                duration: const Duration(seconds: 2),
                              ));
                            }
                          }
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
