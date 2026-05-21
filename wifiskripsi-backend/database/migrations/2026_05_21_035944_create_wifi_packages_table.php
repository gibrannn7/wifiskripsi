<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('wifi_packages', function (Blueprint $table) {
            $table->id();
            $table->string('package_name', 100);
            $table->integer('speed_mbps');
            $table->decimal('price', 10, 2);
            $table->integer('duration_days');
            $table->boolean('is_promoted')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('wifi_packages');
    }
};
