import 'package:flutter/material.dart';

class CSSignInButton extends StatelessWidget {
  const CSSignInButton({super.key, required this.signIn});

  final VoidCallback signIn;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: signIn,
      child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 38, 13, 165),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
          ),
          child: const Text(
            'Log in',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          )),
    );
  }
}
