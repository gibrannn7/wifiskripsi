import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/network/api_client.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, dynamic>? _dashboardData;
  List<dynamic> _packages = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<dynamic> get packages => _packages;

  Future<void> fetchData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Melakukan fetch secara paralel untuk efisiensi
      final results = await Future.wait([
        ApiClient.get('/dashboard-status'),
        ApiClient.get('/packages'),
      ]);

      final statusResponse = results[0];
      final packageResponse = results[1];

      if (statusResponse.statusCode == 200 && packageResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        final packageData = jsonDecode(packageResponse.body);

        if (statusData['success'] == true) {
          _dashboardData = statusData['data'];
        }

        if (packageData['success'] == true) {
          _packages = packageData['data'];
        }
      } else {
        _errorMessage = 'Gagal memuat data dari server.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi utilitas untuk mengecek ketersediaan notifikasi belum terbaca
  int get unreadNotificationsCount {
    if (_dashboardData != null && _dashboardData!['notifications'] != null) {
      return _dashboardData!['notifications']['unread_count'] ?? 0;
    }
    return 0;
  }
}
