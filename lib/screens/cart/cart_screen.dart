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
      }
    });
  }

  Future<void> _placeOrder(BuildContext context) async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser!;
    final products = productProvider.products;

    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping address')),
      );
      return;
    }

    final itemsMap = {
      for (var item in cartProvider.items) item.productId: item.quantity
    };
    final total = cartProvider.getTotalPrice(products ?? []);
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
      context.go('/error?message=Failed%20to%20place%20order:%20$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final userProvider = Provider.of<CustomAuthProvider>(context);
    final cartItems = cartProvider.items;
    final products = productProvider.products;
    final addresses = userProvider.addresses;

    return productProvider.isLoading ||
            cartProvider.isLoading ||
            userProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : cartItems.isEmpty
            ? const Center(child: Text('Your cart is empty'))
            : products == null
                ? const Center(child: Text('No products available'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        DropdownButton<String>(
                          value: _selectedAddressId,
                          hint: const Text('Select Shipping Address'),
                          items: addresses.map((address) {
                            return DropdownMenuItem<String>(
                              value: address.id,
                              child: Text(
                                  '${address.street}, ${address.city}, ${address.state}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAddressId = value;
                            });
                          },
                        ),
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
                                  merchantId: ''),
                            );
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                  'Quantity: ${cartItem.quantity} - \$${product.price * cartItem.quantity}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: () {
                                  cartProvider.removeFromCart(
                                      FirebaseAuth.instance.currentUser!.uid,
                                      cartItem.productId);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
  }
}
