import 'dart:io'; // File 사용
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택을 위한 패키지
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage 사용
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore 사용
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MakeProfile extends StatefulWidget {
  const MakeProfile({super.key});

  @override
  State<MakeProfile> createState() => _MakeProfileState();
}

class _MakeProfileState extends State<MakeProfile> {
  bool isSeller = false; // 판매자 여부
  File? _profileImage; // 선택된 이미지 파일
  String userName = ''; // 입력받은 사용자 이름

  // 이미지 선택
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // 갤러리에서 이미지 선택
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path); // 선택된 이미지 저장
      });
    }
  }

  // Firebase Storage에 이미지 업로드
  Future<String?> _uploadImageToFirebase(String userEmail) async {
    try {
      // 업로드할 파일이 없으면 기본 이미지 업로드
      File imageToUpload;
      if (_profileImage == null) {
        final byteData = await rootBundle.load('assets/profile_placeholder.png'); // 기본 이미지 로드
        final tempDir = await getTemporaryDirectory(); // 임시 디렉토리 경로 가져오기
        final tempFile = File('${tempDir.path}/profile_placeholder.png');
        imageToUpload = await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      } else {
        imageToUpload = _profileImage!;
      }

      // Firebase Storage 경로 설정
      final storageRef = FirebaseStorage.instance.ref();
      final profileImageRef = storageRef.child('$userEmail/profile_image.jpg');

      // 이미지 업로드
      await profileImageRef.putFile(imageToUpload);

      // 업로드된 이미지의 URL 반환
      return await profileImageRef.getDownloadURL();
    } catch (e) {
      _showSnackbar('이미지 업로드 실패: $e');
      return null;
    }
  }

  // Firebase Firestore에 사용자 데이터 저장
  Future<void> _saveUserData(String userEmail, String userName, bool isSeller) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Users 컬렉션에 사용자 문서 추가
      await firestore.collection('Users').doc(userEmail).set({
        'name': userName,
        'isSeller': isSeller,
      });

      _showSnackbar('사용자 데이터 저장 완료');
    } catch (e) {
      _showSnackbar('사용자 데이터 저장 실패: $e');
    }
  }

  // 스낵바로 메시지 표시
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 완료 버튼 동작
  Future<void> _onComplete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar('로그인된 사용자가 없습니다.');
      return;
    }

    final userEmail = user.email!;
    if (userName.isEmpty) {
      _showSnackbar('사용자 이름을 입력하세요.');
      return;
    }

    // Firebase Storage에 이미지 업로드
    final imageUrl = await _uploadImageToFirebase(userEmail);

    if (imageUrl != null) {
      // Firestore에 사용자 데이터 저장
      await _saveUserData(userEmail, userName, isSeller);
      Navigator.pushReplacementNamed(context, '/main_screens/main_screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50, // 원 크기
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!) // 선택한 이미지로 변경
                  : AssetImage('assets/profile_placeholder.png') as ImageProvider, // 기본 이미지
            ),
            ElevatedButton(
              onPressed: _pickImage, // 이미지 선택
              child: Text('프로필 사진 업로드'),
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: '사용할 이름 입력',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  userName = value; // 사용자 이름 저장
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: isSeller,
                  onChanged: (value) {
                    setState(() {
                      isSeller = value ?? false;
                    });
                  },
                ),
                Text('판매자 여부'),
              ],
            ),
            ElevatedButton(
              onPressed: _onComplete, // 완료 버튼 동작
              child: Text('완료'),
            ),
          ],
        ),
      ),
    );
  }
}
