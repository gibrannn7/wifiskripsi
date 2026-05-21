import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/network/api_client.dart';
import 'package:wifiskripsi_frontend/models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<TransactionModel> _transactions = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<TransactionModel> get transactions => _transactions;

  /// Memulai proses pembayaran paket (Checkout)
  Future<Map<String, dynamic>?> checkout(int packageId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiClient.post('/checkout', {
        'package_id': packageId,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _setLoading(false);
        return data['data']; // Mengembalikan order_id, snap_token, redirect_url
      } else {
        _errorMessage = data['message'] ?? 'Gagal membuat transaksi.';
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan.';
      _setLoading(false);
      return null;
    }
  }

  /// Mengambil data riwayat transaksi
  Future<void> fetchHistory() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiClient.get('/transactions');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _transactions = (data['data'] as List).map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        _errorMessage = data['message'] ?? 'Gagal memuat riwayat transaksi.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan.';
    } finally {
      _setLoading(false);
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
