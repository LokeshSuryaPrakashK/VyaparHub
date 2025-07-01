import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/models/address_model.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
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
    Provider.of<CustomAuthProvider>(context, listen: false);
    Provider.of<UserModelProvider>(context, listen: false);
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
        Provider.of<UserModelProvider>(context, listen: false)
            .fetchAddresses(user.uid);
      }
    });
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
      context.go('/error?message=Sign%20out%20failed:%20$e');
    }
  }

  Future<void> _addOrUpdateAddress(UserModelProvider userProvider) async {
    final user = FirebaseAuth.instance.currentUser!;
    final address = Address(
      id: _editingAddressId ?? '',
      userId: user.uid,
      street: _streetController.text,
      city: _cityController.text,
      state: _stateController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
      isDefault: _isDefault,
    );
    try {
      if (_editingAddressId == null) {
        await userProvider.addAddress(user.uid, address);
      } else {
        await userProvider.updateAddress(_editingAddressId!, address);
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
      context.go('/error?message=Failed%20to%20save%20address:%20$e');
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final userProvider = Provider.of<UserModelProvider>(context);
    final userModel = userProvider.userModel;
    final addresses = userProvider.addresses;

    return Scaffold(
      body: authProvider.isLoading ||
              userProvider.isLoading ||
              userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${userModel.email}'),
                  Text('Role: ${userModel.isUser ? 'User' : 'Merchant'}'),
                  const SizedBox(height: 16),
                  if (!userModel.isUser)
                    ElevatedButton(
                      onPressed: () => context.go('/merchant_products'),
                      child: const Text('Manage Products'),
                    ),
                  const SizedBox(height: 16),
                  const Text('Addresses',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _streetController,
                    decoration: const InputDecoration(labelText: 'Street'),
                  ),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                  TextField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(labelText: 'Postal Code'),
                  ),
                  TextField(
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                  CheckboxListTile(
                    title: const Text('Set as Default'),
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value!;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: userProvider.isLoading
                        ? null
                        : () => _addOrUpdateAddress(userProvider),
                    child: Text(_editingAddressId == null
                        ? 'Add Address'
                        : 'Update Address'),
                  ),
                  const SizedBox(height: 16),
                  addresses.isEmpty
                      ? const Text('No addresses added')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            return ListTile(
                              title: Text(
                                  '${address.street}, ${address.city}, ${address.state}'),
                              subtitle: Text(
                                  '${address.postalCode}, ${address.country}${address.isDefault ? ' (Default)' : ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editAddress(address),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: address.isDefault
                                        ? null
                                        : () => userProvider.updateAddress(
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
                                            ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        authProvider.isLoading ? null : () => _signOut(context),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }
}
