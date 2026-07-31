/**
 * Decodes Google Encoded Polyline format to an array of [latitude, longitude] pairs.
 */
export function decodePolyline(str: string): [number, number][] {
  const coordinates: [number, number][] = [];
  let index = 0;
  const len = str.length;
  let lat = 0;
  let lng = 0;

  while (index < len) {
    let b: number;
    let shift = 0;
    let result = 0;
    do {
      b = str.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = str.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += dlng;

    coordinates.push([lat / 1e5, lng / 1e5]);
  }

  return coordinates;
}

/**
 * Encodes an array of [latitude, longitude] pairs to Google Polyline format.
 */
export function encodePolyline(coordinates: [number, number][]): string {
  let str = '';
  let plat = 0;
  let plng = 0;

  for (let i = 0; i < coordinates.length; i++) {
    const lat = Math.round(coordinates[i][0] * 1e5);
    const lng = Math.round(coordinates[i][1] * 1e5);

    str += encodeSignedNumber(lat - plat);
    str += encodeSignedNumber(lng - plng);

    plat = lat;
    plng = lng;
  }

  return str;
}

function encodeSignedNumber(num: number): string {
  let sgnNum = num << 1;
  if (num < 0) {
    sgnNum = ~sgnNum;
  }
  return encodeNumber(sgnNum);
}

function encodeNumber(num: number): string {
  let str = '';
  let tempNum = num;
  while (tempNum >= 0x20) {
    const nextVal = (0x20 | (tempNum & 0x1f)) + 63;
    str += String.fromCharCode(nextVal);
    tempNum >>= 5;
  }
  str += String.fromCharCode(tempNum + 63);
  return str;
}
