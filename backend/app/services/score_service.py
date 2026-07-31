import math
from datetime import datetime
from typing import List, Dict, Any

class ScoreService:
    @staticmethod
    def evaluate_trip(points: List[Dict[str, Any]], events: List[Dict[str, Any]]) -> Dict[str, Any]:
        harsh_braking_count = 0
        rapid_accel_count = 0
        overspeed_count = 0
        sharp_turn_count = 0
        phone_usage_count = 0
        crash_count = 0

        # Count events from explicit event logs
        for event in events:
            evt_type = event.get("eventType") or event.get("event_type")
            if evt_type == "HARSH_BRAKING":
                harsh_braking_count += 1
            elif evt_type == "RAPID_ACCELERATION":
                rapid_accel_count += 1
            elif evt_type == "OVERSPEED":
                overspeed_count += 1
            elif evt_type == "SHARP_TURN":
                sharp_turn_count += 1
            elif evt_type == "PHONE_USAGE":
                phone_usage_count += 1
            elif evt_type == "CRASH":
                crash_count += 1

        # Fallback raw GPS points logic for acceleration anomalies
        if len(points) > 1:
            for i in range(1, len(points)):
                prev = points[i - 1]
                curr = points[i]
                
                try:
                    prev_time = datetime.fromisoformat(prev["timestamp"].replace("Z", "+00:00"))
                    curr_time = datetime.fromisoformat(curr["timestamp"].replace("Z", "+00:00"))
                    time_diff = (curr_time - prev_time).total_seconds()
                except Exception:
                    time_diff = 1.0  # fallback interval

                if time_diff > 0:
                    prev_speed_ms = float(prev.get("speed", 0)) / 3.6
                    curr_speed_ms = float(curr.get("speed", 0)) / 3.6
                    acceleration = (curr_speed_ms - prev_speed_ms) / time_diff

                    if acceleration < -3.0:
                        harsh_braking_count += 1
                    elif acceleration > 3.0:
                        rapid_accel_count += 1

        # Calculate safety score
        safety_score = 100
        safety_score -= harsh_braking_count * 3
        safety_score -= rapid_accel_count * 2
        safety_score -= overspeed_count * 4
        safety_score -= sharp_turn_count * 3
        safety_score -= phone_usage_count * 8
        safety_score -= crash_count * 50
        safety_score = max(0.0, min(100.0, float(safety_score)))

        # Calculate risk score
        risk_score = 0
        risk_score += harsh_braking_count * 4
        risk_score += rapid_accel_count * 3
        risk_score += overspeed_count * 5
        risk_score += sharp_turn_count * 4
        risk_score += phone_usage_count * 12
        risk_score += crash_count * 80
        risk_score = max(0.0, min(100.0, float(risk_score)))

        # Driver classification
        classification = "BALANCED"
        if safety_score > 85 and risk_score < 20:
            classification = "CONSERVATIVE"
        elif safety_score < 60 or risk_score > 50:
            classification = "AGGRESSIVE"

        # Generate recommendations
        recommendations = []
        if harsh_braking_count > 2:
            recommendations.append("Maintain a larger following distance to avoid sudden stop decelerations.")
        if rapid_accel_count > 2:
            recommendations.append("Accelerate progressively to save vehicle fuel and decrease engine wear.")
        if overspeed_count > 2:
            recommendations.append("Respect road speed limits to lower risk profiles and reduce accident probability.")
        if sharp_turn_count > 2:
            recommendations.append("Reduce speed before entering turns to prevent high lateral G-forces.")
        if phone_usage_count > 0:
            recommendations.append("Avoid handling mobile devices during movement. Keep your focus on the road.")
        
        if not recommendations:
            recommendations.append("Excellent driving performance! Continue following safe travel rules.")

        # Calculate XP reward
        xp_earned = int(100 + (safety_score * 1.5))

        # Check for achievements/badges earned on this trip
        badges_earned = []
        if harsh_braking_count == 0 and rapid_accel_count == 0:
            badges_earned.append("smooth_operator")
        if overspeed_count == 0:
            badges_earned.append("speed_sentinel")
        if phone_usage_count == 0:
            badges_earned.append("focus_champion")

        return {
            "safetyScore": safety_score,
            "riskScore": risk_score,
            "behaviorClassification": classification,
            "recommendations": recommendations,
            "xpEarned": xp_earned,
            "badgesEarned": badges_earned
        }

score_service = ScoreService()
