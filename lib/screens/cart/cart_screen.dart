import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/models/product_model.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/cart_provider.dart';
import 'package:vyaparhub/backend/providers/order_provider.dart';
import 'package:vyaparhub/backend/providers/product_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
        Provider.of<CartProvider>(context, listen: false)
            .fetchCartItems(user.uid);
        Provider.of<CustomAuthProvider>(context, listen: false)
            .fetchAddresses(user.uid);
      } else {
        context.go('/login');
      }
    });
  }

  Future<void> _placeOrder(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order')),
      );
      return;
    }

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final products = productProvider.products ?? [];

    // Validations
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select a shipping address in Profile screen')),
      );
      return;
    }
    final itemsMap = {
      for (var item in cartProvider.items)
        if (products.any((p) => p.id == item.productId))
          item.productId: item.quantity,
    };
    if (itemsMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid products found in cart')),
      );
      return;
    }

    final total = cartProvider.getTotalPrice(products);
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid total price')),
      );
      return;
    }

    try {
      await orderProvider.placeOrder(
        user.uid,
        itemsMap,
        total,
        user.email!,
        shippingAddressId: _selectedAddressId!,
      );
      await cartProvider.clearCart(user.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final userProvider = Provider.of<CustomAuthProvider>(context);
    final cartItems = cartProvider.items;
    final products = productProvider.products ?? [];
    final addresses = userProvider.addresses ?? [];
    final totalPrice = cartProvider.getTotalPrice(products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: productProvider.isLoading ||
              cartProvider.isLoading ||
              userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Shop Now'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Selection
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shipping Address',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedAddressId,
                                hint: const Text('Select Shipping Address'),
                                items: addresses.map((address) {
                                  return DropdownMenuItem<String>(
                                    value: address.id,
                                    child: Text(
                                      '${address.street}, ${address.city}, ${address.state}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAddressId = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                validator: (value) => value == null
                                    ? 'Please select an address'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cart Items
                      Text(
                        'Cart Items (${cartItems.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final cartItem = cartItems[index];
                          final product = products.firstWhere(
                            (p) => p.id == cartItem.productId,
                            orElse: () => Product(
                              id: '',
                              name: 'Unknown Product',
                              price: 0,
                              description: '',
                              merchantId: '',
                              category: 'General',
                              productPhotoUrl: null,
                            ),
                          );
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
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
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Icon(Icons.error, size: 40),
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      size: 40),
                              title: Text(
                                product.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                'Price: \$${product.price.toStringAsFixed(2)}\n'
                                'Quantity: ${cartItem.quantity}\n'
                                'Total: \$${(product.price * cartItem.quantity).toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  cartProvider.removeFromCart(
                                    FirebaseAuth.instance.currentUser!.uid,
                                    cartItem.productId,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Total Price
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '\$${totalPrice.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: cartItems.isEmpty || products.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _placeOrder(context),
              label: const Text('Place Order'),
              icon: const Icon(Icons.check_circle),
              backgroundColor: Theme.of(context).primaryColor,
            ),
    );
  }
}
