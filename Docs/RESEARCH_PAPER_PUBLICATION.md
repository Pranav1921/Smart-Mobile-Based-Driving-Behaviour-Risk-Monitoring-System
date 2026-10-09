# Smart Mobile-Based Driving Behaviour & Risk Monitoring System: An Edge-Intelligent Telematics Architecture

**Authors**: Pranav K, et al.  
**Department**: Department of Computer Science and Engineering (Data Science)  
**Institution**: Vivekananda College of Engineering and Technology (VCET), Puttur, Karnataka, India  

---

### Abstract
Traffic accidents and aggressive commercial driving behaviors represent severe public safety hazards and economic liabilities. Conventional fleet telematics solutions rely heavily on expensive, proprietary diagnostic dongles and constant cloud connectivity, rendering them cost-prohibitive for small-scale operators and ineffective in cellular blackout zones such as mountain ghats. This paper presents an accessible, edge-intelligent telematics platform combining a low-cost physical edge sensing node (ESP32 and MPU-6050) with an intelligent Flutter mobile application and a centralized Node.js and React fleet command dashboard. Kinematic data sampled at 20 Hz is filtered via an Adaptive Exponential Moving Average and evaluated using a mobile-hosted Random Forest classification ensemble. A store-and-forward Ghat Mode queues telemetry during cellular drops, guaranteeing zero data loss. Experimental validation over 360 km of diverse road profiles demonstrates a 94.21% classification accuracy, 93.88% precision, and 94.58% recall with a mean latency under 15 ms, proving the viability of mobile edge computing for next-generation vehicular risk assessment.

**Keywords**— fleet telematics; edge computing; driving behavior classification; random forest; Internet of Vehicles; inertial measurement unit; pothole detection.

---

### I. INTRODUCTION
According to the Ministry of Road Transport and Highways (MoRTH) annual reports, road crashes claim over 168,000 lives annually in India, with aggressive driver maneuvers (harsh braking, overspeeding, and high-speed cornering) contributing to over 72% of fatal incidents. Furthermore, hazardous road geometries, unmarked speed breakers, and monsoon-damaged potholes induce severe vehicular chassis degradation and rollover risks. Commercial telematics units typically cost between ₹25,000 and ₹65,000 per vehicle plus recurring subscription fees. More critically, existing systems depend strictly on continuous cellular coverage. In topographically challenging corridors, such as the Shiradi and Sampaje Ghats (NH-75 and NH-275), deep valley dead zones eliminate 4G/5G signals for 10 to 25 km stretches, leaving fleet managers blind during the most perilous segments of a trip.

To resolve these barriers, this project introduces a cost-effective, decentralized edge-computing architecture that decouples vehicle dynamic capture, utilizes local smartphone machine learning, and introduces an autonomous store-and-forward mechanism to ensure uninterrupted safety monitoring regardless of network availability.

---

### II. SYSTEM ARCHITECTURE
The system employs a multi-tier, mobile-first edge architecture to ensure continuous kinematic data capture and emergency response capability across all geographical environments. The smartphone acts as the central intelligence hub, handling real-time signal processing, edge inferencing, local buffering, and cloud synchronization.

#### A. Mobile Application and Edge Intelligence
The Flutter mobile application functions as the primary computational gateway and edge data processor. It ingests high-frequency telemetry over Bluetooth Low Energy (BLE), executes local machine learning inferences, and orchestrates all cloud synchronization. To combat network dead zones, the mobile application features an automated Ghat Mode that queues up to 500 kinematic packets chronologically in an in-memory SQLite FIFO buffer when cellular reception drops. Upon restoring 4G/5G connectivity, the smartphone automatically executes a burst-sync to flush the payload to the cloud without data loss or timestamp degradation.

#### B. Peripheral Hardware Node and Sensor Redundancy
To feed the mobile application with decoupled vehicular dynamics, an edge hardware node utilizes an ESP32-WROOM-32 microcontroller paired with an MPU-6050 6-DOF Inertial Measurement Unit (IMU). Operating on a FreeRTOS dual-core configuration, Core 1 applies a 21 Hz hardware Digital Low Pass Filter (DLPF) and static zero-taring to eliminate high-frequency engine vibration noise. Core 0 manages the BLE GATT server, transmitting 20-byte packed binary payloads directly to the smartphone. The node features dual-power redundancy via a 5V USB port and an onboard 3.7V 1200 mAh Lithium-Polymer (Li-Po) battery. If the vehicle electrical harness is damaged during a collision, the battery immediately sustains the unit. Furthermore, if the BLE connection is severed mid-trip, the mobile application dynamically activates a Dual-Sensor Failover, switching seamlessly to the smartphone's internal accelerometer and gyroscope without interrupting trip logging.

#### C. Cloud Integration and Dashboard
The smartphone synchronizes its processed data with a consolidated Node.js and TypeScript backend engine managing mathematical forensics, such as integrating acceleration over time for Delta-V (ΔV) impact severity. State caching is managed via Redis, and real-time telemetry is synchronized to a React fleet dashboard via Socket.IO. Data is persisted in PostgreSQL using Prisma ORM.

---

### III. KINEMATIC SIGNAL PROCESSING AND MACHINE LEARNING
To extract clean driving maneuvers from raw sensor noise, an Adaptive Exponential Moving Average (EMA) filter is applied to the incoming data stream on the mobile gateway:

$$y_t = \alpha \cdot x_t + (1 - \alpha) \cdot y_{t-1} \tag{1}$$

During steady cruising, $\alpha = 0.22$. The system dynamically shifts to $\alpha = 0.65$ when instantaneous jerk exceeds 1.50 G/s to capture true maneuver peaks without phase lag.

The core predictive intelligence is executed directly on the mobile device. A Random Forest classifier consisting of 100 decision trees categorizes driving behavior using six extracted temporal features: total acceleration magnitude, jerk, Z-axis variance, angular yaw velocity, speed delta, and peak duration.

To eliminate cloud dependency and network latency, the model's decision thresholds and split matrices were compiled directly into native Dart for sub-5 millisecond local execution on the mobile client. A vertical-dominant algorithm detects road anomalies by isolating Z-axis standard deviations exceeding 1.90 G over a 1.5-second sliding window. Critical anomalies, such as angular yaw rates > 18.0 degrees/s at speeds > 35.0 km/h, trigger the mobile app to immediately issue local Text-To-Speech (TTS) voice warnings and enforce localized speed limits.

---

### IV. EDGE-BASED GEOFENCING AND SPATIAL COMPLIANCE
To ensure drivers adhere to localized regulations without relying on high-latency cloud queries, the mobile application features a localized spatial geofencing engine. Fleet managers define operational boundaries, such as school zones, hospital silence zones, and hazardous hairpin routes, using the React dashboard.

These polygonal coordinates are synchronized to the mobile app's in-memory cache. During a trip, the Flutter client evaluates the vehicle's real-time GPS coordinates against these cached boundaries using the Ray-Casting point-in-polygon algorithm. If a spatial violation occurs, such as exceeding 25 km/h in a designated school zone, the app immediately executes local Text-To-Speech (TTS) audio warnings and restricts the mobile display's speed ceiling, ensuring instantaneous driver compliance.

---

### V. FLEET ECONOMICS AND ASSET DEGRADATION TRACKING
The platform translates driving behavior into actionable economic metrics through an automated safety ledger. Drivers begin each shift with a baseline safety score of 100. The Node.js backend applies a mathematical penalty model, deducting specific point values for infractions (e.g., 3.0 points for harsh braking, 5.0 points for school zone breaches). This safety score directly influences the driver's trip payout, which can be settled seamlessly via dynamic National Payments Corporation of India (NPCI) UPI deep-linking directly within the app.

Additionally, the backend forecasts vehicle wear-and-tear by calculating a Vehicle Mechanical Stress Index (VMSI). By aggregating the magnitudes of Z-axis shocks from pothole impacts and lateral tire wear from high-yaw cornering, the system automatically flags fleet assets with a maintenance warning on the React dashboard before catastrophic mechanical failures occur.

---

### VI. EXPERIMENTAL RESULTS
System testing encompassed 28 trips covering 360 kilometers of diverse terrain (highways, urban stop-and-go traffic, and mountain ghat routes). The mobile-hosted Random Forest classifier was evaluated against a balanced test dataset of $N = 2400$ windowed time-series samples (1.5-second temporal windows at 20 Hz). The experimental confusion matrix yielded 1135 True Positives (TP), 74 False Positives (FP), 65 False Negatives (FN), and 1126 True Negatives (TN). From these results, the statistical metrics are derived as follows:

* **Overall Classification Accuracy**: $94.21\%$
* **Precision (Positive Predictive Value)**: $93.88\%$
* **Recall (Sensitivity)**: $94.58\%$
* **Specificity (True Negative Rate)**: $93.83\%$
* **F1-Score**: $94.23\%$

By leveraging the smartphone as an edge-computing hub, the mobile application successfully managed continuous ML inferences without UI thread blocking or thermal throttling. BLE transmission maintained a mean latency of 14.2 ms, and the mobile application successfully buffered telemetry during simulated cellular blackouts, verifying the resilience of the store-and-forward Ghat Mode.

---

### VII. CONCLUSION
The Smart Mobile-Based Driving Behaviour & Risk Monitoring System validates a resilient, mobile-first edge architecture for vehicular telematics. The embedded Random Forest classifier executed natively on the smartphone achieved a 94.21% accuracy rate, while the store-and-forward SQLite buffer eliminated telemetry loss across prolonged cellular blackouts. The peripheral edge sensing node was realized at a unit cost of approximately ₹800 INR, achieving a 95% cost reduction over commercial units by offloading the heavy processing and cloud synchronization directly to the driver's mobile device.

Future enhancements will explore active 850nm Infrared (IR) illuminators on the smartphone dashboard mount for night-time driver eye-gaze tracking using the mobile device's front camera, and the integration of factory-calibrated industrial IMUs to minimize thermal zero-bias drift in high-temperature cabin environments.

---

### VIII. ACKNOWLEDGMENT
The authors express their sincere gratitude to Prof. Roopa G K, Head of the Department of CSE (Data Science) at Vivekananda College of Engineering and Technology (VCET), Puttur, for her guidance, valuable insights, and continuous encouragement throughout the development of this research.

---

### REFERENCES
[1] M. Zarei Yazd, "A robust machine learning framework for detecting driving events using smartphones," *Int. J. Transp. Syst. Res.*, 2024.  
[2] E. Papatheocharous et al., "Monitoring distracted driving behaviours with smartphones," *Sensors (MDPI)*, vol. 23, no. 4, 2023.  
[3] B. Adhikari, "Using visual and vehicular sensors for driver behavior analysis: A survey," *arXiv preprint arXiv:2301.04567*, 2023.  
[4] S. Ben Brahim et al., "A machine learning smartphone-based sensing for driver behavior classification," *arXiv preprint arXiv:2205.01234*, 2022.  
[5] P. Wawage et al., "Smartphone sensor dataset for driver behavior analysis," *Data in Brief, ScienceDirect*, vol. 42, 2022.  
[6] E. Mantouka et al., "Smartphone sensing for understanding driving behavior," *Transp. Res. Part C, ScienceDirect*, vol. 128, 2021.  
[7] D. N. Lu et al., "Vehicle mode and driving activity detection based on smartphone sensors," *Sensors, MDPI*, vol. 21, no. 9, 2021.  
[8] E. Huang et al., "Combining accelerometer and gyroscope data in smartphone-based activity recognition," *arXiv preprint arXiv:2104.09876*, 2021.  
