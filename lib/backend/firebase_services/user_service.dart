import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vyaparhub/backend/models/address_model.dart';
import 'package:vyaparhub/backend/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(String uid, String email, bool isUser) async {
    try {
      UserModel userModel = UserModel(
        uid: uid,
        email: email,
        isUser: isUser,
      );
      await _firestore.collection('users').doc(uid).set(userModel.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserModel?> fetchUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<void> addAddress(String userId, Address address) async {
    try {
      final addressRef = _firestore.collection('addresses').doc();
      final newAddress = Address(
        id: addressRef.id,
        userId: userId,
        street: address.street,
        city: address.city,
        state: address.state,
        postalCode: address.postalCode,
        country: address.country,
        isDefault: address.isDefault,
      );
      await addressRef.set(newAddress.toMap());
      if (address.isDefault) {
        await _setDefaultAddress(userId, addressRef.id);
      }
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  Future<void> updateAddress(String addressId, Address address) async {
    try {
      await _firestore
          .collection('addresses')
          .doc(addressId)
          .update(address.toMap());
      if (address.isDefault) {
        await _setDefaultAddress(address.userId, addressId);
      }
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> _setDefaultAddress(String userId, String addressId) async {
    try {
      final addresses = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .get();
      for (var doc in addresses.docs) {
        if (doc.id != addressId) {
          await doc.reference.update({'isDefault': false});
        }
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'selectedAddressId': addressId});
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  Stream<List<Address>> getAddresses(String userId) {
    return _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Address.fromMap(doc.data())).toList());
  }
}
