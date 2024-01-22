import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SignUpNavigation extends StatelessWidget {
  const SignUpNavigation({super.key, required this.navigateToSignup});
  final VoidCallback navigateToSignup;

  @override
  Widget build(BuildContext context) {
    return !kIsWeb
    ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 15,
            ),
            child: const Text(
              'Don\'t have an account?',
            ),
          ),
          GestureDetector(
            onTap: navigateToSignup,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: const Text(
                ' Sign up.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      )
    : const SizedBox.shrink();
  }
}
