import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:catculator/script.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  bool? emailAuth;
  bool phoneAuth = false;

  bool? emailDuplicate;
  bool? passwordSame;
  bool authProgress = false;
  bool checkProgress=false;
  bool confirmProgress=false;

  String email = '';
  String emailAuthCorrect = '';
  String emailAuthNum = '';
  String password = '';
  String confirmPassword = '';

  Scripts script = Scripts();

  bool isEmailValid(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 전체 화면 여백 추가
          child: ListView(
            children: [
              const SizedBox(height: 20),
              // 이메일
              const Text(
                '이메일',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '이메일을 입력하세요',
                        ),
                        onSaved: (newValue) => email = newValue ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    margin: EdgeInsets.only(bottom: 15),
                    height: 60,
                    width: 85,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDBE85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        setState(() {
                          authProgress = true;
                        });
                        _formKey.currentState!.save();
                        if (!isEmailValid(email.trim())) {
                          setState(() {
                            emailDuplicate = true;
                          });
                          authProgress = false;
                          return;
                        }
                        bool check = await script.checkEmailDuplicate(email);
                        if (check) {
                          setState(() {
                            emailDuplicate = true;
                          });
                          authProgress = false;
                          return;
                        }

                        emailAuthCorrect = await script.sendEmailVerification(email);
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
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('확인'),
                                ),
                              ],
                            );
                          },
                        );
                        setState(() {
                          authProgress = false;
                        });
                      },
                      child: authProgress
                          ? const CircularProgressIndicator()
                          : const Text(
                              '인증하기',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                    ),
                  ),
                ],
              ),
              if (emailDuplicate == false)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '사용 가능한 이메일 주소입니다.',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              if (emailDuplicate == true)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '이메일 형식이 유효하지 않거나 이미 가입된 이메일 주소입니다.',
                    style: TextStyle(color: Colors.red),
                    maxLines: 2,
                  ),
                ),

              // 이메일 인증번호
              const Text(
                '이메일 인증번호',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '인증번호를 입력하세요',
                        ),
                        onSaved: (newValue) => emailAuthNum = newValue ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    margin: EdgeInsets.only(bottom: 15),
                    height: 60,
                    width: 85,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDBE85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          checkProgress = true;
                        });
                        _formKey.currentState!.save();
                        setState(() {
                          emailAuth = (emailAuthNum!='' && emailAuthCorrect == emailAuthNum);
                          checkProgress = false;
                        });
                      },
                      child: checkProgress
                          ? const CircularProgressIndicator()
                          : const Text(
                              '인증확인',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                    ),
                  ),
                ],
              ),
              if (emailAuth == true)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '인증이 완료되었습니다.',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              if (emailAuth == false)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '인증번호가 일치하지 않습니다.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              // 비밀번호
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '비밀번호를 입력하세요',
                  ),
                  obscureText: true,
                  onSaved: (newValue) => password = newValue ?? '',
                ),
              ),

              // 비밀번호 확인
              const Text(
                '비밀번호 확인',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '비밀번호를 다시 입력하세요',
                  ),
                  obscureText: true,
                  onSaved: (newValue) => confirmPassword = newValue ?? '',
                ),
              ),
              if (passwordSame == false)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '비밀번호가 일치하지 않습니다.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              // 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D1D1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '뒤로가기',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBE85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          setState(() {
                            confirmProgress = true;
                          });
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

                            if (emailDuplicate == true || emailDuplicate == null) {
                              setState(() {
                                confirmProgress = false;
                              });
                              return;
                            }
                            if (emailAuth == false || emailAuth == null) {
                              setState(() {
                                confirmProgress = false;
                              });
                              return;
                            }

                            Navigator.of(context).pop();

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

                            final newUser =
                            await authentication.createUserWithEmailAndPassword(email: email, password: password);
                          } catch (e) {
                            setState(() {
                              confirmProgress=false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('비밀번호는 최소 6자 이상이어야 합니다.'),
                                duration: const Duration(seconds: 2), // 표시 시간
                              ),
                            );
                          }
                        },
                        child: confirmProgress
                            ? const CircularProgressIndicator()
                            : const Text(
                                '완료',
                                style: TextStyle(fontSize: 14, color: Colors.black),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
