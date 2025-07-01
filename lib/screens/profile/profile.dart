import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/models/address_model.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isDefault = false;
  String? _editingAddressId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Provider.of<CustomAuthProvider>(context, listen: false)
        ..fetchUserData(user.uid)
        ..fetchAddresses(user.uid);
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final authProvider =
          Provider.of<CustomAuthProvider>(context, listen: false);
      await authProvider.signOut();
      context.go('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  Future<void> _addOrUpdateAddress(CustomAuthProvider userProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage addresses')),
      );
      return;
    }

    final newAddress = Address(
      id: _editingAddressId ?? '',
      userId: user.uid,
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      isDefault: _isDefault,
    );

    try {
      if (_editingAddressId == null) {
        await userProvider.addAddress(user.uid, newAddress);
      } else {
        await userProvider.updateAddress(
            user.uid, _editingAddressId!, newAddress);
      }
      if (_isDefault && _editingAddressId == null) {
        // Unset default for other addresses if new address is default
        for (var address in userProvider.addresses ?? []) {
          if (address.id != newAddress.id && address.isDefault) {
            await userProvider.updateAddress(
              user.uid,
              address.id,
              Address(
                id: address.id,
                userId: address.userId,
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country,
                isDefault: false,
              ),
            );
          }
        }
      }
      _streetController.clear();
      _cityController.clear();
      _stateController.clear();
      _postalCodeController.clear();
      _countryController.clear();
      _isDefault = false;
      _editingAddressId = null;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  void _editAddress(Address address) {
    _streetController.text = address.street;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _postalCodeController.text = address.postalCode;
    _countryController.text = address.country;
    _isDefault = address.isDefault;
    _editingAddressId = address.id;
    setState(() {});
  }

  Future<void> _setDefaultAddress(
      CustomAuthProvider userProvider, Address address) async {
    if (address.isDefault) return;
    try {
      await userProvider.updateAddress(
        userProvider.userModel?.uid ?? '',
        address.id,
        Address(
          id: address.id,
          userId: address.userId,
          street: address.street,
          city: address.city,
          state: address.state,
          postalCode: address.postalCode,
          country: address.country,
          isDefault: true,
        ),
      );
      // Unset default for other addresses
      for (var otherAddress in userProvider.addresses ?? []) {
        if (otherAddress.id != address.id && otherAddress.isDefault) {
          await userProvider.updateAddress(
            userProvider.userModel?.uid ?? '',
            otherAddress.id,
            Address(
              id: otherAddress.id,
              userId: otherAddress.userId,
              street: otherAddress.street,
              city: otherAddress.city,
              state: otherAddress.state,
              postalCode: otherAddress.postalCode,
              country: otherAddress.country,
              isDefault: false,
            ),
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default address updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set default address: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final userModel = authProvider.userModel;
    final addresses = authProvider.addresses ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: authProvider.isLoading || userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${userModel.email}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Role: ${userModel.isUser ? 'User' : 'Merchant'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (!userModel.isUser) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.go('/merchant_products'),
                              child: const Text('Manage Products'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Address Form
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add/Edit Address',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _streetController,
                              decoration: const InputDecoration(
                                labelText: 'Street',
                                hintText: 'Enter street address',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a street address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                hintText: 'Enter city',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a city';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                                hintText: 'Enter state',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a state';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _postalCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Postal Code',
                                hintText: 'Enter postal code',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a postal code';
                                }
                                if (!RegExp(r'^\w{5,10}$')
                                    .hasMatch(value.trim())) {
                                  return 'Enter a valid postal code (5-10 characters)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country',
                                hintText: 'Enter country',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a country';
                                }
                                return null;
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Set as Default'),
                              value: _isDefault,
                              onChanged: (value) {
                                setState(() {
                                  _isDefault = value!;
                                });
                              },
                              activeColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _addOrUpdateAddress(authProvider),
                              child: Text(_editingAddressId == null
                                  ? 'Add Address'
                                  : 'Update Address'),
                              style: ElevatedButton.styleFrom(
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Address List
                  Text(
                    'Saved Addresses (${addresses.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  addresses.isEmpty
                      ? Center(
                          child: Text(
                            'No addresses added',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  '${address.street}, ${address.city}, ${address.state}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  '${address.postalCode}, ${address.country}${address.isDefault ? ' (Default)' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: Theme.of(context).primaryColor,
                                      onPressed: () => _editAddress(address),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.check_circle,
                                        color: address.isDefault
                                            ? Colors.grey
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                      ),
                                      onPressed: address.isDefault
                                          ? null
                                          : () => _setDefaultAddress(
                                              authProvider, address),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: authProvider.isLoading ? null : () => _signOut(context),
        label: const Text('Sign Out'),
        icon: const Icon(Icons.logout),
        backgroundColor: authProvider.isLoading
            ? Colors.grey[300]
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}
