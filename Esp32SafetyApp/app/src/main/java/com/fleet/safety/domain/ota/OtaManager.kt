package com.fleet.safety.domain.ota

import com.fleet.safety.data.remote.Esp32ApiService
import com.fleet.safety.data.remote.OtaUpdateRequest
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject

/**
 * Manages the multi-stage Over-The-Air (OTA) firmware update process.
 */
class OtaManager @Inject constructor(
    private val apiService: Esp32ApiService
) {
    enum class OtaState {
        IDLE, DOWNLOADING, UPLOADING, REBOOTING, VERIFYING, COMPLETED, FAILED
    }

    private val _otaState = MutableStateFlow(OtaState.IDLE)
    val otaState: StateFlow<OtaState> = _otaState

    private val _progress = MutableStateFlow(0f)
    val progress: StateFlow<Float> = _progress

    suspend fun startUpdate(firmwareUrl: String, version: String, checksum: String) {
        try {
            _otaState.value = OtaState.DOWNLOADING
            simulateWork(0.2f)

            _otaState.value = OtaState.UPLOADING
            val response = apiService.startOtaUpdate(OtaUpdateRequest(firmwareUrl, version, checksum))
            if (response.isSuccessful) {
                simulateWork(0.6f)
                
                _otaState.value = OtaState.REBOOTING
                apiService.rebootDevice()
                delay(5000) // Wait for reboot

                _otaState.value = OtaState.VERIFYING
                delay(2000)
                
                _otaState.value = OtaState.COMPLETED
            } else {
                _otaState.value = OtaState.FAILED
            }
        } catch (e: Exception) {
            _otaState.value = OtaState.FAILED
        }
    }

    private suspend fun simulateWork(targetProgress: Float) {
        while (_progress.value < targetProgress) {
            _progress.value += 0.05f
            delay(200)
        }
    }
}
