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
              return MainScreen();
            }
            return Splash();
          },),
      routes: {
        '/splash': (context) => Splash(),
        '/user_auth/login_screen': (context) => LoginScreen(),
        '/user_auth/signup': (context) => Signup(),
        '/user_auth/find_id': (context) => FindId(),
        '/main_screens/make_profile': (context) => MakeProfile(),
        '/main_screens/main_screen': (context) => MainScreen(),
        '/main_screens/setting': (context) => Setting(),
      },
    );
  }
}
