import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';
import 'package:wifiskripsi_frontend/core/network/api_client.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _faqs = [];

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiClient.get('/faqs');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _faqs = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Gagal memuat FAQ.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _contactAdmin() async {
    final Uri url = Uri.parse(
      'https://wa.me/6281998305863?text=Halo%20Admin%20Wifiskripsi,%20saya%20butuh%20bantuan',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka WhatsApp.'),
          backgroundColor: AppColors.statusInactive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.darkWine,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Pusat Bantuan (FAQ)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactAdmin,
        backgroundColor: AppColors.statusActive,
        icon: const Icon(Icons.chat_rounded, color: AppColors.textWhite),
        label: const Text(
          'Hubungi Admin',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: AppTextStyles.medium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFaqs,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBright,
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: AppColors.textWhite),
              ),
            ),
          ],
        ),
      );
    }

    if (_faqs.isEmpty) {
      return Center(
        child: Text(
          'Belum ada informasi bantuan.',
          style: AppTextStyles.medium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryBright,
      onRefresh: _fetchFaqs,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: 80,
        ),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            child: ExpansionTile(
              title: Text(
                faq['question'] ?? '-',
                style: AppTextStyles.semiBold.copyWith(fontSize: 14),
              ),
              iconColor: AppColors.primaryBright,
              collapsedIconColor: AppColors.textSecondary,
              childrenPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq['answer'] ?? '-',
                    style: AppTextStyles.regular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
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
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(height: 60),
          ),
        );
      },
    );
  }
}
