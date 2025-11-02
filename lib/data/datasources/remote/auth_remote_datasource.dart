import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
/// Handles Firebase Auth and Firestore calls
abstract class AuthRemoteDataSource {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register(String email, String password, String displayName, String role);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateUserProfile(String userId, String? avatarUrl);
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
  Future<UserModel?> register(String email, String password, String displayName, String role) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        final userData = {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email ?? email,
          'displayName': displayName,
          'role': role, // 'student' or 'instructor'
          'avatarUrl': null,
          'createdAt': DateTime.now().toIso8601String(),
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        return UserModel.fromJson(userData);
      }

      return null;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
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

  @override
  Future<UserModel> updateUserProfile(String userId, String? avatarUrl) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);
      
      // Update only avatarUrl, keep other fields unchanged
      await userDocRef.update({
        'avatarUrl': avatarUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Get updated user data
      final updatedDoc = await userDocRef.get();
      if (updatedDoc.exists) {
        final currentUser = _auth.currentUser;
        return UserModel.fromJson({
          'uid': userId,
          'email': currentUser?.email ?? '',
          ...updatedDoc.data()!,
        });
      }
      
      throw Exception('User document not found');
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }
}
