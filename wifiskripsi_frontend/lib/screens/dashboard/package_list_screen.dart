import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifiskripsi_frontend/providers/dashboard_provider.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';
import 'package:wifiskripsi_frontend/screens/dashboard/package_detail_screen.dart';
import 'package:wifiskripsi_frontend/models/package_model.dart';
import 'package:intl/intl.dart';

class PackageListScreen extends StatelessWidget {
  const PackageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.nightDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Semua Paket Wi-Fi',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: AppColors.textWhite,
          ),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading && dashboard.packages.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBright));
          }

          final packages = dashboard.packages;

          if (packages.isEmpty) {
            return Center(
              child: Text(
                'Belum ada paket tersedia.',
                style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Mengatur rasio aspek kartu agar muat dengan teks dan tombol
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final pkg = packages[index];
              return _buildGridCard(context, pkg);
            },
          );
        },
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, PackageModel pkg) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final isPromoted = pkg.isPromoted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToDetail(context, pkg),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
        color: AppColors.textWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPromoted ? Border.all(color: AppColors.primaryBright, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Icon & Badge)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isPromoted ? AppColors.primaryBright.withValues(alpha: 0.1) : AppColors.bgCanvas,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wifi_rounded,
                  size: 32,
                  color: isPromoted ? AppColors.primaryBright : AppColors.nightDark,
                ),
                if (isPromoted) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBright,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PROMO',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          
          // Body (Details)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pkg.packageName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.nightDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pkg.speedMbps} Mbps | ${pkg.durationDays} Hari',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Harga
                  if (isPromoted) ...[
                    Text(
                      formatCurrency.format(pkg.price * 1.3), // Simulasi coret
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  Text(
                    formatCurrency.format(pkg.price),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryBright,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Button Beli
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToDetail(context, pkg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nightDark,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Beli',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, PackageModel pkg) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailScreen(package: pkg),
      ),
    );
  }
}
