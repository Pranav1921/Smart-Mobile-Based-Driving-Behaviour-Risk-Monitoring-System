# ESP32 Dual-Mode (Bluetooth LE + Wi-Fi) Telemetry & Crash Sensor Node Guide

This guide explains how to wire, flash, and test the **ESP32 30-Pin Dual-Mode Hardware Sensor Node** with **Bluetooth Low Energy (BLE)** and **Wi-Fi** fallback for the **Smart Mobile-Based Driving Behaviour & Risk Monitoring System**.

---

## 1. Components Checklist & Pin Connections

| Component | Pin | Connects to ESP32 | Purpose |
| :--- | :--- | :--- | :--- |
| **MPU-6050 (GY-521)** | **VCC** | **3V3** (or VIN 5V) | Power |
| | **GND** | **GND** | Ground |
| | **SCL** | **GPIO 22** | I2C Clock |
| | **SDA** | **GPIO 21** | I2C Data |
| | **INT** | *Optional (GPIO 19)* | Hardware Interrupt |
| | **AD0** | *Leave Unconnected* | Sets I2C Address to `0x68` |
| **TP4056 Charger** | **OUT+** | **VIN (5V)** (via switch) | Regulated 5V Power |
| | **OUT-** | **GND** | Common Ground |
| | **B+ / B-** | **3.7V Battery (+ / -)** | Li-ion Battery Connection |

---

## 2. Flashing the Dual-Mode Firmware

1. Open **Arduino IDE**.
2. Open [`hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino`](file:///c:/projects/Major_project/hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino).
3. Under **Tools $\rightarrow$ Board**, select **ESP32 Dev Module** (or **DOIT ESP32 DEVKIT V1**).
4. **Choose your build method:**
   - **Method A (Fastest & Default - BLE Mode):** Set `#define SYSTEM_MODE MODE_BLE_ONLY` at line 39. Compiles directly with **Default Partition Scheme** (~950KB / 1.3MB).
   - **Method B (Dual Mode - BLE + Wi-Fi AP):** Set `#define SYSTEM_MODE MODE_DUAL` and select **Tools $\rightarrow$ Partition Scheme $\rightarrow$ `Huge APP (3MB No OTA/1MB SPIFFS)`**.
5. Select your **Port** (e.g. `COM8`).
6. Click **Upload** (Arrow icon). *(Hold the `BOOT` button for 2 seconds if you see `Connecting...___`).*
7. Once uploaded, open **Serial Monitor** (`Ctrl + Shift + M`) at **`115200 baud`**.
7. You should see:
   ```text
   =======================================================
     SMARTDRIVE DUAL-MODE (BLE + WI-FI) SENSOR NODE
     Firmware: 3.7.0-TUNED
   =======================================================
   [I2C] Probing MPU-6050 Gyroscope/Accelerometer... FOUND & INITIALIZED!
   [BLE] Initializing Bluetooth Low Energy GATT Server...
   [BLE] ✅ BLE Advertising Active as 'SmartDrive-Sensor-Node'
   [WiFi] Sensor SoftAP SSID: SmartDrive-Sensor-Node
   [WiFi] Direct IP: http://192.168.4.1
   [HTTP] REST API Server listening on port 80
   =======================================================
   [TELEMETRY] G-Mag: 1.00G | Accel: [0.01, 0.05, 9.81] | BLE: WAITING 📡 | MPU: ACTIVE 🟢
   ```

---

## 3. How to Connect in the Mobile App

### **Option A: Bluetooth LE (Recommended 🌟)**
1. Turn on Bluetooth on your phone.
2. Open the **SmartDrive Mobile App** and tap the **Vehicle Sensor Radar** icon on the Home screen.
3. Keep the **Bluetooth LE (Best)** tab selected.
4. **Distinguishing Your Sensor from Others:**
   - The scan list automatically filters out random "Unknown Devices" and highlights **`SmartDrive-Sensor-Node`** with an **`ESP32 NODE`** emerald badge.
   - Use the **Search Bar** to filter by your sensor name or MAC address (e.g. `SmartDrive` or `24:6F`).
   - Use the **Filter Chips** (`🎯 ESP32 & SmartDrive`, `⭐ My Saved Sensor`, `📡 Show All`).
   - Look at the live **Signal Strength Meter (RSSI)**: The board right in front of you will show `🟢 -45 to -60 dBm (Strong)`.
   - Tap the **Star Icon (⭐)** on your board to bookmark it as **"MY SENSOR"** — it will stay pinned to the top of your list!
5. Tap **CONNECT**!
6. The radar turns green and instantly streams 20 Hz G-Force and Gyro telemetry to the driver HUD!
   - *Advantage:* Zero IP addresses required, and your phone's 4G/5G mobile internet stays active for live GPS navigation and cloud sync!

---

### **Customizing Your Sensor Name (For Multiple ESP32s in Lab/Fleet)**
If you are in a lab or classroom where multiple people are using ESP32 boards:
1. Open [`hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino`](file:///c:/projects/Major_project/hardware_esp32/smartdrive_esp32_sensor/smartdrive_esp32_sensor.ino).
2. Change line 48:
   ```cpp
   #define DEVICE_NAME  "SmartDrive-Sensor-Pranav" // Or your roll number / vehicle plate
   #define DEVICE_ID    "SD-ESP32-001"
   ```
3. Re-upload to your board. Your customized name will appear instantly in the app!

---

### **Option B: Wi-Fi Direct Hotspot (Fallback 🌐)**
1. Go to your phone's Wi-Fi settings and connect to **`SmartDrive-Sensor-Node`** (Password: `SmartDrive2026!`).
2. Open the **SmartDrive Mobile App** $\rightarrow$ Tap the Radar icon.
3. Switch to the **Wi-Fi AP / LAN** tab.
4. Tap **Pair Wi-Fi Sensor Node**.
5. Telemetry streams via HTTP polling with multi-retry resilience.
