import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'Đăng nhập đã bị hủy';
}

class AuthService {
  static FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<void> _upsertUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<User?> authStateChanges() {
    try {
      Firebase.app();
      return _firebaseAuth.authStateChanges();
    } catch (_) {
      return Stream<User?>.value(null);
    }
  }

  static Future<void> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase chưa được khởi tạo');
    }

    if (kIsWeb) {
      // Luôn hiện account chooser để đổi tài khoản nhanh giữa các lần đăng nhập.
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      try {
        final credential = await _firebaseAuth.signInWithPopup(provider);
        final user = credential.user;
        if (user != null) {
          await _upsertUserProfile(user);
        }
      } on FirebaseAuthException catch (error) {
        if (error.code == 'popup-closed-by-user' || error.code == 'cancelled-popup-request') {
          throw const AuthCancelledException();
        }
        throw Exception(error.message ?? 'Không thể đăng nhập Google');
      }
    } else {
      // Xóa session Google cũ để lần sau luôn hiện chọn tài khoản.
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        await _googleSignIn.signOut();
      }

      // Mobile: dùng google_sign_in package.
      final googleAccount = await _googleSignIn.signIn();

      if (googleAccount == null) {
        throw const AuthCancelledException();
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _upsertUserProfile(user);
      }
    }
  }

  static Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        // Đã signOut nhưng không có session để disconnect.
      }
    }
    if (Firebase.apps.isNotEmpty) {
      await _firebaseAuth.signOut();
    }
  }
}
