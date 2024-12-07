import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool progress = false;
  late Future<Map<String, dynamic>> userData;
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    userData = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다.');

    // Firestore에서 사용자 정보 가져오기
    final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    final data = doc.data() ?? {};

    // Firebase Storage에서 프로필 이미지 URL 가져오기
    final imageUrl = await FirebaseStorage.instance
        .ref('${user.uid}/profile_image.jpg')
        .getDownloadURL()
        .catchError((_) => null); // 에러 발생 시 null 반환

    data['image'] = imageUrl; // 이미지 URL 추가
    return data;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path); // 새 프로필 이미지 선택
      });
    }
  }

  Future<void> _updateProfileImage() async {
    if (_newProfileImage == null) return;

    setState(() {
      progress = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('로그인된 사용자가 없습니다.');

    try {
      // Firebase Storage에 새 이미지 업로드
      final storageRef = FirebaseStorage.instance.ref('${user.uid}/profile_image.jpg');
      await storageRef.putFile(_newProfileImage!);

      // Firestore에 이미지 URL 업데이트
      final imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({'profileImage': imageUrl});

      setState(() {
        userData = _fetchUserData(); // 데이터 새로고침
        _newProfileImage = null; // 새 이미지 초기화
      });

      setState(() {
        progress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 이미지가 성공적으로 업데이트되었습니다.')),
      );
    } catch (e) {
      setState(() {
        progress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 이미지 업데이트 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/splash');
            return Center(child: Text('사용자 데이터를 가져올 수 없습니다: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final userName = data['name'] ?? '이름 없음';
          final email = data['email'] ?? '이메일 없음';
          final imageUrl = data['image'];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _newProfileImage != null
                                  ? FileImage(_newProfileImage!) // 새 이미지 미리보기
                                  : (imageUrl != null
                                      ? CachedNetworkImageProvider(imageUrl)
                                      : const AssetImage('assets/profile_placeholder.png')) as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage, // 이미지 선택
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0x7E656464),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Color(0xFF656464),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _updateProfileImage, // 새 이미지 저장
                      child: progress
                          ? const CircularProgressIndicator()
                          : const Text(
                              '변경사항 저장',
                              style: TextStyle(color: Colors.black),
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Color(0x81D1D1D1),
                thickness: 6,
              ),
              const SizedBox(height: 8),
              // 로그아웃 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/splash');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: Colors.black,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  '로그아웃',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
