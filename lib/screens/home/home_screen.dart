import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/cart_provider.dart';
import 'package:vyaparhub/backend/providers/product_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          Provider.of<CustomAuthProvider>(context, listen: false);

      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      if (authProvider.isAuthenticated) {
        Provider.of<CartProvider>(context, listen: false)
            .fetchCartItems(authProvider.userModel?.uid ?? "");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final products = productProvider.products;

    return productProvider.isLoading || authProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : products == null
            ? const Center(child: Text('No products available'))
            : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('\$${product.price}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () async {
                        if (!authProvider.isAuthenticated) {
                          context.go('/login');
                          return;
                        }
                        try {
                          await cartProvider.addToCart(
                              authProvider.userModel?.uid ?? "", product.id);
                        } catch (e) {
                          context.go(
                              '/error?message=Failed%20to%20add%20to%20cart:%20$e');
                        }
                      },
                    ),
                  );
                },
              );
  }
}
