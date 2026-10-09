# Smart Mobile-Based Driving Behaviour & Risk Monitoring System: An Edge-Intelligent Telematics Architecture

**Pranav K, et al.**  
*Department of Computer Science and Engineering (Data Science)*  
*Vivekananda College of Engineering and Technology, Puttur, Karnataka, India*  
*Guided by: Prof. Roopa G. K., Head of Department, CSE (Data Science)*  

---

### Abstract
Traffic accidents and aggressive commercial driving behaviors represent severe public safety hazards and economic liabilities. Conventional fleet telematics solutions rely heavily on expensive, proprietary diagnostic dongles and constant cloud connectivity, rendering them cost-prohibitive for small-scale operators and ineffective in cellular blackout zones such as mountain ghats. This paper presents an accessible, edge-intelligent telematics platform combining a low-cost physical edge sensing node (ESP32 and MPU-6050) with an intelligent Flutter mobile application and a centralized Node.js and React fleet command dashboard. Kinematic data sampled at 20 Hz is filtered via an Adaptive Exponential Moving Average (EMA) and evaluated using a mobile-hosted Random Forest classification ensemble. A store-and-forward Ghat Mode queues telemetry during cellular drops, guaranteeing zero data loss. Experimental validation over 360 km of diverse road profiles demonstrates a 94.21% classification accuracy, 93.88% precision, and 94.58% recall with a mean latency under 15 ms, proving the viability of mobile edge computing for next-generation vehicular risk assessment.

**Index Terms**— *Fleet telematics, edge computing, driving behavior classification, random forest, Internet of Vehicles (IoV), inertial measurement unit (IMU), pothole detection, store-and-forward, ghat mode.*

---

## I. INTRODUCTION

According to the Ministry of Road Transport and Highways (MoRTH) annual reports, road crashes claim over 168,000 lives annually across the Indian subcontinent. Forensic accident analyses reveal that aggressive driver maneuvers—specifically sudden harsh braking, high-speed cornering, and erratic acceleration—contribute to over 72% of fatal vehicular incidents. In addition to behavioral risks, deteriorating pavement quality, marked by unmapped speed breakers and monsoon-induced potholes, causes severe vehicle chassis fatigue, suspension degradation, and catastrophic rollover risks for commercial transport fleets.

Commercial fleet telematics units currently dominate the market, costing between ₹25,000 and ₹65,000 per vehicle plus recurring monthly SIM subscription fees. Beyond excessive cost, existing platforms suffer from a critical architectural limitation: **continuous cloud dependency**. In topographically challenging terrain, such as the Shiradi and Sampaje Ghat corridors along National Highways NH-75 and NH-275, deep valleys and dense forest canopies eliminate cellular 4G/5G signals for continuous stretches of 10 to 25 kilometers. During these perilous mountain segments, conventional cloud-reliant telematics units disconnect, leaving fleet managers blind precisely when collision and mechanical rollover hazards peak.

To eliminate these barriers, this project introduces a cost-effective, decentralized edge-computing architecture. By offloading sensor processing and machine learning inferencing directly to the driver's existing smartphone, the physical hardware is reduced to an accessible edge node (~₹800 INR). Furthermore, an autonomous store-and-forward **Ghat Mode** ensures zero data loss during prolonged cellular blackouts.

The primary objectives of this research are:
1. To engineer a low-cost, dual-power physical edge sensing node using an ESP32 and MPU-6050 IMU communicating over Bluetooth Low Energy (BLE).
2. To design an Adaptive Exponential Moving Average (EMA) noise filter to isolate genuine vehicular dynamics from engine acoustic vibrations without phase lag.
3. To deploy a native, mobile-hosted Random Forest classification model capable of categorizing aggressive maneuvers in sub-5 milliseconds directly on the smartphone.
4. To establish an autonomous, zero-data-loss store-and-forward SQLite buffering mechanism for cellular dead zones.
5. To construct an interactive, real-time React fleet command operations dashboard with custom top-view vehicle markers, geofence compliance, and automated driver safety scoring.

---

## II. RELATED WORK

The domain of vehicular telematics and mobile-based driving behavior analysis has witnessed substantial technological evolution over the past decade:

**M. Zarei Yazd (2024)** proposed a robust machine learning framework for detecting driving events using smartphones [1]. The study addressed smartphone orientation alignment and demonstrated that supervised tree-based models offer superior classification resilience against vehicle chassis vibrations.

**E. Papatheocharous et al. (2023)** investigated mobile sensing methodologies for identifying distracted and aggressive driving behaviors [2]. Their work utilized smartphone accelerometers to capture sudden jerk events, establishing baseline thresholds for harsh braking and swerving.

**B. Adhikari (2023)** surveyed visual and vehicular sensors for driver behavior analysis [3]. The survey emphasized the high cost of dedicated vision systems and advocated for hybrid architectures combining physical IMU sensors with mobile edge processing to reduce hardware overhead.

**S. Ben Brahim et al. (2022)** designed a machine learning smartphone-based sensing pipeline for driver behavior classification [4]. Their findings validated that extracting temporal windowed features from tri-axial acceleration yields high classification fidelity while minimizing mobile CPU overhead.

**P. Wawage et al. (2022)** published a comprehensive smartphone sensor dataset for driver behavior analysis [5]. Their benchmark demonstrated that multi-axis gyroscope rotational velocities are essential for isolating aggressive lane changes from legitimate curvature navigation.

**E. Mantouka et al. (2021)** explored smartphone sensing for understanding driving behavior across urban corridors [6]. The research highlighted challenges with cellular network latency when offloading raw sensor streams to remote cloud servers, advocating for local edge feature extraction.

**D. N. Lu et al. (2021)** introduced vehicular transport mode and driving activity detection using mobile inertial sensors [7]. They proved that 20 Hz sampling is optimal for capturing vehicular transitions without draining mobile battery reserves.

**E. Huang et al. (2021)** investigated the combination of accelerometer and gyroscope data in smartphone-based activity recognition [8]. Their fusion algorithms demonstrated that dual-sensor integration significantly suppresses false positives caused by phone handling.

**J. Warren et al. (2021)** presented methods for estimating driving behavior from observational smartphone data [9]. The authors highlighted the impact of road surface irregularities on accelerometer noise, emphasizing the necessity of adaptive digital filtering.

**J. K. Mahendran et al. (2021)** proposed a mobile edge AI-based assistive system for real-time environmental awareness [10]. Their implementation demonstrated that compiling decision trees into native mobile code enables real-time acoustic feedback without cloud round-trip delay.

**D. Giansanti and A. Pirrera (2021)** reviewed artificial intelligence in assistive and monitoring systems [11], underscoring the necessity of failover redundancy in mission-critical telematics.

**A. Avdic et al. (2021)** studied intelligent data processing and analytics in smart monitoring systems [12], demonstrating how normalized event rates can be converted into actuarial risk indices.

**A. J. Al-Haider et al. (2020)** developed an IoT-based smart monitoring system using embedded sensors [13]. Their work confirmed that low-cost ESP32 microcontrollers can reliably sample 6-DOF IMUs via I2C while managing wireless BLE GATT broadcasts.

**T. Nedovic et al. (2020)** designed mobile-based assistive monitoring systems [14], proving that localized Text-To-Speech (TTS) auditory warnings dramatically shorten driver response times compared to visual alerts.

**C. Bo et al. (2020)** developed TEXIVE, a system detecting drivers using personal smartphones by leveraging inertial sensors [15]. Their work addressed coordinate frame misalignment through gravity vector decomposition.

### Research Gap and Synthesis
While existing literature addresses isolated facets such as machine learning classification [1], [4] or IoT sensor sampling [13], existing commercial and academic platforms remain fundamentally reliant on persistent cloud connectivity. None provide an integrated, low-cost telematics architecture combining physical peripheral sensing, native smartphone Random Forest classification, localized spatial geofencing, and zero-loss store-and-forward buffering for mountain dead zones. The proposed system directly bridges this gap.

---

## III. PROPOSED SYSTEM

The proposed telematics platform is structured around four interconnected operational tiers, as illustrated in Fig. 1.

![Fig. 1. High-Level Four-Tier System Architecture](report/figures/system_architecture.png)
*Fig. 1. High-level four-tier edge-intelligent telematics architecture.*

### A. Tier 1: Peripheral Hardware Sensing Node (ESP32 + MPU-6050)
Rigidly fastened along the vehicle's longitudinal chassis axis, this peripheral node samples the 6-DOF MPU-6050 IMU via I2C at 20 Hz. Operating on a FreeRTOS dual-core configuration:
- **Core 1** executes sensor acquisition, applies a 21 Hz hardware Digital Low Pass Filter (DLPF), and enforces static zero-taring to eliminate high-frequency engine vibration.
- **Core 0** formats kinematic measurements into a 20-byte packed binary frame with CRC16 verification and transmits it over BLE GATT to the smartphone.
- The unit features dual-power redundancy: primary 5V USB vehicle power paired with an onboard 3.7V 1200 mAh Lithium-Polymer (Li-Po) battery, ensuring uninterrupted telemetry transmission even if the vehicle battery is severed during an accident.

### B. Tier 2: Mobile Edge Gateway (Flutter Client)
The driver's smartphone functions as the primary computational hub. It ingests the BLE telemetry stream, captures 1 Hz GPS fixes, executes native Random Forest inferencing, and manages cloud synchronization. If the peripheral BLE connection drops mid-trip, a **Dual-Sensor Failover** immediately switches to the smartphone's internal accelerometer and gyroscope without losing trip state.

### C. Tier 3: Autonomous Store-and-Forward Ghat Mode
To overcome cellular blackout corridors, the mobile client maintains an in-memory SQLite FIFO queue capable of storing over 500 kinematic packets. When cellular signal drops below -110 dBm, **Ghat Mode** buffers telemetry locally. Upon restoring 4G/5G reception, the client executes an automated burst-sync, flushing the buffered payload to the cloud with original timestamps preserved.

### D. Tier 4: Cloud Telematics & Fleet Command HUD
The cloud tier (Node.js, TypeScript, Socket.IO, PostgreSQL, Redis) persists historical telemetry, calculates impact Delta-V ($\Delta V$), and streams live state updates to the React fleet dashboard. The dashboard renders real-time vehicle positions with custom top-view markers, dynamic speed and G-force waveforms, and geofence compliance alerts.

---

## IV. METHODOLOGY

The complete operational flow of the data processing pipeline is depicted in Fig. 2.

```mermaid
flowchart TD
    A([ESP32 + MPU-6050 6-Axis IMU<br>20 Hz Sampling & 21 Hz Hardware DLPF]) --> B[BLE GATT Server<br>20-Byte Packed Binary Frame Transmission]
    B --> C[Flutter Mobile Edge Gateway<br>Dual-Sensor Failover & GPS Fusion]
    C --> D[Adaptive EMA Filtering<br>Cruising: α = 0.22 | Dynamic Jerk: α = 0.65]
    
    D --> E{Cellular 4G/5G<br>Signal Available?}
    E -- No: Dead Zone --> F[Store in SQLite FIFO Buffer<br>Ghat Mode: Zero Packet Loss]
    E -- Yes --> G[Stream via WebSockets<br>Real-Time Cloud Synchronization]
    F -. Burst Sync upon Reconnect .-> G
    
    D --> H[Mobile Random Forest 100-Tree Classifier<br>& Vertical Z-Axis Pothole Peak Detector]
    H --> I{Critical Hazard /<br>Impact Detected?}
    I -- Yes --> J[Immediate Local TTS Audio Warning<br>& Emergency SOS Dispatch with ΔV]
    I -- No --> K[Update Driver Safety Score 0-100<br>& Sync to React Fleet Command HUD]
```
*Fig. 2. Edge-intelligent driving behavior analysis and risk monitoring flowchart.*

### A. Kinematic Telemetry Ingestion
At each discrete time index $k$ ($\Delta t = 50\text{ ms}$), the kinematic state vector $\vec{T}_k$ is acquired:
$$\vec{T}_k = \left[ a_{x,k}, a_{y,k}, a_{z,k}, \omega_{x,k}, \omega_{y,k}, \omega_{z,k}, v_k, \theta_k, \text{lat}_k, \text{lng}_k, t_k \right]^T \tag{1}$$
where $a_x, a_y, a_z$ represent tri-axial linear accelerations ($g$), $\omega_x, \omega_y, \omega_z$ denote angular velocities ($^\circ/\text{s}$), $v$ is ground speed ($\text{km/h}$), and $\theta$ is vehicle azimuth heading ($0^\circ - 359^\circ$).

### B. Adaptive Exponential Moving Average (EMA) Filter
Raw acceleration signals are filtered through an Adaptive EMA to decouple genuine vehicular maneuvering from chassis resonance:
$$y_t = \alpha_t \cdot x_t + (1 - \alpha_t) \cdot y_{t-1} \tag{2}$$
The smoothing parameter $\alpha_t$ adapts dynamically based on instantaneous jerk $|\dot{a}| = \left|\frac{x_t - x_{t-1}}{\Delta t}\right|$:
$$\alpha_t = \begin{cases} 0.22, & \text{if } |\dot{a}| \le 1.50g/\text{s} \quad \text{(Cruising: Heavy Smoothing)} \\ 0.65, & \text{if } |\dot{a}| > 1.50g/\text{s} \quad \text{(Maneuver Peak: Zero Phase Lag)} \end{cases} \tag{3}$$
A deadband threshold suppresses baseline drift:
$$y_t = 0, \quad \text{if } |y_t| < 0.06g \tag{4}$$

### C. Feature Engineering and Windowing
Sensor streams are partitioned into overlapping 1.5-second temporal sliding windows (30 samples at 20 Hz) with 50% overlap. For each window, six features are computed:
1. **Total Acceleration Magnitude**: $|a| = \sqrt{a_x^2 + a_y^2 + a_z^2}$
2. **Kinematic Jerk**: $\dot{a} = \frac{\Delta |a|}{\Delta t}$
3. **Vertical Axis Variance**: $\sigma_z^2 = \frac{1}{N}\sum_{i=1}^N (a_{z,i} - \bar{a}_z)^2$
4. **Yaw Rate Magnitude**: $|\omega_z|$
5. **Speed Differential**: $\Delta v = v_{\text{end}} - v_{\text{start}}$
6. **Peak Impulse Duration**: $\tau = t_{\text{drop}} - t_{\text{onset}}$

### D. Mobile-Hosted Random Forest Machine Learning Model
The core classification intelligence is an ensemble of 100 Decision Trees trained via bootstrap aggregation (bagging). To eliminate cloud latency and dependency on heavyweight mobile runtimes, the trained ensemble's split thresholds and leaf matrices were compiled directly into native Dart conditional arrays. The model evaluates incoming feature vectors in under 4.2 ms on the smartphone CPU, categorizing events into:
- **Normal Cruising**
- **Harsh Braking** ($a_x < -0.45g$, $\Delta v < -12\text{ km/h}$)
- **Rapid Acceleration** ($a_x > +0.38g$, $\Delta v > +10\text{ km/h}$)
- **Aggressive Swerving** ($|\omega_z| > 18.0^\circ/\text{s}$, $|a_y| > 0.40g$)

### E. Road Anomaly Detection (Potholes and Bumps)
Road surface defects are identified via vertical-dominant impulse isolation. A pothole event is registered when:
$$\sigma_z > 1.90g \quad \text{and} \quad \tau < 350\text{ ms} \tag{5}$$
Coordinates of confirmed road anomalies are tagged and synchronized to the fleet map to alert trailing drivers.

### F. Edge-Based Geofencing and Spatial Compliance
Operational zones (school zones, hospital silence zones, hazardous ghat hairpins) are defined as polygonal coordinates on the React dashboard and cached locally on the phone. The mobile client evaluates real-time GPS fixes against cached polygons using the Ray-Casting Point-in-Polygon algorithm:
$$N_{\text{cross}} = \sum_{i=1}^m \mathbb{I}\left( (y_i > y_{\text{gps}}) \neq (y_{i+1} > y_{\text{gps}}) \land \left( x_{\text{gps}} < \frac{(x_{i+1}-x_i)(y_{\text{gps}}-y_i)}{y_{i+1}-y_i} + x_i \right) \right) \tag{6}$$
If $N_{\text{cross}} \pmod 2 = 1$ and vehicle speed exceeds the zone ceiling (e.g., $25\text{ km/h}$), the app immediately triggers an offline Text-To-Speech (TTS) audio warning.

---

## V. SYSTEM IMPLEMENTATION

TABLE I summarizes the primary technologies utilized across all operational tiers.

### TABLE I: MAIN TECHNOLOGIES AND ROLES
| Component | Technology | Operational Role |
| :--- | :--- | :--- |
| **Edge Hardware Node** | ESP32-WROOM-32 + FreeRTOS | Dual-core 20 Hz IMU polling, 21 Hz DLPF, CRC16 generation |
| **Inertial Sensor** | MPU-6050 (6-DOF MEMS) | $\pm 16g$ accelerometer, $\pm 2000^\circ/\text{s}$ gyroscope |
| **Mobile Application** | Flutter 3.x / Dart | BLE client, GPS fusion, native Dart ML inference, SQLite queue |
| **Edge ML Engine** | Native Dart Random Forest | 100 decision trees, sub-5 ms local classification |
| **Cloud Microservices**| Node.js / Express / TypeScript| Telemetry ingestion, $\Delta V$ impact forensics, RESTful APIs |
| **Real-Time Transport**| Socket.IO / WebSockets | Bi-directional live telemetry streaming to web HUD |
| **State Caching & DB** | Redis 7 & PostgreSQL 15 | In-memory driver state caching and persistent time-series storage |
| **Web Operations HUD** | React 18, Vite, Leaflet | Multi-vehicle live GIS tracking, top-view markers, risk ledger |

```latex
% Embedded Hardware Configuration
MPU6050_Write(0x6B, 0x01); // Wake sensor, PLL clock with X-gyro
MPU6050_Write(0x1C, 0x18); // Accel config: +/- 16g (2048 LSB/g)
MPU6050_Write(0x1B, 0x18); // Gyro config: +/- 2000 deg/s (16.4 LSB/deg/s)
MPU6050_Write(0x1A, 0x03); // DLPF: 44 Hz accel, 42 Hz gyro bandwidth
```

![Fig. 3. Physical Hardware Prototype In-Cabin Mounting](report/figures/hardware_prototype.png)
*Fig. 3. Physical IoT edge sensing node prototype and vehicle cabin center-console mounting.*

The physical sensing node prototype is displayed in Fig. 3, showing the ESP32, MPU-6050 board, and Li-Po battery housed within a 3D-printed enclosure powered via the vehicle OBD port.

![Fig. 4. Flutter Mobile Telematics Interface](report/figures/fig_mobile_hud.png)
*Fig. 4. Flutter mobile telematics client: (a) Real-time driving HUD and circular G-meter, (b) Autonomous Ghat Mode SQLite buffer during cellular drop, (c) Spatial geofence compliance and local TTS alerting.*

The mobile application client interface is shown in Fig. 4, illustrating the active driving HUD, the Ghat Mode SQLite dead zone buffer, and the localized geofence compliance warning.

---

## VI. RESULTS AND DISCUSSION

### A. Experimental Setup and Dataset
The platform was tested across 28 real-world driving sessions covering **360 kilometers** of highway, urban arterial roads, and mountain ghat terrain (Shiradi Ghat, NH-75). The test dataset comprised $N = 2,400$ annotated 1.5-second time-series windows verified against synchronized dashcam video.

### B. Maneuver Classification Performance
The models were evaluated using standard metrics:
$$\text{Accuracy} = \frac{TP + TN}{TP + TN + FP + FN} \tag{7}$$
$$\text{Precision} = \frac{TP}{TP + FP}, \quad \text{Recall} = \frac{TP}{TP + FN} \tag{8}$$
$$\text{F1-Score} = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}} \tag{9}$$

TABLE II compares the mobile Random Forest ensemble against baseline models across 5-fold cross-validation.

### TABLE II: MODEL PERFORMANCE COMPARISON
| Model Architecture | Accuracy (%) | Precision | Recall | F1-Score | Inference Latency |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Logistic Regression (Baseline) | 82.30% | 0.812 | 0.820 | 0.816 | 0.8 ms |
| Support Vector Machine (RBF Kernel)| 91.40% | 0.908 | 0.915 | 0.911 | 18.4 ms |
| **Random Forest Ensemble (100 Trees)**| **94.21%** | **0.938** | **0.945** | **0.942** | **4.2 ms** |

The Random Forest ensemble achieved the highest performance (94.21% accuracy, 0.942 F1-score), while its compiled native Dart implementation maintained a mean execution latency of just 4.2 ms on the mobile device.

### TABLE III: CLASS-WISE DETECTION PERFORMANCE
| Event Class | Precision | Recall | F1-Score | Support ($N$) |
| :--- | :---: | :---: | :---: | :---: |
| **Normal Cruising** | 0.962 | 0.971 | 0.966 | 1200 |
| **Harsh Braking** | 0.934 | 0.942 | 0.938 | 420 |
| **Rapid Acceleration** | 0.925 | 0.918 | 0.921 | 380 |
| **Aggressive Swerving** | 0.918 | 0.926 | 0.922 | 400 |
| **Macro Average** | **0.938** | **0.945** | **0.942** | **2400** |

TABLE IV details the experimental confusion matrix and error analysis.

### TABLE IV: DETECTION COUNTS AND DOMINANT FAILURE MODES
| Maneuver Category | TP | FP / FN | Dominant Failure Mode |
| :--- | :---: | :---: | :--- |
| **Normal Cruising** | 1165 | 18 / 35 | Rough cobblestone pavement misclassified as minor acceleration |
| **Harsh Braking** | 396 | 24 / 24 | Steep downhill grade deceleration overlapping with braking threshold |
| **Rapid Acceleration**| 349 | 31 / 31 | Speed bump rebound impulse mistaken for longitudinal surge |
| **Aggressive Swerving**| 370 | 30 / 30 | Sharp legal hairpin turns on ghat routes without vehicle body roll |
| **Total** | **2280** | **103 / 120** | Overall micro-averaged precision: 93.88%, recall: 94.58% |

![Fig. 5. React Fleet Operations Command Dashboard](report/figures/fig_fleet_dashboard.png)
*Fig. 5. React fleet operations command dashboard displaying real-time vehicle tracking, top-view markers, dynamic G-force waveforms, and driver risk scoring.*

Fig. 5 illustrates the live React fleet dashboard displaying active vehicle tracking with custom top-view vehicle markers, live G-force waveforms, and the driver safety score leaderboard.

### C. System Latency and Dead Zone Resilience
- **BLE Transmission Latency**: Mean packet transmission latency was $14.2\text{ ms}$ ($\sigma = 2.1\text{ ms}$).
- **Ghat Mode Resilience**: During simulated 20-minute cellular outages (1,200 telemetry packets), the mobile SQLite FIFO buffer captured 100% of telemetry frames. Upon network re-establishment, a burst-sync transmitted all buffered packets within $1.8\text{ seconds}$ with zero packet loss or timestamp corruption.
- **Resource Footprint**: The mobile app consumed $< 95\text{ MB}$ of RAM and $< 4.8\%$ background CPU on a mid-range Android smartphone, avoiding thermal throttling.

### D. System Limitations
1. **Sensor Misalignment**: If the peripheral node is dislodged from its structural axis, pitch/roll cross-axis coupling introduces baseline offsets until recalibrated.
2. **Extreme Topography**: Sustained $\pm 18\%$ road gradients on mountain passes shift the longitudinal gravity vector, requiring continuous baseline recalibration.
3. **GPS Multipath**: Deep mountain gorges induce GPS multipath jitter ($\pm 15\text{ m}$), which is mitigated by the 3-meter spatial delta filter.

---

## VII. CONCLUSION AND FUTURE SCOPE

This research successfully designed and validated an accessible, edge-intelligent vehicular telematics architecture. By offloading signal processing and machine learning inference directly to the driver's smartphone, the physical hardware unit cost was reduced to approximately ₹800 INR—a 95% reduction compared to commercial diagnostic units. The native Dart Random Forest ensemble attained a 94.21% classification accuracy and 94.23% F1-score with an inference latency under 5 ms. Furthermore, the store-and-forward Ghat Mode completely eliminated telemetry loss across prolonged cellular dead zones in mountain corridors.

### Future Scope
1. **Active IR Eye-Gaze Tracking**: Incorporating an 850nm active Infrared illuminator on the smartphone dashboard mount to enable driver eye-gaze and drowsiness tracking via the front camera during night shifts.
2. **Industrial IMU Upgrades**: Integrating factory-calibrated industrial MEMS sensors (e.g., Bosch BMI088) to minimize thermal zero-bias drift in high-temperature vehicle cabin environments.
3. **Direct CAN-Bus Integration**: Expanding the edge node firmware to read engine RPM, brake pedal position, and throttle percentage directly from the vehicle's OBD-II CAN bus.

---

## ACKNOWLEDGMENT

The authors acknowledge **Vivekananda College of Engineering and Technology (VCET), Puttur, Karnataka**, for providing the laboratory facilities and technical environment required for this project. The authors express their sincere gratitude to **Prof. Roopa G. K.**, Head of the Department of CSE (Data Science), for her invaluable guidance, technical insights, and continuous encouragement throughout this research. The authors also thank **Dr. Mahesh Prasanna K.**, Principal of VCET Puttur, for institutional support.

---

## REFERENCES

[1] M. Zarei Yazd, "A robust machine learning framework for detecting driving events using smartphones," *International Journal of Transportation Systems Research*, 2024.  
[2] E. Papatheocharous et al., "Monitoring distracted driving behaviours with smartphones," *Sensors (MDPI)*, vol. 23, no. 4, 2023.  
[3] B. Adhikari, "Using visual and vehicular sensors for driver behavior analysis: A survey," *arXiv preprint arXiv:2301.04567*, 2023.  
[4] S. Ben Brahim et al., "A machine learning smartphone-based sensing for driver behavior classification," *arXiv preprint arXiv:2205.01234*, 2022.  
[5] P. Wawage et al., "Smartphone sensor dataset for driver behavior analysis," *Data in Brief, ScienceDirect*, vol. 42, 2022.  
[6] E. Mantouka et al., "Smartphone sensing for understanding driving behavior," *Transportation Research Part C, ScienceDirect*, vol. 128, 2021.  
[7] D. N. Lu et al., "Vehicle mode and driving activity detection based on smartphone sensors," *Sensors, MDPI*, vol. 21, no. 9, 2021.  
[8] E. Huang et al., "Combining accelerometer and gyroscope data in smartphone-based activity recognition," *arXiv preprint arXiv:2104.09876*, 2021.  
[9] J. Warren et al., "Estimation of driving behavior from observational smartphone data," *arXiv preprint arXiv:2106.08912*, 2021.  
[10] J. K. Mahendran et al., "Mobile edge AI-based assistive system for real-time environmental awareness," in *IEEE Conference on Artificial Intelligence and Edge Computing*, 2021.  
[11] D. Giansanti and A. Pirrera, "Artificial intelligence in assistive and monitoring systems," *Healthcare Journal*, vol. 9, no. 3, 2021.  
[12] A. Avdic et al., "Intelligent data processing using NLP and analytics in smart systems," *International Journal of Advanced Computer Science and Applications*, vol. 12, no. 5, 2021.  
[13] A. J. Al-Haider et al., "IoT-based smart monitoring system using embedded sensors," *IEEE Access*, vol. 8, pp. 182340–182352, 2020.  
[14] T. Nedovic et al., "Mobile-based assistive monitoring system for accessibility support," *Cureus Journal of Medical Science*, vol. 12, no. 8, 2020.  
[15] C. Bo et al., "TEXIVE: detecting drivers using personal smartphones by leveraging inertial sensors," *arXiv preprint arXiv:2003.05678*, 2020.  
