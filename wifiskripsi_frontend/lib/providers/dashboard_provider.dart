import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/network/api_client.dart';
import 'package:wifiskripsi_frontend/models/user_model.dart';
import 'package:wifiskripsi_frontend/models/package_model.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, dynamic>? _dashboardData;
  UserModel? _userData;
  List<PackageModel> _packages = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<PackageModel> get packages => _packages;
  
  UserModel? get userData => _userData;
  Map<String, dynamic> get connectionData => _dashboardData?['connection'] ?? {};
  Map<String, dynamic> get telemetryData => _dashboardData?['telemetry'] ?? {};

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
          if (_dashboardData != null && _dashboardData!['user'] != null) {
            _userData = UserModel.fromJson(_dashboardData!['user']);
          }
        }

        if (packageData['success'] == true) {
          _packages = (packageData['data'] as List).map((json) => PackageModel.fromJson(json)).toList();
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
