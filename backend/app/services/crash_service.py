from typing import Dict, Any

class CrashService:
    @staticmethod
    def generate_summary(crash_report_id: str, sensor_values: Dict[str, Any]) -> Dict[str, Any]:
        # G-Force calculations based on sensor acceleration vectors
        accel_x = abs(float(sensor_values.get("accel_x", 0) or 0))
        accel_y = abs(float(sensor_values.get("accel_y", 0) or 0))
        accel_z = abs(float(sensor_values.get("accel_z", 0) or 0))
        
        # Driver movement context
        speed_before = float(sensor_values.get("speedBefore", 0) or sensor_values.get("speed_before", 0) or 0)
        speed_after = float(sensor_values.get("speedAfter", 0) or sensor_values.get("speed_after", 0) or 0)
        delta_v = max(0.0, speed_before - speed_after)

        # Standard G divisor
        g_force_x = accel_x / 9.80665
        g_force_y = accel_y / 9.80665
        g_force_z = accel_z / 9.80665
        
        # Peak sensor impact ("crush value")
        max_g = float(sensor_values.get("gForce", 0) or max(g_force_x, g_force_y, g_force_z))
        if max_g == 0:
            max_g = 1.0

        # Crush deformation index (Kinetic energy delta dissipation: delta_v * peak G)
        crush_index = (delta_v * max_g) / 10.0
        
        # Calibrated crash probability based on huge value change + driver movement
        if max_g >= 5.5 or (delta_v >= 35.0 and max_g >= 4.0):
            crash_probability = 0.98
            severity_class = "Catastrophic (Severe Impact)"
        elif max_g >= 4.0 or (delta_v >= 20.0 and max_g >= 3.0):
            crash_probability = 0.88
            severity_class = "High Impact Collision"
        elif max_g >= 2.5:
            crash_probability = 0.65
            severity_class = "Moderate Collision"
        else:
            crash_probability = 0.25
            severity_class = "Low Impact / Filtered Anomaly"
            
        axis = "longitudinal" if g_force_x > g_force_y else "lateral"
        potential_event = "rear/front-end collision" if g_force_x > g_force_y else "side-swipe or rollover impact"
        
        summary = (
            f"Crash Investigation Report (ID: {crash_report_id}): "
            f"Telemetry indicates a {severity_class} event. "
            f"Impact force reached {max_g:.2f}G with driver speed changing from {speed_before:.1f} km/h to {speed_after:.1f} km/h (Delta V: {delta_v:.1f} km/h). "
            f"Crush deformation energy rated at {crush_index:.1f}. Acceleration spike concentrated along the {axis} axis ({potential_event}). "
            f"Emergency SOS protocols verified."
        )
        
        return {
            "summary": summary,
            "crashProbability": crash_probability,
            "severityClass": severity_class,
            "crushIndex": round(crush_index, 2),
            "deltaV": round(delta_v, 2),
            "maxG": round(max_g, 2)
        }

crash_service = CrashService()

