import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

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
      List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }

  //note. this logs in the user as the password 'password'
  Future<String> sendEmailVerification(String email) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'password',
      );

      String verificationCode = generateVerificationCode();

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
      print('Sign up : ${userCredential.user?.uid}');
    } catch (e) {
      print("Error : $e");
    }
  }

  Future<void> sendVerificationEmail(String email, String verificationCode) async {
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
      ..subject = 'Email Verification Code'
      ..text = 'Your verification code is: $verificationCode';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } catch (e) {
      print('Message not sent. $e');
    }
  }

  Future<bool> verifyCode(String uid, String codeEntered) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      String? storedCode = userData['verificationCode'];

      if(storedCode != null && storedCode == codeEntered) {
        await _firestore.collection('users').doc(uid).update({
          'emailVerified': true,
        });
        return true;
      }
    }
    return false;
  }

  Future<void> verifyPhone(String phoneNumber, Function(String) code, Function(String) error, ) async {
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
        codeAutoRetrievalTimeout:  (String verificationId) {
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
    } catch(e) {
      print("Error phone verification: $e");
    }
  }

  //This can be used in the signup process to cancle it
  Future<void> deleteUser(String uid) async {
    if(uid == '') {
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
    } catch(e) {
      print("Error : $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
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

        await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(
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
    } catch (e) {
      print("Error : $e");
      return {
        'success': false,
        'error': e.toString(),
      };
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

  Future<void> uploadItem(String itemName, int itemPrice, int sellPrice, int quantity, String imageUrl) async {
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

    final String fileName = 'item_images/${user.uid}/${imageName}-${DateTime
        .now()
        .millisecondsSinceEpoch}.jpg';

    final UploadTask uploadTask = _storage.ref(fileName).putFile(imageFile);
    final TaskSnapshot snapshot = await uploadTask;

    //the download URL of img
    final String imageUrl = await snapshot.ref.getDownloadURL();

    return imageUrl;
  }

  Future<void> updateItem(String itemId, String itemName, int itemPrice, int sellPrice, int quantity, String imageUrl) async {
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
    } catch(e) {
      print("Error : $e");
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      User? user = _auth.currentUser;
      if(user == null) {
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
    } catch(e) {
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
}