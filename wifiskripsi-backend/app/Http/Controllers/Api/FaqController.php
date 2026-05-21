<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class FaqController extends Controller
{
    /**
     * Mengambil daftar FAQ statis.
     */
    public function index()
    {
        $faqs = [
            [
                'id' => 1,
                'question' => 'Bagaimana cara membeli paket Wi-Fi?',
                'answer' => 'Anda dapat memilih paket pada menu utama, lalu klik "Beli". Selesaikan pembayaran menggunakan metode yang tersedia melalui Midtrans.',
            ],
            [
                'id' => 2,
                'question' => 'Kapan masa aktif paket saya dimulai?',
                'answer' => 'Masa aktif akan langsung bertambah dan dihitung tepat setelah sistem mengonfirmasi pembayaran Anda sukses.',
            ],
            [
                'id' => 3,
                'question' => 'Apakah paket Wi-Fi bisa diakumulasi?',
                'answer' => 'Ya, jika Anda membeli paket baru sementara masa aktif lama masih ada, maka sisa hari akan diakumulasikan secara otomatis.',
            ],
            [
                'id' => 4,
                'question' => 'Saya sudah bayar tapi status masih pending?',
                'answer' => 'Mohon tunggu beberapa saat untuk sinkronisasi sistem. Jika lebih dari 10 menit, silakan hubungi admin melalui tombol bantuan.',
            ]
        ];

        return response()->json([
            'success' => true,
            'message' => 'Daftar FAQ berhasil diambil.',
            'data' => $faqs
        ], 200);
    }
}
