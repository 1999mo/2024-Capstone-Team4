import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    // 1초 후 화면 전환
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/user_auth/login_screen');
    });
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/splash.png',
        fit: BoxFit.cover, // 화면에 꽉 채움
        width: double.infinity, // 가로 크기를 화면에 맞춤
        height: double.infinity, // 세로 크기를 화면에 맞춤
      ),
    );
  }
}
