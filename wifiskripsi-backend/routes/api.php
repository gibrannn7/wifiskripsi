<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\FaqController;
use App\Http\Controllers\Api\AdminController;

// Public Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/payment-callback', [TransactionController::class, 'handleCallback']);
Route::get('/faqs', [FaqController::class, 'index']);

// Protected Routes (Harus Menggunakan Bearer Token Sanctum)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::put('/profile/update', [AuthController::class, 'updateProfile']);
    
    // Dashboard & Paket
    Route::get('/dashboard-status', [DashboardController::class, 'getStatus']);
    Route::get('/packages', [DashboardController::class, 'getPackages']);
    
    // Transaksi
    Route::post('/checkout', [TransactionController::class, 'checkout']);
    Route::get('/transactions', [TransactionController::class, 'getHistory']);
    
    // Notifikasi
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);

    // Admin Routes
    Route::prefix('admin')->group(function () {
        Route::get('/analytics', [AdminController::class, 'getAnalytics']);
        
        Route::post('/packages', [AdminController::class, 'storePackage']);
        Route::put('/packages/{id}', [AdminController::class, 'updatePackage']);
        Route::delete('/packages/{id}', [AdminController::class, 'deletePackage']);
        
        Route::get('/transactions', [AdminController::class, 'getAllTransactions']);
        Route::get('/users', [AdminController::class, 'getAllUsers']);
        Route::post('/notifications/send', [AdminController::class, 'sendPushNotification']);
        Route::post('/notifications/broadcast', [AdminController::class, 'broadcastNotification']);
    });
});
