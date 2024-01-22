import 'package:bscs_chat/layouts/screen_layout.dart';
import 'package:bscs_chat/models/profile.dart' as model;
import 'package:bscs_chat/resources/auth_methods.dart';
import 'package:bscs_chat/screens/login_screen.dart';
import 'package:bscs_chat/widgets/text_field_input.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleInitialController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _retypePasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> signUpAsClient() async {

    if (_firstNameController.text.trim().isEmpty      ||
        _middleInitialController.text.trim().isEmpty  ||
        _lastNameController.text.trim().isEmpty       ||
        _emailController.text.trim().isEmpty          ||
        _passwordController.text.trim().isEmpty       
    ) return onSignupFailure('Please complete all required fields.');

    // Validation for password
    if (_passwordController.text.trim() != _retypePasswordController.text.trim()) {
      onSignupFailure('Passwords do not match.');
      return;
    }

    String fullname = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    model.Profile profile = model.Profile(
      fullName: fullname,
      firstName: _firstNameController.text.trim(),
      middleInitial: _middleInitialController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    BuildContext? dialogContext;
    showDialog(context: context, builder: (context) {
      return const Center(child: CircularProgressIndicator());
    });

    // Add a slight delay to ensure the dialog has displayed
    await Future.delayed(const Duration(milliseconds: 100));

    String res = await AuthMethods().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        profile: profile,
        userType: 'Student');

    // ignore: unnecessary_null_comparison
    if (dialogContext != null) {
      mounted ? Navigator.of(dialogContext).pop() : '';
    }

    if (res == 'Success') {
      onSignupSuccess();
    } else {
      onSignupFailure(res);
    }
  }

  void onSignupSuccess() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ScreenLayout()));
  }

  void onSignupFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  void navigateToLogin() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _retypePasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // When screen touched, keyboard will be hidden
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
          body: SafeArea(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      children: [
                        Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(thickness: 1.0),
                  ),
                  Row(
                    children: [
                      // text field input for first name
                      Expanded(
                        child: TextFieldInput(
                          prefixIcon: const Icon(Icons.person),
                          textEditingController: _firstNameController,
                          labelText: 'First name*',
                          textInputType: TextInputType.text
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      // text field input for middle initial
                      Expanded(
                        child: TextFieldInput(
                          prefixIcon: const Icon(Icons.person),
                          textEditingController: _middleInitialController,
                          labelText: 'Middle Initial*',
                          textInputType: TextInputType.text
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      // text field input for last name
                      Expanded(
                        child: TextFieldInput(
                          prefixIcon: const Icon(Icons.person),
                          textEditingController: _lastNameController,
                          labelText: 'Last name*',
                          textInputType: TextInputType.text
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      // text field input for email
                      Expanded(
                        child: TextFieldInput(
                          prefixIcon: const Icon(Icons.email),
                          textEditingController: _emailController,
                          labelText: 'Email*',
                          textInputType: TextInputType.emailAddress
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  const Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '+63',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  // text field input for password
                  TextFieldInput(
                    prefixIcon: const Icon(Icons.lock),
                    textEditingController: _passwordController,
                    labelText: 'Password*',
                    textInputType: TextInputType.visiblePassword,
                    isPass: true,
                  ),
                  const SizedBox(height: 10.0),
                  TextFieldInput(
                    prefixIcon: const Icon(Icons.lock),
                    textEditingController: _retypePasswordController,
                    labelText: 'Retype Password*',
                    textInputType: TextInputType.visiblePassword,
                    isPass: true,
                  ),
                  const SizedBox(height: 12.0),
                  // button login
                  InkWell(
                      onTap: signUpAsClient,
                      child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          decoration: const ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0)),
                            ),
                          ),
                          child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Colors.white
                                  ),
                                ))),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        child: const Text('Already have an account?', style: TextStyle(
                          )
                          ,),
                      ),
                      GestureDetector(
                        onTap: navigateToLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          child: const Text(
                            ' Login here',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                  // transitioning to signing up
                ],
              ),
            ),
          )),
        ));
  }
}
