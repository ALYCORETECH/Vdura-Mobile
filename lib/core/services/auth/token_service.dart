import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sales_management/core/models/auth_response.dart';

class TokenService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';
  static const _usernameKey = 'user_username';
  static const _dealerIdKey = 'dealer_id';
  static const _fullNameKey = 'user_fullname';
  static const _salesIdKey = 'sales_id';
  static const _activeTripIdKey = 'active_trip_id';
  static const _activeTripStartKey = 'active_trip_start';

  // ── AUTOREFILL KEYS ──
  static const _savedUsernameKey = 'saved_username';
  static const _savedPasswordKey = 'saved_password';

  Future<void> saveSession(AuthResponse authData) async {
    await _storage.write(key: _tokenKey, value: authData.token);
    await _storage.write(key: _userIdKey, value: authData.userId.toString());
    await _storage.write(key: _roleKey, value: authData.role);
    await _storage.write(key: _usernameKey, value: authData.username);
    await _storage.write(key: _fullNameKey, value: authData.fullName);

    if (authData.dealerId != null) {
      await _storage.write(key: _dealerIdKey, value: authData.dealerId.toString());
    }

    if (authData.salesId != null) {
      await _storage.write(key: _salesIdKey, value: authData.salesId.toString());
    }
  }

  // ── SILENTLY SAVE CREDENTIALS ──
  Future<void> saveLoginCredentials(String username, String password) async {
    await _storage.write(key: _savedUsernameKey, value: username);
    await _storage.write(key: _savedPasswordKey, value: password);
  }

  // ── GET SAVED CREDENTIALS ──
  Future<Map<String, String>?> getSavedCredentials() async {
    final username = await _storage.read(key: _savedUsernameKey);
    final password = await _storage.read(key: _savedPasswordKey);

    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getSalesId() async {
    return await _storage.read(key: _salesIdKey);
  }

  Future<String?> getFullName() async {
    return await _storage.read(key: _fullNameKey);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // ── CLEAR SESSION (Preserving Saved Credentials & Active Trip) ──
  Future<void> clearSession() async {
    // DO NOT use _storage.deleteAll() because it wipes the active trip!
    // If the active trip is wiped, the background location isolate will kill itself.
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _fullNameKey);
    await _storage.delete(key: _dealerIdKey);
    await _storage.delete(key: _salesIdKey);
  }

  Future<void> saveActiveTrip(int tripId, DateTime startedAt) async {
    await _storage.write(key: _activeTripIdKey, value: tripId.toString());
    await _storage.write(key: _activeTripStartKey, value: startedAt.toIso8601String());
  }

  // ── GET ACTIVE TRIP ──
  Future<Map<String, dynamic>?> getActiveTrip() async {
    final tripId = await _storage.read(key: _activeTripIdKey);
    final startedAt = await _storage.read(key: _activeTripStartKey);

    if (tripId != null && startedAt != null) {
      return {
        'id': int.parse(tripId),
        'startedAt': DateTime.parse(startedAt),
      };
    }
    return null;
  }

  // ── CLEAR ACTIVE TRIP (On Punch Out) ──
  Future<void> clearActiveTrip() async {
    await _storage.delete(key: _activeTripIdKey);
    await _storage.delete(key: _activeTripStartKey);
  }
}