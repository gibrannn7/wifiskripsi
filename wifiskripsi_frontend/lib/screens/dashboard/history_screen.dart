import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';
import 'package:wifiskripsi_frontend/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).fetchHistory();
    });
  }

  String _formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(amount);
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'settlement':
      case 'capture':
        return AppColors.statusActive; // Hijau
      case 'pending':
        return Colors.orange; // Kuning
      case 'cancel':
      case 'deny':
      case 'expire':
      case 'failed':
        return AppColors.statusInactive; // Merah
      default:
        return AppColors.textSecondary;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'settlement':
      case 'capture':
        return 'BERHASIL';
      case 'pending':
        return 'TERTUNDA';
      case 'cancel':
        return 'DIBATALKAN';
      case 'deny':
        return 'DITOLAK';
      case 'expire':
        return 'KEDALUWARSA';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.nightDark, AppColors.darkWine],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildSkeletonLoading();
          }

          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage, style: AppTextStyles.medium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchHistory(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBright),
                    child: const Text('Coba Lagi', style: TextStyle(color: AppColors.textWhite)),
                  )
                ],
              ),
            );
          }

          if (provider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada transaksi',
                    style: AppTextStyles.semiBold.copyWith(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryBright,
            onRefresh: () => provider.fetchHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.transactions.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.transactions.length) {
                  return const SizedBox(height: 120);
                }

                final tx = provider.transactions[index];
                final double amount = tx.grossAmount.toDouble();
                final status = tx.status;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tx.orderId,
                              style: AppTextStyles.medium.copyWith(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _getStatusColor(status)),
                              ),
                              child: Text(
                                _translateStatus(status),
                                style: AppTextStyles.bold.copyWith(color: _getStatusColor(status), fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bgCanvas,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.wifi_rounded, color: AppColors.darkWine),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.packageName ?? 'Paket Wi-Fi',
                                    style: AppTextStyles.semiBold.copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(tx.createdAt),
                                    style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(amount),
                              style: AppTextStyles.bold.copyWith(color: AppColors.primaryBright, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16.0),
            ),
          ),
        );
      },
    );
  }
}
