package com.fleet.safety.data.repository

import com.fleet.safety.data.model.ConnectionStatus
import com.fleet.safety.data.model.Esp32ConnectionConfig
import com.fleet.safety.data.remote.Esp32ApiService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages the connection state and lifecycle with the ESP32 hardware.
 */
@Singleton
class ConnectionManager @Inject constructor(
    private val apiService: Esp32ApiService
) {
    private val _connectionConfig = MutableStateFlow(Esp32ConnectionConfig())
    val connectionConfig: StateFlow<Esp32ConnectionConfig> = _connectionConfig.asStateFlow()

    private val _isMockMode = MutableStateFlow(false)
    val isMockMode: StateFlow<Boolean> = _isMockMode.asStateFlow()

    fun updateConfig(ip: String, port: Int) {
        _connectionConfig.value = _connectionConfig.value.copy(
            ipAddress = ip,
            port = port
        )
    }

    fun setMockMode(enabled: Boolean) {
        _isMockMode.value = enabled
    }

    suspend fun checkConnection() {
        if (_isMockMode.value) {
            _connectionConfig.value = _connectionConfig.value.copy(
                connectionStatus = ConnectionStatus.CONNECTED,
                lastHeartbeat = System.currentTimeMillis()
            )
            return
        }

        try {
            _connectionConfig.value = _connectionConfig.value.copy(connectionStatus = ConnectionStatus.CONNECTING)
            val response = apiService.getDeviceStatus()
            if (response.isSuccessful) {
                _connectionConfig.value = _connectionConfig.value.copy(
                    connectionStatus = ConnectionStatus.CONNECTED,
                    lastHeartbeat = System.currentTimeMillis()
                )
            } else {
                _connectionConfig.value = _connectionConfig.value.copy(connectionStatus = ConnectionStatus.ERROR)
            }
        } catch (e: Exception) {
            _connectionConfig.value = _connectionConfig.value.copy(connectionStatus = ConnectionStatus.DISCONNECTED)
        }
    }
}
