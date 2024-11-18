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
    return DefaultTabController(
      length: 2, // 탭 개수
      child: Scaffold(
        appBar: AppBar(
          title: Text('아이디/비밀번호 찾기'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, // 배경색
                borderRadius: BorderRadius.circular(25), // 둥근 테두리
              ),
              child: TabBar(
                tabs: [
                  Tab(text: '        아이디 찾기        '),
                  Tab(text: '        비밀번호 찾기        '),
                ],
                labelColor: Colors.black, // 활성 탭 텍스트 색상
                unselectedLabelColor: Colors.grey, // 비활성 탭 텍스트 색상
                indicator: BoxDecoration(
                  color: Color(0xFFFDBE85),
                  borderRadius: BorderRadius.circular(25), // 활성 탭 둥근 테두리
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Form(
                key: _findIdKey,
                child: Center(
                  child: Column(
                    children: [
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
                            onPressed: () {},
                            child: Text('인증하기'),
                          ),
                        ],
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
                              onSaved: (newValue) =>
                                  phone_auth = newValue ?? '',
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              // 전화번호 인증 확인 로직
                            },
                            child: Text('인증 확인'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('뒤로가기')),
                          ElevatedButton(onPressed: () {}, child: Text('완료'))
                        ],
                      )
                    ],
                  ),
                )),
            FindPassword(),
          ],
        ),
      ),
    );
  }
}

class FindPassword extends StatefulWidget {
  const FindPassword({super.key});

  @override
  State<FindPassword> createState() => _FindPasswordState();
}

class _FindPasswordState extends State<FindPassword> {
  final _findPwKey = GlobalKey<FormState>();

  String email = '';
  String phone = '';
  String phoneAuthNum = '';
  String password = '';
  String confirmPassword = '';

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
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '이메일을 입력하세요',
              ),
              onSaved: (newValue) => email = newValue ?? '',
            ),
            SizedBox(height: 20),

            // 전화번호 입력란과 인증번호 보내기 버튼
            Text('전화 번호'),
            Row(
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
                    _findPwKey.currentState!.save();
                    // 전화번호 인증번호 발송 로직
                  },
                  child: Text('인증번호 보내기'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 전화번호 인증번호 입력란과 인증 버튼
            Text('전화번호 인증번호'),
            Row(
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
                    _findPwKey.currentState!.save();
                    // 인증번호 확인 로직
                  },
                  child: Text('인증'),
                ),

              ],
            ),
            ElevatedButton(onPressed: () {
              // 완료 버튼
            }, child: Text('완료'))
          ],
        ),
      ),
    );
  }
}

