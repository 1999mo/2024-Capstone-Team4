import 'package:flutter/material.dart';

class FindId extends StatefulWidget {
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
          title: Text('비밀번호 찾기'),
          centerTitle: true,
        ),
        body: Form(
          key: _findIdKey,
          child: FindPassword(),
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _findPwKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 이메일 입력란
            Text('이메일'),
            Row(
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
                TextButton(
                  onPressed: () {
                    _findPwKey.currentState!.save();
                    // 이메일 발송 로직
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('인증번호 발송'),
                          content: Text('인증번호가 발송되었습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // 팝업 닫기
                              },
                              child: Text('확인'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('인증번호 보내기'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // 전화번호 입력란과 인증번호 보내기 버튼
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
                TextButton(
                  onPressed: () async {
                    _findPwKey.currentState!.save();
                    // 이메일 인증 확인 로직
                    setState(() {
                      emailAuth = (emailAuthCorrect == emailAuthNum);
                    });
                  },
                  child: Text('인증 확인'),
                ),
              ],
            ),
            SizedBox(height: 20),

            TextButton(
                onPressed: () {
                  // 완료 버튼
                },
                child: Text('완료'))
          ],
        ),
      ),
    );
  }
}
