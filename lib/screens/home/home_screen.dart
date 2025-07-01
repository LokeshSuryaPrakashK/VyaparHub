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
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: product.productPhotoUrl != null &&
                              product.productPhotoUrl!.isNotEmpty
                          ? Image.network(
                              product.productPhotoUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(product.name),
                      subtitle: Text(
                          '\$${product.price} - ${product.description}\nCategory: ${product.category}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${product.name} added to cart')),
                          );
                        },
                      ),
                      onTap: () =>
                          context.push('/product_details', extra: product),
                    ),
                  );
                },
              );
  }
}
