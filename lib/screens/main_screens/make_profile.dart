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
  bool _isLoading = true;

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

  Future<void> _checkUserDocument() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final uid = user.uid;

      // Firestore에서 문서 존재 여부 확인
      final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (doc.exists) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/main_screens/main_screen');
        return;
      }
    } catch (e) {
      _showSnackbar('사용자 데이터 확인 중 오류가 발생했습니다: $e');
    } finally {
      // 로딩 완료 상태로 변경
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Firebase Storage에 이미지 업로드
  Future<String?> _uploadImageToFirebase(String uid) async {
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
      final profileImageRef = storageRef.child('$uid/profile_image.jpg');

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
  Future<void> _saveUserData(String uid, String userName, bool isSeller, String? email) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Users 컬렉션에 사용자 문서 추가
      await firestore.collection('Users').doc(uid).set({
        'name': userName,
        'isSeller': isSeller,
        'email': email, // 이메일 필드 추가
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
        duration: const Duration(seconds: 2),
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

    final uid = user.uid;
    final email = user.email; // 이메일 가져오기

    if (userName.isEmpty) {
      _showSnackbar('사용자 이름을 입력하세요.');
      return;
    }

    // Firebase Storage에 이미지 업로드
    final imageUrl = await _uploadImageToFirebase(uid);

    if (imageUrl != null) {
      // Firestore에 사용자 데이터 저장
      await _saveUserData(uid, userName, isSeller, email);
      Navigator.pushReplacementNamed(context, '/main_screens/main_screen');
    }
  }

  @override
  void initState()  {
    super.initState();
    _checkUserDocument(); // initState에서 비동기 작업 시작
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      // 로딩 상태일 때 로딩 화면 표시
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // 로딩 인디케이터
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50, // 원 크기
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!) // 선택한 이미지로 변경
                        : const AssetImage('assets/profile_placeholder.png') as ImageProvider, // 기본 이미지
                  ),
                  TextButton(
                    onPressed: _pickImage, // 이미지 선택
                    child: const Text(
                        '프로필 사진 업로드',
                      style: TextStyle(
                        color: Colors.black,
                      )
                    ),
                  ),
                  const SizedBox(height: 24), // 프로필 사진과 텍스트 필드 사이 간격
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 40),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '사용할 이름 입력',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          userName = value; // 사용자 이름 저장
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12), // 텍스트 필드와 체크박스 사이 간격
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.2, // 체크박스 크기 조정
                        child: Checkbox(
                          value: isSeller,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100), // 체크박스 모양을 둥글게
                          ),
                          activeColor: Color(0xFF525252), // 체크박스 활성 색상
                          onChanged: (value) {
                            setState(() {
                              isSeller = value ?? false;
                            });
                          },
                        ),
                      ),
                      const Text(
                        '판매자 여부',
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 320,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: const Color(0xFFFDBE85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: TextButton(
              onPressed: _onComplete, // 완료 버튼 동작
              child: const Text(
                '완료',
                style: TextStyle(
                    fontSize: 14, color: Colors.black
                ),
              ),
            ),
          ),
          const SizedBox(height: 24), // 하단 여백
        ],
      ),
    );

  }
}
