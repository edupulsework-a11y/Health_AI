import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final secureStorageProvider = Provider<SecureStorageHelper>((ref) => SecureStorageHelper());

class SecureStorageHelper {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.authTokenKey, value: token);

  Future<String?> getToken() =>
      _storage.read(key: AppConstants.authTokenKey);

  Future<void> deleteToken() =>
      _storage.delete(key: AppConstants.authTokenKey);

  Future<void> saveWalletKey(String key) =>
      _storage.write(key: AppConstants.walletKeyRef, value: key);

  Future<String?> getWalletKey() =>
      _storage.read(key: AppConstants.walletKeyRef);

  Future<void> clearAll() => _storage.deleteAll();
}
