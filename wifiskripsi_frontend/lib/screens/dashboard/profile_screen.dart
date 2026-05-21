import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/theme/app_text_styles.dart';
import 'package:wifiskripsi_frontend/providers/auth_provider.dart';
import 'package:wifiskripsi_frontend/providers/dashboard_provider.dart';
import 'package:wifiskripsi_frontend/screens/auth/login_screen.dart';
import 'package:wifiskripsi_frontend/widgets/custom_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  void _toggleEdit(String currentPhone, String currentAddress) {
    if (!_isEditing) {
      _phoneController.text = currentPhone;
      _addressController.text = currentAddress;
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() async {
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (phone.isEmpty || address.isEmpty) {
      CustomDialog.showError(context, 'Validasi Gagal', 'Semua kolom harus diisi.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(phone, address);

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      Provider.of<DashboardProvider>(context, listen: false).fetchData();
      CustomDialog.showSuccess(context, 'Berhasil', 'Profil Anda telah diperbarui.');
    } else if (mounted) {
      CustomDialog.showError(context, 'Gagal', authProvider.errorMessage);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
          'Profil Pengguna',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: AppColors.textWhite,
          ),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading && dashboard.userData == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBright),
            );
          }

          final user = dashboard.userData;
          if (user == null) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profil Avatar
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryBright,
                            width: 2,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.textSecondary,
                          child: Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: AppTextStyles.bold.copyWith(color: AppColors.nightDark, fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.nightDark.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID Router: ${user.routerId}',
                          style: AppTextStyles.regular.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.nightDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Informasi Detail Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Informasi Akun',
                      style: AppTextStyles.bold.copyWith(color: AppColors.textPrimary, fontSize: 18),
                    ),
                    if (!_isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBright),
                        onPressed: () => _toggleEdit(user.phone, user.address),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.statusInactive),
                        onPressed: () => _toggleEdit(user.phone, user.address),
                      )
                  ],
                ),
                const SizedBox(height: 12),
                Container(
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
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email_outlined, 'Surel', user.email, isMultiline: false),
                      const Divider(height: 1, indent: 56),
                      _buildInfoRow(Icons.phone_outlined, 'Nomor Telepon', user.phone, isMultiline: false, controller: _phoneController, keyboardType: TextInputType.phone),
                      const Divider(height: 1, indent: 56),
                      _buildInfoRow(Icons.home_outlined, 'Alamat Pemasangan', user.address, isMultiline: true, controller: _addressController),
                    ],
                  ),
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: auth.isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBright,
                            foregroundColor: AppColors.textWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: auth.isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded),
                          label: Text(auth.isLoading ? 'Menyimpan...' : 'Simpan Profil'),
                        ),
                      );
                    }
                  )
                ],

                const SizedBox(height: 48),

                // Tombol Logout
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutConfirmation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusInactive,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Keluar (Logout)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isMultiline = false, TextEditingController? controller, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: isMultiline || (_isEditing && controller != null) ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgCanvas,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryBright, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                if (_isEditing && controller != null)
                  TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    maxLines: isMultiline ? 3 : 1,
                    style: AppTextStyles.regular.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.nightDark,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryBright),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryBright),
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: AppTextStyles.regular.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.nightDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              
              if (!context.mounted) return;
              
              // Arahkan ke LoginScreen dan hapus semua riwayat rute
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusInactive,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }
}
