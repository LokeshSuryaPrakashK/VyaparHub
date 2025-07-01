import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/models/product_model.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/product_provider.dart';
import 'package:vyaparhub/backend/providers/user_provider.dart';

class MerchantProductScreen extends StatefulWidget {
  const MerchantProductScreen({super.key});

  @override
  MerchantProductScreenState createState() => MerchantProductScreenState();
}

class MerchantProductScreenState extends State<MerchantProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _editingProductId;

  @override
  void initState() {
    super.initState();
    Provider.of<CustomAuthProvider>(context, listen: false);
    Provider.of<UserModelProvider>(context, listen: false);
    Provider.of<ProductProvider>(context, listen: false);
    FirebaseAuth.instance.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider =
        Provider.of<CustomAuthProvider>(context, listen: false);
    authProvider.authStateChanges.listen((user) {
      if (user != null && mounted) {
        Provider.of<UserModelProvider>(context, listen: false)
            .fetchUserData(user.uid);
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      } else if (user == null) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateProduct(ProductProvider productProvider) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userModel =
        Provider.of<UserModelProvider>(context, listen: false).userModel;
    if (userModel == null || userModel.isUser) {
      context.go('/error?message=Only%20merchants%20can%20manage%20products');
      return;
    }
    final product = Product(
      id: _editingProductId ?? '',
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      merchantId: user.uid,
    );
    try {
      if (_editingProductId == null) {
        await productProvider.addProduct(product);
      } else {
        await productProvider.updateProduct(product);
      }
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _editingProductId = null;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully')),
      );
    } catch (e) {
      context.go('/error?message=Failed%20to%20save%20product:%20$e');
    }
  }

  void _editProduct(Product product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _editingProductId = product.id;
    setState(() {});
  }

  Future<void> _deleteProduct(
      ProductProvider productProvider, String productId) async {
    try {
      await productProvider.deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      context.go('/error?message=Failed%20to%20delete%20product:%20$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final userProvider = Provider.of<UserModelProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final userModel = userProvider.userModel;
    final products = productProvider.products;

    return Scaffold(
      body: authProvider.isLoading ||
              userProvider.isLoading ||
              productProvider.isLoading ||
              userModel == null
          ? const Center(child: CircularProgressIndicator())
          : userModel.isUser
              ? const Center(child: Text('Only merchants can access this page'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Product Name'),
                      ),
                      TextField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                      ),
                      TextField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: productProvider.isLoading
                            ? null
                            : () => _addOrUpdateProduct(productProvider),
                        child: Text(_editingProductId == null
                            ? 'Add Product'
                            : 'Update Product'),
                      ),
                      const SizedBox(height: 16),
                      products == null || products.isEmpty
                          ? const Text('No products available')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                if (product.merchantId !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  return const SizedBox.shrink();
                                }
                                return ListTile(
                                  title: Text(product.name),
                                  subtitle: Text(
                                      '\$${product.price} - ${product.description}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editProduct(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteProduct(
                                            productProvider, product.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
