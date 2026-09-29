/*
 * =========================================================================================
 *  SMART MOBILE-BASED DRIVING BEHAVIOUR & RISK MONITORING SYSTEM
 *  ESP32 Dual-Mode (Bluetooth LE + Wi-Fi) Telemetry & Crash Sensor Node (v3.7.0 - Auto-Tuned)
 *  Hardware: ESP32 Dev Board + MPU-6050 / MPU-6500 Gyro & Accelerometer
 * =========================================================================================
 *  
 *  HARDWARE PINOUT:
 *  -------------------------------------------------------------
 *  MPU6050 (GY-521)    -->    ESP32
 *  ----------------    -->    ------------------
 *  VCC                 -->    VIN (5V) or 3V3
 *  GND                 -->    GND
 *  SCL                 -->    GPIO 22 (I2C SCL)
 *  SDA                 -->    GPIO 21 (I2C SDA)
 *  AD0                 -->    GND (Address 0x68) or 3V3 (Address 0x69)
 *  INT (Optional)      -->    GPIO 19 (Hardware Impact Interrupt)
 * =========================================================================================
 */

// -------------------------------------------------------------
// FIRMWARE OPERATING MODE SELECTION
// -------------------------------------------------------------
#define MODE_DUAL       1
#define MODE_BLE_ONLY   2
#define MODE_WIFI_ONLY  3

// >>> SELECT YOUR FIRMWARE MODE HERE <<<
#define SYSTEM_MODE     MODE_BLE_ONLY

#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_WIFI_ONLY)
  #include <WiFi.h>
  #include <WebServer.h>
#endif

#include <Wire.h>

#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_BLE_ONLY)
  #include <BLEDevice.h>
  #include <BLEServer.h>
  #include <BLEUtils.h>
  #include <BLE2902.h>
#endif

// -------------------------------------------------------------
// CONFIGURATION & CONSTANTS
// -------------------------------------------------------------
#define DEVICE_NAME         "SmartDrive-Sensor-Node"
#define DEVICE_ID           "SD-ESP32-001"
#define FIRMWARE_VERSION    "3.7.0-TUNED"
#define LED_PIN             2       // Built-in Blue LED on GPIO 2
#define I2C_SDA_PIN         21      // Default ESP32 SDA
#define I2C_SCL_PIN         22      // Default ESP32 SCL

// BLE UUIDs (GATT Service & Characteristics)
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_TX "beb5483e-36e1-4688-b7f5-ea07361b26a8" // Telemetry Notify
#define CHARACTERISTIC_UUID_RX "beb5483e-36e1-4688-b7f5-ea07361b26a9" // Commands (LED Toggle, etc.)

// Wi-Fi Access Point Credentials (for Wi-Fi fallback)
#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_WIFI_ONLY)
const char* AP_SSID = "SmartDrive-Sensor-Node";
const char* AP_PASS = "SmartDrive2026!";
#endif

// Dynamic Driving Anomaly Thresholds (Automotive Standard Scale - Minute variations filtered out)
const float DEADBAND_DELTA_ACCEL  = 8.0;   // Discard delta changes below 8.0 m/s^2 (~0.8G)
const float THRESHOLD_HARSH_BRAKE = 10.5;  // Dynamic braking change > 10.5 m/s^2 (>1.0G)
const float THRESHOLD_RAPID_ACCEL = 9.8;   // Dynamic launch change > 9.8 m/s^2 (>1.0G)
const float THRESHOLD_SHARP_TURN  = 3.20;  // Yaw angular rate > 3.2 rad/s (~183 deg/s)
const float THRESHOLD_CRASH_G     = 5.0;   // Severe Collision Shockwave (> 5.0G)
const float THRESHOLD_CRASH_DELTA = 38.0;  // Massive Sudden Acceleration Jolt (> 38 m/s^2)

// -------------------------------------------------------------
// OBJECTS & GLOBALS
// -------------------------------------------------------------
uint8_t mpuAddress = 0x68;

#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_WIFI_ONLY)
WebServer server(80);
#endif

#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_BLE_ONLY)
BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
BLECharacteristic* pRxCharacteristic = NULL;
bool bleDeviceConnected = false;
bool oldBleDeviceConnected = false;
#else
bool bleDeviceConnected = false;
#endif

bool mpuConnected = false;
bool ledState = false;

// Real-time Raw & Filtered Readings
float ax = 0.0, ay = 0.0, az = 9.81;
float gx = 0.0, gy = 0.0, gz = 0.0;
float tempC = 25.0;
float gMagnitude = 1.0;

// Dynamic Zero Baseline Tracking (Adapts to any mounting orientation)
float baseAx = 0.0, baseAy = 0.0, baseAz = 9.81;
float deltaAx = 0.0, deltaAy = 0.0, deltaAz = 0.0;
bool baselineCalibrated = false;

// Anomaly Counters & Flags
bool impactDetected = false;
int harshBrakeCount = 0;
int rapidAccelCount = 0;
int sharpTurnCount = 0;

// Cooldown Timers (Prevents repeat triggers within 1.5 seconds)
unsigned long lastHarshBrakeEvent = 0;
unsigned long lastRapidAccelEvent = 0;
unsigned long lastSharpTurnEvent = 0;
unsigned long lastImpactEvent = 0;

unsigned long lastReadTime = 0;
unsigned long lastBlinkTime = 0;
unsigned long lastBleStreamTime = 0;
unsigned long lastMpuRetryTime = 0;
unsigned long uptimeSeconds = 0;
float simAngle = 0.0;

// -------------------------------------------------------------
// I2C BUS RECOVERY
// -------------------------------------------------------------
void recoverI2CBus() {
  pinMode(I2C_SDA_PIN, INPUT_PULLUP);
  pinMode(I2C_SCL_PIN, OUTPUT);
  digitalWrite(I2C_SCL_PIN, HIGH);

  for (int i = 0; i < 9; i++) {
    digitalWrite(I2C_SCL_PIN, LOW);
    delayMicroseconds(10);
    digitalWrite(I2C_SCL_PIN, HIGH);
    delayMicroseconds(10);
    if (digitalRead(I2C_SDA_PIN) == HIGH) break;
  }

  pinMode(I2C_SDA_PIN, OUTPUT);
  digitalWrite(I2C_SDA_PIN, LOW);
  delayMicroseconds(10);
  digitalWrite(I2C_SCL_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(I2C_SDA_PIN, HIGH);
  delayMicroseconds(10);
}

// -------------------------------------------------------------
// DIRECT HARDWARE REGISTER INITIALIZER
// -------------------------------------------------------------
bool tryInitMPU() {
  Serial.print("[I2C] Probing MPU-6050 / MPU-6500... ");

  uint8_t addresses[] = {0x68, 0x69};
  bool found = false;
  uint8_t targetAddr = 0x68;

  for (int i = 0; i < 2; i++) {
    Wire.beginTransmission(addresses[i]);
    if (Wire.endTransmission() == 0) {
      targetAddr = addresses[i];
      found = true;
      break;
    }
  }

  if (!found) {
    Serial.println("❌ No response on 0x68 or 0x69.");
    mpuConnected = false;
    return false;
  }

  mpuAddress = targetAddr;

  // 1. Reset Power Management
  Wire.beginTransmission(mpuAddress);
  Wire.write(0x6B);
  Wire.write(0x80);
  Wire.endTransmission();
  delay(50);

  // 2. Wake up with PLL X-gyro clock reference
  Wire.beginTransmission(mpuAddress);
  Wire.write(0x6B);
  Wire.write(0x01);
  Wire.endTransmission();
  delay(20);

  // 3. Set Gyro Range to +/- 250 deg/s (131.0 LSB / deg/s)
  Wire.beginTransmission(mpuAddress);
  Wire.write(0x1B);
  Wire.write(0x00);
  Wire.endTransmission();

  // 4. Set Accel Range to +/- 16g (2048.0 LSB / g) for Collision Shockwaves
  Wire.beginTransmission(mpuAddress);
  Wire.write(0x1C);
  Wire.write(0x18);
  Wire.endTransmission();

  // 5. Digital Low Pass Filter (DLPF = 21 Hz)
  Wire.beginTransmission(mpuAddress);
  Wire.write(0x1A);
  Wire.write(0x03);
  Wire.endTransmission();

  mpuConnected = true;
  baselineCalibrated = false;
  Serial.println("🟢 INITIALIZED & ACTIVE (Tuned Thresholds - 16G High-Impact Mode)!");
  return true;
}

// -------------------------------------------------------------
// SENSOR PROCESSING FUNCTION WITH AUTO-ZERO BASELINE
// -------------------------------------------------------------
void readMPU6050() {
  unsigned long now = millis();

  if (!mpuConnected) {
    simAngle += 0.05;
    ax = 0.02 * sin(simAngle);
    ay = 0.02 * cos(simAngle);
    az = 9.81;
    gx = 0.0;
    gy = 0.0;
    gz = 0.0;
    gMagnitude = 1.0;
    return;
  }

  // Request 14 bytes starting at ACCEL_XOUT_H (0x3B)
  Wire.beginTransmission(mpuAddress);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) {
    mpuConnected = false;
    Serial.println("[I2C] ⚠️ Sensor communication lost!");
    return;
  }

  if (Wire.requestFrom((uint8_t)mpuAddress, (uint8_t)14) == 14) {
    int16_t raw_ax = (Wire.read() << 8) | Wire.read();
    int16_t raw_ay = (Wire.read() << 8) | Wire.read();
    int16_t raw_az = (Wire.read() << 8) | Wire.read();
    int16_t raw_temp = (Wire.read() << 8) | Wire.read();
    int16_t raw_gx = (Wire.read() << 8) | Wire.read();
    int16_t raw_gy = (Wire.read() << 8) | Wire.read();
    int16_t raw_gz = (Wire.read() << 8) | Wire.read();

    // Scale Accelerometer (+/- 16g range => 2048.0 LSB/g => convert to m/s^2)
    ax = (raw_ax / 2048.0) * 9.80665;
    ay = (raw_ay / 2048.0) * 9.80665;
    az = (raw_az / 2048.0) * 9.80665;

    // Scale Gyroscope (+/- 250 deg/s => 131.0 LSB/(deg/s) => convert to rad/s)
    gx = (raw_gx / 131.0) * (PI / 180.0);
    gy = (raw_gy / 131.0) * (PI / 180.0);
    gz = (raw_gz / 131.0) * (PI / 180.0);

    tempC = (raw_temp / 340.0) + 36.53;

    // Total G-Force magnitude (1.00G at rest)
    float totalAccel = sqrt(ax * ax + ay * ay + az * az);
    gMagnitude = totalAccel / 9.80665;

    // -------------------------------------------------------------
    // AUTOMATIC RESTING BASELINE LEARNING
    // -------------------------------------------------------------
    if (!baselineCalibrated) {
      baseAx = ax;
      baseAy = ay;
      baseAz = az;
      baselineCalibrated = true;
    } else {
      // Slowly adapt baseline to vehicle tilt over time
      baseAx = 0.98 * baseAx + 0.02 * ax;
      baseAy = 0.98 * baseAy + 0.02 * ay;
      baseAz = 0.98 * baseAz + 0.02 * az;
    }

    // Dynamic deviation from resting position
    deltaAx = ax - baseAx;
    deltaAy = ay - baseAy;
    deltaAz = az - baseAz;

    // Filter minute variations below deadband threshold
    if (abs(deltaAx) < DEADBAND_DELTA_ACCEL) deltaAx = 0.0;
    if (abs(deltaAy) < DEADBAND_DELTA_ACCEL) deltaAy = 0.0;
    if (abs(deltaAz) < DEADBAND_DELTA_ACCEL) deltaAz = 0.0;

    float maxDelta = max(abs(deltaAx), max(abs(deltaAy), abs(deltaAz)));

    // -------------------------------------------------------------
    // DRIVING EVENT & CRASH DETECTION (Huge value changes only)
    // -------------------------------------------------------------
    
    // 1. HUGE CHANGE: Collision Impact Shockwave (>= 5.0G or delta >= 38 m/s^2)
    if (gMagnitude >= THRESHOLD_CRASH_G || maxDelta >= THRESHOLD_CRASH_DELTA) {
      if (now - lastImpactEvent > 3000) {
        lastImpactEvent = now;
        impactDetected = true;
        Serial.printf("[CRITICAL] 🚨 HUGE COLLISION IMPACT! Magnitude: %.2f G | Delta: %.2f m/s^2\n", gMagnitude, maxDelta);
      }
    }

    // 2. Harsh Braking (Forward Dynamic Deceleration > 10.5 m/s^2)
    if ((deltaAy < -THRESHOLD_HARSH_BRAKE || deltaAx < -THRESHOLD_HARSH_BRAKE) && (gMagnitude < THRESHOLD_CRASH_G)) {
      if (now - lastHarshBrakeEvent > 2000) {
        lastHarshBrakeEvent = now;
        harshBrakeCount++;
        Serial.printf("[EVENT] ⚠️ Harsh Braking Detected! Decel Jolt: %.2f m/s^2\n", min(deltaAy, deltaAx));
      }
    }

    // 3. Rapid Acceleration (Forward Dynamic Launch > 9.8 m/s^2)
    if ((deltaAy > THRESHOLD_RAPID_ACCEL || deltaAx > THRESHOLD_RAPID_ACCEL) && (gMagnitude < THRESHOLD_CRASH_G)) {
      if (now - lastRapidAccelEvent > 2000) {
        lastRapidAccelEvent = now;
        rapidAccelCount++;
        Serial.printf("[EVENT] ⚡ Rapid Launch Detected! Accel Jolt: %.2f m/s^2\n", max(deltaAy, deltaAx));
      }
    }

    // 4. Sharp Cornering Turn (Yaw Angular Velocity > 183 deg/s)
    if (abs(gz) > THRESHOLD_SHARP_TURN) {
      if (now - lastSharpTurnEvent > 2000) {
        lastSharpTurnEvent = now;
        sharpTurnCount++;
        Serial.printf("[EVENT] 🔄 Sharp Turn Detected! Yaw Rate: %.2f rad/s\n", gz);
      }
    }
  } else {
    mpuConnected = false;
  }
}

// -------------------------------------------------------------
// BLE CALLBACKS
// -------------------------------------------------------------
#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_BLE_ONLY)
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      bleDeviceConnected = true;
      Serial.println("[BLE] 📱 Mobile Client Connected over Bluetooth LE!");
    };

    void onDisconnect(BLEServer* pServer) {
      bleDeviceConnected = false;
      Serial.println("[BLE] 🔌 Mobile Client Disconnected from Bluetooth LE.");
    }
};

class MyRxCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue().c_str();
      if (rxValue.length() > 0) {
        Serial.print("[BLE RX] Received: ");
        Serial.println(rxValue);
        if (rxValue.indexOf("LED_TOGGLE") >= 0 || rxValue.indexOf("toggle") >= 0) {
          ledState = !ledState;
          digitalWrite(LED_PIN, ledState ? HIGH : LOW);
        }
      }
    }
};
#endif

// -------------------------------------------------------------
// REST API HANDLERS (Wi-Fi Fallback)
// -------------------------------------------------------------
#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_WIFI_ONLY)
void sendCORSHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

void handleOptions() {
  sendCORSHeaders();
  server.send(204);
}

void handleDeviceStatus() {
  sendCORSHeaders();
  uptimeSeconds = millis() / 1000;
  
  String json = "{";
  json += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
  json += "\"firmwareVersion\":\"" + String(FIRMWARE_VERSION) + "\",";
  json += "\"sensorConnected\":" + String(mpuConnected ? "true" : "false") + ",";
  json += "\"bleConnected\":" + String(bleDeviceConnected ? "true" : "false") + ",";
  json += "\"uptime\":" + String(uptimeSeconds) + ",";
  json += "\"freeHeap\":" + String(ESP.getFreeHeap()) + ",";
  json += "\"ipAddress\":\"" + WiFi.softAPIP().toString() + "\",";
  json += "\"ledState\":" + String(ledState ? "true" : "false");
  json += "}";

  server.send(200, "application/json", json);
}

void handleLatestTelemetry() {
  sendCORSHeaders();
  
  String json = "{";
  json += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
  json += "\"timestamp\":" + String(millis()) + ",";
  json += "\"sensorConnected\":" + String(mpuConnected ? "true" : "false") + ",";
  json += "\"bleConnected\":" + String(bleDeviceConnected ? "true" : "false") + ",";
  json += "\"ax\":" + String(ax, 3) + ",";
  json += "\"ay\":" + String(ay, 3) + ",";
  json += "\"az\":" + String(az, 3) + ",";
  json += "\"gx\":" + String(gx, 3) + ",";
  json += "\"gy\":" + String(gy, 3) + ",";
  json += "\"gz\":" + String(gz, 3) + ",";
  json += "\"temperature\":" + String(tempC, 1) + ",";
  json += "\"gMagnitude\":" + String(gMagnitude, 2) + ",";
  json += "\"impactDetected\":" + String(impactDetected ? "true" : "false") + ",";
  json += "\"harshBrakeCount\":" + String(harshBrakeCount) + ",";
  json += "\"rapidAccelCount\":" + String(rapidAccelCount) + ",";
  json += "\"sharpTurnCount\":" + String(sharpTurnCount);
  json += "}";

  if (impactDetected) {
    impactDetected = false;
  }

  server.send(200, "application/json", json);
}

void handleToggleLed() {
  sendCORSHeaders();
  ledState = !ledState;
  digitalWrite(LED_PIN, ledState ? HIGH : LOW);
  
  String json = "{\"success\":true,\"ledState\":" + String(ledState ? "true" : "false") + "}";
  server.send(200, "application/json", json);
}

void handleNotFound() {
  sendCORSHeaders();
  server.send(404, "application/json", "{\"error\":\"Endpoint not found\"}");
}
#endif

// -------------------------------------------------------------
// SETUP
// -------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=======================================================");
  Serial.println("  SMARTDRIVE DUAL-MODE (BLE + WI-FI) SENSOR NODE");
  Serial.println("  Firmware: " FIRMWARE_VERSION);
  Serial.println("=======================================================");

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  recoverI2CBus();

  // Initialize I2C Bus with 40kHz speed
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setClock(40000);
  Wire.setTimeOut(30);

  // Initialize MPU directly via hardware registers
  tryInitMPU();

  // -------------------------------------------------------------
  // 1. INITIALIZE BLUETOOTH LOW ENERGY (BLE) SERVER
  // -------------------------------------------------------------
#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_BLE_ONLY)
  Serial.println("[BLE] Initializing Bluetooth Low Energy GATT Server...");
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Telemetry Characteristic (Notify)
  pTxCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID_TX,
                        BLECharacteristic::PROPERTY_READ |
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
  pTxCharacteristic->addDescriptor(new BLE2902());

  // Command Characteristic (Write)
  pRxCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID_RX,
                        BLECharacteristic::PROPERTY_WRITE
                      );
  pRxCharacteristic->setCallbacks(new MyRxCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("[BLE] ✅ BLE Advertising Active as '" DEVICE_NAME "'");
#endif

  // -------------------------------------------------------------
  // 2. INITIALIZE WI-FI ACCESS POINT (DUAL-MODE FALLBACK)
  // -------------------------------------------------------------
#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_WIFI_ONLY)
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP(AP_SSID, AP_PASS);
  IPAddress apIP = WiFi.softAPIP();

  Serial.print("[WiFi] Sensor SoftAP SSID: ");
  Serial.println(AP_SSID);
  Serial.print("[WiFi] Direct IP: http://");
  Serial.println(apIP);

  // Setup REST Web Server Routes
  server.on("/api/v1/device/status", HTTP_GET, handleDeviceStatus);
  server.on("/api/v1/telemetry/latest", HTTP_GET, handleLatestTelemetry);
  server.on("/api/v1/device/led", HTTP_POST, handleToggleLed);
  server.on("/api/v1/device/status", HTTP_OPTIONS, handleOptions);
  server.on("/api/v1/telemetry/latest", HTTP_OPTIONS, handleOptions);
  server.on("/api/v1/device/led", HTTP_OPTIONS, handleOptions);
  server.onNotFound(handleNotFound);

  server.begin();
  Serial.println("[HTTP] REST API Server listening on port 80");
#endif
  Serial.println("=======================================================");

  for (int i = 0; i < 4; i++) {
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    delay(100);
  }
}

// -------------------------------------------------------------
// MAIN LOOP
// -------------------------------------------------------------
void loop() {
#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_WIFI_ONLY)
  server.handleClient();
#endif

  unsigned long currentMillis = millis();

#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_BLE_ONLY)
  if (!bleDeviceConnected && oldBleDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Restarted BLE Advertising...");
    oldBleDeviceConnected = bleDeviceConnected;
  }
  if (bleDeviceConnected && !oldBleDeviceConnected) {
    oldBleDeviceConnected = bleDeviceConnected;
  }
#endif

  // Auto-retry MPU initialization every 2 seconds if disconnected
  if (!mpuConnected && (currentMillis - lastMpuRetryTime >= 2000)) {
    lastMpuRetryTime = currentMillis;
    tryInitMPU();
  }

  // Read sensor at 20 Hz (every 50ms)
  if (currentMillis - lastReadTime >= 50) {
    lastReadTime = currentMillis;
    readMPU6050();
  }

#if (SYSTEM_MODE == MODE_DUAL || SYSTEM_MODE == MODE_BLE_ONLY)
  // Stream Live Telemetry over BLE Notify at 20 Hz
  if (bleDeviceConnected && (currentMillis - lastBleStreamTime >= 50)) {
    lastBleStreamTime = currentMillis;

    char bleBuf[192];
    snprintf(bleBuf, sizeof(bleBuf),
      "{\"ax\":%.2f,\"ay\":%.2f,\"az\":%.2f,\"gx\":%.2f,\"gy\":%.2f,\"gz\":%.2f,\"gMag\":%.2f,\"temp\":%.1f,\"imp\":%d,\"hb\":%d,\"ra\":%d,\"st\":%d,\"sc\":%d}",
      ax, ay, az, gx, gy, gz, gMagnitude, tempC, impactDetected ? 1 : 0, harshBrakeCount, rapidAccelCount, sharpTurnCount, mpuConnected ? 1 : 0
    );

    pTxCharacteristic->setValue((uint8_t*)bleBuf, strlen(bleBuf));
    pTxCharacteristic->notify();

    if (impactDetected) {
      impactDetected = false;
    }
  }
#endif

  // Heartbeat LED Blink (Every 2 seconds)
  if (currentMillis - lastBlinkTime >= 2000) {
    lastBlinkTime = currentMillis;
    digitalWrite(LED_PIN, HIGH);
    delay(30);
    digitalWrite(LED_PIN, LOW);

    Serial.printf("[TELEMETRY] G-Mag: %.2fG | Accel: [%.2f, %.2f, %.2f] | BLE: %s | MPU: %s\n",
      gMagnitude, ax, ay, az,
      bleDeviceConnected ? "CONNECTED 📱" : "WAITING 📡",
      mpuConnected ? "ACTIVE 🟢" : "SEARCHING ⚠️");
  }
}
