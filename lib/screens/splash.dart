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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/catcul_w.jpg', height: 150, width: 150,),
            Text(
                "축제 필수템!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                )
            ),
            Text(
                "축제 도우미 앱",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                )
            ),

          ],
        ),
      ),
    );
  }
}
