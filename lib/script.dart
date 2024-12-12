import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/material.dart';
import 'package:uni_links5/uni_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class Scripts {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateVerificationCode() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  Future<bool> checkEmailDuplicate(String email) async {
    try {
      // Fetch sign-in methods for the given email
      List<String> signInMethods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error checking email: $e");
      return true;
    }
  }

  //note. this logs in the user as the password 'password'
  Future<String> sendEmailVerification(String email) async {
    try {
      /*
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'password',
      );


      await sendVerificationEmail(email, verificationCode);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'userName': '',
        'emailType': 'None',
        'idType': 0,
        'photoURL': '',
        'verificationCode': verificationCode,
        'emailVerified': false,
      });

      return userCredential.user!.uid;
      print('Sign up : ${userCredential.user?.uid}');*/

      String verificationCode = generateVerificationCode();
      await sendVerificationEmail(email, verificationCode);
      print(verificationCode);
      return verificationCode;
    } catch (e) {
      print("Error : $e");
      return '';
    }
  }

  Future<void> sendVerificationEmail(String email,
      String verificationCode) async {
    String username = 'lapuliachloros@gmail.com';
    String password = 'mwje memm ogrt htqk';

    final smtpServer = SmtpServer('smtp.gmail.com',
        username: username,
        password: password,
        port: 587,
        ssl: false);

    final message = Message()
      ..from = Address(username)
      ..recipients.add(email)
      ..subject = '[CatCulator] 이메일 인증번호를 확인해주세요'
      ..text = '''
  안녕하세요, CatCulator입니다.

  회원가입을 위해 아래 인증번호를 입력해주세요:

  인증번호: $verificationCode

  감사합니다.

  - CatCulator 앱 개발자
  ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
    } catch (e) {
      print('Message not sent. $e');
    }
  }

  Future<bool> verifyCode(String email, String codeEntered) async {
    DocumentSnapshot userDoc = await _firestore.collection('email_verify').doc(
        email).get();
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      String? storedCode = userData['verificationCode'];

      if (storedCode != null && storedCode == codeEntered) {
        return true;
      }
    }
    return false;
  }

  Future<void> verifyPhone(String phoneNumber, Function(String) code,
      Function(String) error,) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          error(e.message ?? 'Verification fail');
        },
        codeSent: (String verificationId, int? resendToken) {
          code(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          error('Verification time out');
          //when timed out
        },
      );
    } catch (e) {
      error('Error: $e');
    }
  }

  Future<void> smsCode(String verificationId, String smsCode) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode, //The code we need from the user
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Error phone verification: $e");
    }
  }

  //This can be used in the signup process to cancle it
  Future<void> deleteUser(String uid) async {
    if (uid == '') {
      return;
    }
    await FirebaseAuth.instance.currentUser?.delete();
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    print("Cleaned up the process");
  }


  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print("Error : $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    //The idType means if it is a buyer or Artist, 0 is buyer, 1 is Artist
    try {
      //Login using google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        //cancle of login
        return null;
      }

      //Google Auth
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      //Firebase Auth
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      //Firebase login
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      return user;

      /*
      //Make userdata if there is none
      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return {
            'success': true,
            'user': userDoc.data(),
          };
        }

        final String? photoURL = user.photoURL;

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {
              'userName': user.displayName ?? '',
              'emailType': 'Google',
              'idType': 0,
              'photoURL': photoURL ?? '',
            }, SetOptions(merge: true));

        return {
          'success': true,
          'user': {
            'userName': user.displayName ?? '',
            'emailType': 'Google',
            'idType': 0,
            'photoURL': photoURL ?? '',
          },
        };

      }
      */
    } catch (e) {
      print("Error : $e");
      return null;
    }
  }

//Mabye add the userDoc check function
  Future<void> updateUserData(String uid, String userName, int idType,
      String photoURL) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'userName': userName,
        'idType': idType,
        'photoURL': photoURL,
      });
    } catch (e) {
      print("Error : $e");
    }
  }

  Future<void> uploadItem(String itemName, int itemPrice, int sellPrice,
      int quantity, String imageUrl) async {
    try {
      //user check, might not need this
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      /*
      //upload image to firebase
      final String fileName = 'item_images/${user.uid}/${itemName}-${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg';
      final UploadTask uploadTask = _storage.ref(fileName).putFile(imageFile);

      final TaskSnapshot snapshot = await uploadTask;

      //the download URL of img
      final String imageUrl = await snapshot.ref.getDownloadURL();
      */

      //create the item document
      await _firestore.collection('items').add({
        'userId': user.uid,
        'itemName': itemName,
        'itemPrice': itemPrice,
        'sellPrice': sellPrice,
        'quantity': quantity,
        'itemImage': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Item upload success");
    } catch (e) {
      print("Error uploading item: $e");
    }
  }

  Future<String> uploadImage(File imageFile, String imageName) async {
    User? user = _auth.currentUser;

    if (user == null) {
      return '';
    }

    final String fileName = 'item_images/${user.uid}/$imageName-${DateTime
        .now()
        .millisecondsSinceEpoch}.jpg';

    final UploadTask uploadTask = _storage.ref(fileName).putFile(imageFile);
    final TaskSnapshot snapshot = await uploadTask;

    //the download URL of img
    final String imageUrl = await snapshot.ref.getDownloadURL();

    return imageUrl;
  }

  Future<void> updateItem(String itemId, String itemName, int itemPrice,
      int sellPrice, int quantity, String imageUrl) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'no current user';
      }

      DocumentSnapshot itemDoc = await _firestore.collection('items').doc(
          itemId).get();

      if (!itemDoc.exists) {
        throw 'No such item';
      }

      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      String itemUserId = itemData['userId'];

      if (itemUserId != user.uid) {
        throw 'no permission';
      }

      await _firestore.collection('items').doc(itemId).update({
        'itemName': itemName,
        'itemPrice': itemPrice,
        'sellPrice': sellPrice,
        'quantity': quantity,
        'itemImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error : $e");
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'no current user';
      }

      DocumentSnapshot itemDoc = await _firestore.collection('items').doc(
          itemId).get();

      if (!itemDoc.exists) {
        throw 'No such item';
      }

      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      String itemUserId = itemData['userId'];

      if (itemUserId != user.uid) {
        throw 'no permission';
      }

      await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
      print("cleaned up items");
    } catch (e) {
      print("Error : $e");
    }
  }

  Future<List<Map<String, dynamic>>> getItemsByUserId(String userId) async {
    List<Map<String, dynamic>> itemsList = [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('items')
          .where('userId', isEqualTo: userId)
          .get();

      // Convert the QuerySnapshot to a list of maps
      for (var doc in querySnapshot.docs) {
        itemsList.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error retrieving items: $e");
    }

    return itemsList;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {}
  }

  void resetPasswordByLink(BuildContext context, String email,
      String newPassword) async {
    try {
      final initialLink = await getInitialLink();

      if (initialLink != null) {
        Uri link = Uri.parse(initialLink);

        if (FirebaseAuth.instance.isSignInWithEmailLink(link.toString())) {
          // Call the password reset method
          await resetPassword(link, email, newPassword, context);
        } else {
          print("Invalid reset link.");
        }
      }
    } catch (e) {
      print("Error handling deep link: $e");
    }
  }

  Future<String> sendPaymentCheck(BuildContext context, int totalCost, String accountNumber, String payName) async
  {
    /*
    클라이언트에서 보내는
    1. 결제 처리가 완료 되었는지 확인 하는 코드
    - 이는 클라이언트에서 특정 결제 번호를 서버에 보내고
    - 서버가 결제가 완료 되었는지를 확인하고 firebase에 결제가 완료 됨을 기록
    - 이를 구분하는 방법?
    2. 코드를 최대한 덜 고치는 방안
    - 현재 사용자가 일정 금액을 앱 계좌에 보냈는지 확인
    - 만약 들어왔을 시에 서버에서 이에 대해 true를 보내서
    - 결제 코드쪽에서 문제가 없도록 바로 처리,
    - 만약 돈이 들어오지 않았을 경우에는 거부
    - 결과는 일단 true, false이긴 하지만 여러 케이스를 감당해야 할 수 있으므로 String
    - 추후에 변경 가능
     */
    /*
    try {
      Map<String, dynamic> data = {
        'totalCost': totalCost,
        'accountNumber': accountNumber,
      };

      var url = Uri.parse("http://서버 ip 주소:5000");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      String result;
      if (response.statusCode == 200) {
        result = 'true';
      } else if (response.statusCode == 100) {
        result = '아직 결제가 완료되지 않았습니다, 먼저 결제가 되었는지 다시 확인해 주세요';
      } else {
        result = '결제 과정 확인에 문제가 있었습니다, 다시 시도해 주세요';
      }

      return result;
    } catch (e) {
      print("Error of payment check : $e");
      return '결제 과정 확인에 문제가 있었습니다, 다시 시도해 주세요';
    }
  }
     */
    final url = Uri.parse(
        'https://open-api.kakaopay.com/online/v1/payment/ready');
    final header = {
      'Authorization': 'SECRET_KEY DEV77ECB5ABFFC90F238F88B9B85ECA6D06EB8DF',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'cid': 'TC0ONETIME',
      'partner_order_id': 'ThisIsTest',
      'partner_user_id': accountNumber,
      'item_name': payName,
      'quantity': 1,
      'total_amount': totalCost,
      'tax_free_amount': 0,
      'approval_url': 'http://localhost:8080/success',
      'cancel_url': 'http://localhost:8080/fail',
      'fail_url': 'http://localhost:8080/cancel',
    });

    try {
      final response = await http.post(
        url,
        headers: header,
        body: body,
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      final tid = data['tid'];
      final next_url = data['next_redirect_app_url'];

      //launchUrl(Uri.parse(next_url));
      //launchUrl(Uri.parse('kakaoPay://'));

      if (await canLaunchUrl(Uri.parse(next_url))) {
        await launchUrl(Uri.parse(next_url));
      } else {
        throw 'Could not launch $next_url';
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen(paymentUrl: next_url,)),
      );

      if(result['pg_token'] == 'cancel') {
        return '결제가 도중에 취소되었습니다, 다시 시도해주세요';
      }

      if(result['pg_token'] == 'fail') {
        return '결제 도중에 오류가 있었습니다, 다시 시도해주세요';
      }

      return approvePayment(accountNumber, tid, result['pg_token']);
    } catch (e) {
      print("error while testing : $e");
    }

    return '결제 도중에 오류가 있었습니다, 개발자에게 연락 후 다시 시도해주세요';
  }

  Future<String> approvePayment(String accountNumber, String tid, String pgToken) async{
    final url = Uri.parse(
        'https://open-api.kakaopay.com/online/v1/payment/approve');
    final header = {
      'Authorization': 'SECRET_KEY DEV77ECB5ABFFC90F238F88B9B85ECA6D06EB8DF',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'cid': 'TC0ONETIME',
      'tid': tid,
      'partner_order_id': 'ThisIsTest',
      'partner_user_id': accountNumber,
      'pg_token': pgToken,
    });

    try {
      final response = await http.post(
        url,
        headers: header,
        body: body,
      );

      if(response.statusCode == 200) {
        return 'true';
      }
    } catch (e) {
      print("error while testing_2 : $e");
    }

    return '결제 결과 확인중 오류가 있었습니다, 다시 시도해주세요';
  }
}

Future<void> resetPassword(Uri link, String email, String newPassword, BuildContext context) async {
  try {
    await FirebaseAuth.instance.confirmPasswordReset(
      code: link.toString(),
      newPassword: newPassword,
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("비밀번호가 변경되었습니다.")));
    Navigator.pop(context);
  } catch (e) {
  }
}

class PaymentScreen extends StatefulWidget {
  final String paymentUrl;

  PaymentScreen({required this.paymentUrl});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Loading started: $url');
          },
          onPageFinished: (String url) {
            print('Loading finished: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async{
            print("Change of navigation : ${request.url}");

            if(request.url.startsWith('intent')){
              return NavigationDecision.prevent;
            }

            if (request.url.startsWith('http://localhost:8080/success?pg_token=')){
              final Uri uri = Uri.parse(request.url);
              final String? pgToken = uri.queryParameters['pg_token'];
              print('pg_token : $pgToken');

              Navigator.pop(context, {'pg_token': pgToken});
            }

            if (request.url.startsWith('http://localhost:8080/fail')) {
              Navigator.pop(context, {'pg_token' : 'fail'});
            }

            if (request.url.startsWith('http://localhost:8080/cancel')) {
              Navigator.pop(context, {'pg_token' : 'cancel'});
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: WebViewWidget(
        controller: _webViewController,
      ),
    );
  }
}