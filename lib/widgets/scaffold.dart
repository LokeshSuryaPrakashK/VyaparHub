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
        return Consumer<CustomAuthProvider>(
          builder: (context, authProvider, _) {
            final isUser = authProvider.userModel?.isUser ?? true;
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'VyaparHub',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                actions: [
                  _buildNavButton(
                    context,
                    label: 'Home',
                    icon: Icons.home_outlined,
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(width: 8),
                  _buildNavButton(
                    context,
                    label: 'Products',
                    icon: Icons.store_outlined,
                    onPressed: () => context.go('/products'),
                  ),
                  const SizedBox(width: 8),
                  _buildNavButton(
                    context,
                    label: 'Cart',
                    icon: Icons.shopping_cart_outlined,
                    onPressed: isAuthenticated
                        ? () => context.go('/cart')
                        : () => context.go('/login'),
                  ),
                  const SizedBox(width: 8),
                  _buildNavButton(
                    context,
                    label: 'Profile',
                    icon: Icons.person_outline,
                    onPressed: () => context.go('/profile'),
                  ),
                  if (isAuthenticated && !isUser) ...[
                    const SizedBox(width: 8),
                    _buildNavButton(
                      context,
                      label: 'Merchant',
                      icon: Icons.business_center_outlined,
                      onPressed: () => context.go('/merchant_products'),
                    ),
                  ],
                  if (isAuthenticated) ...[
                    const SizedBox(width: 8),
                    _buildNavButton(
                      context,
                      label: 'Logout',
                      icon: Icons.logout,
                      onPressed: () async {
                        try {
                          await authProvider.signOut();
                          context.go('/login');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign out failed: $e')),
                          );
                        }
                      },
                    ),
                  ],
                  const SizedBox(width: 16),
                ],
              ),
              drawer:
                  _buildDrawer(context, isAuthenticated, isUser, authProvider),
              body: child,
            );
          },
        );
      },
    );
  }

  Widget _buildNavButton(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isAuthenticated, bool isUser,
      CustomAuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'VyaparHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your Business Companion',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              context.go('/home');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('Products'),
            onTap: () {
              context.go('/products');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Cart'),
            onTap: () {
              if (isAuthenticated) {
                context.go('/cart');
              } else {
                context.go('/login');
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              context.go('/profile');
              Navigator.pop(context);
            },
          ),
          if (isAuthenticated && !isUser)
            ListTile(
              leading: const Icon(Icons.business_center_outlined),
              title: const Text('Merchant'),
              onTap: () {
                context.go('/merchant_products');
                Navigator.pop(context);
              },
            ),
          if (isAuthenticated)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                try {
                  await authProvider.signOut();
                  context.go('/login');
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign out failed: $e')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
