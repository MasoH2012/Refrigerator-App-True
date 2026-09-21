import '../../domain/models/user_profile.dart';

class AuthSession {
  const AuthSession({
    required this.profile,
    required this.isAuthenticated,
    required this.hasProfiles,
  });

  final UserProfile? profile;
  final bool isAuthenticated;
  final bool hasProfiles;
}

class UsernameAlreadyExistsException implements Exception {
  const UsernameAlreadyExistsException();
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Future<AuthSession> restoreSession();

  Future<UserProfile> register({
    required String username,
    required String password,
    required String refrigeratorModel,
  });

  Future<UserProfile?> signIn({
    required String username,
    required String password,
  });

  Future<UserProfile> updateRefrigeratorModel({
    required String username,
    required String refrigeratorModel,
  });

  Future<void> signOut();
}
