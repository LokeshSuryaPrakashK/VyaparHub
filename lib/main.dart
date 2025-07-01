import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:vyaparhub/app/go_router.dart';
import 'package:vyaparhub/app/provider.dart';
import 'package:vyaparhub/const/theme.dart';
import 'package:vyaparhub/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProvider().providers,
      child: MaterialApp.router(
        title: 'VyaparHub',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        routerConfig: createRouter(),
      ),
    );
  }
}
