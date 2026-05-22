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
     * Konfigurasi Midtrans.
     */
    public function __construct()
    {
        \Midtrans\Config::$serverKey = env('MIDTRANS_SERVER_KEY');
        \Midtrans\Config::$isProduction = env('MIDTRANS_IS_PRODUCTION', false);
        \Midtrans\Config::$isSanitized = env('MIDTRANS_IS_SANITIZED', true);
        \Midtrans\Config::$is3ds = env('MIDTRANS_IS_3DS', true);

        // Perbaikan Mutlak untuk Bug PHP 8 "Undefined array key 10023"
        if (env('APP_ENV') === 'local') {
            \Midtrans\Config::$curlOptions = [
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_HTTPHEADER => [], // <-- Kunci penyelamat bug 10023 di PHP 8+
            ];
        }
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
            'data' => $transactions,
        ], 200);
    }

    /**
     * Membuat transaksi baru (Checkout).
     */
    public function checkout(Request $request)
    {
        $request->validate([
            'package_id' => 'required|exists:wifi_packages,id',
        ], [
            'package_id.required' => 'ID Paket wajib diisi.',
            'package_id.exists' => 'Paket Wi-Fi tidak ditemukan.',
        ]);

        $user = $request->user();
        $package = WifiPackage::findOrFail($request->package_id);

        $orderId = 'WS-'.time().'-'.rand(100, 999);
        $grossAmount = (int) round((float) $package->price);

        $transaction = Transaction::create([
            'order_id' => $orderId,
            'user_id' => $user->id,
            'package_id' => $package->id,
            'gross_amount' => $grossAmount,
            'transaction_status' => 'pending',
        ]);

        // STRICT PAYLOAD SANITIZATION AREA
        $rawPhone = preg_replace('/[^0-9\+]/', '', $user->phone ?? '');
        $phone = (empty($rawPhone) || strlen($rawPhone) < 5) ? '081111111111' : substr($rawPhone, 0, 19);
        $name = empty($user->name) ? 'Customer' : substr(trim($user->name), 0, 255);
        $email = filter_var($user->email, FILTER_VALIDATE_EMAIL) ? substr(trim($user->email), 0, 255) : 'no-email@domain.com';
        $address = empty($user->address) ? 'Alamat belum diisi' : substr(trim($user->address), 0, 200);
        $packageName = substr(trim($package->package_name), 0, 50);

        $params = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => (int) $grossAmount,
            ],
            'item_details' => [
                [
                    'id' => 'PKG-'.$package->id,
                    'price' => (int) $grossAmount,
                    'quantity' => 1,
                    'name' => $packageName,
                ],
            ],
            'customer_details' => [
                'first_name' => $name,
                'email' => $email,
                'phone' => $phone,
                'billing_address' => [
                    'first_name' => $name,
                    'email' => $email,
                    'phone' => $phone,
                    'address' => $address,
                    'country_code' => 'IDN',
                ],
            ],
        ];

        try {
            $snapToken = \Midtrans\Snap::getSnapToken($params);

            $transaction->update(['snap_token' => $snapToken]);

            return response()->json([
                'success' => true,
                'message' => 'Token transaksi berhasil dibuat.',
                'data' => [
                    'order_id' => $orderId,
                    'snap_token' => $snapToken,
                    'redirect_url' => 'https://app.sandbox.midtrans.com/snap/v2/vtweb/'.$snapToken,
                ],
            ], 201);
        } catch (\Exception $e) {
            Log::error('MIDTRANS HANDSHAKE ERROR: '.$e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal menghubungkan ke Midtrans: '.$e->getMessage(),
            ], 500);
        }
    }

    /**
     * Webhook Callback dari Midtrans.
     */
    public function handleCallback(Request $request)
    {
        $orderId = $request->order_id;

        // =================================================================
        // BYPASS KHUSUS UNTUK TOMBOL "TEST NOTIFIKASI" MIDTRANS DASHBOARD
        // =================================================================
        // Jika Order ID diawali dengan 'payment_notif_test', langsung kembalikan status 200 OK
        if (is_string($orderId) && str_starts_with($orderId, 'payment_notif_test')) {
            Log::info('Menerima ping test dari Midtrans Dashboard.');

            return response()->json(['message' => 'Test notification received successfully'], 200);
        }

        $serverKey = env('MIDTRANS_SERVER_KEY');
        $statusCode = $request->status_code;
        $grossAmount = $request->gross_amount;
        $signatureKey = $request->signature_key;

        // Validasi Keaslian Signature (SHA512)
        $hashed = hash('sha512', $orderId.$statusCode.$grossAmount.$serverKey);

        if ($hashed !== $signatureKey) {
            Log::warning("Validasi Signature Midtrans Gagal untuk Order ID: {$orderId}");

            return response()->json(['message' => 'Invalid signature key'], 403);
        }

        // Cari transaksi di database
        $transaction = Transaction::where('order_id', $orderId)->first();

        if (!$transaction) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        // Hindari proses ganda jika status sudah final
        if (in_array($transaction->transaction_status, ['settlement', 'capture', 'success', 'deny', 'cancel', 'expire'])) {
            return response()->json(['message' => 'Order already processed'], 200);
        }

        $transactionStatus = $request->transaction_status;
        $paymentType = $request->payment_type;

        // Update tipe pembayaran (contoh: qris, gopay, bank_transfer)
        $transaction->update(['payment_type' => $paymentType]);

        // =================================================================
        // LOGIKA PENANGANAN STATUS PEMBAYARAN
        // =================================================================
        if ($transactionStatus == 'capture' || $transactionStatus == 'settlement') {
            $transaction->update(['transaction_status' => 'success']);

            $user = $transaction->user;
            $package = $transaction->wifiPackage;

            $now = Carbon::now();
            $expiresAt = $user->wifi_expires_at ? Carbon::parse($user->wifi_expires_at) : $now;

            // Jika masa aktif sebelumnya sudah hangus, mulai hitung dari sekarang
            if ($expiresAt->isBefore($now)) {
                $expiresAt = $now;
            }

            // Tambahkan hari sesuai durasi paket
            $newExpiresAt = $expiresAt->addDays($package->duration_days);

            $user->update([
                'wifi_expires_at' => $newExpiresAt,
            ]);

            // Kirim Notifikasi Sukses
            $user->notifications()->create([
                'title' => 'Pembayaran Berhasil',
                'message' => "Paket {$package->package_name} berhasil diaktifkan. Masa aktif Wi-Fi Anda bertambah {$package->duration_days} hari.",
            ]);
        } elseif ($transactionStatus == 'cancel' || $transactionStatus == 'deny' || $transactionStatus == 'expire') {
            $transaction->update(['transaction_status' => $transactionStatus]);

            // Kirim Notifikasi Gagal/Kedaluwarsa
            $transaction->user->notifications()->create([
                'title' => 'Pembayaran Gagal',
                'message' => "Pembayaran untuk paket {$transaction->wifiPackage->package_name} gagal atau kedaluwarsa. Silakan lakukan pemesanan ulang.",
            ]);
        } elseif ($transactionStatus == 'pending') {
            $transaction->update(['transaction_status' => 'pending']);
        }

        return response()->json(['message' => 'Callback handled successfully'], 200);
    }
}
