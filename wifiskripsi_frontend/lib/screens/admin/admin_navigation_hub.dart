import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';
import 'package:wifiskripsi_frontend/screens/auth/login_screen.dart';
import 'package:wifiskripsi_frontend/providers/admin_provider.dart';
import 'package:wifiskripsi_frontend/models/package_model.dart';
import 'package:wifiskripsi_frontend/widgets/custom_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminNavigationHub extends StatefulWidget {
  final int initialIndex;
  
  const AdminNavigationHub({super.key, this.initialIndex = 0});

  @override
  State<AdminNavigationHub> createState() => _AdminNavigationHubState();
}

class _AdminNavigationHubState extends State<AdminNavigationHub> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const _AnalyticsTab(),
    const _PackagesTab(),
    const _TransactionsTab(),
    const _UsersTab(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  void _fetchInitialData() {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    provider.fetchAnalytics();
    provider.fetchPackages();
    provider.fetchTransactions();
    provider.fetchUsers();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
        title: const Text(
          'Dasbor Admin',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textWhite),
            onPressed: _fetchInitialData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textWhite),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0, top: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.nightDark,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.bar_chart_rounded, 'Analitik'),
                    _buildNavItem(1, Icons.wifi_rounded, 'Paket'),
                    _buildNavItem(2, Icons.receipt_long_rounded, 'Transaksi'),
                    _buildNavItem(3, Icons.people_alt_rounded, 'User'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCirc,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0, 
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryBright.withValues(alpha: 0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCirc,
              padding: EdgeInsets.only(right: isSelected ? 6.0 : 0),
              child: Icon(
                icon,
                color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                size: 22,
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCirc,
                alignment: Alignment.centerLeft,
                widthFactor: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.textWhite,
                  ),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: ANALITIK PENDAPATAN
// ==========================================
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.chartDataCurrent.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBright));
        }

        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan Grid (4 Item)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildSummaryCard(
                    'Total Pendapatan',
                    currencyFormatter.format(provider.totalRevenue),
                    Icons.account_balance_wallet_rounded,
                  ),
                  _buildSummaryCard(
                    'Transaksi Sukses',
                    '${provider.totalTransactions}',
                    Icons.check_circle_rounded,
                  ),
                  _buildSummaryCard(
                    'Total Pelanggan',
                    '${provider.totalUsersMetrics}',
                    Icons.people_alt_rounded,
                  ),
                  _buildSummaryCard(
                    'Paket Terlaris',
                    provider.bestSellingPackage,
                    Icons.star_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Komparasi Tren Harian',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
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
                ),
                child: provider.chartDataCurrent.isEmpty
                    ? const Center(child: Text('Belum ada data pendapatan'))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: provider.chartDataLast.map((data) {
                                return FlSpot(data['day'].toDouble(), data['revenue'].toDouble());
                              }).toList(),
                              isCurved: true,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                            ),
                            LineChartBarData(
                              spots: provider.chartDataCurrent.map((data) {
                                return FlSpot(data['day'].toDouble(), data['revenue'].toDouble());
                              }).toList(),
                              isCurved: true,
                              color: AppColors.primaryBright,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primaryBright.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.primaryBright, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Bulan Ini', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 16),
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.5), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Bulan Lalu', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.nightDark, AppColors.darkWine],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBright.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textWhite, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 2: KELOLA PAKET
// ==========================================
class _PackagesTab extends StatelessWidget {
  const _PackagesTab();

  void _showPackageDialog(BuildContext context, {PackageModel? package}) {
    final nameCtrl = TextEditingController(text: package?.packageName ?? '');
    final speedCtrl = TextEditingController(text: package?.speedMbps.toString() ?? '');
    final priceCtrl = TextEditingController(text: package?.price.toString() ?? '');
    final durationCtrl = TextEditingController(text: package?.durationDays.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: AppColors.textWhite,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi_rounded, color: AppColors.primaryBright),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        package == null ? 'Tambah Paket Baru' : 'Edit Paket',
                        style: AppTextStyles.bold.copyWith(color: AppColors.nightDark, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPremiumTextField(nameCtrl, 'Nama Paket', Icons.label_outline_rounded),
                const SizedBox(height: 16),
                _buildPremiumTextField(speedCtrl, 'Kecepatan (Mbps)', Icons.speed_rounded, isNumber: true),
                const SizedBox(height: 16),
                _buildPremiumTextField(priceCtrl, 'Harga (Rp)', Icons.monetization_on_outlined, isNumber: true),
                const SizedBox(height: 16),
                _buildPremiumTextField(durationCtrl, 'Durasi (Hari)', Icons.calendar_today_rounded, isNumber: true),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.textSecondary),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Batal', style: AppTextStyles.bold.copyWith(color: AppColors.textSecondary, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBright,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final provider = Provider.of<AdminProvider>(context, listen: false);
                          final data = {
                            'package_name': nameCtrl.text,
                            'speed_mbps': int.tryParse(speedCtrl.text) ?? 0,
                            'price': int.tryParse(priceCtrl.text) ?? 0,
                            'duration_days': int.tryParse(durationCtrl.text) ?? 0,
                          };
                          
                          bool success;
                          if (package == null) {
                            success = await provider.createPackage(data);
                          } else {
                            success = await provider.updatePackage(package.id, data);
                          }

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          
                          if (success) {
                            CustomDialog.showSuccess(
                              context, 
                              'Berhasil', 
                              package == null ? 'Paket baru berhasil ditambahkan.' : 'Data paket berhasil diperbarui.',
                              autoDismiss: true,
                            );
                          } else {
                            CustomDialog.showError(
                              context, 
                              'Gagal', 
                              'Terjadi kesalahan saat menyimpan data paket.',
                              autoDismiss: true,
                            );
                          }
                        },
                        child: Text('Simpan', style: AppTextStyles.bold.copyWith(color: AppColors.textWhite, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: AppTextStyles.regular.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primaryBright, size: 20),
        filled: true,
        fillColor: AppColors.bgCanvas,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBright),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int packageId) {
    CustomDialog.showConfirmation(
      context,
      'Hapus Paket',
      'Apakah Anda yakin ingin menghapus paket ini dari database?',
      onConfirm: () async {
        final provider = Provider.of<AdminProvider>(context, listen: false);
        final success = await provider.deletePackage(packageId);
        
        if (!context.mounted) return;
        
        if (success) {
          CustomDialog.showSuccess(
            context, 
            'Terhapus', 
            'Paket berhasil dihapus dari database.',
            autoDismiss: true,
          );
        } else {
          CustomDialog.showError(
            context, 
            'Gagal', 
            'Terjadi kesalahan saat menghapus paket.',
            autoDismiss: true,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.packages.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBright));
        }

        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
              itemCount: provider.packages.length,
              itemBuilder: (context, index) {
                final pkg = provider.packages[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi_rounded, color: AppColors.primaryBright),
                    ),
                    title: Text(
                      pkg.packageName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                    subtitle: Text('Kec: ${pkg.speedMbps} Mbps | Harga: ${currencyFormatter.format(pkg.price)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.orange),
                          onPressed: () => _showPackageDialog(context, package: pkg),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: AppColors.statusInactive),
                          onPressed: () => _confirmDelete(context, pkg.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 120,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: AppColors.statusActive,
                onPressed: () => _showPackageDialog(context),
                child: const Icon(Icons.add_rounded, color: AppColors.textWhite),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// TAB 3: TRANSAKSI PELANGGAN
// ==========================================
class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBright));
        }

        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
          itemCount: provider.transactions.length,
          itemBuilder: (context, index) {
            final tx = provider.transactions[index];
            final isSuccess = tx.status == 'success' || tx.status == 'settlement';
            final isPending = tx.status == 'pending';
            
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess 
                        ? AppColors.statusActive.withValues(alpha: 0.1) 
                        : isPending 
                            ? Colors.orange.withValues(alpha: 0.1)
                            : AppColors.statusInactive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : isPending ? Icons.access_time_filled_rounded : Icons.cancel_rounded, 
                    color: isSuccess ? AppColors.statusActive : isPending ? Colors.orange : AppColors.statusInactive
                  ),
                ),
                title: Text(
                  tx.orderId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 14),
                ),
                subtitle: Text('Paket ID: ${tx.packageId}\n${currencyFormatter.format(tx.grossAmount)}'),
                trailing: Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(
                    color: isSuccess ? AppColors.statusActive : isPending ? Colors.orange : AppColors.statusInactive,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// TAB 4: MANAJEMEN USER & NOTIFIKASI
// ==========================================
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  void _showBroadcastDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: AppColors.textWhite,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.primaryBright),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Broadcast Massal',
                        style: AppTextStyles.bold.copyWith(color: AppColors.nightDark, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleCtrl,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Judul Notifikasi',
                    labelStyle: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primaryBright, size: 20),
                    filled: true,
                    fillColor: AppColors.bgCanvas,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryBright),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Pesan Broadcast',
                    alignLabelWithHint: true,
                    labelStyle: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgCanvas,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryBright),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.textSecondary),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Batal', style: AppTextStyles.bold.copyWith(color: AppColors.textSecondary, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBright,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) return;
                          
                          final provider = Provider.of<AdminProvider>(context, listen: false);
                          final success = await provider.broadcastNotification(titleCtrl.text, messageCtrl.text);

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          
                          if (success) {
                            CustomDialog.showSuccess(
                              context, 
                              'Terkirim', 
                              'Pesan massal berhasil dikirim ke semua pelanggan.',
                              autoDismiss: true,
                            );
                          } else {
                            CustomDialog.showError(
                              context, 
                              'Gagal', 
                              'Terjadi kesalahan saat mengirim broadcast.',
                              autoDismiss: true,
                            );
                          }
                        },
                        child: Text('Kirim', style: AppTextStyles.bold.copyWith(color: AppColors.textWhite, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationDialog(BuildContext context, int userId, String userName) {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: AppColors.textWhite,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryBright),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Notifikasi ke $userName',
                        style: AppTextStyles.bold.copyWith(color: AppColors.nightDark, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleCtrl,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Judul Notifikasi',
                    labelStyle: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primaryBright, size: 20),
                    filled: true,
                    fillColor: AppColors.bgCanvas,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryBright),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Pesan',
                    alignLabelWithHint: true,
                    labelStyle: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgCanvas,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryBright),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.textSecondary),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Batal', style: AppTextStyles.bold.copyWith(color: AppColors.textSecondary, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBright,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) return;
                          
                          final provider = Provider.of<AdminProvider>(context, listen: false);
                          final success = await provider.sendNotification(userId, titleCtrl.text, messageCtrl.text);

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          
                          if (success) {
                            CustomDialog.showSuccess(
                              context, 
                              'Terkirim', 
                              'Pesan notifikasi berhasil dikirim ke pelanggan.',
                              autoDismiss: true,
                            );
                          } else {
                            CustomDialog.showError(
                              context, 
                              'Gagal', 
                              'Terjadi kesalahan saat mengirim notifikasi.',
                              autoDismiss: true,
                            );
                          }
                        },
                        child: Text('Kirim', style: AppTextStyles.bold.copyWith(color: AppColors.textWhite, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.users.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBright));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBright,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.campaign_rounded, color: AppColors.textWhite),
                label: Text('Kirim Notifikasi Massal (Broadcast)', style: AppTextStyles.bold.copyWith(color: AppColors.textWhite)),
                onPressed: () => _showBroadcastDialog(context),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
                itemCount: provider.users.length,
                itemBuilder: (context, index) {
                  final user = provider.users[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryBright.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded, color: AppColors.primaryBright),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                      subtitle: Text('${user.email}\n${user.phone}'),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBright,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.notifications_active_rounded, color: AppColors.textWhite, size: 16),
                        label: const Text('Kirim Notif', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                        onPressed: () => _showNotificationDialog(context, user.id, user.name),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
