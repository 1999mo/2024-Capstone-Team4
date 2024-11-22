// Firestore 사용
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:catculator/main/script.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authentication = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  Scripts script = Scripts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '로그인',
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/catcul_w.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                width: 320,
                height: 44,
                margin:
                    const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 5),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (newValue) {
                    email = newValue!;
                  },
                ),
              ),
              Container(
                width: 320,
                height: 44,
                margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (newValue) {
                    password = newValue!;
                  },
                ),
              ),
              Container(
                width: 320,
                height: 44,
                margin:
                    const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xfffdbe85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton(
                  onPressed: () async {
                    try {
                      _formKey.currentState!.save();
                      final currentUser =
                          await _authentication.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      Navigator.pushReplacementNamed(
                          context, '/main_screens/make_profile');
                      // 로그인 성공 여부 확인
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('아이디 혹은 비밀번호가 일치하지 않습니다.'),
                          duration: Duration(seconds: 2), // 스낵바 표시 시간
                        ),
                      );
                    }
                  },
                  child: const Center(child: Text('로그인')),
                ),
              ),
              SizedBox(
                width: 320,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/user_auth/signup');
                      },
                      child: const Text('회원가입'),
                    ),
                    Container(
                      height: 20, // 경계선 높이
                      width: 1, // 경계선 두께
                      color: Colors.grey, // 경계선 색상
                      margin: const EdgeInsets.symmetric(horizontal: 8), // 버튼 간 여백
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/user_auth/find_id');
                      },
                      child: const Text('비밀번호 찾기'),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                child: Container(
                  width: 320,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black, // 외곽선 색상
                      width: 1.0,       // 외곽선 두께
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/google_logo.png', width: 22, height: 22,),
                      const Text('구글 계정으로 계속'),
                    ],
                  ),
                ),
                onTap: () async {
                  // 구글 간편 로그인 구현 로직
                  final user = await script.signInWithGoogle();
                  print("Try logging in with google");
                  print(user);
                  if (user != null) {
                    Navigator.pushReplacementNamed(
                        context, '/main_screens/make_profile');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('구글로그인 실패'),
                      duration: Duration(seconds: 1),
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
