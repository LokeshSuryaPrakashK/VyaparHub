import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:vyaparhub/backend/providers/auth_provider.dart';
import 'package:vyaparhub/backend/providers/cart_provider.dart';
import 'package:vyaparhub/backend/providers/order_provider.dart';
import 'package:vyaparhub/backend/providers/product_provider.dart';
import 'package:vyaparhub/backend/providers/user_provider.dart';

class AppProvider {
  final List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (context) => CartProvider()),
    ChangeNotifierProvider(create: (context) => UserModelProvider()),
    ChangeNotifierProvider(create: (context) => CustomAuthProvider()),
    ChangeNotifierProvider(create: (context) => ProductProvider()),
    ChangeNotifierProvider(create: (context) => OrderProvider()),
  ];
}
