import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';

class SnapWebviewScreen extends StatefulWidget {
  final String redirectUrl;

  const SnapWebviewScreen({super.key, required this.redirectUrl});

  @override
  State<SnapWebviewScreen> createState() => _SnapWebviewScreenState();
}

class _SnapWebviewScreenState extends State<SnapWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            // Intersepsi Callback Webhook/Simulasi Selesai dari Midtrans
            // Midtrans Sandbox biasanya mengarahkan kembali dengan memuat keyword tertentu
            // Atau Anda bisa mendeteksi return URL yang Anda atur di dashboard Midtrans.
            if (url.contains('sukses.wifiskripsi.com') ||
                url.contains('transaction_status=settlement') || 
                url.contains('transaction_status=capture') ||
                url.contains('transaction_status=success') ||
                url.contains('transaction_status=deny') ||
                url.contains('transaction_status=cancel') ||
                url.contains('gojek://') || // Deteksi deeplink GoPay
                url.contains('shopeepay://')) {
              
              // Menutup halaman webview dengan status selesai
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
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
          'Pembayaran Keamanan Tinggi',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBright,
              ),
            ),
        ],
      ),
    );
  }
}
