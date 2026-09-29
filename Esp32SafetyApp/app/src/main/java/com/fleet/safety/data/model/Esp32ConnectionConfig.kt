package com.fleet.safety.data.model

/**
 * Configuration for the ESP32 connection.
 */
data class Esp32ConnectionConfig(
    val ipAddress: String = "192.168.4.1",
    val port: Int = 80,
    val connectionStatus: ConnectionStatus = ConnectionStatus.DISCONNECTED,
    val lastHeartbeat: Long = 0L
)

enum class ConnectionStatus {
    CONNECTED,
    DISCONNECTED,
    CONNECTING,
    ERROR
}
