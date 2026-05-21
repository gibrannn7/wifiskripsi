import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/network/api_client.dart';
import 'package:wifiskripsi_frontend/models/package_model.dart';
import 'package:wifiskripsi_frontend/models/transaction_model.dart';
import 'package:wifiskripsi_frontend/models/user_model.dart';

class AdminProvider with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  int _totalRevenue = 0;
  int _totalTransactions = 0;
  int _totalUsersMetrics = 0;
  String _bestSellingPackage = '';
  List<Map<String, dynamic>> _chartDataCurrent = [];
  List<Map<String, dynamic>> _chartDataLast = [];

  List<PackageModel> _packages = [];
  List<TransactionModel> _transactions = [];
  List<UserModel> _users = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get totalRevenue => _totalRevenue;
  int get totalTransactions => _totalTransactions;
  int get totalUsersMetrics => _totalUsersMetrics;
  String get bestSellingPackage => _bestSellingPackage;
  List<Map<String, dynamic>> get chartDataCurrent => _chartDataCurrent;
  List<Map<String, dynamic>> get chartDataLast => _chartDataLast;
  List<PackageModel> get packages => _packages;
  List<TransactionModel> get transactions => _transactions;
  List<UserModel> get users => _users;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchAnalytics() async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final response = await ApiClient.get('/admin/analytics');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _totalRevenue = data['total_revenue'] ?? 0;
        _totalTransactions = data['total_transactions'] ?? 0;
        _totalUsersMetrics = data['total_users'] ?? 0;
        _bestSellingPackage = data['best_selling_package'] ?? 'Belum Ada';
        _chartDataCurrent = List<Map<String, dynamic>>.from(data['chart_data_current'] ?? []);
        _chartDataLast = List<Map<String, dynamic>>.from(data['chart_data_last'] ?? []);
      } else {
        _setError('Gagal memuat analitik');
      }
    } catch (e) {
      _setError('Terjadi kesalahan jaringan');
    }
    _setLoading(false);
  }

  Future<void> fetchPackages() async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final response = await ApiClient.get('/packages'); // Boleh pakai yang publik/user
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> packageList = data['data'];
        _packages = packageList.map((json) => PackageModel.fromJson(json)).toList();
      } else {
        _setError('Gagal memuat paket');
      }
    } catch (e) {
      _setError('Terjadi kesalahan jaringan');
    }
    _setLoading(false);
  }

  Future<bool> createPackage(Map<String, dynamic> packageData) async {
    _setLoading(true);
    try {
      final response = await ApiClient.post('/admin/packages', packageData);
      if (response.statusCode == 201) {
        await fetchPackages();
        return true;
      }
    } catch (e) {
      _setError('Gagal membuat paket');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updatePackage(int id, Map<String, dynamic> packageData) async {
    _setLoading(true);
    try {
      final response = await ApiClient.put('/admin/packages/$id', packageData);
      if (response.statusCode == 200) {
        await fetchPackages();
        return true;
      }
    } catch (e) {
      _setError('Gagal memperbarui paket');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> deletePackage(int id) async {
    _setLoading(true);
    try {
      final response = await ApiClient.delete('/admin/packages/$id');
      if (response.statusCode == 200) {
        await fetchPackages();
        return true;
      }
    } catch (e) {
      _setError('Gagal menghapus paket');
    }
    _setLoading(false);
    return false;
  }

  Future<void> fetchTransactions() async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final response = await ApiClient.get('/admin/transactions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> txList = data['data'];
        _transactions = txList.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        _setError('Gagal memuat transaksi');
      }
    } catch (e) {
      _setError('Terjadi kesalahan jaringan');
    }
    _setLoading(false);
  }

  Future<void> fetchUsers() async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final response = await ApiClient.get('/admin/users');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> userList = data['data'];
        _users = userList.map((json) => UserModel.fromJson(json)).toList();
      } else {
        _setError('Gagal memuat pengguna');
      }
    } catch (e) {
      _setError('Terjadi kesalahan jaringan');
    }
    _setLoading(false);
  }

  Future<bool> sendNotification(int userId, String title, String message) async {
    _setLoading(true);
    try {
      final response = await ApiClient.post('/admin/notifications/send', {
        'user_id': userId,
        'title': title,
        'message': message,
      });
      if (response.statusCode == 201) {
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError('Gagal mengirim notifikasi');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> broadcastNotification(String title, String message) async {
    _setLoading(true);
    try {
      final response = await ApiClient.post('/admin/notifications/broadcast', {
        'title': title,
        'message': message,
      });
      if (response.statusCode == 201) {
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError('Gagal mengirim notifikasi massal');
    }
    _setLoading(false);
    return false;
  }
}
