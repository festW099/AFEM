import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'USER PROFILE',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}