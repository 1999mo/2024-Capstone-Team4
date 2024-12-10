import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddBooth extends StatefulWidget {
  const AddBooth({super.key});

  @override
  State<AddBooth> createState() => _AddBoothState();
}

class _AddBoothState extends State<AddBooth> {
  final _formKey = GlobalKey<FormState>();
  List<String> festivalNames = []; // 축제명을 저장할 리스트
  String selectedFestival = '';
  String boothName = '';
  List<String> painters = [];
  String location = '';
  bool isPreSell = false;
  DateTime? preSellStart;
  DateTime? preSellEnd;

  @override
  void initState() {
    super.initState();
    fetchFestivalNames(); // 데이터 로드
  }

  Future<void> fetchFestivalNames() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Festivals').get();
      final names = snapshot.docs
          .map((doc) => doc['FestivalName'] as String) // 'FestivalName' 필드 값 추출
          .toList();
      setState(() {
        festivalNames = names; // 상태 업데이트
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('축제 목록을 가져오지 못 했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView( // ListView로 변경하여 스크롤 가능하게 함
              children: [
                Text(
                  '축제명',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField(
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  value: selectedFestival.isEmpty ? '' : selectedFestival,
                  // 초기 선택 값 설정
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text('축제를 선택하세요'),
                    ),
                    ...festivalNames
                        .map((name) =>
                        DropdownMenuItem(value: name, child: Text(name)))
                        .toList(), // 축제 목록 추가
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFestival = value!;
                    });
                  },
                  validator: (value) {
                    if (value == '') return '축제를 선택하세요';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '부스명',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return '부스명을 입력하세요';
                    return null;
                  },
                  onSaved: (newValue) {
                    boothName = newValue!;
                  },
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    ...painters.asMap().entries.map((entry) {
                      int index = entry.key;
                      String value = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Row(
                          children: [
                            // 텍스트 필드
                            Expanded(
                              child: TextFormField(
                                decoration:
                                InputDecoration(border: OutlineInputBorder()),
                                initialValue: value, // 기존 입력값 유지
                                onChanged: (newValue) {
                                  painters[index] = newValue; // 입력값 변경 시 업데이트
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return '작가명을 입력하세요';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8), // 텍스트 필드와 버튼 간격
                            // 제거 버튼
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  painters.removeAt(index); // 해당 항목 제거
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          painters.add(''); // 빈 입력 필드 추가
                        });
                      },
                      style: TextButton.styleFrom(
                        side: BorderSide(color: Colors.grey), // 아웃라인 추가
                        minimumSize: Size(320, 56), // 너비와 높이 설정
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '참여 작가 명단 +',
                          style: TextStyle(
                            color: Colors.black, // 텍스트 색상 검은색
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '부스 위치',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '부스 위치를 알려주세요';
                    }

                    // 첫 글자 확인
                    String firstChar = value.trim()[0]; // 입력 값의 첫 글자
                    if (!RegExp(r'^[a-zA-Z]$').hasMatch(firstChar)) {
                      return 'a-1, a1과 같이 알파벳이 앞으로 오게 작성해주세요';
                    }

                    return null;
                  },
                  onSaved: (newValue) {
                    location = newValue!;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start, // 시작 위치에 배치
                  children: [
                    Transform.scale(
                      scale: 1.2, // 체크박스 크기 조정
                      child: Checkbox(
                        value: isPreSell,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(100), // 체크박스 모양을 둥글게
                        ),
                        activeColor: Color(0xFF525252), // 체크박스 활성 색상
                        onChanged: (value) {
                          setState(() {
                            isPreSell = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8), // 체크박스와 텍스트 사이의 간격
                    Text(
                      '사전 판매 실시 여부',
                      style: TextStyle(
                        fontSize: 16, // 텍스트 크기
                        color: Colors.black, // 텍스트 색상
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // 체크박스와 기간 설정 사이의 간격
                if (isPreSell)
                  Container(
                    padding: const EdgeInsets.all(16), // 내부 여백 추가
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey), // 아웃라인 추가
                      borderRadius: BorderRadius.circular(8), // 모서리를 둥글게
                    ),
                    child: Column(
                      children: [
                        Text(
                          '사전 판매 기간 설정',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold, // 텍스트 강조 (선택사항)
                          ),
                        ),
                        const SizedBox(height: 16), // 텍스트와 경계선 사이의 여백
                        Divider(
                          color: Color(0xFFD1D1D1),
                          thickness: 1, // 경계선 두께
                          height: 1, // 경계선 높이
                        ),
                        const SizedBox(height: 16), // 경계선과 Row 사이의 여백
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text('시작 날짜'),
                                TextButton(
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      preSellStart ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        preSellStart = pickedDate;
                                      });
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                    Colors.grey[200], // 버튼 배경색 회색 설정
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8), // 버튼 내부 여백
                                  ),
                                  child: Text(preSellStart == null
                                      ? '날짜 선택'
                                      : '${preSellStart!.year}-${preSellStart!.month}-${preSellStart!.day}'),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text('종료 날짜'),
                                TextButton(
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      preSellEnd ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        preSellEnd = pickedDate;
                                      });
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                    Colors.grey[200], // 버튼 배경색 회색 설정
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8), // 버튼 내부 여백
                                  ),
                                  child: Text(preSellEnd == null
                                      ? '날짜 선택'
                                      : '${preSellEnd!.year}-${preSellEnd!.month}-${preSellEnd!.day}'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  //버튼들
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
                            child: Text(
                              '뒤로가기',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            )),
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
                            final uid =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '사용자 인증에 문제가 발생했습니다. 다시 로그인해주세요.')),
                              );
                              return;
                            }

                            final userDocRef = FirebaseFirestore.instance
                                .collection('Users')
                                .doc(uid);
                            final boothsCollectionRef =
                            userDocRef.collection('booths');
                            final existingDoc =
                            await boothsCollectionRef
                                .doc(selectedFestival)
                                .get();

                            if (existingDoc.exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '이미 추가된 축제입니다. 부스 목록화면에서 해당 부스를 길게 클릭하여 삭제한 후 다시 시도해주세요.',
                                  ),
                                ),
                              );
                              return; // 중복된 문서가 있으면 저장 작업 중단
                            }
                            if (isPreSell == true) {
                              if (preSellStart == null || preSellEnd == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '사전 판매 시작 날짜와 종료 날짜를 모두 입력해주세요.')));
                                return;
                              }
                              if (preSellStart!.isAfter(preSellEnd!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '사전판매 종료기간이 시작기간보다 앞섭니다.')));
                                return;
                              }
                            }
                            if (painters.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('참여 작가를 1명 이상 입력해주세요.')));
                              return;
                            }

                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              try {
                                // Firestore 참조
                                final userDocRef =
                                FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(uid);
                                final boothsCollectionRef =
                                userDocRef.collection('booths');

                                // 고유 ID 생성
                                final newBoothDoc =
                                boothsCollectionRef.doc(
                                    selectedFestival);

                                // Firestore에 데이터 추가
                                await newBoothDoc.set({
                                  'FestivalName': selectedFestival,
                                  'boothName': boothName,
                                  'painters': painters,
                                  'location': location,
                                  'isPreSell': isPreSell,
                                  'preSellStart':
                                  preSellStart, // DateTime 객체 그대로 저장
                                  'preSellEnd':
                                  preSellEnd, // DateTime 객체 그대로 저장
                                });

                                // `Festival` 컬렉션의 `sellers` 필드에 UID 추가
                                final festivalDocRef =
                                FirebaseFirestore.instance
                                    .collection('Festivals')
                                    .doc(selectedFestival);
                                await festivalDocRef.update({
                                  'sellers': FieldValue.arrayUnion(
                                      [uid]) // UID를 배열에 추가
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('부스 정보가 성공적으로 저장되었습니다.')),
                                );
                                setState(() {
                                  Navigator.pop(context); // 저장 후 이전 화면으로 이동
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '부스 정보를 저장하는 중 오류가 발생했습니다: $e')),
                                );
                              }
                            }
                          },
                          child: Text(
                            '확인',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
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
