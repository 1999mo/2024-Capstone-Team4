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
          child: Column(
            children: [
              Text('축제명'),
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
              Text('부스명'),
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
                  TextButton(
                    onPressed: () {
                      setState(() {
                        painters.add(''); // 빈 입력 필드 추가
                      });
                    },
                    child: Text('참여 작가 명단 +'),
                  ),
                ],
              ),
              Text('부스 위치'),
              TextFormField(
                decoration: InputDecoration(border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return '부스 위치를 알려주세요';
                  return null;
                },
                onSaved: (newValue) {
                  location = newValue!;
                },
              ),
              CheckboxListTile(
                value: isPreSell,
                title: Text('사전 판매 실시 여부'),
                onChanged: (value) {
                  setState(() {
                    isPreSell = !isPreSell;
                  });
                },
              ),
              if (isPreSell)
                Column(
                  children: [
                    Text('사전 판매 기간 설정'),
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
                                  initialDate: preSellStart ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    preSellStart = pickedDate;
                                  });
                                }
                              },
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
                                  initialDate: preSellEnd ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    preSellEnd = pickedDate;
                                  });
                                }
                              },
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
              Row(
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('뒤로')),
                  TextButton(
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('사용자 인증에 문제가 발생했습니다. 다시 로그인해주세요.')),
                        );
                        return;
                      }

                      final userDocRef = FirebaseFirestore.instance
                          .collection('Users')
                          .doc(uid);
                      final boothsCollectionRef = userDocRef.collection('booths');
                      final existingDoc = await boothsCollectionRef
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                              Text('사전 판매 시작 날짜와 종료 날짜를 모두 입력해주세요.')));
                          return;
                        }
                        if (preSellStart!.isAfter(preSellEnd!)) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('사전판매 종료기간이 시작기간보다 앞섭니다.')));
                          return;
                        }
                      }
                      if (painters.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('참여 작가를 1명 이상 입력해주세요.')));
                        return;
                      }

                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        try {
                          // Firestore 참조
                          final userDocRef = FirebaseFirestore.instance
                              .collection('Users')
                              .doc(uid);
                          final boothsCollectionRef = userDocRef.collection('booths');

                          // 고유 ID 생성
                          final newBoothDoc = boothsCollectionRef
                              .doc(selectedFestival);

                          // Firestore에 데이터 추가
                          await newBoothDoc.set({
                            'FestivalName': selectedFestival,
                            'boothName': boothName,
                            'painters': painters,
                            'location': location,
                            'isPreSell': isPreSell,
                            'preSellStart':
                            preSellStart, // DateTime 객체 그대로 저장
                            'preSellEnd': preSellEnd, // DateTime 객체 그대로 저장
                          });

                          // `Festival` 컬렉션의 `sellers` 필드에 UID 추가
                          final festivalDocRef = FirebaseFirestore.instance
                              .collection('Festivals')
                              .doc(selectedFestival);
                          await festivalDocRef.update({
                            'sellers': FieldValue.arrayUnion([uid]) // UID를 배열에 추가
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('부스 정보가 성공적으로 저장되었습니다.')),
                          );
                          setState(() {
                            Navigator.pop(context); // 저장 후 이전 화면으로 이동
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                Text('부스 정보를 저장하는 중 오류가 발생했습니다: $e')),
                          );
                        }
                      }
                    },
                    child: Text('확인'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
