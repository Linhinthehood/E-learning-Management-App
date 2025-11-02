import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
/// Handles Firebase Auth and Firestore calls
abstract class AuthRemoteDataSource {
  Future<UserModel?> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

/// Implementation of AuthRemoteDataSource using Firebase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromJson({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email ?? email,
            ...userDoc.data()!,
          });
        } else {
          // User doesn't exist in Firestore, create one
          final userData = {
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email ?? email,
            'displayName': email == 'admin@example.com'
                ? 'Administrator'
                : 'Student',
            'role': email == 'admin@example.com' ? 'instructor' : 'student',
            'avatarUrl': null,
          };

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);

          return UserModel.fromJson(userData);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromJson({
            'uid': currentUser.uid,
            'email': currentUser.email ?? '',
            ...userDoc.data()!,
          });
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
