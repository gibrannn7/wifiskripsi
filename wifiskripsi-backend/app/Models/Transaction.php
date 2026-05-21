<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'user_id',
        'package_id',
        'gross_amount',
        'payment_type',
        'transaction_status',
        'snap_token',
    ];

    /**
     * Relasi ke User (Transaksi dimiliki oleh 1 User)
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relasi ke Paket Wifi (Transaksi terkait dengan 1 Paket)
     */
    public function wifiPackage()
    {
        return $this->belongsTo(WifiPackage::class, 'package_id');
    }
}
