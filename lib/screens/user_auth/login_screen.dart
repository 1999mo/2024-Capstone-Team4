import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email='';
  String password='';
  final _formKey=GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
      ),

      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/catcul_w.jpg'),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
                onSaved: (newValue) {
                  email=newValue!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                onSaved: (newValue) {
                  password=newValue!;
                },
              ),
              ElevatedButton(onPressed: () {
                
              }, child: Text('로그인')),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: () {

                  }, child: Text('회원가입'),),
                  ElevatedButton(onPressed: () {

                  }, child: Text('아이디/비밀번호 찾기'))

                ],
              ),
              
              ElevatedButton(onPressed: () {
                
              }, child: Text('구글 간편로그인'))
            ],
          ),
        ),
      ),
    );
  }
}
