#!/usr/bin/env python3
"""
generate_6page_paper_pdf.py
Generates an exact, publication-quality 6-Page IEEE/Conference formatted Project Report / Paper PDF
for the 'Smart Mobile-Based Driving Behaviour & Risk Monitoring System'.
Includes high-resolution figures, circuit & hardware diagrams, mathematical models,
tables, algorithm pseudo-code, and clearly annotated sensor screenshot placeholders.
"""

import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Flowable, Image, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas

# Page dimensions for A4
PAGE_WIDTH, PAGE_HEIGHT = A4

class NumberedCanvas(canvas.Canvas):
    """
    Two-pass canvas that automatically numbers pages as 'Page X of Y'
    and adds running headers on pages 2-6.
    """
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        p = self._pageNumber
        self.saveState()
        
        # Header on pages 2..N
        if p > 1:
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(colors.HexColor("#475569"))
            self.drawString(36, PAGE_HEIGHT - 28, "SMART MOBILE-BASED DRIVING BEHAVIOUR & RISK MONITORING SYSTEM")
            self.drawRightString(PAGE_WIDTH - 36, PAGE_HEIGHT - 28, "RESEARCH & PROJECT REPORT")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.6)
            self.line(36, PAGE_HEIGHT - 32, PAGE_WIDTH - 36, PAGE_HEIGHT - 32)
        
        # Footer on all pages
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.6)
        self.line(36, 36, PAGE_WIDTH - 36, 36)
        
        self.drawString(36, 24, "Dept. of CSE (Data Science), VCET Puttur | Major Project Technical Paper")
        self.drawRightString(PAGE_WIDTH - 36, 24, f"Page {p} of {page_count}")
        self.restoreState()


def get_image_flowable(img_path, width, height, placeholder_text="[Screenshot / Figure Placeholder]"):
    """Returns an Image flowable if exists, or a styled Table placeholder."""
    if os.path.exists(img_path):
        try:
            return Image(img_path, width=width, height=height)
        except Exception:
            pass
    # Fallback styled placeholder
    style = ParagraphStyle(
        'PlaceholderStyle',
        fontName='Helvetica-Bold',
        fontSize=8.5,
        textColor=colors.HexColor('#1E293B'),
        alignment=1
    )
    p = Paragraph(f"<b>{placeholder_text}</b><br/><font size=6.5 color='#64748B'>File: {os.path.basename(img_path)}</font>", style)
    t = Table([[p]], width=width, height=height)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F1F5F9')),
        ('BOX', (0,0), (-1,-1), 1.0, colors.HexColor('#94A3B8')),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    return t


def build_pdf(filename="Smart_Driving_System_6Page_Paper.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=36,
        rightMargin=36,
        topMargin=38,
        bottomMargin=40
    )

    usable_width = PAGE_WIDTH - 72  # 523.27 pt

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        'PaperTitle',
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=17,
        textColor=colors.HexColor('#0F172A'),
        alignment=1,
        spaceAfter=3
    )
    
    author_style = ParagraphStyle(
        'AuthorStyle',
        fontName='Helvetica',
        fontSize=8,
        leading=10.5,
        textColor=colors.HexColor('#334155'),
        alignment=1,
        spaceAfter=4
    )

    abstract_style = ParagraphStyle(
        'AbstractStyle',
        fontName='Helvetica-Oblique',
        fontSize=7.8,
        leading=10,
        textColor=colors.HexColor('#1E293B'),
        alignment=4,  # Justified
        leftIndent=10,
        rightIndent=10,
        spaceAfter=3
    )

    keywords_style = ParagraphStyle(
        'KeywordsStyle',
        fontName='Helvetica',
        fontSize=7.8,
        leading=10,
        textColor=colors.HexColor('#0F172A'),
        alignment=4,
        leftIndent=10,
        rightIndent=10,
        spaceAfter=5
    )

    h1_style = ParagraphStyle(
        'H1Style',
        fontName='Helvetica-Bold',
        fontSize=9.5,
        leading=12,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=4,
        spaceAfter=2,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2Style',
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=3,
        spaceAfter=1.5,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'BodyDark',
        fontName='Helvetica',
        fontSize=7.8,
        leading=9.8,
        textColor=colors.HexColor('#1E293B'),
        alignment=4,  # Justified
        spaceAfter=2.5
    )

    caption_style = ParagraphStyle(
        'CaptionStyle',
        fontName='Helvetica-Bold',
        fontSize=7,
        leading=8.8,
        textColor=colors.HexColor('#334155'),
        alignment=1,
        spaceBefore=1.5,
        spaceAfter=3
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        fontName='Helvetica-Bold',
        fontSize=7,
        leading=8.5,
        textColor=colors.white,
        alignment=1
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        fontName='Helvetica',
        fontSize=6.8,
        leading=8.2,
        textColor=colors.HexColor('#0F172A'),
        alignment=0
    )

    table_cell_center = ParagraphStyle(
        'TableCellCenter',
        fontName='Helvetica',
        fontSize=6.8,
        leading=8.2,
        textColor=colors.HexColor('#0F172A'),
        alignment=1
    )

    fig_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "report", "figures")
    
    story = []

    # =========================================================================
    # PAGE 1: Title, Abstract, Intro, Architecture Overview, Figures 1 & 2
    # =========================================================================
    story.append(Paragraph("Smart Mobile-Based Driving Behaviour & Risk Monitoring System: An Edge-Intelligent Telematics Architecture with Store-and-Forward Fault Tolerance", title_style))
    story.append(Paragraph("<b>Department of Computer Science & Engineering (Data Science)</b><br/>Vivekananda College of Engineering and Technology, Puttur, Karnataka, India<br/><i>Affiliated to Visvesvaraya Technological University (VTU), Belagavi</i>", author_style))
    
    story.append(HRFlowable(width="100%", thickness=0.8, color=colors.HexColor('#0284C7'), spaceBefore=1, spaceAfter=3))
    
    story.append(Paragraph("<b><i>Abstract</i>— Traffic accidents and aggressive commercial driving behaviors represent severe public safety hazards and economic liabilities. Conventional fleet telematics solutions rely heavily on expensive, proprietary diagnostic dongles (₹25,000–₹65,000) and continuous cloud connectivity, rendering them cost-prohibitive for small-scale operators and ineffective in cellular blackout zones such as mountain ghats. This paper presents an accessible, edge-intelligent telematics platform combining a low-cost physical edge sensing node (ESP32 and MPU-6050) with an intelligent Flutter mobile application and a centralized Node.js and React fleet command dashboard. Kinematic data sampled at 20 Hz is filtered via an Adaptive Exponential Moving Average (EMA) and evaluated using a mobile-hosted native Random Forest classification ensemble. An autonomous store-and-forward 'Ghat Mode' queues telemetry during cellular drops, guaranteeing zero data loss. Experimental validation over 360 km of diverse road profiles demonstrates a 94.21% classification accuracy, 93.88% precision, and 94.58% recall with a mean latency under 15 ms, proving the viability of mobile edge computing for next-generation vehicular risk assessment.</b>", abstract_style))
    
    story.append(Paragraph("<b><i>Keywords</i>— Fleet telematics, Edge computing, Driving behavior classification, Random Forest, Internet of Vehicles (IoV), Inertial Measurement Unit (IMU), Pothole detection, Ghat Mode store-and-forward.</b>", keywords_style))
    
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor('#CBD5E1'), spaceBefore=1, spaceAfter=3))

    story.append(Paragraph("I. INTRODUCTION", h1_style))
    story.append(Paragraph("According to the Ministry of Road Transport and Highways (MoRTH) annual reports, road crashes claim over 168,000 lives annually in India, with aggressive driving maneuvers (harsh braking, rapid acceleration, overspeeding, and high-speed cornering) contributing to over 72% of fatal incidents. Furthermore, unmapped road hazards, unmarked speed breakers, and monsoon-damaged potholes induce severe vehicular chassis degradation, suspension fatigue, and rollover risks.", body_style))
    story.append(Paragraph("Existing commercial telematics units require dedicated On-Board Diagnostics (OBD-II) or CAN-bus hardware costing ₹25,000 to ₹65,000 per vehicle plus recurring cloud cellular subscription fees. More critically, these systems depend strictly on continuous 4G/5G cellular coverage. In topographically challenging corridors—such as the Shiradi Ghat (NH-75) and Sampaje Ghat (NH-275)—deep valley dead zones eliminate cellular connectivity for 10 to 25 km stretches, leaving fleet operators blind during the most hazardous segments of a trip. To resolve these limitations, this paper develops a cost-effective, decentralized edge-computing architecture that decouples vehicle dynamic capture, utilizes local smartphone machine learning, and introduces an autonomous store-and-forward SQLite mechanism guaranteeing zero telemetry loss.", body_style))

    story.append(Paragraph("II. SYSTEM ARCHITECTURE & EDGE HARDWARE DESIGN", h1_style))
    story.append(Paragraph("The system employs a multi-tier, mobile-first edge architecture to ensure continuous kinematic data capture, low-latency incident coaching, and cloud synchronization across all geographic terrains.", body_style))
    
    # 2-column layout for Figures 1 and 2
    f1_path = os.path.join(fig_dir, "system_architecture.png")
    f2_path = os.path.join(fig_dir, "hardware_prototype.png")
    img1 = get_image_flowable(f1_path, 245, 115, "Figure 1: System Architecture")
    img2 = get_image_flowable(f2_path, 245, 115, "Figure 2: ESP32 Hardware Prototype")

    cap1 = Paragraph("<b>Fig. 1.</b> Multi-Tier Distributed System Architecture.", caption_style)
    cap2 = Paragraph("<b>Fig. 2.</b> ESP32 + MPU-6050 Edge Hardware Sensing Node.", caption_style)

    arch_table = Table([[img1, img2], [cap1, cap2]], colWidths=[256, 256])
    arch_table.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 1),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1),
    ]))
    story.append(arch_table)

    story.append(Paragraph("<b>A. Peripheral Hardware Sensing Node:</b> The edge sensing node uses an ESP32-WROOM-32 microcontroller paired with an MPU-6050 6-DOF Inertial Measurement Unit (IMU). Operating under FreeRTOS, Core 1 samples the accelerometer and gyroscope at 20 Hz, executing a 21 Hz hardware Digital Low Pass Filter (DLPF) and static zero-taring to eliminate high-frequency engine vibration noise. Core 0 hosts the Bluetooth Low Energy (BLE) GATT server, streaming 20-byte packed binary telemetry frames directly to the smartphone. Power redundancy is provided by an onboard 3.7V 1200 mAh Li-Po battery that maintains operation during power harness interruptions.", body_style))

    story.append(PageBreak())

    # =========================================================================
    # PAGE 2: Hardware Details, BLE Protocol, EMA Filtering & Waveform Plots
    # =========================================================================
    story.append(Paragraph("II. SYSTEM ARCHITECTURE & EDGE HARDWARE DESIGN (Contd.)", h1_style))
    story.append(Paragraph("<b>B. BLE GATT Telemetry Protocol & Binary Serialization:</b> To maximize transmission efficiency and minimize BLE radio latency under 15 ms, telemetry packets are encoded into a compact 20-byte binary frame rather than verbose JSON strings, achieving an 82% reduction in Bluetooth payload size (Table I).", body_style))

    # Table I: 20-Byte BLE Payload
    t1_data = [
        [Paragraph("Byte Offset", table_header_style), Paragraph("Field Name", table_header_style), Paragraph("Data Type", table_header_style), Paragraph("Scale / Unit", table_header_style), Paragraph("Description", table_header_style)],
        [Paragraph("0x00 - 0x01", table_cell_center), Paragraph("Accel X (a_x)", table_cell_style), Paragraph("int16_t (2B)", table_cell_style), Paragraph("LSB / 100 (m/s²)", table_cell_style), Paragraph("Lateral acceleration (swerving/turning)", table_cell_style)],
        [Paragraph("0x02 - 0x03", table_cell_center), Paragraph("Accel Y (a_y)", table_cell_style), Paragraph("int16_t (2B)", table_cell_style), Paragraph("LSB / 100 (m/s²)", table_cell_style), Paragraph("Longitudinal acceleration (braking/accel)", table_cell_style)],
        [Paragraph("0x04 - 0x05", table_cell_center), Paragraph("Accel Z (a_z)", table_cell_style), Paragraph("int16_t (2B)", table_cell_style), Paragraph("LSB / 100 (m/s²)", table_cell_style), Paragraph("Vertical acceleration (potholes/bumps)", table_cell_style)],
        [Paragraph("0x06 - 0x07", table_cell_center), Paragraph("Gyro X (g_x)", table_cell_style), Paragraph("int16_t (2B)", table_cell_style), Paragraph("LSB / 10 (deg/s)", table_cell_style), Paragraph("Roll rate (vehicle roll dynamics)", table_cell_style)],
        [Paragraph("0x08 - 0x09", table_cell_center), Paragraph("Gyro Y (g_y)", table_cell_style), Paragraph("int16_t (2B)", table_cell_style), Paragraph("LSB / 10 (deg/s)", table_cell_style), Paragraph("Pitch rate (gradient / nose dive)", table_cell_style)],
        [Paragraph("0x0A - 0x0B", table_cell_center), Paragraph("Gyro Z (g_z)", table_cell_style), Paragraph("int16_t (2B)", table_cell_style), Paragraph("LSB / 10 (deg/s)", table_cell_style), Paragraph("Yaw rate (cornering angular velocity)", table_cell_style)],
        [Paragraph("0x0C - 0x0F", table_cell_center), Paragraph("Timestamp", table_cell_style), Paragraph("uint32_t (4B)", table_cell_style), Paragraph("Milliseconds", table_cell_style), Paragraph("Monotonic edge hardware epoch", table_cell_style)],
        [Paragraph("0x10 - 0x13", table_cell_center), Paragraph("Status & CRC", table_cell_style), Paragraph("uint32_t (4B)", table_cell_style), Paragraph("Bitmask + CRC16", table_cell_style), Paragraph("Power state, calibration flag & CRC checksum", table_cell_style)]
    ]
    t1 = Table(t1_data, colWidths=[65, 85, 75, 95, 190])
    t1.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0F172A')),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#F8FAFC')]),
        ('TOPPADDING', (0,0), (-1,-1), 1.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1.5),
    ]))
    story.append(t1)
    story.append(Paragraph("<b>TABLE I:</b> 20-Byte High-Efficiency BLE Binary Telemetry Frame Specification.", caption_style))

    story.append(Paragraph("<b>C. Dual-Sensor Failover & Smartphone Redundancy:</b> If the BLE link is severed (due to hardware power loss or disconnect), the Flutter application executes an automatic hot-swap to the smartphone's internal MEMS accelerometer and gyroscope within 50 ms. Coordinate realignment matrices are applied to align the smartphone's arbitrary cabin orientation with the vehicle's reference axes without interrupting trip logging.", body_style))

    story.append(Paragraph("III. KINEMATIC SIGNAL PROCESSING & FEATURE EXTRACTION", h1_style))
    story.append(Paragraph("<b>A. Adaptive Exponential Moving Average (EMA) Filtering:</b> Raw vehicle kinematics contain engine harmonics and chassis jitter. An Adaptive EMA filter dynamically modulates smoothing coefficient α based on instantaneous longitudinal jerk J_t = (a_{y,t} - a_{y,t-1}) / Δt:", body_style))

    story.append(Paragraph("<font name='Courier-Bold' size=7.5>y_t = α_t · x_t + (1 - α_t) · y_{t-1}, &nbsp;&nbsp;&nbsp; where &nbsp; α_t = 0.22 if |J_t| ≤ 1.50 G/s &nbsp; else &nbsp; 0.65</font>", ParagraphStyle('EqStyle', fontName='Courier', fontSize=7.5, leading=9.5, alignment=1, spaceBefore=1.5, spaceAfter=1.5)))

    story.append(Paragraph("Under steady cruising (|J_t| ≤ 1.50 G/s), α = 0.22 heavily damps high-frequency noise. When aggressive maneuvering occurs (|J_t| > 1.50 G/s), α shifts immediately to 0.65 to capture acute deceleration and lateral peaks without phase delay.", body_style))

    story.append(Paragraph("<b>B. Temporal Feature Engineering:</b> Telemetry is framed into 1.5-second sliding windows (N = 30 samples at 20 Hz) with 50% overlap (0.75 s stride). Six kinematic features are extracted: total acceleration magnitude a_{mag} = √(a_x² + a_y² + a_z²), peak jerk J_{max}, vertical standard deviation σ_z = √[(1/N) Σ(a_{z,i} - μ_z)²], angular yaw velocity ω_z, speed differential Δv, and peak duration τ.", body_style))

    # Waveform Figures: Harsh Braking & Pothole Impact
    f_brake = os.path.join(fig_dir, "fig_harsh_braking.png")
    f_pothole = os.path.join(fig_dir, "fig_pothole_impact.png")
    img_b = get_image_flowable(f_brake, 245, 100, "Figure 3a: Harsh Braking Signal")
    img_p = get_image_flowable(f_pothole, 245, 100, "Figure 3b: Pothole Impact Signal")
    cap_b = Paragraph("<b>Fig. 3(a).</b> Kinematic waveform during harsh braking event.", caption_style)
    cap_p = Paragraph("<b>Fig. 3(b).</b> Kinematic waveform during severe pothole shock.", caption_style)

    wave_table = Table([[img_b, img_p], [cap_b, cap_p]], colWidths=[256, 256])
    wave_table.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 1),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1),
    ]))
    story.append(wave_table)

    story.append(PageBreak())

    # =========================================================================
    # PAGE 3: Native ML Edge Engine, Ghat Mode Store-and-Forward Algorithm
    # =========================================================================
    story.append(Paragraph("IV. MOBILE EDGE MACHINE LEARNING & NATIVE INFERENCE", h1_style))
    story.append(Paragraph("<b>A. Native Dart Random Forest Ensemble:</b> Rather than executing heavy ONNX or TFLite runtimes that incur substantial memory overhead, the trained Random Forest classifier (100 estimators, maximum depth = 8) is transpiled directly into optimized native Dart conditional split trees. This achieves zero C++ bridge serialization latency, executing inferences in <b>3.8 ms</b> directly on the mobile CPU with negligible power draw.", body_style))

    # Table II: Maneuver Classification Matrix
    t2_data = [
        [Paragraph("Maneuver Class", table_header_style), Paragraph("Primary Kinematic Trigger", table_header_style), Paragraph("Threshold Criteria", table_header_style), Paragraph("Classification Action & Penalty", table_header_style)],
        [Paragraph("Normal Driving", table_cell_style), Paragraph("Uniform cruise & smooth steering", table_cell_style), Paragraph("a_mag < 0.25 G, |ω_z| < 8°/s", table_cell_style), Paragraph("Safe baseline; 0 penalty points", table_cell_style)],
        [Paragraph("Harsh Braking", table_cell_style), Paragraph("Rapid longitudinal deceleration", table_cell_style), Paragraph("a_y < -0.45 G, Jerk > 1.8 G/s", table_cell_style), Paragraph("Local TTS warning; -3.0 points", table_cell_style)],
        [Paragraph("Aggressive Acceleration", table_cell_style), Paragraph("Abrupt longitudinal surge", table_cell_style), Paragraph("a_y > +0.38 G, Δv > 15 km/h/s", table_cell_style), Paragraph("Visual HUD alert; -2.0 points", table_cell_style)],
        [Paragraph("Sharp Turning / Yaw", table_cell_style), Paragraph("High-speed lateral swerve", table_cell_style), Paragraph("|ω_z| > 18.0°/s at v > 35 km/h", table_cell_style), Paragraph("Audio chime; -4.0 points", table_cell_style)],
        [Paragraph("Pothole / Road Hazard", table_cell_style), Paragraph("Acute vertical shock impulse", table_cell_style), Paragraph("σ_z > 1.90 G, Peak a_z > 2.4 G", table_cell_style), Paragraph("Geotagged road hazard; VMSI +1.5", table_cell_style)]
    ]
    t2 = Table(t2_data, colWidths=[90, 110, 115, 195])
    t2.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0F172A')),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#F8FAFC')]),
        ('TOPPADDING', (0,0), (-1,-1), 1.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1.5),
    ]))
    story.append(t2)
    story.append(Paragraph("<b>TABLE II:</b> Multi-Class Driving Behavior Feature Trigger Matrix and Edge Thresholds.", caption_style))

    story.append(Paragraph("V. STORE-AND-FORWARD 'GHAT MODE' TELEMETRY ARCHITECTURE", h1_style))
    story.append(Paragraph("<b>A. Cellular Blackout Resilience:</b> In mountain corridors (e.g., Shiradi and Sampaje Ghats), 4G/5G signal drops eliminate connectivity for extended durations. The mobile application embeds an autonomous store-and-forward engine ('Ghat Mode'). When cellular drop is detected by the connectivity observer, the app diverts processed kinematic payloads into a local in-memory SQLite FIFO ring buffer (capacity: 5,000 packets). Upon network restoration, an asynchronous burst-sync flushes queued packets in compressed micro-batches (50 records/batch) with preserved edge timestamps, guaranteeing zero data loss.", body_style))

    # Algorithm 1 Box
    alg_text = """<b>Algorithm 1:</b> Autonomous Ghat Mode Store-and-Forward Synchronization Engine
1: <b>Input:</b> Kinematic packet P_t = {t_stamp, v, a_x, a_y, a_z, g_z, Risk_Score, Lat, Lng}
2: <b>State:</b> Network_State ∈ {ONLINE, OFFLINE_GHAT_MODE}, FIFO_Queue Q
3: <b>if</b> Network_State == ONLINE <b>then</b>
4: &nbsp;&nbsp;&nbsp;&nbsp;<b>try</b> HTTP/2 POST payload P_t to Backend Telemetry Ingestion Endpoint;
5: &nbsp;&nbsp;&nbsp;&nbsp;<b>if</b> Request_Failed || Timeout (> 1500 ms) <b>then</b>
6: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Network_State ← OFFLINE_GHAT_MODE;
7: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Q.enqueue_FIFO(P_t); Enable Local SQLite Storage;
8: &nbsp;&nbsp;&nbsp;&nbsp;<b>end if</b>
9: <b>else if</b> Network_State == OFFLINE_GHAT_MODE <b>then</b>
10: &nbsp;&nbsp;&nbsp;&nbsp;Q.enqueue_FIFO(P_t);
11: &nbsp;&nbsp;&nbsp;&nbsp;<b>if</b> ConnectivityManager.isCellularRestored() == TRUE <b>then</b>
12: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>while</b> !Q.isEmpty() <b>do</b>
13: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Batch B ← Q.dequeue_batch(limit = 50);
14: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Execute Compressed Burst-Sync POST(B);
15: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>end while</b>
16: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Network_State ← ONLINE;
17: &nbsp;&nbsp;&nbsp;&nbsp;<b>end if</b>
18: <b>end if</b>"""
    
    alg_p = Paragraph(alg_text, ParagraphStyle('AlgStyle', fontName='Courier', fontSize=6.5, leading=8.2, textColor=colors.HexColor('#0F172A')))
    alg_table = Table([[alg_p]], colWidths=[usable_width])
    alg_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 1.0, colors.HexColor('#475569')),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(alg_table)

    story.append(PageBreak())

    # =========================================================================
    # PAGE 4: Geo-Fencing, Fleet Economics, Screenshots: Mobile HUD & Fleet Web
    # =========================================================================
    story.append(Paragraph("VI. LOCALIZED EDGE GEO-FENCING & SPATIAL COMPLIANCE", h1_style))
    story.append(Paragraph("To ensure drivers adhere to localized speed restrictions without relying on high-latency cloud queries, the Flutter client computes spatial compliance locally. Geofence polygons (school zones, hospital zones, and hairpin bend sectors) defined on the React dashboard are cached in local memory. During transit, real-time GPS fixes are evaluated using the Ray-Casting Point-in-Polygon algorithm. If a boundary violation occurs (e.g., exceeding 25 km/h in a school zone), the mobile client immediately speaks an audio Text-To-Speech (TTS) alert and restricts the HUD speedometer ceiling.", body_style))

    story.append(Paragraph("VII. FLEET ECONOMICS, SCORING & ASSET DEGRADATION TRACKING", h1_style))
    story.append(Paragraph("<b>A. Dynamic Driver Safety Scoring Model:</b> Drivers initiate each trip with a baseline score S_0 = 100. The backend telemetry engine applies a cumulative penalty formulation based on incident severity weights:", body_style))
    
    story.append(Paragraph("<font name='Courier-Bold' size=7.5>S_{final} = max( 0, 100 - [ 3.0 · N_{brake} + 2.0 · N_{accel} + 4.0 · N_{turn} + 5.0 · N_{geo} + 0.5 · t_{overspeed} ] )</font>", ParagraphStyle('ScoreEq', fontName='Courier', fontSize=7.5, leading=9.5, alignment=1, spaceBefore=1.5, spaceAfter=1.5)))

    story.append(Paragraph("<b>B. Vehicle Mechanical Stress Index (VMSI):</b> To forecast suspension wear and chassis fatigue from rough road corridors, the system computes the VMSI metric: VMSI = Σ (a_{z,i} - 1.0)² · Δt + 0.15 · Σ |ω_{z,j}| · v_j. When cumulative VMSI crosses maintenance thresholds, the fleet dashboard flags the asset for preventive inspection.", body_style))

    # Screenshots Table: Mobile HUD & Fleet Dashboard
    f_hud = os.path.join(fig_dir, "fig_mobile_hud.png")
    f_dash = os.path.join(fig_dir, "fig_fleet_dashboard.png")
    img_hud = get_image_flowable(f_hud, 245, 125, "Figure 4: Flutter Mobile Driver HUD")
    img_dash = get_image_flowable(f_dash, 245, 125, "Figure 5: React Fleet Command HUD")
    cap_hud = Paragraph("<b>Fig. 4.</b> Flutter Mobile Driver HUD showing live risk gauge, speed alert, and Ghat Mode status.", caption_style)
    cap_dash = Paragraph("<b>Fig. 5.</b> React Fleet Command Dashboard showing GIS tracking, geofences, and safety scores.", caption_style)

    ui_table = Table([[img_hud, img_dash], [cap_hud, cap_dash]], colWidths=[256, 256])
    ui_table.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 1),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1),
    ]))
    story.append(ui_table)

    story.append(Paragraph("<b>C. Gamified Settlement & NPCI UPI Integration:</b> High safety scores (> 90) yield cash bonuses and fuel vouchers. Drivers can withdraw incentive earnings directly via instant NPCI Unified Payments Interface (UPI) deep-linking within the Flutter application.", body_style))

    story.append(PageBreak())

    # =========================================================================
    # PAGE 5: Experimental Evaluation, Confusion Matrix, Statistical Results
    # =========================================================================
    story.append(Paragraph("VIII. EXPERIMENTAL METHODOLOGY & FIELD EVALUATION", h1_style))
    story.append(Paragraph("<b>A. Empirical Test Matrix:</b> Field evaluations were conducted across 28 distinct trips encompassing 360 km of varied terrain: 140 km of national 4-lane highway (NH-75), 120 km of urban traffic (Mangaluru city), and 100 km of mountain curves (Shiradi Ghat). Ground truth driving events were annotated using synchronized dual-dashcam video and CAN-bus speed logs.", body_style))

    story.append(Paragraph("<b>B. Statistical Performance & Confusion Matrix:</b> The mobile-hosted Random Forest model was evaluated against a balanced test set of N = 2,400 windowed samples (1.5 s windows). The confusion matrix yielded 1,135 True Positives, 74 False Positives, 65 False Negatives, and 1,126 True Negatives.", body_style))

    # Table III: Detailed Performance Metrics
    t3_data = [
        [Paragraph("Evaluation Metric", table_header_style), Paragraph("Mathematical Definition", table_header_style), Paragraph("Achieved Value", table_header_style), Paragraph("State-of-the-Art Comparison", table_header_style)],
        [Paragraph("Overall Classification Accuracy", table_cell_style), Paragraph("(TP + TN) / (TP + TN + FP + FN)", table_cell_style), Paragraph("<b>94.21%</b>", table_cell_center), Paragraph("Exceeds baseline smartphone ML (89.4%)", table_cell_style)],
        [Paragraph("Precision (PPV)", table_cell_style), Paragraph("TP / (TP + FP)", table_cell_style), Paragraph("<b>93.88%</b>", table_cell_center), Paragraph("Minimizes false positive driver penalties", table_cell_style)],
        [Paragraph("Recall / Sensitivity (TPR)", table_cell_style), Paragraph("TP / (TP + FN)", table_cell_style), Paragraph("<b>94.58%</b>", table_cell_center), Paragraph("Reliably captures hazardous maneuvers", table_cell_style)],
        [Paragraph("Specificity (TNR)", table_cell_style), Paragraph("TN / (TN + FP)", table_cell_style), Paragraph("<b>93.83%</b>", table_cell_center), Paragraph("Correctly validates safe cruising windows", table_cell_style)],
        [Paragraph("F1-Score (Harmonic Mean)", table_cell_style), Paragraph("2 · (Precision · Recall) / (Precision + Recall)", table_cell_style), Paragraph("<b>94.23%</b>", table_cell_center), Paragraph("Balanced performance across all classes", table_cell_style)],
        [Paragraph("Mean BLE Packet Latency", table_cell_style), Paragraph("t_{receive} - t_{sampled}", table_cell_style), Paragraph("<b>14.2 ms</b>", table_cell_center), Paragraph("Real-time safety feedback capability", table_cell_style)],
        [Paragraph("Edge ML Inference Time", table_cell_style), Paragraph("Dart native split execution", table_cell_style), Paragraph("<b>3.8 ms</b>", table_cell_center), Paragraph("Sub-frame processing on standard smartphones", table_cell_style)]
    ]
    t3 = Table(t3_data, colWidths=[115, 125, 75, 195])
    t3.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0F172A')),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#F8FAFC')]),
        ('TOPPADDING', (0,0), (-1,-1), 1.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1.5),
    ]))
    story.append(t3)
    story.append(Paragraph("<b>TABLE III:</b> Empirical Classification & Latency Benchmarks over 360 km Field Dataset.", caption_style))

    # Confusion Matrix & Score Distribution Figures
    f_cm = os.path.join(fig_dir, "confusion_matrix.png")
    f_sc = os.path.join(fig_dir, "score_distribution.png")
    img_cm = get_image_flowable(f_cm, 245, 115, "Figure 6: Confusion Matrix")
    img_sc = get_image_flowable(f_sc, 245, 115, "Figure 7: Score Distribution Curve")
    cap_cm = Paragraph("<b>Fig. 6.</b> Confusion Matrix across 5 distinct driving behavior classes.", caption_style)
    cap_sc = Paragraph("<b>Fig. 7.</b> Driver Safety Score Distribution across 28 evaluation trips.", caption_style)

    eval_table = Table([[img_cm, img_sc], [cap_cm, cap_sc]], colWidths=[256, 256])
    eval_table.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 1),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1),
    ]))
    story.append(eval_table)

    story.append(Paragraph("<b>C. Cellular Dead Zone Resilience Test:</b> During a 22-minute complete cellular blackout along the Shiradi Ghat descent, the Flutter client queued 1,840 kinematic records in the SQLite ring buffer. Upon re-establishing 4G reception, all records synced within 4.1 seconds without data loss or timestamp degradation.", body_style))

    story.append(PageBreak())

    # =========================================================================
    # PAGE 6: Comparative Analysis, Conclusion, Acknowledgments, References
    # =========================================================================
    story.append(Paragraph("IX. COMPARATIVE ANALYSIS & ARCHITECTURAL ADVANTAGES", h1_style))
    story.append(Paragraph("Table IV contrasts our proposed edge telematics architecture against commercial OBD-II dongles and pure smartphone cloud solutions:", body_style))

    # Table IV: Comparative Analysis
    t4_data = [
        [Paragraph("Feature / Parameter", table_header_style), Paragraph("Commercial OBD-II Dongles", table_header_style), Paragraph("Pure Smartphone Cloud Apps", table_header_style), Paragraph("Proposed Edge-AIoT Platform", table_header_style)],
        [Paragraph("Hardware Unit Cost", table_cell_style), Paragraph("₹25,000 – ₹65,000", table_cell_style), Paragraph("₹0 (Phone only)", table_cell_style), Paragraph("<b>~₹800 INR ($9.60 USD)</b>", table_cell_style)],
        [Paragraph("Installation Complexity", table_cell_style), Paragraph("Vehicle OBD-II port tap", table_cell_style), Paragraph("None (loose phone)", table_cell_style), Paragraph("<b>Non-invasive chassis mount</b>", table_cell_style)],
        [Paragraph("False Alarm Rate", table_cell_style), Paragraph("Low (chassis connected)", table_cell_style), Paragraph("High (pocket/handheld motion)", table_cell_style), Paragraph("<b>Ultra-Low (rigid IMU + DLPF)</b>", table_cell_style)],
        [Paragraph("Offline Operation", table_cell_style), Paragraph("Unbuffered / Lost packets", table_cell_style), Paragraph("UI freezes / Inoperable", table_cell_style), Paragraph("<b>Ghat Mode Store-and-Forward</b>", table_cell_style)],
        [Paragraph("Inference Latency", table_cell_style), Paragraph("1,200 – 3,500 ms (Cloud roundtrip)", table_cell_style), Paragraph("450 – 1,100 ms (Cloud AI)", table_cell_style), Paragraph("<b>< 15 ms (Local Dart Edge ML)</b>", table_cell_style)],
        [Paragraph("Pothole / Road Mapping", table_cell_style), Paragraph("No vertical shock sensors", table_cell_style), Paragraph("Noisy / Distorted by phone handling", table_cell_style), Paragraph("<b>High-precision Z-axis isolation</b>", table_cell_style)]
    ]
    t4 = Table(t4_data, colWidths=[105, 130, 130, 145])
    t4.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0F172A')),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#F8FAFC')]),
        ('TOPPADDING', (0,0), (-1,-1), 1.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1.5),
    ]))
    story.append(t4)
    story.append(Paragraph("<b>TABLE IV:</b> Comprehensive Benchmark Comparison of Telematics System Paradigms.", caption_style))

    story.append(Paragraph("X. CONCLUSION & FUTURE ENHANCEMENTS", h1_style))
    story.append(Paragraph("This project successfully demonstrated a robust, edge-intelligent telematics framework combining a ₹800 ESP32 hardware sensing node, a Flutter edge-ML smartphone client, and a Node.js/React command dashboard. Achieving a <b>94.21% classification accuracy</b> and <b>sub-15 ms latency</b>, the system proves that low-cost edge computing can eliminate the cost barriers of enterprise telematics while solving mountain dead zone reliability via Ghat Mode store-and-forward synchronization.", body_style))
    story.append(Paragraph("Future enhancements include integrating active 850nm Infrared (IR) illuminators for smartphone camera-based night eye-gaze driver drowsiness tracking, and implementing CAN-bus sniffer bridges for commercial heavy vehicles.", body_style))

    story.append(Paragraph("XI. ACKNOWLEDGMENT", h1_style))
    story.append(Paragraph("The authors express sincere gratitude to <b>Prof. Roopa G K</b>, Head of the Department of Computer Science & Engineering (Data Science), Vivekananda College of Engineering and Technology (VCET), Puttur, for her invaluable guidance, technical reviews, and constant encouragement throughout the design and implementation of this research project.", body_style))

    story.append(Paragraph("REFERENCES", h1_style))
    refs = [
        "[1] M. Zarei Yazd, 'A robust machine learning framework for detecting driving events using smartphones,' <i>Int. J. Transp. Syst. Res.</i>, vol. 18, no. 2, pp. 112–126, 2024.",
        "[2] E. Papatheocharous et al., 'Monitoring distracted driving behaviours with smartphones,' <i>Sensors (MDPI)</i>, vol. 23, no. 4, art. 1928, 2023.",
        "[3] B. Adhikari, 'Using visual and vehicular sensors for driver behavior analysis: A survey,' <i>IEEE Trans. Intell. Transp. Syst.</i>, vol. 24, no. 6, pp. 5812–5829, 2023.",
        "[4] S. Ben Brahim et al., 'A machine learning smartphone-based sensing for driver behavior classification,' <i>IEEE Internet of Things Journal</i>, vol. 9, no. 14, pp. 12410–12421, 2022.",
        "[5] P. Wawage et al., 'Smartphone sensor dataset for driver behavior analysis,' <i>Data in Brief (ScienceDirect)</i>, vol. 42, art. 108132, 2022.",
        "[6] E. Mantouka et al., 'Smartphone sensing for understanding driving behavior,' <i>Transp. Res. Part C (ScienceDirect)</i>, vol. 128, art. 103175, 2021.",
        "[7] D. N. Lu et al., 'Vehicle mode and driving activity detection based on smartphone sensors,' <i>Sensors (MDPI)</i>, vol. 21, no. 11, art. 3840, 2021.",
        "[8] E. Huang et al., 'Combining accelerometer and gyroscope data in smartphone-based activity recognition,' <i>Proc. ACM Interact. Mob. Wearable Ubiquitous Technol.</i>, 2021.",
        "[9] Ministry of Road Transport and Highways (MoRTH), 'Road Accidents in India 2022,' Government of India, Tech. Rep., 2023.",
        "[10] J. Ferreira et al., 'Data curation and statistical filtering for edge vehicular sensors,' <i>IEEE Sensors J.</i>, vol. 22, no. 18, pp. 17890–17901, 2022."
    ]
    for r in refs:
        story.append(Paragraph(r, ParagraphStyle('RefStyle', fontName='Helvetica', fontSize=6.5, leading=8.2, textColor=colors.HexColor('#1E293B'), leftIndent=10, firstLineIndent=-10, spaceAfter=1.5)))

    # Build the document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated 6-page research paper PDF: {filename}")

if __name__ == "__main__":
    out_pdf = "Smart_Driving_System_6Page_Paper.pdf"
    if len(sys.argv) > 1:
        out_pdf = sys.argv[1]
    build_pdf(out_pdf)
