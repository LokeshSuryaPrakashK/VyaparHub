import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/models/product_model.dart';
import 'package:vyaparhub/backend/providers/cart_provider.dart';
import 'package:vyaparhub/backend/providers/product_provider.dart';

enum ProductCategory { Electronics, Clothing, Groceries, Books, General }

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  ProductScreenState createState() => ProductScreenState();
}

class ProductScreenState extends State<ProductScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
    _tabController =
        TabController(length: ProductCategory.values.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products, String category) {
    if (category == 'All') return products;
    return products.where((product) => product.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: 'All'),
            ...ProductCategory.values
                .map((category) => Tab(text: category.name)),
          ],
        ),
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 80, color: Color(0xFF757575)),
                      const SizedBox(height: 16),
                      Text(
                        'No products available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF757575),
                            ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // All Products
                    _buildProductList(context, products, 'All'),
                    // Category-specific lists
                    ...ProductCategory.values.map((category) =>
                        _buildProductList(context, products, category.name)),
                  ],
                ),
    );
  }

  Widget _buildProductList(
      BuildContext context, List<Product> products, String category) {
    final filteredProducts = _filterProducts(products, category);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: filteredProducts.isEmpty
          ? Center(
              child: Text(
                'No products in $category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF757575),
                    ),
              ),
            )
          : ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: product.productPhotoUrl != null &&
                              product.productPhotoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.productPhotoUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error,
                                        size: 40, color: Color(0xFFD32F2F)),
                              ),
                            )
                          : const Icon(Icons.image_not_supported,
                              size: 40, color: Color(0xFF757575)),
                      title: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        '\$${product.price.toStringAsFixed(2)}\nCategory: ${product.category}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            context.push('/login');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please log in to add to cart')),
                            );
                            return;
                          }
                          if (product.id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Invalid product ID')),
                            );
                            return;
                          }
                          Provider.of<CartProvider>(context, listen: false)
                              .addToCart(user.uid, product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${product.name} added to cart')),
                          );
                        },
                      ),
                      onTap: () =>
                          context.push('/product_details', extra: product),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
