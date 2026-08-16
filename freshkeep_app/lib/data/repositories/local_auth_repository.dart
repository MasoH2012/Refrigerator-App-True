import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_profile.dart';
import 'auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._preferences);

  static const _profilesKey = 'account.profiles.v2';
  static const _credentialsKey = 'account.credentials.v2';
  static const _legacyProfileKey = 'account.profile.v1';
  static const _legacyHashKey = 'account.password.hash';
  static const _legacySaltKey = 'account.password.salt';

  final SharedPreferences _preferences;

  @override
  Future<AuthSession> restoreSession() async {
    await _migrateLegacyAccount();
    return AuthSession(
      profile: null,
      isAuthenticated: false,
      hasProfiles: _readProfiles().isNotEmpty,
    );
  }

  @override
  Future<UserProfile> register({
    required String username,
    required String password,
    required String refrigeratorModel,
  }) async {
    await _migrateLegacyAccount();
    final key = _normalizeUsername(username);
    final profiles = _readProfiles();
    if (profiles.containsKey(key)) {
      throw const UsernameAlreadyExistsException();
    }

    final salt = _createSalt();
    final profile = UserProfile(
      username: username.trim(),
      refrigeratorModel: refrigeratorModel.trim(),
      createdAt: DateTime.now(),
    );
    profiles[key] = profile;
    final credentials = _readCredentials();
    credentials[key] = _Credential(
      salt: salt,
      hash: _hashPassword(password, salt),
    );
    await _writeProfiles(profiles);
    await _writeCredentials(credentials);
    return profile;
  }

  @override
  Future<UserProfile?> signIn({
    required String username,
    required String password,
  }) async {
    await _migrateLegacyAccount();
    final key = _normalizeUsername(username);
    final profile = _readProfiles()[key];
    final credential = _readCredentials()[key];
    if (profile == null || credential == null) return null;
    final passwordMatches = _constantTimeEquals(
      _hashPassword(password, credential.salt),
      credential.hash,
    );
    return passwordMatches ? profile : null;
  }

  @override
  Future<void> signOut() async {}

  Map<String, UserProfile> _readProfiles() {
    final encoded = _preferences.getString(_profilesKey);
    if (encoded == null) return {};
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        UserProfile.fromJson(
          (value as Map<String, dynamic>).cast<String, Object?>(),
        ),
      ),
    );
  }

  Map<String, _Credential> _readCredentials() {
    final encoded = _preferences.getString(_credentialsKey);
    if (encoded == null) return {};
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        _Credential.fromJson(
          (value as Map<String, dynamic>).cast<String, Object?>(),
        ),
      ),
    );
  }

  Future<void> _writeProfiles(Map<String, UserProfile> profiles) {
    return _preferences.setString(
      _profilesKey,
      jsonEncode(profiles.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }

  Future<void> _writeCredentials(Map<String, _Credential> credentials) {
    return _preferences.setString(
      _credentialsKey,
      jsonEncode(
        credentials.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  Future<void> _migrateLegacyAccount() async {
    if (_preferences.containsKey(_profilesKey)) return;
    final profileJson = _preferences.getString(_legacyProfileKey);
    final salt = _preferences.getString(_legacySaltKey);
    final hash = _preferences.getString(_legacyHashKey);
    if (profileJson == null || salt == null || hash == null) return;

    final profile = UserProfile.fromJson(
      (jsonDecode(profileJson) as Map<String, dynamic>).cast<String, Object?>(),
    );
    final key = _normalizeUsername(profile.username);
    await _writeProfiles({key: profile});
    await _writeCredentials({key: _Credential(salt: salt, hash: hash)});
  }

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _createSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}

class _Credential {
  const _Credential({required this.salt, required this.hash});

  final String salt;
  final String hash;

  Map<String, String> toJson() => {'salt': salt, 'hash': hash};

  factory _Credential.fromJson(Map<String, Object?> json) => _Credential(
        salt: json['salt']! as String,
        hash: json['hash']! as String,
      );
}
