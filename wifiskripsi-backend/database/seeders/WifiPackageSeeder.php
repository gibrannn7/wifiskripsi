<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class WifiPackageSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('wifi_packages')->insert([
            [
                'package_name' => 'Paket Harian (5 Mbps)',
                'speed_mbps' => 5,
                'price' => 5000.00,
                'duration_days' => 1,
                'is_promoted' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'package_name' => 'Paket Mingguan (10 Mbps)',
                'speed_mbps' => 10,
                'price' => 25000.00,
                'duration_days' => 7,
                'is_promoted' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'package_name' => 'Paket Bulanan (20 Mbps)',
                'speed_mbps' => 20,
                'price' => 100000.00,
                'duration_days' => 30,
                'is_promoted' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
