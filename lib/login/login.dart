import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:super_dash/game_intro/view/game_intro_page.dart';
import 'package:super_dash/login/username_page.dart';

class LoginGate extends StatelessWidget {
  final AuthenticationRepository authenticationRepository;

  const LoginGate({super.key, required this.authenticationRepository});

  Future<bool> _shouldShowUsernameScreen() async {
    final user = authenticationRepository.currentUser;
    if (user == null) return true;
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('users/${user.id}/username')
        .get();
    return !snapshot.exists;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowUsernameScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data!
            ? UsernameEntryPage(
                authenticationRepository: authenticationRepository)
            : const GameIntroPage(); // Go to main game page
      },
    );
  }
}
