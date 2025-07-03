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

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isDefault = false;
  String? _editingAddressId;
  bool _isAddressFormExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final authProvider =
          Provider.of<CustomAuthProvider>(context, listen: false);
      await authProvider.signOut();
      context.go('/login');
    } catch (e) {
      _showSnackBar('Sign out failed: $e', isError: true);
    }
  }

  Future<void> _addOrUpdateAddress(CustomAuthProvider userProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      _showSnackBar('Please log in to manage addresses', isError: true);
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
      _clearForm();
      _showSnackBar('Address saved successfully', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to save address: $e', isError: true);
    }
  }

  void _clearForm() {
    _streetController.clear();
    _cityController.clear();
    _stateController.clear();
    _postalCodeController.clear();
    _countryController.clear();
    _isDefault = false;
    _editingAddressId = null;
    _isAddressFormExpanded = false;
    setState(() {});
  }

  void _editAddress(Address address) {
    _streetController.text = address.street;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _postalCodeController.text = address.postalCode;
    _countryController.text = address.country;
    _isDefault = address.isDefault;
    _editingAddressId = address.id;
    _isAddressFormExpanded = true;
    setState(() {});
  }

  Future<void> _setDefaultAddress(
      CustomAuthProvider userProvider, Address address) async {
    if (address.isDefault) return;
    try {
      await userProvider.updateAddress(
        userProvider.userModel?.uid ?? '',
        address.id!,
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
      _showSnackBar('Default address updated', isSuccess: true);
    } catch (e) {
      _showSnackBar('Failed to set default address: $e', isError: true);
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error
                  : (isSuccess ? Icons.check_circle : Icons.info),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : (isSuccess ? const Color(0xFF4CAF50) : const Color(0xFF1976D2)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomAuthProvider>(context);
    final userModel = authProvider.userModel;
    final addresses = authProvider.addresses ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: authProvider.isLoading || userModel == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF5F5F5),
                      const Color(0xFFF5F5F5).withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      _buildUserInfoCard(userModel),
                      const SizedBox(height: 20),

                      // Address Form Card
                      _buildAddressFormCard(authProvider),
                      const SizedBox(height: 20),

                      // Address List
                      _buildAddressListSection(addresses, authProvider),
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: _buildSignOutFAB(authProvider),
    );
  }

  Widget _buildUserInfoCard(userModel) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF212121),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your profile details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF757575),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.email, 'Email', userModel.email),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.badge,
              'Role',
              userModel.isUser ? 'User' : 'Merchant',
              badge: true,
            ),
            if (!userModel.isUser) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/merchant_products'),
                  icon: const Icon(Icons.store, size: 20),
                  label: const Text('Manage Products'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool badge = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF757575)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
              ),
        ),
        badge
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              )
            : Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
              ),
      ],
    );
  }

  Widget _buildAddressFormCard(CustomAuthProvider authProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isAddressFormExpanded = !_isAddressFormExpanded;
                });
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 24,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingAddressId == null
                              ? 'Add New Address'
                              : 'Edit Address',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF212121),
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your delivery addresses',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF757575),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isAddressFormExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: const Color(0xFF757575),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isAddressFormExpanded ? null : 0,
              child: _isAddressFormExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextFormField(
                                  _streetController, 'Street', Icons.home),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextFormField(_cityController,
                                        'City', Icons.location_city),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextFormField(
                                        _stateController, 'State', Icons.map),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextFormField(
                                        _postalCodeController,
                                        'Postal Code',
                                        Icons.markunread_mailbox),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextFormField(
                                        _countryController,
                                        'Country',
                                        Icons.flag),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CheckboxListTile(
                                  title: const Text('Set as Default Address'),
                                  value: _isDefault,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDefault = value!;
                                    });
                                  },
                                  activeColor: const Color(0xFF4CAF50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  if (_editingAddressId != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _clearForm,
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Cancel'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_editingAddressId != null)
                                    const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : () =>
                                              _addOrUpdateAddress(authProvider),
                                      icon: Icon(_editingAddressId == null
                                          ? Icons.add
                                          : Icons.save),
                                      label: Text(_editingAddressId == null
                                          ? 'Add Address'
                                          : 'Update Address'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF757575)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Postal Code' &&
            !RegExp(r'^\w{5,10}$').hasMatch(value.trim())) {
          return 'Enter a valid postal code (5-10 characters)';
        }
        return null;
      },
    );
  }

  Widget _buildAddressListSection(
      List<Address> addresses, CustomAuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF1976D2)),
            const SizedBox(width: 8),
            Text(
              'Saved Addresses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212121),
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${addresses.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1976D2),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        addresses.isEmpty
            ? _buildEmptyAddressState()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAddressCard(address, authProvider),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyAddressState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF757575).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off,
              size: 48,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No addresses added yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first address to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF757575),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address, CustomAuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    address.isDefault ? Icons.home : Icons.location_on,
                    size: 16,
                    color: address.isDefault
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${address.street}, ${address.city}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${address.state} ${address.postalCode}, ${address.country}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF757575),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editAddress(address),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: address.isDefault
                        ? null
                        : () => _setDefaultAddress(authProvider, address),
                    icon: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: address.isDefault ? Colors.grey : Colors.white,
                    ),
                    label: const Text('Set Default'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: address.isDefault
                          ? Colors.grey[300]
                          : const Color(0xFF4CAF50),
                      foregroundColor:
                          address.isDefault ? Colors.grey[600] : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutFAB(CustomAuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: authProvider.isLoading ? null : () => _signOut(context),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.logout),
        backgroundColor:
            authProvider.isLoading ? Colors.grey[300] : const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
