import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';
import 'package:wifiskripsi_frontend/models/package_model.dart';
import 'package:wifiskripsi_frontend/providers/transaction_provider.dart';
import 'package:wifiskripsi_frontend/screens/dashboard/snap_webview_screen.dart';
import 'package:wifiskripsi_frontend/widgets/custom_dialog.dart';
import 'package:intl/intl.dart';

class PackageDetailScreen extends StatefulWidget {
  final PackageModel package;

  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final _formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  Future<void> _handleCheckout(BuildContext context) async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Konversi ke int murni agar aman untuk Midtrans
    final packageId = widget.package.id;
    
    final result = await txProvider.checkout(packageId);
    
    if (!context.mounted) return;

    if (result != null && result['redirect_url'] != null) {
      final isSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SnapWebviewScreen(
            redirectUrl: result['redirect_url'],
          ),
        ),
      );

      if (isSuccess == true && context.mounted) {
        CustomDialog.showSuccess(
          context,
          'Transaksi Selesai!',
          'Pembayaran paket berhasil dan sedang diproses.',
          autoDismiss: true,
          onConfirm: () {
            if (context.mounted) Navigator.pop(context); // Kembali ke list/beranda
          },
        );
      } else if (isSuccess == false && context.mounted) {
        CustomDialog.showError(
          context,
          'Transaksi Batal',
          'Pembayaran tidak diselesaikan.',
        );
      }
    } else {
      CustomDialog.showError(
        context,
        'Gagal Checkout',
        txProvider.errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final bool isPromoted = pkg.isPromoted;
    final double currentPrice = pkg.price.toDouble();
    final double fakeOriginalPrice = isPromoted ? currentPrice * 1.3 : currentPrice;

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
          'Detail Paket',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image/Hero Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.textWhite,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.wifi_rounded,
                    size: 80,
                    color: isPromoted ? AppColors.primaryBright : AppColors.nightDark,
                  ),
                  const SizedBox(height: 16),
                  if (isPromoted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PENAWARAN TERBAIK',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  Text(
                    pkg.packageName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bold.copyWith(fontSize: 24, color: AppColors.nightDark),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniBadge(Icons.speed_rounded, '${pkg.speedMbps} Mbps'),
                      const SizedBox(width: 16),
                      _buildMiniBadge(Icons.timer_rounded, '${pkg.durationDays} Hari'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isPromoted)
                    Text(
                      _formatCurrency.format(fakeOriginalPrice),
                      style: AppTextStyles.strikethrough.copyWith(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  Text(
                    _formatCurrency.format(currentPrice),
                    style: AppTextStyles.bold.copyWith(fontSize: 32, color: AppColors.primaryBright),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Fitur/Manfaat Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Manfaat Utama',
                style: AppTextStyles.bold.copyWith(fontSize: 18, color: AppColors.nightDark),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.textWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem('Kuota Tanpa Batas / FUP'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                    _buildFeatureItem('Koneksi Stabil 24/7'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                    _buildFeatureItem('Cocok untuk 4-5 Perangkat Sekaligus'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Konfirmasi & Bayar Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Consumer<TransactionProvider>(
                builder: (context, txProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: txProvider.isLoading ? null : () => _handleCheckout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkWine,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.darkWine.withValues(alpha: 0.5),
                      ),
                      child: txProvider.isLoading
                          ? const CircularProgressIndicator(color: AppColors.textWhite)
                          : const Text(
                              'Konfirmasi & Bayar Sekarang',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textWhite,
                              ),
                            ),
                    ),
                  );
                }
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.darkWine),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.semiBold.copyWith(fontSize: 14, color: AppColors.darkWine),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.statusActive.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 16, color: AppColors.statusActive),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.medium.copyWith(fontSize: 14, color: AppColors.nightDark),
          ),
        ),
      ],
    );
  }
}
