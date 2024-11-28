import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineSelectBooth extends StatefulWidget {
  const OnlineSelectBooth({super.key});

  @override
  State<OnlineSelectBooth> createState() => _OnlineSelectBoothState();
}

class _OnlineSelectBoothState extends State<OnlineSelectBooth> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('온라인 판매'),
        centerTitle: true,// 제목 변경
      ),
      body: Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(12)
        ),
        margin: EdgeInsets.symmetric(vertical:10, horizontal: 20),
        child: Column(
          children: [
            // "축제 선택" 헤더
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '축제 선택',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 회색 경계선
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.grey,
              height: 1,
            ),

            const SizedBox(height: 8),

            // 축제 목록
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Festivals') // Festivals 컬렉션 참조
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('등록된 축제가 없습니다.'));
                  }

                  final festivals = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: festivals.length,
                    itemBuilder: (context, index) {
                      final festivalData =
                      festivals[index].data() as Map<String, dynamic>;
                      final festivalName = festivalData['FestivalName'] ?? '이름 없음';

                      return ListTile(
                        title: Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECECEC),
                            border:
                            Border.all(color: const Color(0xFFD1D1D1), width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(festivalName), // 축제 이름
                              const Icon(Icons.chevron_right), // 꺽쇠 아이콘
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/online_seller_screens/my_online_items',
                            arguments: festivals[index].id, // Festival ID 전달
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
