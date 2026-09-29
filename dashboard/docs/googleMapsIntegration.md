# Integrating Google Maps APIs for Driving Rules Compliance

This document explains how the **Context-Aware Driving Compliance Model** implemented on the SmartDrive Admin Dashboard can be connected to real Google Maps Platform APIs in a production backend.

```
+--------------------+
| Driver GPS Telemetry| (Latitude, Longitude, Speed)
+---------+----------+
          |
          v
+---------+-------------------------------------------------------+
|                 CONTEXT EXTRACTION LAYER (BACKEND)              |
|                                                                 |
| 1. Query Google Roads API    => Get official posted speed limit |
| 2. Query Google Places API   => Detect nearby schools/hospitals |
| 3. Query Directions API      => Detect heavy traffic congestion |
+---------+-------------------------------------------------------+
          |
          v
+---------+-------------------------------------------------------+
|                     COMPLIANCE ENGINE EVALUATION                |
|                                                                 |
|  - Resolve Effective Speed Limit based on context (e.g., 30km/h)|
|  - Compare Driver's Speed against Effective Limit               |
|  - Flag Rules Violations and send Real-time WebSocket Alert    |
+---------+-------------------------------------------------------+
          |
          v
+---------+----------+
|  Admin Web Dashboard | (Live Map Alerts & Driver Panel status)
+--------------------+
```

---

## 1. Querying Road Speed Limits (Google Roads API)

The **Google Roads API** provides the posted speed limit for any road segment. You send a sequence of GPS points or a single coordinate and receive the speed limit for that road.

### API Endpoint
`GET https://roads.googleapis.com/v1/speedLimits?path=lat,lng&key=YOUR_API_KEY`

### Backend Implementation Example (Node.js)

```javascript
const axios = require('axios');

async function getSpeedLimit(latitude, longitude) {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://roads.googleapis.com/v1/speedLimits`;
  
  try {
    const response = await axios.get(url, {
      params: {
        path: `${latitude},${longitude}`,
        key: apiKey
      }
    });
    
    // The response returns speed limits for matching road segments
    if (response.data.speedLimits && response.data.speedLimits.length > 0) {
      const limitKmh = response.data.speedLimits[0].speedLimit; // speed limit in km/h
      return limitKmh;
    }
    return 60; // fallback default limit
  } catch (error) {
    console.error('Error fetching speed limit:', error.message);
    return 60;
  }
}
```

---

## 2. Detecting School & Safety Zones (Google Places API)

To check if the driver is inside a school zone, use the **Google Places API** to perform a text search or nearby search for institutions within a radius of the driver's current coordinates.

### API Endpoint (Places API New)
`POST https://places.googleapis.com/v1/places:searchNearby`

### Backend Implementation Example (Python / FastAPI)

```python
import os
import requests

def check_school_zone(latitude: float, longitude: float, radius_meters: float = 300) -> bool:
    api_key = os.getenv("GOOGLE_MAPS_API_KEY")
    url = "https://places.googleapis.com/v1/places:searchNearby"
    
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": api_key,
        "X-Goog-FieldMask": "places.displayName,places.types"
    }
    
    payload = {
        "includedTypes": ["school", "primary_school", "secondary_school"],
        "maxResultCount": 1,
        "locationRestriction": {
            "circle": {
                "center": {
                    "latitude": latitude,
                    "longitude": longitude
                },
                "radius": radius_meters
            }
        }
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        if response.status_code == 200:
            data = response.json()
            # If any school is found within this circle, flag as School Zone
            return len(data.get("places", [])) > 0
        return False
    except Exception as e:
        print(f"Error checking school zone: {e}")
        return False
```

---

## 3. Detecting Heavy Traffic (Google Directions / Distance Matrix API)

To establish if the driver is traveling through heavy traffic, query the **Google Distance Matrix API** or **Directions API** specifying a departure time of `now` to request real-time traffic details. You can compare the duration with traffic to the free-flow duration.

### API Endpoint
`GET https://maps.googleapis.com/maps/api/distancematrix/json?origins=lat,lng&destinations=lat_ahead,lng_ahead&departure_time=now&traffic_model=best_guess&key=YOUR_API_KEY`

### Logic
If the ratio of `duration_in_traffic` to standard `duration` is high (e.g. `duration_in_traffic / duration >= 1.5`), it indicates that the route ahead has significant congestion (heavy traffic), which means driving behavior should be constrained.

### Congestion Ratio Calculation

```javascript
function evaluateTrafficStatus(duration, durationInTraffic) {
  if (!durationInTraffic || duration <= 0) return 'normal';
  
  const ratio = durationInTraffic / duration;
  if (ratio >= 1.6) {
    return 'heavy';  // traffic causes 60%+ time delay
  } else if (ratio >= 1.25) {
    return 'moderate';
  }
  return 'normal';
}
```

---

## 4. Production Integration Architecture

To run this model efficiently at scale:
1. **Telemetry Batching**: Avoid querying the Google APIs for every single GPS ping. Batch requests or query only when the vehicle has moved at least 50–100 meters, or cache coordinates locally.
2. **Geofence Caching**: Cache detected school zone bounds in your database (e.g., Redis spatial indexes or PostgreSQL PostGIS) to avoid making recurring calls to Google Places API for identical regions.
3. **Event Correlation**: Combine speed limit data with phone usage, accelerometer/gyroscope readings, and traffic levels to score trip safety dynamically inside your backend `ScoreService`.
