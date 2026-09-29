package com.fleet.safety.data.remote

import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Body

/**
 * Retrofit interface for the ESP32 firmware API.
 */
interface Esp32ApiService {
    
    @GET("/api/v1/device/status")
    suspend fun getDeviceStatus(): Response<DeviceStatusResponse>

    @GET("/api/v1/telemetry/latest")
    suspend fun getLatestTelemetry(): Response<TelemetryResponse>

    @POST("/api/v1/ota/update")
    suspend fun startOtaUpdate(@Body updateInfo: OtaUpdateRequest): Response<OtaUpdateResponse>

    @POST("/api/v1/device/reboot")
    suspend fun rebootDevice(): Response<Unit>
}

data class DeviceStatusResponse(
    val deviceId: String,
    val firmwareVersion: String,
    val uptime: Long,
    val freeHeap: Long
)

data class TelemetryResponse(
    val accelX: Float,
    val accelY: Float,
    val accelZ: Float,
    val gyroX: Float,
    val gyroY: Float,
    val gyroZ: Float,
    val impactDetected: Boolean,
    val temperature: Float,
    val timestamp: Long
)

data class OtaUpdateRequest(
    val url: String,
    val version: String,
    val checksum: String
)

data class OtaUpdateResponse(
    val jobId: String,
    val status: String
)
