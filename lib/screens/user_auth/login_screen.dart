import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용
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

  Scripts script = new Scripts();

  Future<void> _checkUserDocument(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final email = user.email!;
      final doc = await FirebaseFirestore.instance.collection('Users').doc(email).get();

      if (doc.exists) {
        // 문서가 존재하면 /main_screens/main_screen으로 이동
        Navigator.pushReplacementNamed(context, '/main_screens/main_screen');
      } else {
        // 문서가 없으면 /main_screens/make_profile로 이동
        Navigator.pushReplacementNamed(context, '/main_screens/make_profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사용자 데이터 확인 중 오류가 발생했습니다: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
              Image.asset(
                'assets/catcul_w.jpg',
                width: 120,
                height: 120,
              ),
              Container(
                width: 320,
                height: 44,
                margin: EdgeInsets.all(10),
                child: TextFormField(
                  decoration: InputDecoration(
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
                margin: EdgeInsets.all(10),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (newValue) {
                    password = newValue!;
                  },
                ),
              ),
              Container(
                color: Color(0xfffdbe85),
                width: 320,
                height: 44,
                child: TextButton(
                  onPressed: () async {
                    try {
                      _formKey.currentState!.save();

                      final currentUser = await _authentication.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // 로그인 성공 여부 확인
                      if (currentUser.user != null) {
                        if (!mounted) return;

                        // Firestore에서 사용자 문서 확인
                        await _checkUserDocument(context);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('아이디 혹은 비밀번호가 일치하지 않습니다.'),
                          duration: Duration(seconds: 2), // 스낵바 표시 시간
                        ),
                      );
                    }
                  },
                  child: Center(child: Text('로그인')),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/user_auth/signup');
                    },
                    child: Text('회원가입'),
                  ),
                  Container(
                    height: 20, // 경계선 높이
                    width: 1, // 경계선 두께
                    color: Colors.grey, // 경계선 색상
                    margin: EdgeInsets.symmetric(horizontal: 8), // 버튼 간 여백
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/user_auth/find_id');
                    },
                    child: Text('아이디/비밀번호 찾기'),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // 구글 간편 로그인 구현 로직
                  script.signInWithGoogle();
                  Navigator.pushReplacementNamed(context, '/main_screens/main_screen');
                },
                child: Text('구글 간편로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
