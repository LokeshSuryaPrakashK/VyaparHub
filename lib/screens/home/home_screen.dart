import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/product_provider.dart';
import 'package:vyaparhub/backend/providers/cart_provider.dart';
import 'package:vyaparhub/backend/providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser;
    Provider.of<CustomAuthProvider>(context, listen: false);
    Provider.of<ProductProvider>(context, listen: false);
    Provider.of<CartProvider>(context, listen: false);
  }

  @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     Provider.of<UserModelProvider>(context, listen: false)
  //         .fetchUserData(user.uid);
  //     Provider.of<ProductProvider>(context, listen: false).fetchProducts();
  //     if (Provider.of<UserModelProvider>(context, listen: false)
  //         .isAuthenticated) {
  //       Provider.of<CartProvider>(context, listen: false)
  //           .fetchCartItems(user.uid);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-commerce App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : products == null || products.isEmpty
              ? const Center(child: Text('No products available'))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle:
                          Text('\$${product.price} - ${product.description}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            context.go('/login');
                          } else {
                            cartProvider.addToCart(user.uid, product.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${product.name} added to cart')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
