import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/network/api_client.dart';

class NotificationProvider with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _notifications = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<dynamic> get notifications => _notifications;

  Future<void> fetchNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiClient.get('/notifications');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _notifications = data['data'];
      } else {
        _errorMessage = data['message'] ?? 'Gagal memuat notifikasi.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await ApiClient.post('/notifications/$notificationId/read', {});
      if (response.statusCode == 200) {
        // Perbarui status lokal agar UI langsung bereaksi tanpa fetch ulang
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = 1; // atau true
          notifyListeners();
        }
      }
    } catch (e) {
      // Gagal tandai dibaca, abaikan saja (fail silently) agar tidak mengganggu UX
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
