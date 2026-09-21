import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/models/user_profile.dart';
import 'auth_repository.dart';

/// Firebase-backed authentication while preserving FreshKeep's username UI.
///
/// Firebase Email/Password authentication requires an email-shaped identifier.
/// A deterministic internal address is derived from the username, so the raw
/// password never enters Firestore and users can continue signing in with the
/// username they already know. An email field can be added later for password
/// reset and verification flows.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _usernameDomain = 'users.freshkeep.app';
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<AuthSession> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthSession(
        profile: null,
        isAuthenticated: false,
        hasProfiles: false,
      );
    }
    return AuthSession(
      profile: await _profileForUser(user),
      isAuthenticated: true,
      hasProfiles: true,
    );
  }

  @override
  Future<UserProfile> register({
    required String username,
    required String password,
    required String refrigeratorModel,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.length < 3) {
      throw const AuthRepositoryException(
          'Use at least 3 characters for your username.');
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailForUsername(trimmedUsername),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthRepositoryException(
            'Firebase did not return a user profile.');
      }
      await user.updateDisplayName(trimmedUsername);
      final profile = UserProfile(
        username: trimmedUsername,
        refrigeratorModel: refrigeratorModel.trim(),
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set({
        ...profile.toJson(),
        'uid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return profile;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        throw const UsernameAlreadyExistsException();
      }
      throw AuthRepositoryException(_authMessage(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(
          error.message ?? 'Could not save your profile.');
    }
  }

  @override
  Future<UserProfile?> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailForUsername(username),
        password: password,
      );
      final user = credential.user;
      return user == null ? null : _profileForUser(user);
    } on FirebaseAuthException catch (error) {
      if ({
        'invalid-credential',
        'invalid-email',
        'user-disabled',
        'user-not-found',
        'wrong-password',
      }.contains(error.code)) {
        return null;
      }
      throw AuthRepositoryException(_authMessage(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(
        error.message ?? 'Could not load your Firebase profile.',
      );
    }
  }

  @override
  Future<UserProfile> updateRefrigeratorModel({
    required String username,
    required String refrigeratorModel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthRepositoryException(
          'Sign in before changing your refrigerator.');
    }
    final existing = await _profileForUser(user);
    final updated = existing.copyWith(refrigeratorModel: refrigeratorModel);
    await _firestore.collection('users').doc(user.uid).set({
      ...updated.toJson(),
      'uid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return updated;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<UserProfile> _profileForUser(User user) async {
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    if (data != null && data['username'] is String) {
      return UserProfile.fromJson(data.cast<String, Object?>());
    }
    final fallback = UserProfile(
      username:
          user.displayName ?? user.email?.split('@').first ?? 'FreshKeep user',
      refrigeratorModel: 'ge-gne27jymfs',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set({
      ...fallback.toJson(),
      'uid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return fallback;
  }

  String _emailForUsername(String username) {
    final normalized = username.trim().toLowerCase();
    final encoded =
        base64UrlEncode(utf8.encode(normalized)).replaceAll('=', '');
    return '$encoded@$_usernameDomain';
  }

  String _authMessage(FirebaseAuthException error) => switch (error.code) {
        'weak-password' =>
          'Choose a stronger password with at least 8 characters.',
        'operation-not-allowed' =>
          'Enable Email/Password sign-in in Firebase Console.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        _ =>
          error.message ?? 'Firebase authentication failed. Please try again.',
      };
}
