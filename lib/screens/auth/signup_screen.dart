import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/user_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isMerchant = false;

  @override
  void initState() {
    super.initState();
    Provider.of<CustomAuthProvider>(context, listen: false);
    Provider.of<UserModelProvider>(context, listen: false);
    FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(
      CustomAuthProvider authProvider, UserModelProvider userProvider) async {
    try {
      await authProvider.signUp(
          _emailController.text, _passwordController.text, !_isMerchant);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await userProvider.fetchUserData(user.uid);
        await userProvider.fetchAddresses(user.uid);
      }
      context.go('/home');
    } catch (e) {
      context.go('/error?message=Sign%20up%20failed:%20$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final userProvider = Provider.of<UserModelProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            CheckboxListTile(
              title: const Text('Register as Merchant'),
              value: _isMerchant,
              onChanged: (value) {
                setState(() {
                  _isMerchant = value!;
                });
              },
            ),
            if (authProvider.isLoading || userProvider.isLoading)
              const CircularProgressIndicator(),
            ElevatedButton(
              onPressed: authProvider.isLoading || userProvider.isLoading
                  ? null
                  : () => _handleSignUp(authProvider, userProvider),
              child: const Text('Sign Up'),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
