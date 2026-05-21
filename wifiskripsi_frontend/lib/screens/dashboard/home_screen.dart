import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/constants/app_assets.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';
import 'package:wifiskripsi_frontend/providers/dashboard_provider.dart';
import 'package:wifiskripsi_frontend/providers/auth_provider.dart';
import 'package:wifiskripsi_frontend/providers/transaction_provider.dart';
import 'package:wifiskripsi_frontend/screens/auth/login_screen.dart';
import 'package:wifiskripsi_frontend/models/user_model.dart';
import 'package:wifiskripsi_frontend/screens/dashboard/package_detail_screen.dart';
import 'package:wifiskripsi_frontend/models/package_model.dart';
import 'package:wifiskripsi_frontend/screens/dashboard/history_screen.dart';
import 'package:wifiskripsi_frontend/screens/dashboard/notification_screen.dart';
import 'package:wifiskripsi_frontend/screens/dashboard/faq_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    // Meminta pembaruan data secara asinkron tanpa menghentikan siklus hidup UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchData();
    });

    // Menjalankan jam digital
    _currentTime = _formatTime(DateTime.now());
    _currentDate = _formatDate(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          _currentTime = _formatTime(now);
          _currentDate = _formatDate(now);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(amount);
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
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
        backgroundColor: AppColors.nightDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(AppAssets.logo),
        ),
        title: const Text(
          'WIFISKRIPSI',
          style: TextStyle(
            fontFamily: AppAssets.fontInter,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textWhite,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, dashboard, child) {
              final unreadCount = dashboard.unreadNotificationsCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textWhite),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.statusInactive,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textWhite),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading) {
            return _buildSkeletonLoading();
          }

          if (dashboard.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dashboard.errorMessage, style: AppTextStyles.medium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dashboard.fetchData(),
                    child: const Text('Coba Lagi'),
                  )
                ],
              ),
            );
          }

          final userData = dashboard.userData;
          final connectionData = dashboard.connectionData;
          final telemetryData = dashboard.telemetryData;
          final packages = dashboard.packages;

          return RefreshIndicator(
            color: AppColors.primaryBright,
            onRefresh: () => dashboard.fetchData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latar Belakang Header Transisi
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.nightDark,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  // Widget 1: User Context Floating Card
                  Transform.translate(
                    offset: const Offset(0, -60), // Dikurangi agar jarak bawah tidak terlalu renggang
                    child: _buildUserCard(userData),
                  ),
                  
                  // Widget 2: Connection Telemetry Card
                  Transform.translate(
                    offset: const Offset(0, -50), // Ditarik ke atas agar dekat dengan User Card
                    child: _buildTelemetryCard(connectionData, telemetryData),
                  ),
                  
                  // Widget 3: Penawaran Terbaik (Carousel)
                  Transform.translate(
                    offset: const Offset(0, -20), // Ditarik ke atas
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Penawaran Terbaik',
                        style: AppTextStyles.bold.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: _buildPackagesCarousel(packages),
                  ),
                  
                  const SizedBox(height: 120), // Bantalan aman bawah Navbar melayang
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel? user) {
    final String name = user?.name ?? 'Pengguna';
    final String phone = user?.phone ?? '-';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.textWhite,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Jam dan Tanggal Digital
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentTime,
                    style: AppTextStyles.bold.copyWith(
                      color: AppColors.primaryBright,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    _currentDate,
                    style: AppTextStyles.medium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1),
              
              // Profil Singkat
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.deepMaroon.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: AppTextStyles.bold.copyWith(
                        color: AppColors.deepMaroon,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.semiBold.copyWith(fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: AppTextStyles.regular.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    child: _buildActionItem(Icons.receipt_long_rounded, 'Riwayat'),
                  ),
                  _buildActionItem(Icons.send_rounded, 'Kirim'),
                  _buildActionItem(Icons.money_rounded, 'Tarik'),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FaqScreen()),
                      );
                    },
                    child: _buildActionItem(Icons.help_outline_rounded, 'Bantuan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: AppColors.darkWine, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.medium.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard(Map<String, dynamic> connection, Map<String, dynamic> telemetry) {
    final bool isActive = connection['is_active'] == true;
    final int daysRemaining = double.tryParse(connection['days_remaining']?.toString() ?? '0')?.toInt() ?? 0;
    final double upload = (telemetry['upload_mbps'] ?? 0).toDouble();
    final double download = (telemetry['download_mbps'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.darkWine, AppColors.nightDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'KONEKSI JARINGAN',
                      style: AppTextStyles.semiBold.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.7),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.statusActive : AppColors.statusInactive,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'STATUS: AKTIF ($daysRemaining Hari)' : 'TIDAK AKTIF',
                      style: AppTextStyles.bold.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Telemetri Angka
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpeedIndicator(Icons.arrow_downward_rounded, 'Unduh', download),
                  Container(width: 1, height: 40, color: AppColors.textWhite.withValues(alpha: 0.2)),
                  _buildSpeedIndicator(Icons.arrow_upward_rounded, 'Unggah', upload),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Grafik FL-Chart (Kurva Halus Tanpa Grid)
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateSmoothData(download),
                        isCurved: true,
                        color: Colors.greenAccent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.greenAccent.withValues(alpha: 0.1),
                        ),
                      ),
                      LineChartBarData(
                        spots: _generateSmoothData(upload, offset: 20),
                        isCurved: true,
                        color: Colors.orangeAccent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedIndicator(IconData icon, String label, double speed) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textWhite.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.regular.copyWith(
                color: AppColors.textWhite.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              speed.toStringAsFixed(1),
              style: AppTextStyles.bold.copyWith(
                color: AppColors.textWhite,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                'Mbps',
                style: AppTextStyles.medium.copyWith(
                  color: AppColors.textWhite.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Fungsi utilitas untuk membuat data grafik palsu berdasarkan kecepatan asli agar grafik terlihat nyata
  List<FlSpot> _generateSmoothData(double baseSpeed, {double offset = 0}) {
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      // Fluktuasi acak yang masuk akal
      double fluctuation = (i % 2 == 0) ? (baseSpeed * 0.1) : -(baseSpeed * 0.1);
      spots.add(FlSpot(i.toDouble(), (baseSpeed + offset + fluctuation).clamp(0, 200)));
    }
    return spots;
  }

  Widget _buildPackagesCarousel(List<PackageModel> packages) {
    if (packages.isEmpty) {
      return const Center(child: Text('Tidak ada paket tersedia.'));
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final package = packages[index];
          final bool isPromoted = package.isPromoted;
          final double currentPrice = package.price.toDouble();
          
          // Memanipulasi harga inti jika dipromosikan (diskon seolah-olah 30% lebih mahal aslinya)
          final double fakeOriginalPrice = isPromoted ? currentPrice * 1.3 : currentPrice;

          return Container(
            width: 260,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.packageName,
                          style: AppTextStyles.bold.copyWith(
                            color: AppColors.darkWine,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.speed_rounded, size: 16, color: AppColors.statusActive),
                            const SizedBox(width: 4),
                            Text(
                              '${package.speedMbps} Mbps • ${package.durationDays} Hari',
                              style: AppTextStyles.medium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        
                        // Logika Harga Coret
                        if (isPromoted)
                          Text(
                            _formatCurrency(fakeOriginalPrice),
                            style: AppTextStyles.strikethrough.copyWith(fontSize: 12),
                          ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(currentPrice),
                              style: AppTextStyles.bold.copyWith(
                                color: AppColors.primaryBright,
                                fontSize: 20,
                              ),
                            ),
                            Consumer<TransactionProvider>(
                              builder: (context, txProvider, child) {
                                return ElevatedButton(
                                  onPressed: txProvider.isLoading 
                                      ? null 
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PackageDetailScreen(package: package),
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.darkWine,
                                    foregroundColor: AppColors.textWhite,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: txProvider.isLoading
                                      ? const SizedBox(
                                          width: 16, height: 16, 
                                          child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2)
                                        )
                                      : const Text('Beli', style: TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Stiker Banner Promosi menggunakan Stack
                  if (isPromoted)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Image.asset(
                          AppAssets.promoBanner,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppColors.primaryBright,
                              child: const Icon(Icons.star_rounded, color: Colors.yellow),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Kerangka Skeleton Loading (Shimmer)
  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
            // Skeleton User Card
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            
            // Skeleton Telemetry
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            
            // Skeleton Carousel Title
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(width: 150, height: 20, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            
            // Skeleton Carousel Item
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 260,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
