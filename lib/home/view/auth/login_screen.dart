import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_chess/values/colors.dart';

// File: lib/screens/login_screen.dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isLogin = true; // Toggle between login and sign up
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      debugPrint('Signed in: ${userCredential.user?.uid}');
    } catch (e) {
      debugPrint('Error signing in: $e');
      _showErrorSnackBar('Failed to sign in. Please check your credentials.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Set display name
      if (_nameController.text.isNotEmpty) {
        await userCredential.user?.updateDisplayName(_nameController.text);
      }

      debugPrint('Account created: ${userCredential.user?.uid}');
    } catch (e) {
      debugPrint('Error creating account: $e');
      _showErrorSnackBar('Failed to create account. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MyColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MyColors.darkBackground,
              MyColors.cardBackground,
              MyColors.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildWelcomeSection(),
                    const SizedBox(height: 40),
                    _buildAuthForm(),
                    const SizedBox(height: 20),
                    _buildToggleButton(),
                    const Spacer(),
                    _buildActionButton(),
                    const SizedBox(height: 20),
                    _buildTermsText(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MyColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyColors.lightGray.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_esports,
              size: 40,
              color: MyColors.lightGray,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isLogin ? 'Welcome Back!' : 'Join the Game!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MyColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? 'Sign in to continue your chess journey'
                : 'Create an account to start playing chess with players worldwide',
            style: const TextStyle(
              fontSize: 16,
              color: MyColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MyColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          if (!_isLogin) ...[
            _buildTextField(
              controller: _nameController,
              hintText: 'Enter your name',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Enter your password',
            icon: Icons.lock,
            isPassword: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: MyColors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: MyColors.mediumGray),
        prefixIcon: Icon(icon, color: MyColors.lightGray),
        filled: true,
        fillColor: MyColors.lightGray.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: MyColors.lightGray.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: MyColors.lightGray.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MyColors.lightGray, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: const TextStyle(
            color: MyColors.mediumGray,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(
              color: MyColors.lightGray,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : (_isLogin ? _signInWithEmail : _createAccount),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.lightGray,
          foregroundColor: MyColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: MyColors.white,
                strokeWidth: 2,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isLogin ? Icons.login : Icons.person_add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isLogin ? 'Sign In' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: const TextStyle(
        fontSize: 12,
        color: MyColors.mediumGray,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
