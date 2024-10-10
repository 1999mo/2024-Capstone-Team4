import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이미지 위젯
                Image.asset(
                  'assets/catcul_w.jpg', // 이미지 경로 확인
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 40), // 위젯 간격 조정

                // 아이디 입력란
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '아이디',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20), // 위젯 간격 조정

                // 비밀번호 입력란
                TextField(
                  controller: _passwordController,
                  obscureText: true, // 비밀번호 숨김
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20), // 위젯 간격 조정

                // 회원가입 버튼
                TextButton(
                  onPressed: () {
                    // 회원가입 버튼 클릭 시 동작할 코드
                    // 예를 들어, 회원가입 화면으로 이동할 수 있음
                  },
                  child: const Text(
                    '회원가입',
                    style: TextStyle(color: Colors.grey), // 옅은 회색 글씨
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
