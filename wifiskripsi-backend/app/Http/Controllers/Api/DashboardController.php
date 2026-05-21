<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\WifiPackage;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Mengambil status utama dashboard pengguna.
     */
    public function getStatus(Request $request)
    {
        $user = $request->user();

        // Hitung notifikasi belum terbaca
        $unreadCount = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        // Status Wi-Fi dan sisa hari
        $now = Carbon::now();
        $expiresAt = $user->wifi_expires_at ? Carbon::parse($user->wifi_expires_at) : null;
        $isActive = $expiresAt && $expiresAt->isAfter($now);
        $daysRemaining = $isActive ? $now->diffInDays($expiresAt) : 0;

        // Simulasi data bandwidth telemetri (Acak agar terlihat dinamis)
        $uploadSpeed = $isActive ? rand(10, 50) + (rand(0, 99) / 100) : 0;
        $downloadSpeed = $isActive ? rand(50, 150) + (rand(0, 99) / 100) : 0;

        return response()->json([
            'success' => true,
            'message' => 'Status dashboard berhasil diambil.',
            'data' => [
                'user' => [
                    'name' => $user->name,
                    'phone' => $user->phone,
                    'router_id' => $user->router_id,
                ],
                'connection' => [
                    'is_active' => $isActive,
                    'expires_at' => $expiresAt ? $expiresAt->toDateTimeString() : null,
                    'days_remaining' => $daysRemaining,
                ],
                'telemetry' => [
                    'upload_mbps' => round($uploadSpeed, 2),
                    'download_mbps' => round($downloadSpeed, 2),
                ],
                'notifications' => [
                    'unread_count' => $unreadCount,
                ],
                'wallet' => [
                    'points' => rand(1000, 5000), // Poin tiruan seperti blueprint
                ]
            ]
        ], 200);
    }

    /**
     * Mengambil daftar paket Wi-Fi.
     */
    public function getPackages()
    {
        $packages = WifiPackage::orderBy('price', 'asc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar paket berhasil diambil.',
            'data' => $packages
        ], 200);
    }
}
