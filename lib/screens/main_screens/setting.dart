import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushNamed(context, '/splash');
            }, child: Text('로그아웃'))
          ],
        ),
      ),
    );
  }
}
