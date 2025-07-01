import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';

class NavScaffold extends StatelessWidget {
  final Widget child;

  const NavScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VyaparHub'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Home', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: isAuthenticated
                ? () => context.go('/cart')
                : () => context.go('/login'),
            child: const Text('Cart', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Profile', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: isAuthenticated
                ? () => context.go('/merchant_products')
                : () => context.go('/login'),
            child:
                const Text('Merchant', style: TextStyle(color: Colors.black)),
          ),
          if (isAuthenticated)
            TextButton(
              onPressed: () async {
                await authProvider.signOut();
                context.go('/login');
              },
              child:
                  const Text('Logout', style: TextStyle(color: Colors.black)),
            ),
        ],
      ),
      body: child,
    );
  }
}
