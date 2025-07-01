import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';

class NavScaffold extends StatelessWidget {
  final Widget child;

  const NavScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.hasData;
        return Scaffold(
          appBar: AppBar(
            title: const Text('VyaparHub'),
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 4,
            actions: [
              TextButton(
                onPressed: () => context.go('/home'),
                child:
                    const Text('Home', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => context.go('/products'),
                child: const Text('Products',
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: isAuthenticated
                    ? () => context.go('/cart')
                    : () => context.go('/login'),
                child:
                    const Text('Cart', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => context.go('/profile'),
                child: const Text('Profile',
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: isAuthenticated
                    ? () => context.go('/merchant_products')
                    : () => context.go('/login'),
                child: const Text('Merchant',
                    style: TextStyle(color: Colors.white)),
              ),
              if (isAuthenticated)
                TextButton(
                  onPressed: () async {
                    final authProvider =
                        Provider.of<CustomAuthProvider>(context, listen: false);
                    try {
                      await authProvider.signOut();
                      context.go('/login');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign out failed: $e')),
                      );
                    }
                  },
                  child: const Text('Logout',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          body: child,
        );
      },
    );
  }
}
