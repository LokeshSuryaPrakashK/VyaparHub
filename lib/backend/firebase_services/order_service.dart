import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> placeOrder(
    String userId,
    Map<String, int> items,
    double total,
    String email, {
    required String shippingAddressId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc();
      await orderRef.set({
        'userId': userId,
        'items': items,
        'total': total,
        'createdAt': FieldValue.serverTimestamp(),
        'shippingAddressId': shippingAddressId,
      });

      final response = await http.post(
        Uri.parse(
            'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendThankYouEmail'),
        body: {
          'email': email,
          'orderId': orderRef.id,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send thank-you email');
      }
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }
}
