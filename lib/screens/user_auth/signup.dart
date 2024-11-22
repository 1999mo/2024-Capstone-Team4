import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:catculator/main/script.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  bool? emailAuth; // 이메일 인증 여부
  bool phoneAuth = false; // 전화번호 인증 여부

  bool? emailDuplicate;
  bool? passwordSame;

  String email = '';
  String emailAuthCorrect = '';
  String emailAuthNum = '';
  String password = '';
  String confirmPassword = '';

  Scripts script = Scripts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
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
                const Text('이메일'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '이메일을 입력하세요',
                          ),
                          onSaved: (newValue) => email = newValue ?? '',
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () async {
                          _formKey.currentState!.save();
                          // 이메일 중복 확인 및 인증 번호 발송 로직
                          bool check = await script.checkEmailDuplicate(email);
                          if (check) {
                            setState(() {
                              emailDuplicate = true;
                            });
                            return;
                          }
                          emailAuthCorrect =
                              await script.sendEmailVerification(email);
                          setState(() {
                            emailDuplicate = false;
                          });
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('인증번호 발송'),
                                content: const Text('인증번호가 발송되었습니다.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // 팝업 닫기
                                    },
                                    child: const Text('확인'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('인증하기'),
                      ),
                    ],
                  ),

                if (emailDuplicate == false)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '사용 가능한 이메일 주소입니다.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                if (emailDuplicate == true)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '이미 가입된 이메일 주소입니다.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                // 이메일 인증번호
                const Text('이메일 인증번호'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '인증번호를 입력하세요',
                        ),
                        onSaved: (newValue) => emailAuthNum = newValue ?? '',
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () async {
                        _formKey.currentState!.save();
                        // 이메일 인증 확인 로직
                        setState(() {
                          emailAuth = (emailAuthCorrect == emailAuthNum);
                        });
                      },
                      child: const Text('인증 확인'),
                    ),
                  ],
                ),

                if (emailAuth == true)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '인증이 완료되었습니다.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                if (emailAuth == false)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '인증번호가 일치하지 않습니다.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                const SizedBox(height: 20), //공백주기

                // 비밀번호
                const Text('비밀번호'),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '비밀번호를 입력하세요',
                  ),
                  obscureText: true,
                  onSaved: (newValue) => password = newValue ?? '',
                ),

                const SizedBox(height: 20),

                // 비밀번호 확인
                const Text('비밀번호 확인'),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '비밀번호를 다시 입력하세요',
                  ),
                  obscureText: true,
                  onSaved: (newValue) => confirmPassword = newValue ?? '',
                ),
                if (passwordSame == false)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '비밀번호가 일치하지 않습니다.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                Row(
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('뒤로가기')),
                    TextButton(
                        onPressed: () async {
                          _formKey.currentState!.save();
                          final authentication = FirebaseAuth.instance;
                          try {
                            if (password != confirmPassword) {
                              setState(() {
                                passwordSame = false;
                              });
                              return;
                            } else {
                              setState(() {
                                passwordSame = true;
                              });
                            }

                            if(emailDuplicate==true) return;
                            if(emailAuth==false) return;

                            final newUser = await authentication
                                .createUserWithEmailAndPassword(
                                    email: email, password: password);
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('회원가입 완료'),
                                  content: const Text('회원가입이 완료되었습니다!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // 팝업 닫기
                                      },
                                      child: const Text('확인'),
                                    ),
                                  ],
                                );
                              },
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('오류 : $e'),
                                duration: const Duration(seconds: 2), // 표시 시간
                              ),
                            );
                          }
                        },
                        child: const Text('완료'))
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
