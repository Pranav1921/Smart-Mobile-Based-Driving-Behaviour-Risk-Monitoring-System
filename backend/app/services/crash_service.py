from typing import Dict, Any

class CrashService:
    @staticmethod
    def generate_summary(crash_report_id: str, sensor_values: Dict[str, Any]) -> Dict[str, Any]:
        # G-Force calculations based on sensor acceleration vectors
        accel_x = abs(float(sensor_values.get("accel_x", 0) or 0))
        accel_y = abs(float(sensor_values.get("accel_y", 0) or 0))
        accel_z = abs(float(sensor_values.get("accel_z", 0) or 0))
        
        # Standard G divisor
        g_force_x = accel_x / 9.81
        g_force_y = accel_y / 9.81
        g_force_z = accel_z / 9.81
        
        max_g = max(g_force_x, g_force_y, g_force_z)
        
        crash_probability = 0.5
        severity_class = "Moderate"
        
        if max_g > 4.0:
            crash_probability = 0.95
            severity_class = "Severe (High Impact)"
        elif max_g > 2.0:
            crash_probability = 0.75
            severity_class = "Significant"
        else:
            crash_probability = 0.35
            severity_class = "Minor"
            
        axis = "longitudinal" if g_force_x > g_force_y else "lateral"
        potential_event = "rear/front-end collision" if g_force_x > g_force_y else "side-swipe or rollover event"
        
        summary = (
            f"Crash Investigation Report (ID: {crash_report_id}): "
            f"Telemetry triggers indicate a {severity_class} crash impact event. "
            f"Peak gravity forces hit {max_g:.2f}G. Acceleration signatures show sharp spikes "
            f"in the {axis} axis, indicating a potential {potential_event}. "
            f"Emergency protocols are engaged."
        )
        
        return {
            "summary": summary,
            "crashProbability": crash_probability
        }

crash_service = CrashService()
