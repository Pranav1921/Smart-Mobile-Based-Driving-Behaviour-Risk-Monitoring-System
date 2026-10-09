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

        # Compute estimated trip distance in kilometers from GPS points
        distance_km = 0.0
        if len(points) > 1:
            for i in range(1, len(points)):
                p1, p2 = points[i - 1], points[i]
                lat1, lon1 = float(p1.get("latitude", 0)), float(p1.get("longitude", 0))
                lat2, lon2 = float(p2.get("latitude", 0)), float(p2.get("longitude", 0))
                if lat1 != 0 and lat2 != 0:
                    phi1, phi2 = math.radians(lat1), math.radians(lat2)
                    dphi = math.radians(lat2 - lat1)
                    dlambda = math.radians(lon2 - lon1)
                    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
                    a = min(1.0, max(0.0, a))
                    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
                    distance_km += (6371.0 * c)

        eff_distance = max(1.0, distance_km)

        # Distance-Normalized Penalty Model: events per 100 km
        # lambda_i = (count / distance_km) * 100
        lambda_brake = (harsh_braking_count / eff_distance) * 100.0
        lambda_accel = (rapid_accel_count / eff_distance) * 100.0
        lambda_speed = (overspeed_count / eff_distance) * 100.0
        lambda_turn  = (sharp_turn_count / eff_distance) * 100.0
        lambda_phone = (phone_usage_count / eff_distance) * 100.0

        # Sub-Penalties with Exponential Tolerance Decay
        # P_i = 100 * (1 - exp(-lambda_i / beta_i))
        pen_brake = 100.0 * (1.0 - math.exp(-lambda_brake / 6.0))
        pen_accel = 100.0 * (1.0 - math.exp(-lambda_accel / 8.0))
        pen_speed = 100.0 * (1.0 - math.exp(-lambda_speed / 5.0))
        pen_turn  = 100.0 * (1.0 - math.exp(-lambda_turn / 7.0))
        pen_phone = 100.0 * (1.0 - math.exp(-lambda_phone / 3.0))

        # Weighted Overall Safety Score (Braking 0.25, Speed 0.25, Turn 0.20, Accel 0.15, Focus 0.15)
        total_penalty = (
            0.25 * pen_brake +
            0.25 * pen_speed +
            0.20 * pen_turn +
            0.15 * pen_accel +
            0.15 * pen_phone
        )
        if crash_count > 0:
            total_penalty = max(total_penalty, 80.0)

        safety_score = round(max(0.0, min(100.0, 100.0 - total_penalty)), 1)
        risk_score = round(100.0 - safety_score, 1)

        # Sub-Scores (0-100)
        sub_scores = {
            "braking": round(max(0.0, 100.0 - pen_brake), 1),
            "acceleration": round(max(0.0, 100.0 - pen_accel), 1),
            "speed": round(max(0.0, 100.0 - pen_speed), 1),
            "cornering": round(max(0.0, 100.0 - pen_turn), 1),
            "focus": round(max(0.0, 100.0 - pen_phone), 1),
        }

        # Driver classification
        classification = "BALANCED"
        if safety_score > 85 and risk_score < 20:
            classification = "CONSERVATIVE"
        elif safety_score < 60 or risk_score > 50:
            classification = "AGGRESSIVE"

        # Generate explainable recommendations
        recommendations = []
        if harsh_braking_count > 0:
            recommendations.append(f"{harsh_braking_count} harsh braking events ({round(lambda_brake, 1)} / 100km). Increase following distance.")
        if rapid_accel_count > 0:
            recommendations.append(f"{rapid_accel_count} rapid acceleration events. Smooth throttle inputs to improve fuel economy.")
        if overspeed_count > 0:
            recommendations.append(f"{overspeed_count} overspeed incidents. Observe roadway speed caps.")
        if sharp_turn_count > 0:
            recommendations.append(f"{sharp_turn_count} sharp cornering events. Decelerate smoothly prior to curve entry.")
        if phone_usage_count > 0:
            recommendations.append(f"{phone_usage_count} mobile handling distractions recorded. Keep device mounted.")
        
        if not recommendations:
            recommendations.append("Flawless trip with zero safety infractions. Excellent driving adherence!")

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
            "subScores": sub_scores,
            "distanceKm": round(distance_km, 2),
            "eventsPer100Km": {
                "braking": round(lambda_brake, 1),
                "acceleration": round(lambda_accel, 1),
                "speed": round(lambda_speed, 1),
                "cornering": round(lambda_turn, 1),
            },
            "behaviorClassification": classification,
            "recommendations": recommendations,
            "xpEarned": xp_earned,
            "badgesEarned": badges_earned
        }

score_service = ScoreService()
