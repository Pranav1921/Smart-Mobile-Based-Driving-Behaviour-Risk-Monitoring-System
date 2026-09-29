# 🛡️ SmartDrive A to Z Testing Guide

This guide provides a comprehensive walkthrough to test every professional feature of the Smart Mobile-Based Driving Behaviour & Risk Monitoring System platform, from secure vault sign-in to hybrid operation modes and multi-app financial synchronization.

---

## 🏗️ 1. Infrastructure Setup
1.  **Launch All Services**: Open a terminal in the project root and run `.\run_system.bat`.
    *   This starts the Backend, AI Service, Dispatcher Portal, and Admin Command Center.
2.  **Start Mobile App**:
    ```cmd
    cd MobileApp
    set "ANDROID_PREFS_ROOT=" && set "JAVA_HOME=C:\Program Files\Java\jdk-17"
    flutter run -d 1376361275000B9
    ```

---

## 🔐 2. Admin Command Security (New Refined UI)
1.  **Open Admin HUD**: `http://localhost:5173`
2.  **Secure Authentication**:
    *   Note that the "Platform Selector" and "Register" buttons are gone for a cleaner, more secure look.
    *   **Test Login (Puttur)**: Select **Taluk: Puttur**, Enter Passcode: `puttur2026`.
    *   **Result**: System initializes with **SmartDrive Enterprise** theme.
    *   **Test Login (Mangaluru)**: Logout, select **Taluk: Mangaluru**, Enter Passcode: `admin123`.
    *   **Result**: System initializes with **Logistics Pro AI** (Deep Navy) theme.

---

## 📲 3. Mobile Hybrid Operation & Multi-App Sync
1.  **Direct Mode (Standalone)**:
    *   On the Home Screen, ensure **DIRECT MODE** is active.
    *   You see the **CONTROL HUB** (Go Live, Dispatch Grid, SOS).
2.  **Shadow Mode (Background Sync)**:
    *   Toggle to **SHADOW MODE**.
    *   **Result**: The tactical map and dispatch buttons are hidden. The app now acts as a silent background safety service for external apps.
3.  **Multi-App Income Sync**:
    *   Go to **Operator Dossier (Profile)** -> **Service Synchronization**.
    *   Toggle **Zomato** and **Swiggy** to "ON".
    *   Go to **Earnings Analytics** (tap the earnings card on Home or Profile).
    *   **Result**: See the **Aggregate Total Income** combining your SmartDrive safety base pay with live data from Zomato and Swiggy.
    *   **Post-Work Balance**: After finishing a shift, review your breakdown of earnings, tips, and safety-linked insurance bonuses.

---

## 📡 4. Mission Dispatch & Forensic Audit
1.  **Direct Mission**: Go to `http://localhost:3000/dispatch`.
    *   Create a mission with exact coordinates (e.g. 12.7749, 75.2023).
    *   On Mobile, go to **Dispatch** and accept the mission.
2.  **Forensic Crash Simulation**:
    *   Tap **SOS** on the phone.
    *   On Admin Dashboard, click the red alert -> **Investigate**.
    *   **Forensic Sequence**:
        1.  Verify the **Impact Deceleration Graph** (60 to 0 km/h).
        2.  Transmit **Safe Check**. Wait for "No Response".
        3.  Initiate **3 Voice Link attempts**.
        4.  Click **INITIALIZE FULL DISPATCH**.
    *   **Result**: Automated family and police notifications are triggered with the incident dossier.

---

## 🛣️ 5. ML Driving Behavior (Intelligence Alerts)
1.  **Pothole Ahead**: Drive (or mock location) near `12.7800, 75.2100`. The phone will announce "Pothole Ahead" via TTS.
2.  **School Zones**: Admin map will flag a warning if the driver exceeds 30km/h near the "Puttur School" zone.
3.  **Fatigue Intel**: The system monitors continuous operation. After 2 simulated hours, a rest reminder is announced.

**The system is now a zero-defect, high-security autonomous intelligence platform.** 🛡️🚀🛰️✨
