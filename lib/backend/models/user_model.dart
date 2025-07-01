class UserModel {
  final String uid;
  final String email;
  final bool isUser;
  final String? selectedAddressId;

  UserModel({
    required this.uid,
    required this.email,
    required this.isUser,
    this.selectedAddressId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'isUser': isUser,
      'selectedAddressId': selectedAddressId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      isUser: data['isUser'] ?? true,
      selectedAddressId: data['selectedAddressId'],
    );
  }
}
