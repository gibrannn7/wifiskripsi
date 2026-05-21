<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('users')->insert([
            [
                'name' => 'Administrator',
                'email' => 'admin@wifiskripsi.com',
                'password' => Hash::make('password123'),
                'phone' => '081234567890',
                'router_id' => 'RT-ADMIN',
                'address' => 'Pusat Manajemen Wi-Fi',
                'role' => 'admin',
                'wifi_expires_at' => now()->addYears(10),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Pengguna Demo',
                'email' => 'user@wifiskripsi.com',
                'password' => Hash::make('password123'),
                'phone' => '089876543210',
                'router_id' => 'RT-001',
                'address' => 'Jalan Kenangan No. 123',
                'role' => 'user',
                'wifi_expires_at' => now()->addDays(7),
                'created_at' => now(),
                'updated_at' => now(),
            ]
        ]);
    }
}
