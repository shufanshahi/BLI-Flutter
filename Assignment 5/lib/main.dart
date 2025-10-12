import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './home.dart';
import './sign_in.dart';
import './update_password.dart';
import './landing_page.dart';
import './profile.dart';
import './cart_page.dart';
import './purchase_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pxtbhidirsybawafhbjo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4dGJoaWRpcnN5YmF3YWZoYmpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3NDI4MzcsImV4cCI6MjA3NTMxODgzN30.6IZLz4UooCOKYmgJXQpBiBVXtKzDDOFQLtUfbnMBHNI',
  );
  runApp(ProviderScope(
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/landing',
      routes: {
        '/landing': (context) => const LandingPage(),
        '/': (context) => const SignUp(),
        '/update_password': (context) => const UpdatePassword(),
        '/home': (context) => const Home(),
        '/profile': (context) => const Profile(),
        '/cart': (context) => const CartPage(),
        '/purchase': (context) => const PurchasePage(),
      },
      onUnknownRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const Scaffold(
            body: Center(
              child: Text(
                'Not Found',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
