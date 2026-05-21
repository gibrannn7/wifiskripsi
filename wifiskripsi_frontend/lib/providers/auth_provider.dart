import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifiskripsi_frontend/core/network/api_client.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Melakukan proses masuk (Login)
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiClient.post('/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['access_token'];
        final role = data['data']['user']['role'] ?? 'user';
        await _saveAuthData(token, role);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal masuk. Periksa kembali kredensial Anda.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan atau server.';
      _setLoading(false);
      return false;
    }
  }

  /// Melakukan proses pendaftaran (Register)
  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiClient.post('/register', userData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['data']['access_token'];
        final role = data['data']['user']['role'] ?? 'user';
        await _saveAuthData(token, role);
        _setLoading(false);
        return true;
      } else {
        // Menangkap pesan error dari validasi backend Laravel
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          _errorMessage = errors.values.first[0]; // Ambil pesan error pertama
        } else {
          _errorMessage = data['message'] ?? 'Pendaftaran gagal.';
        }
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan atau server.';
      _setLoading(false);
      return false;
    }
  }

  /// Menyimpan token autentikasi dan role ke penyimpanan lokal
  Future<void> _saveAuthData(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_role', role);
  }

  /// Keluar (Logout) dan menghapus token lokal
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await ApiClient.post('/logout', {});
    } catch (e) {
      // Abaikan error jaringan saat logout
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    
    _setLoading(false);
  }

  /// Memperbarui profil pengguna (Nomor Telepon & Alamat)
  Future<bool> updateProfile(String phone, String address) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiClient.put('/profile/update', {
        'phone': phone,
        'address': address,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          _errorMessage = errors.values.first[0];
        } else {
          _errorMessage = data['message'] ?? 'Gagal memperbarui profil.';
        }
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan atau server.';
      _setLoading(false);
      return false;
    }
  }

  /// Mengelola status loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Membersihkan pesan error
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
