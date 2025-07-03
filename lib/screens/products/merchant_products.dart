import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/models/product_model.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/product_provider.dart';
import 'dart:async';

enum ProductCategory {
  Electronics,
  Clothing,
  Groceries,
  Books,
  General,
}

class MerchantProductScreen extends StatefulWidget {
  const MerchantProductScreen({super.key});

  @override
  MerchantProductScreenState createState() => MerchantProductScreenState();
}

class MerchantProductScreenState extends State<MerchantProductScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _editingProductId;
  ProductCategory _selectedCategory = ProductCategory.General;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final authProvider =
        Provider.of<CustomAuthProvider>(context, listen: false);
    print("Auth provider loaded in initState");
    _authSubscription = authProvider.authStateChanges.listen((user) {
      if (user != null && mounted) {
        print('user data fetched');
        Provider.of<CustomAuthProvider>(context, listen: false)
            .fetchUserData(user.uid);
        print('products fetched');
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      } else if (user == null) {
        print('No user, redirecting to login');
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateProduct(ProductProvider productProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser!;
    final userModel =
        Provider.of<CustomAuthProvider>(context, listen: false).userModel;
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
      productPhotoUrl: _photoUrlController.text,
      category: _selectedCategory.name,
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
      _photoUrlController.clear();
      _selectedCategory = ProductCategory.General;
      _editingProductId = null;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingProductId == null
              ? 'Product added successfully'
              : 'Product updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      context.go('/error?message=Failed%20to%20save%20product:%20$e');
    }
  }

  void _editProduct(Product product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _photoUrlController.text = product.productPhotoUrl ?? '';
    _selectedCategory = ProductCategory.values.firstWhere(
      (category) => category.name == product.category,
      orElse: () => ProductCategory.General,
    );
    _editingProductId = product.id;
    setState(() {});
  }

  void _cancelEdit() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _photoUrlController.clear();
    _selectedCategory = ProductCategory.General;
    _editingProductId = null;
    setState(() {});
  }

  Future<void> _deleteProduct(
      ProductProvider productProvider, String productId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await productProvider.deleteProduct(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      } catch (e) {
        context.go('/error?message=Failed%20to%20delete%20product:%20$e');
      }
    }
  }

  Future<void> _addStaticProduct(ProductProvider productProvider) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userModel =
        Provider.of<CustomAuthProvider>(context, listen: false).userModel;
    if (userModel == null || userModel.isUser) {
      context.go('/error?message=Only%20merchants%20can%20manage%20products');
      return;
    }
    final staticProduct = Product(
      id: '',
      name: 'Sample Product',
      description: 'A sample product for testing purposes',
      price: 29.99,
      merchantId: user.uid,
      productPhotoUrl:
          'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      category: ProductCategory.General.name,
    );
    try {
      await productProvider.addProduct(staticProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sample product added to Firestore'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      context.go('/error?message=Failed%20to%20add%20sample%20product:%20$e');
    }
  }

  Widget _buildProductForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _editingProductId == null
                        ? 'Add New Product'
                        : 'Edit Product',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (_editingProductId != null)
                    IconButton(
                      onPressed: _cancelEdit,
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel Edit',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Product Photo URL',
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductCategory>(
                    value: _selectedCategory,
                    onChanged: (ProductCategory? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items:
                        ProductCategory.values.map((ProductCategory category) {
                      return DropdownMenuItem<ProductCategory>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(category)),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    hint: const Text('Select Category'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: Provider.of<ProductProvider>(context).isLoading
                          ? null
                          : () => _addOrUpdateProduct(
                              Provider.of<ProductProvider>(context,
                                  listen: false)),
                      icon: Icon(
                          _editingProductId == null ? Icons.add : Icons.update),
                      label: Text(_editingProductId == null
                          ? 'Add Product'
                          : 'Update Product'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: Provider.of<ProductProvider>(context).isLoading
                        ? null
                        : () => _addStaticProduct(Provider.of<ProductProvider>(
                            context,
                            listen: false)),
                    icon: const Icon(Icons.add_box),
                    label: const Text('Sample'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    final userProducts = products
        .where((product) =>
            product.merchantId == FirebaseAuth.instance.currentUser!.uid)
        .toList();

    if (userProducts.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No products yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first product to get started',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Products',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${userProducts.length} ${userProducts.length == 1 ? 'product' : 'products'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: userProducts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = userProducts[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: product.productPhotoUrl != null &&
                          product.productPhotoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.productPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.broken_image,
                                color: Colors.grey[400]),
                          ),
                        )
                      : Icon(Icons.image_not_supported,
                          color: Colors.grey[400]),
                ),
                title: Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getCategoryIcon(ProductCategory.values.firstWhere(
                            (cat) => cat.name == product.category,
                            orElse: () => ProductCategory.General,
                          )),
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _editProduct(product),
                      tooltip: 'Edit Product',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _deleteProduct(
                          Provider.of<ProductProvider>(context, listen: false),
                          product.id),
                      tooltip: 'Delete Product',
                    ),
                  ],
                ),
                onTap: () => context.push('/product_details', extra: product),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.Electronics:
        return Icons.electrical_services;
      case ProductCategory.Clothing:
        return Icons.checkroom;
      case ProductCategory.Groceries:
        return Icons.local_grocery_store;
      case ProductCategory.Books:
        return Icons.menu_book;
      case ProductCategory.General:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final userProvider = Provider.of<CustomAuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final userModel = userProvider.userModel;
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: authProvider.isLoading ||
              userProvider.isLoading ||
              productProvider.isLoading ||
              userModel == null
          ? const Center(child: CircularProgressIndicator())
          : userModel.isUser
              ? Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Merchant Access Required',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Only merchants can access this page',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProductForm(),
                      _buildProductList(products ?? []),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
