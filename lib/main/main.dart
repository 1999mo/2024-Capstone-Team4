import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:catculator/screens/splash.dart';
import 'package:catculator/screens/user_auth/auth_screen_export.dart';
import 'package:catculator/screens/main_screens/main_screen_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "축제 도우미",
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(), builder: (context, snapshot) {
            if(snapshot.hasData) {
              return const MainScreen();
            }
            return const Splash();
          },),
      routes: {
        '/splash': (context) => const Splash(),
        '/user_auth/login_screen': (context) => const LoginScreen(),
        '/user_auth/signup': (context) => const Signup(),
        '/user_auth/find_id': (context) => const FindId(),
        '/main_screens/make_profile': (context) => const MakeProfile(),
        '/main_screens/main_screen': (context) => const MainScreen(),
        '/main_screens/setting': (context) => const Setting(),
      },
    );
  }
}