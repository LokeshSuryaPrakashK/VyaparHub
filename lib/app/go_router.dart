import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/app/error_screen.dart';
import 'package:vyaparhub/backend/models/product_model.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/screens/auth/login_screen.dart';
import 'package:vyaparhub/screens/auth/signup_screen.dart';
import 'package:vyaparhub/screens/cart/cart_screen.dart';
import 'package:vyaparhub/screens/home/home_screen.dart';
import 'package:vyaparhub/screens/products/merchant_products.dart';
import 'package:vyaparhub/screens/products/product_details.dart';
import 'package:vyaparhub/screens/products/products_screen.dart';
import 'package:vyaparhub/screens/profile/profile.dart';
import 'package:vyaparhub/widgets/scaffold.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/login',
    errorBuilder: (context, state) => ErrorScreen(
      errorMessage: state.error?.message ?? 'Page not found',
    ),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => NavScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
            redirect: (context, state) async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                return '/login';
              }
              return null;
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/merchant_products',
            builder: (context, state) => const MerchantProductScreen(),
            redirect: (context, state) async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                return '/login';
              }
              final userModel = await context
                  .read<CustomAuthProvider>()
                  .fetchUserData(user.uid);
              // if (userModel == null || userModel.isUser) {
              //   return '/error?message=Only%20merchants%20can%20access%20this%20page';
              // }
              return null;
            },
          ),
          GoRoute(
            path: '/product_details',
            builder: (context, state) {
              final product = state.extra as Product;
              return ProductDetailsScreen(product: product);
            },
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) {
              return ProductScreen();
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (user == null && !isAuthRoute) {
        return '/login';
      }
      if (user != null && isAuthRoute) {
        return '/home';
      }
      return null;
    },
  );
}
