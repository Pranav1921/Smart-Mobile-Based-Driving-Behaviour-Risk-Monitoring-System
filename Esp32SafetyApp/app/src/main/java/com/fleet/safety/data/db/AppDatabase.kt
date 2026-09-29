package com.fleet.safety.data.db

import androidx.room.Database
import androidx.room.RoomDatabase
import com.fleet.safety.data.db.entity.TelemetryEntity

@Database(entities = [TelemetryEntity::class], version = 1)
abstract class AppDatabase : RoomDatabase() {
    // Define DAOs here
}
