import 'package:flutter/material.dart';
import 'package:catculator/main/script.dart';

class FindId extends StatefulWidget {
  const FindId({super.key});

  @override
  _FindIdState createState() => _FindIdState();
}

class _FindIdState extends State<FindId> {
  final _findIdKey = GlobalKey<FormState>();

  String phone = '';
  String phone_auth = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('비밀번호 변경'),
          centerTitle: true,
        ),
        body: Form(
          key: _findIdKey,
          child: const FindPassword(),
        ));
  }
}

class FindPassword extends StatefulWidget {
  const FindPassword({super.key});

  @override
  State<FindPassword> createState() => _FindPasswordState();
}

class _FindPasswordState extends State<FindPassword> {
  final _findPwKey = GlobalKey<FormState>();

  bool? emailAuth; // 이메일 인증 여부
  bool phoneAuth = false; // 전화번호 인증 여부

  String email = '';
  String emailAuthCorrect = '';
  String emailAuthNum = '';
  String newPassword = '';

  Scripts script = Scripts();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _findPwKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 이메일 입력란
            const Text('이메일'),
            Row(
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
                TextButton(
                  onPressed: () {
                    _findPwKey.currentState!.save();
                    // 이메일 발송 로직
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('비밀번호 변경'),
                          content: const Text('입력하신 이메일로 비밀번호 변경 메일이 발송되었습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                await script.sendPasswordResetEmail(email);
                                Navigator.of(context).pop(); // 팝업 닫기
                              },
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('비밀번호 변경하기'),
                ),
              ],
            ),
            /*
            const SizedBox(height: 20),

            // 전화번호 입력란과 인증번호 보내기 버튼
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
                    onSaved: (newValue) => newPassword = newValue ?? '',
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    _findPwKey.currentState!.save();
                    // 이메일 인증 확인 로직
                    script.resetPasswordByLink(context, email, newPassword);
                    setState(() {
                      emailAuth = (emailAuthCorrect == emailAuthNum);
                    });
                  },
                  child: const Text('인증 확인'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            */
            TextButton(
                onPressed: () {
                  // 완료 버튼
                },
                child: const Text('완료'))
          ],
        ),
      ),
    );
  }
}
