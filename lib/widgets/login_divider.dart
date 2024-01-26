import 'package:flutter/material.dart';

class LoginDivider extends StatelessWidget {
  const LoginDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey,
            height: 50,
            thickness: 2,
            indent: 20,
            endIndent: 20,
          ),
        ),
        Text('or continue with', style: TextStyle(color: Colors.grey),),
        Expanded(
          child: Divider(
            color: Colors.grey,
            height: 50,
            thickness: 2,
            indent: 20,
            endIndent: 20,
          ),
        ),
      ],
    );
  }
}
