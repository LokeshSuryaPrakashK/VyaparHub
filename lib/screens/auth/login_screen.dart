import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<CustomAuthProvider>(context, listen: false);
    FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(CustomAuthProvider authProvider) async {
    try {
      await authProvider.signIn(
          _emailController.text, _passwordController.text);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await authProvider.fetchUserData(user.uid);
        await authProvider.fetchAddresses(user.uid);
      }
      context.go('/home');
    } catch (e) {
      context.go('/error?message=Sign%20in%20failed:%20$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
            if (authProvider.isLoading || authProvider.isLoading)
              const CircularProgressIndicator(),
            ElevatedButton(
              onPressed: authProvider.isLoading || authProvider.isLoading
                  ? null
                  : () => _handleSignIn(authProvider),
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
