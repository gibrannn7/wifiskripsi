<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\WifiPackage;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class TransactionController extends Controller
{
    /**
     * Konfigurasi Midtrans
     */
    public function __construct()
    {
        \Midtrans\Config::$serverKey = env('MIDTRANS_SERVER_KEY');
        \Midtrans\Config::$isProduction = env('MIDTRANS_IS_PRODUCTION', false);
        \Midtrans\Config::$isSanitized = env('MIDTRANS_IS_SANITIZED', true);
        \Midtrans\Config::$is3ds = env('MIDTRANS_IS_3DS', true);
    }

    /**
     * Mengambil riwayat transaksi.
     */
    public function getHistory(Request $request)
    {
        $transactions = Transaction::with('wifiPackage')
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat transaksi berhasil diambil.',
            'data' => $transactions
        ], 200);
    }

    /**
     * Membuat transaksi baru (Checkout).
     */
    public function checkout(Request $request)
    {
        $request->validate([
            'package_id' => 'required|exists:wifi_packages,id'
        ], [
            'package_id.required' => 'ID Paket wajib diisi.',
            'package_id.exists' => 'Paket Wi-Fi tidak ditemukan.',
        ]);

        $user = $request->user();
        $package = WifiPackage::findOrFail($request->package_id);

        // Buat Order ID Unik (WS-Timestamp-Random)
        $orderId = 'WS-' . time() . '-' . rand(100, 999);
        $grossAmount = $package->price;

        // Simpan Transaksi ke Database (Status: Pending)
        $transaction = Transaction::create([
            'order_id' => $orderId,
            'user_id' => $user->id,
            'package_id' => $package->id,
            'gross_amount' => $grossAmount,
            'transaction_status' => 'pending',
        ]);

        // Siapkan Parameter Payload Midtrans Snap
        $params = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => (int) $grossAmount,
            ],
            'item_details' => [
                [
                    'id' => 'PKG-' . $package->id,
                    'price' => (int) $grossAmount,
                    'quantity' => 1,
                    'name' => $package->package_name
                ]
            ],
            'customer_details' => [
                'first_name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'billing_address' => [
                    'first_name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'address' => $user->address,
                ]
            ],
        ];

        try {
            // Minta Snap Token dari Midtrans
            $snapToken = \Midtrans\Snap::getSnapToken($params);

            // Simpan Snap Token ke transaksi
            $transaction->update(['snap_token' => $snapToken]);

            return response()->json([
                'success' => true,
                'message' => 'Token transaksi berhasil dibuat.',
                'data' => [
                    'order_id' => $orderId,
                    'snap_token' => $snapToken,
                    'redirect_url' => "https://app.sandbox.midtrans.com/snap/v2/vtweb/" . $snapToken
                ]
            ], 201);

        } catch (\Exception $e) {
            Log::error('Gagal membuat transaksi Midtrans: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal terhubung ke layanan pembayaran. Silakan coba lagi nanti.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Webhook Callback dari Midtrans.
     */
    public function handleCallback(Request $request)
    {
        $serverKey = env('MIDTRANS_SERVER_KEY');
        
        $orderId = $request->order_id;
        $statusCode = $request->status_code;
        $grossAmount = $request->gross_amount;
        $signatureKey = $request->signature_key;

        // 1. Verifikasi Keaslian Signature (SHA512)
        $hashed = hash("sha512", $orderId . $statusCode . $grossAmount . $serverKey);

        if ($hashed !== $signatureKey) {
            Log::warning("Validasi Signature Midtrans Gagal untuk Order ID: {$orderId}");
            return response()->json(['message' => 'Invalid signature key'], 403);
        }

        // 2. Ambil Transaksi dari Database
        $transaction = Transaction::where('order_id', $orderId)->first();

        if (!$transaction) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        // Jika sudah success atau failed sebelumnya, hindari pemrosesan ganda
        if (in_array($transaction->transaction_status, ['settlement', 'capture', 'success', 'deny', 'cancel', 'expire'])) {
            return response()->json(['message' => 'Order already processed'], 200);
        }

        $transactionStatus = $request->transaction_status;
        $paymentType = $request->payment_type;

        $transaction->update(['payment_type' => $paymentType]);

        // 3. Tangani Status Transaksi
        if ($transactionStatus == 'capture' || $transactionStatus == 'settlement') {
            $transaction->update(['transaction_status' => 'success']);
            
            // Tambahkan masa aktif ke User
            $user = $transaction->user;
            $package = $transaction->wifiPackage;

            $now = Carbon::now();
            $expiresAt = $user->wifi_expires_at ? Carbon::parse($user->wifi_expires_at) : $now;
            
            // Jika masa aktif sudah habis di masa lalu, mulai dari hari ini
            if ($expiresAt->isBefore($now)) {
                $expiresAt = $now;
            }

            $newExpiresAt = $expiresAt->addDays($package->duration_days);
            
            $user->update([
                'wifi_expires_at' => $newExpiresAt
            ]);

            // Buat Notifikasi Sukses
            $user->notifications()->create([
                'title' => 'Pembayaran Berhasil!',
                'message' => "Paket {$package->package_name} berhasil diaktifkan. Masa aktif Wi-Fi Anda bertambah {$package->duration_days} hari.",
            ]);

        } else if ($transactionStatus == 'cancel' || $transactionStatus == 'deny' || $transactionStatus == 'expire') {
            $transaction->update(['transaction_status' => $transactionStatus]);
            
            // Buat Notifikasi Gagal/Kedaluwarsa
            $transaction->user->notifications()->create([
                'title' => 'Pembayaran Gagal',
                'message' => "Pembayaran untuk paket {$transaction->wifiPackage->package_name} gagal atau kedaluwarsa. Silakan lakukan pemesanan ulang.",
            ]);

        } else if ($transactionStatus == 'pending') {
            $transaction->update(['transaction_status' => 'pending']);
        }

        return response()->json(['message' => 'Callback handled successfully'], 200);
    }
}
