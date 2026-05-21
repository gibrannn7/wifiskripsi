<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WifiPackage extends Model
{
    use HasFactory;

    protected $fillable = [
        'package_name',
        'speed_mbps',
        'price',
        'duration_days',
        'is_promoted',
    ];

    /**
     * Relasi ke transaksi (1 Paket bisa dibeli di banyak Transaksi)
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class, 'package_id');
    }
}
