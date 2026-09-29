package com.fleet.safety.domain.detector

import com.fleet.safety.data.remote.TelemetryResponse
import javax.inject.Inject
import kotlin.math.sqrt

/**
 * Detects harsh driving events based on telemetry data.
 */
class DrivingEventDetector @Inject constructor() {

    enum class EventType {
        NORMAL,
        HARSH_BRAKING,
        HARSH_ACCELERATION,
        IMPACT
    }

    fun detectEvent(telemetry: TelemetryResponse): EventType {
        val magnitude = sqrt(
            telemetry.accelX * telemetry.accelX +
            telemetry.accelY * telemetry.accelY +
            telemetry.accelZ * telemetry.accelZ
        )

        return when {
            telemetry.impactDetected -> EventType.IMPACT
            magnitude > 2.5f -> EventType.HARSH_BRAKING // Example threshold
            magnitude > 2.0f -> EventType.HARSH_ACCELERATION
            else -> EventType.NORMAL
        }
    }
}
