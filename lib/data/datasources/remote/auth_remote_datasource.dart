import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
/// Handles Firebase Auth and Firestore calls
abstract class AuthRemoteDataSource {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register(
    String email,
    String password,
    String displayName,
    String role,
  );
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateUserProfile(String userId, String? avatarUrl);

  // Student management methods
  Future<List<UserModel>> getAllStudents();
  Future<UserModel> createStudent(
    String email,
    String password,
    String displayName,
  );
  Future<UserModel> updateStudent(
    String userId,
    String displayName,
    String email,
  );
  Future<void> deleteStudent(String userId);
}

/// Implementation of AuthRemoteDataSource using Firebase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      debugPrint('🔐 Firebase Auth: Attempting login for $email');

      // Check current auth state before login
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint(
          '⚠️ Firebase Auth: User already logged in: ${currentUser.email}',
        );
        debugPrint('🔄 Firebase Auth: Signing out current user first...');
        await _auth.signOut();
      }

      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Firebase Auth: Sign in successful');

      if (userCredential.user != null) {
        debugPrint('📥 Firebase Auth: Fetching user data from Firestore...');
        // Get user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          debugPrint('✅ Firebase Auth: User profile found');
          return UserModel.fromJson({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email ?? email,
            ...userDoc.data()!,
          });
        } else {
          debugPrint('❌ Firebase Auth: User profile not found in Firestore');
          // User authenticated but doesn't have a profile
          // Sign them out and throw an error
          await _auth.signOut();
          throw Exception(
            'Account not found. Please contact an administrator to create your account',
          );
        }
      }

      debugPrint('❌ Firebase Auth: No user credential returned');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      // Handle specific Firebase Auth errors with user-friendly messages
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Wrong email or password');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later');
        case 'network-request-failed':
          throw Exception('Network error. Please check your connection');
        default:
          throw Exception('Login failed. Please try again');
      }
    } catch (e) {
      debugPrint('❌ Firebase Auth Error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> register(
    String email,
    String password,
    String displayName,
    String role,
  ) async {
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
    debugPrint('🚪 Firebase Auth: Signing out...');
    await _auth.signOut();
    debugPrint('✅ Firebase Auth: Sign out complete');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      debugPrint(
        '🔍 Firebase Auth: getCurrentUser - ${currentUser?.email ?? "null"}',
      );

      if (currentUser != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          debugPrint('✅ Firebase Auth: User profile exists in Firestore');
          return UserModel.fromJson({
            'uid': currentUser.uid,
            'email': currentUser.email ?? '',
            ...userDoc.data()!,
          });
        } else {
          debugPrint(
            '⚠️ Firebase Auth: User authenticated but no profile in Firestore',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Firebase Auth: getCurrentUser error: $e');
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

  @override
  Future<List<UserModel>> getAllStudents() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final students = querySnapshot.docs
          .map((doc) => UserModel.fromJson({'uid': doc.id, ...doc.data()}))
          .toList();

      // Sort by displayName in memory to avoid needing a composite index
      students.sort((a, b) => a.displayName.compareTo(b.displayName));

      return students;
    } catch (e) {
      throw Exception('Failed to get students: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> createStudent(
    String email,
    String password,
    String displayName,
  ) async {
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
          'role': 'student',
          'avatarUrl': null,
          'createdAt': DateTime.now().toIso8601String(),
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        return UserModel.fromJson(userData);
      }

      throw Exception('Failed to create user');
    } catch (e) {
      throw Exception('Failed to create student: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateStudent(
    String userId,
    String displayName,
    String email,
  ) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // Update user data in Firestore
      await userDocRef.update({
        'displayName': displayName,
        'email': email,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Note: Firebase Auth email update requires re-authentication
      // For now, we only update Firestore. Email update can be added later if needed.

      // Get updated user data
      final updatedDoc = await userDocRef.get();
      if (updatedDoc.exists) {
        return UserModel.fromJson({'uid': userId, ...updatedDoc.data()!});
      }

      throw Exception('User document not found');
    } catch (e) {
      throw Exception('Failed to update student: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteStudent(String userId) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Note: Firebase Auth user deletion requires the user to be signed in
      // This should be handled by Cloud Functions in production
      // For now, we only delete the Firestore document
    } catch (e) {
      throw Exception('Failed to delete student: ${e.toString()}');
    }
  }
}
