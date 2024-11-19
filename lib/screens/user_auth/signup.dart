import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  bool emailAuth = false; // 이메일 인증 여부
  bool phoneAuth = false; // 전화번호 인증 여부

  String email = '';
  String emailAuthNum = '';
  String phone = '';
  String phoneAuthNum = '';
  String password = '';
  String confirmPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이메일
                Text('이메일'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '이메일을 입력하세요',
                        ),
                        onSaved: (newValue) => email = newValue ?? '',
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _formKey.currentState!.save();
                        // 이메일 중복 확인 및 인증 번호 발송 로직
                        //
                        //
                        //
                      },
                      child: Text('인증하기'),
                    ),
                  ],
                ),
                if (emailAuth)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '사용 가능한 이메일 주소입니다.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),

                // 이메일 인증번호
                Text('이메일 인증번호'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '인증번호를 입력하세요',
                        ),
                        onSaved: (newValue) => emailAuthNum = newValue ?? '',
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _formKey.currentState!.save();
                        // 이메일 인증 확인 로직
                        //
                        //
                        //
                        //
                      },
                      child: Text('인증 확인'),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // 전화번호
                Text('전화번호'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '전화번호를 입력하세요',
                        ),
                        onSaved: (newValue) => phone = newValue ?? '',
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _formKey.currentState!.save();
                        //전화 번호 중복 확인 및 인증 번호 발송 로직
                        //
                        //
                        //
                      },
                      child: Text('인증하기'),
                    ),
                  ],
                ),
                if (phoneAuth)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '사용 가능한 전화번호입니다.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),

                // 전화번호 인증번호
                Text('전화번호 인증번호'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '인증번호를 입력하세요',
                        ),
                        onSaved: (newValue) => phoneAuthNum = newValue ?? '',
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _formKey.currentState!.save();
                        // 전화번호 인증 확인 로직
                        //
                        //
                        //
                        //
                      },
                      child: Text('인증 확인'),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // 비밀번호
                Text('비밀번호'),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '비밀번호를 입력하세요',
                  ),
                  obscureText: true,
                  onSaved: (newValue) => password = newValue ?? '',
                ),

                SizedBox(height: 20),

                // 비밀번호 확인
                Text('비밀번호 확인'),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '비밀번호를 다시 입력하세요',
                  ),
                  obscureText: true,
                  onSaved: (newValue) => confirmPassword = newValue ?? '',
                ),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('뒤로가기')),
                    ElevatedButton(onPressed: () async {
                      _formKey.currentState!.save();
                      final _authentication=FirebaseAuth.instance;
                      try{
                        final newUser=await _authentication.createUserWithEmailAndPassword(email: email, password: password);
                        if(!mounted) return;
                        Navigator.pop(context);
                      } catch(e) {

                      }
                    }, child: Text('완료'))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
