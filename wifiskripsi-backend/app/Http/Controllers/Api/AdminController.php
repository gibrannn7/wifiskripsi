<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Transaction;
use App\Models\WifiPackage;
use App\Models\User;
use App\Models\Notification;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    /**
     * Memeriksa apakan user yang request adalah Admin
     */
    private function ensureAdmin($user)
    {
        if ($user->role !== 'admin') {
            abort(403, 'Akses ditolak. Anda bukan admin.');
        }
    }

    /**
     * Mendapatkan data analitik (total pendapatan dan transaksi per bulan)
     */
    public function getAnalytics(Request $request)
    {
        $this->ensureAdmin($request->user());

        $currentMonth = Carbon::now()->month;
        $currentYear = Carbon::now()->year;
        $lastMonth = Carbon::now()->subMonth()->month;
        $lastMonthYear = Carbon::now()->subMonth()->year;

        // Ambil transaksi bulan ini
        $currentMonthTx = Transaction::where('transaction_status', 'success')
            ->whereMonth('created_at', $currentMonth)
            ->whereYear('created_at', $currentYear)
            ->get();

        // Ambil transaksi bulan lalu
        $lastMonthTx = Transaction::where('transaction_status', 'success')
            ->whereMonth('created_at', $lastMonth)
            ->whereYear('created_at', $lastMonthYear)
            ->get();

        // Tren Harian (1-31)
        $chartDataCurrent = [];
        $chartDataLast = [];

        for ($i = 1; $i <= 31; $i++) {
            $sumCurrent = $currentMonthTx->filter(function ($tx) use ($i) {
                return Carbon::parse($tx->created_at)->day == $i;
            })->sum('gross_amount');

            $sumLast = $lastMonthTx->filter(function ($tx) use ($i) {
                return Carbon::parse($tx->created_at)->day == $i;
            })->sum('gross_amount');

            $chartDataCurrent[] = [
                'day' => $i,
                'revenue' => (int) $sumCurrent
            ];

            $chartDataLast[] = [
                'day' => $i,
                'revenue' => (int) $sumLast
            ];
        }

        $totalRevenue = Transaction::where('transaction_status', 'success')->sum('gross_amount');
        $totalTransactions = Transaction::where('transaction_status', 'success')->count();
        $totalUsers = User::where('role', 'user')->count();

        // Cari paket paling laris
        $bestSellingPackage = 'Belum Ada';
        $bestSellingData = Transaction::where('transaction_status', 'success')
            ->select('package_id', DB::raw('count(*) as total'))
            ->groupBy('package_id')
            ->orderBy('total', 'desc')
            ->first();

        if ($bestSellingData) {
            $pkg = WifiPackage::find($bestSellingData->package_id);
            if ($pkg) {
                $bestSellingPackage = $pkg->package_name;
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Data analitik berhasil diambil',
            'data' => [
                'total_revenue' => (int) $totalRevenue,
                'total_transactions' => $totalTransactions,
                'total_users' => $totalUsers,
                'best_selling_package' => $bestSellingPackage,
                'chart_data_current' => $chartDataCurrent,
                'chart_data_last' => $chartDataLast
            ]
        ], 200);
    }

    /**
     * Membuat Paket Baru
     */
    public function storePackage(Request $request)
    {
        $this->ensureAdmin($request->user());

        $request->validate([
            'package_name' => 'required|string',
            'speed_mbps' => 'required|numeric',
            'price' => 'required|numeric',
            'duration_days' => 'required|integer',
            'description' => 'nullable|string',
        ]);

        $package = WifiPackage::create($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Paket berhasil ditambahkan',
            'data' => $package
        ], 201);
    }

    /**
     * Mengupdate Paket
     */
    public function updatePackage(Request $request, $id)
    {
        $this->ensureAdmin($request->user());

        $request->validate([
            'package_name' => 'required|string',
            'speed_mbps' => 'required|numeric',
            'price' => 'required|numeric',
            'duration_days' => 'required|integer',
            'description' => 'nullable|string',
        ]);

        $package = WifiPackage::findOrFail($id);
        $package->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Paket berhasil diperbarui',
            'data' => $package
        ], 200);
    }

    /**
     * Menghapus Paket
     */
    public function deletePackage(Request $request, $id)
    {
        $this->ensureAdmin($request->user());

        $package = WifiPackage::findOrFail($id);
        $package->delete();

        return response()->json([
            'success' => true,
            'message' => 'Paket berhasil dihapus',
        ], 200);
    }

    /**
     * Mendapatkan semua transaksi pelanggan
     */
    public function getAllTransactions(Request $request)
    {
        $this->ensureAdmin($request->user());

        $transactions = Transaction::with(['user', 'wifiPackage'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Seluruh transaksi berhasil diambil',
            'data' => $transactions
        ], 200);
    }

    /**
     * Mendapatkan semua pengguna/pelanggan
     */
    public function getAllUsers(Request $request)
    {
        $this->ensureAdmin($request->user());

        $users = User::where('role', 'user')->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar pengguna berhasil diambil',
            'data' => $users
        ], 200);
    }

    /**
     * Mengirim notifikasi manual ke pelanggan
     */
    public function sendPushNotification(Request $request)
    {
        $this->ensureAdmin($request->user());

        $request->validate([
            'user_id' => 'required|exists:users,id',
            'title' => 'required|string',
            'message' => 'required|string',
        ]);

        $notification = Notification::create([
            'user_id' => $request->user_id,
            'title' => $request->title,
            'message' => $request->message,
            'is_read' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi berhasil dikirim',
            'data' => $notification
        ], 201);
    }

    /**
     * Mengirim notifikasi massal ke semua pengguna
     */
    public function broadcastNotification(Request $request)
    {
        $this->ensureAdmin($request->user());

        $request->validate([
            'title' => 'required|string',
            'message' => 'required|string',
        ]);

        $users = User::where('role', 'user')->pluck('id');
        $notifications = [];
        $now = now();

        foreach ($users as $userId) {
            $notifications[] = [
                'user_id' => $userId,
                'title' => $request->title,
                'message' => $request->message,
                'is_read' => false,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        if (!empty($notifications)) {
            Notification::insert($notifications);
        }

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi massal berhasil dikirim ke ' . count($notifications) . ' pengguna',
        ], 201);
    }
}
