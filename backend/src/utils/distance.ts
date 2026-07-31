/**
 * Calculates the geodesic distance between two GPS points using the Haversine formula.
 * Returns the distance in kilometers.
 */
export function calculateHaversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const EARTH_RADIUS_KM = 6371;
  const dLat = degreeToRadian(lat2 - lat1);
  const dLon = degreeToRadian(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(degreeToRadian(lat1)) *
      Math.cos(degreeToRadian(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = EARTH_RADIUS_KM * c;

  return Number(distance.toFixed(3)); // 3 decimal places (meter precision)
}

function degreeToRadian(degree: number): number {
  return degree * (Math.PI / 180);
}
