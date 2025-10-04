// File: lib/chat/chat_room.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_chess/home/view/auth/login_screen.dart';
import 'package:the_chess/home/view/home_screen.dart';
 
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is signed in
          return ChessAppUI();
        } else {
          // User is not signed in
          return LoginScreen();
        }
      },
    );
  }
}
