#!/usr/bin/env python3
"""
generate_jnanasangama_docx.py
Generates the exact JNANASANGAMA 2026 IEEE 2-Column Conference Report in .docx format
styled in Times New Roman at 10pt font, matching the LibreOffice Writer / MS Word layout.
Includes:
- JNANASANGAMA 2026 header and VTU logo (Top Right)
- Exact Authors: Mohammed Afzal, Pranav K U, Sujay S G, Gagan Deep P K, Roopa G K
- 2-Column Section Layout
- Full 8-Page academic depth with mathematical models, tables, algorithms, and figures
"""

import os
import sys
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import qn, nsdecls

def set_cell_background(cell, hex_color):
    """Sets background color of a table cell."""
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    """Sets cell padding in twips (1/20th of a point)."""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def set_section_columns(section, num_cols=2, space_twips=540):
    """Sets the number of columns in a Word section."""
    sectPr = section._sectPr
    cols = sectPr.xpath('./w:cols')
    if cols:
        col_elem = cols[0]
    else:
        col_elem = OxmlElement('w:cols')
        sectPr.append(col_elem)
    col_elem.set(qn('w:num'), str(num_cols))
    col_elem.set(qn('w:space'), str(space_twips))

def add_callout_box(doc, text):
    """Adds a single-cell callout box for algorithms/equations."""
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    cell = tbl.cell(0, 0)
    cell.width = Inches(3.4)
    set_cell_background(cell, "F8FAFC")
    set_cell_margins(cell, top=120, bottom=120, left=150, right=150)
    
    # Borders
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(f'<w:tcBorders {nsdecls("w")}><w:top w:val="single" w:sz="6" w:space="0" w:color="475569"/><w:bottom w:val="single" w:sz="6" w:space="0" w:color="475569"/><w:left w:val="single" w:sz="6" w:space="0" w:color="475569"/><w:right w:val="single" w:sz="6" w:space="0" w:color="475569"/></w:tcBorders>')
    tcPr.append(borders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.05
    run = p.add_run(text)
    run.font.name = 'Courier New'
    run.font.size = Pt(8)
    run.font.color.rgb = RGBColor(15, 23, 42)

def generate_report_docx(output_path="report.docx"):
    doc = docx.Document()
    
    # Global margins: 0.75 in (54 pt)
    section1 = doc.sections[0]
    section1.top_margin = Inches(0.75)
    section1.bottom_margin = Inches(0.75)
    section1.left_margin = Inches(0.75)
    section1.right_margin = Inches(0.75)
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    fig_dir = os.path.join(base_dir, "report", "figures")
    
    # -------------------------------------------------------------
    # 1. Top Header Table: JNANASANGAMA 2026 (Left) + Logo (Right)
    # -------------------------------------------------------------
    header_table = doc.add_table(rows=1, cols=2)
    header_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    header_table.autofit = False
    
    cell_left = header_table.cell(0, 0)
    cell_left.width = Inches(5.0)
    p_hdr_l = cell_left.paragraphs[0]
    p_hdr_l.paragraph_format.space_before = Pt(0)
    p_hdr_l.paragraph_format.space_after = Pt(0)
    run_hdr = p_hdr_l.add_run("JNANASANGAMA 2026")
    run_hdr.font.name = "Times New Roman"
    run_hdr.font.size = Pt(11)
    run_hdr.font.bold = True
    run_hdr.font.color.rgb = RGBColor(99, 36, 35) # VCET Maroon
    
    cell_right = header_table.cell(0, 1)
    cell_right.width = Inches(1.8)
    p_hdr_r = cell_right.paragraphs[0]
    p_hdr_r.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p_hdr_r.paragraph_format.space_before = Pt(0)
    p_hdr_r.paragraph_format.space_after = Pt(0)
    
    vtu_logo_path = os.path.join(fig_dir, "vtu_logo.png")
    if os.path.exists(vtu_logo_path):
        p_hdr_r.add_run().add_picture(vtu_logo_path, width=Inches(0.65))
    
    # -------------------------------------------------------------
    # 2. Main Paper Title
    # -------------------------------------------------------------
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_title.paragraph_format.space_before = Pt(14)
    p_title.paragraph_format.space_after = Pt(6)
    run_title = p_title.add_run("Smart Mobile-Based Driving Behaviour & Risk\nMonitoring System")
    run_title.font.name = "Times New Roman"
    run_title.font.size = Pt(20)
    run_title.font.bold = True
    run_title.font.color.rgb = RGBColor(15, 23, 42)
    
    # -------------------------------------------------------------
    # 3. Authors & Affiliation
    # -------------------------------------------------------------
    p_auth = doc.add_paragraph()
    p_auth.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_auth.paragraph_format.space_before = Pt(3)
    p_auth.paragraph_format.space_after = Pt(2)
    run_auth = p_auth.add_run("Mohammed Afzal, Pranav K U, Sujay S G, Gagan Deep P K, Roopa G K")
    run_auth.font.name = "Times New Roman"
    run_auth.font.size = Pt(10)
    run_auth.font.color.rgb = RGBColor(99, 36, 35)
    
    p_dept = doc.add_paragraph()
    p_dept.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_dept.paragraph_format.space_before = Pt(0)
    p_dept.paragraph_format.space_after = Pt(1)
    run_dept = p_dept.add_run("Department of CSE (Data Science)")
    run_dept.font.name = "Times New Roman"
    run_dept.font.size = Pt(10)
    run_dept.font.color.rgb = RGBColor(51, 65, 85)
    
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_inst.paragraph_format.space_before = Pt(0)
    p_inst.paragraph_format.space_after = Pt(8)
    run_inst = p_inst.add_run("Vivekananda College of Engineering & Technology, Puttur, Karnataka, India\nAffiliated to Visvesvaraya Technological University (VTU), Belagavi")
    run_inst.font.name = "Times New Roman"
    run_inst.font.size = Pt(9.5)
    run_inst.font.italic = True
    run_inst.font.color.rgb = RGBColor(71, 85, 105)
    
    # -------------------------------------------------------------
    # 4. SECTION BREAK -> Switch to 2 COLUMNS
    # -------------------------------------------------------------
    section2 = doc.add_section(docx.enum.section.WD_SECTION.CONTINUOUS)
    section2.top_margin = Inches(0.75)
    section2.bottom_margin = Inches(0.75)
    section2.left_margin = Inches(0.75)
    section2.right_margin = Inches(0.75)
    set_section_columns(section2, num_cols=2, space_twips=540) # 0.375 in column gap
    
    def add_p(text, bold=False, italic=False, font_size=10, space_before=0, space_after=3.5, align=WD_ALIGN_PARAGRAPH.JUSTIFY, color=RGBColor(15, 23, 42)):
        p = doc.add_paragraph()
        p.alignment = align
        p.paragraph_format.space_before = Pt(space_before)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = 1.15
        run = p.add_run(text)
        run.font.name = "Times New Roman"
        run.font.size = Pt(font_size)
        run.font.bold = bold
        run.font.italic = italic
        run.font.color.rgb = color
        return p

    def add_heading_1(text):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(2.5)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = "Times New Roman"
        run.font.size = Pt(10)
        run.font.bold = True
        run.font.color.rgb = RGBColor(15, 23, 42)
        return p

    def add_heading_2(text):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(5)
        p.paragraph_format.space_after = Pt(1.5)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.font.name = "Times New Roman"
        run.font.size = Pt(10)
        run.font.bold = True
        run.font.italic = True
        run.font.color.rgb = RGBColor(30, 41, 59)
        return p

    def add_fig(img_name, caption_text, width_inches=3.25):
        img_path = os.path.join(fig_dir, img_name)
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(5)
        p_img.paragraph_format.space_after = Pt(2)
        if os.path.exists(img_path):
            p_img.add_run().add_picture(img_path, width=Inches(width_inches))
        else:
            r = p_img.add_run(f"[{caption_text}]")
            r.font.name = "Times New Roman"
            r.font.size = Pt(9)
            r.font.bold = True
            
        p_cap = doc.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap.paragraph_format.space_before = Pt(1)
        p_cap.paragraph_format.space_after = Pt(5)
        r_cap = p_cap.add_run(caption_text)
        r_cap.font.name = "Times New Roman"
        r_cap.font.size = Pt(8.5)
        r_cap.font.bold = True
        r_cap.font.color.rgb = RGBColor(51, 65, 85)

    # -------------------------------------------------------------
    # 5. ABSTRACT & KEYWORDS
    # -------------------------------------------------------------
    add_p("Abstract— Traffic accidents and aggressive commercial driving behaviors represent severe public safety hazards and economic liabilities. Conventional fleet telematics solutions rely heavily on expensive, proprietary diagnostic dongles (₹25,000–₹65,000) and continuous cloud connectivity, rendering them cost-prohibitive for small-scale operators and ineffective in cellular blackout zones such as mountain ghats. This paper presents an accessible, edge-intelligent telematics platform combining a low-cost physical edge sensing node (ESP32 and MPU-6050) with an intelligent Flutter mobile application and a centralized Node.js and React fleet command dashboard. Kinematic data sampled at 20 Hz is filtered via an Adaptive Exponential Moving Average (EMA) and evaluated using a mobile-hosted native Random Forest classification ensemble. An autonomous store-and-forward 'Ghat Mode' queues telemetry during cellular drops, guaranteeing zero data loss. Experimental validation over 360 km of diverse road profiles demonstrates a 94.21% classification accuracy, 93.88% precision, and 94.58% recall with a mean latency under 15 ms, proving the viability of mobile edge computing for next-generation vehicular risk assessment.", italic=True, font_size=10)
    
    add_p("Keywords— fleet telematics; edge computing; driving behavior classification; random forest; Internet of Vehicles; inertial measurement unit; pothole detection; store-and-forward.", bold=True, font_size=10, space_after=6)

    # -------------------------------------------------------------
    # SECTION I: INTRODUCTION
    # -------------------------------------------------------------
    add_heading_1("I. INTRODUCTION")
    add_p("According to the Ministry of Road Transport and Highways (MoRTH) annual reports, road crashes claim over 168,000 lives annually in India, with aggressive driver maneuvers (harsh braking, rapid acceleration, overspeeding, and high-speed cornering) contributing to over 72% of fatal incidents. Furthermore, hazardous road geometries, unmarked speed breakers, and monsoon-damaged potholes induce severe vehicular chassis degradation, suspension fatigue, and rollover risks.")
    add_p("Commercial telematics units typically cost between ₹25,000 and ₹65,000 per vehicle plus recurring subscription fees. More critically, existing systems depend strictly on continuous cellular coverage. In topographically challenging corridors, such as the Shiradi and Sampaje Ghats (NH-75 and NH-275), deep valley dead zones eliminate 4G/5G signals for 10 to 25 km stretches, leaving fleet managers blind during the most perilous segments of a trip.")
    add_p("To resolve these barriers, this project introduces a cost-effective, decentralized edge-computing architecture that decouples vehicle dynamic capture, utilizes local smartphone machine learning, and introduces an autonomous store-and-forward mechanism to ensure uninterrupted safety monitoring regardless of network availability.")

    # -------------------------------------------------------------
    # SECTION II: SYSTEM ARCHITECTURE
    # -------------------------------------------------------------
    add_heading_1("II. SYSTEM ARCHITECTURE")
    add_p("The system employs a multi-tier, mobile-first edge architecture to ensure continuous kinematic data capture and emergency response capability across all geographical environments. The smartphone acts as the central intelligence hub, handling real-time signal processing, edge inferencing, local buffering, and cloud synchronization.")
    
    add_fig("system_architecture.png", "Fig. 1. Multi-Tier Distributed System Architecture.", width_inches=3.3)

    add_heading_2("A. Mobile Application and Edge Intelligence")
    add_p("The Flutter mobile application functions as the primary computational gateway and edge data processor. It ingests high-frequency telemetry over Bluetooth Low Energy (BLE), executes local machine learning inferences, and orchestrates all cloud synchronization. To combat network dead zones, the mobile application features an automated Ghat Mode that queues up to 5,000 kinematic packets chronologically in an in-memory SQLite FIFO buffer when cellular reception drops. Upon restoring 4G/5G connectivity, the smartphone automatically executes a burst-sync to flush the payload to the cloud without data loss or timestamp degradation.")

    add_heading_2("B. Peripheral Hardware Node and Sensor Redundancy")
    add_p("To feed the mobile application with decoupled vehicular dynamics, an edge hardware node utilizes an ESP32-WROOM-32 microcontroller paired with an MPU-6050 6-DOF Inertial Measurement Unit (IMU). Operating on a FreeRTOS dual-core configuration, Core 1 applies a 21 Hz hardware Digital Low Pass Filter (DLPF) and static zero-taring to eliminate high-frequency engine vibration noise. Core 0 manages the BLE GATT server, transmitting 20-byte packed binary payloads directly to the smartphone. The node features dual-power redundancy via a 5V USB port and an onboard 3.7V 1200 mAh Lithium-Polymer (Li-Po) battery. If the vehicle electrical harness is damaged during a collision, the battery immediately sustains the unit. Furthermore, if the BLE connection is severed mid-trip, the mobile application dynamically activates a Dual-Sensor Failover, switching seamlessly to the smartphone's internal accelerometer and gyroscope without interrupting trip logging.")

    add_fig("hardware_prototype.png", "Fig. 2. ESP32 + MPU-6050 Edge Hardware Sensing Node.", width_inches=3.2)

    add_heading_2("C. Cloud Integration and Dashboard")
    add_p("The smartphone synchronizes its processed data with a consolidated Node.js and TypeScript backend engine managing mathematical forensics, such as integrating acceleration over time for Delta-V (ΔV) impact severity. State caching is managed via Redis, and real-time telemetry is synchronized to a React fleet dashboard via Socket.IO. Data is persisted in PostgreSQL using Prisma ORM.")

    # Table I: BLE Telemetry Frame
    p_t1 = doc.add_paragraph()
    p_t1.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t1 = p_t1.add_run("TABLE I: 20-Byte BLE Telemetry Frame Structure")
    r_t1.font.name = "Times New Roman"
    r_t1.font.size = Pt(8.5)
    r_t1.font.bold = True
    
    t_ble = doc.add_table(rows=5, cols=3)
    t_ble.alignment = WD_TABLE_ALIGNMENT.CENTER
    t_ble.autofit = False
    
    headers = ["Byte Offset", "Field Name", "Scale & Description"]
    for i, h in enumerate(headers):
        cell = t_ble.cell(0, i)
        set_cell_background(cell, "0F172A")
        set_cell_margins(cell, top=60, bottom=60, left=80, right=80)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.font.name = "Times New Roman"
        r.font.size = Pt(8)
        r.font.bold = True
        r.font.color.rgb = RGBColor(255, 255, 255)
        
    rows_data = [
        ("0x00 - 0x05", "Accel X, Y, Z", "int16 (LSB/100 m/s²) 3-axis motion"),
        ("0x06 - 0x0B", "Gyro X, Y, Z", "int16 (LSB/10 °/s) angular rates"),
        ("0x0C - 0x0F", "Timestamp", "uint32 (ms) monotonic clock"),
        ("0x10 - 0x13", "Status & CRC", "uint32 bitmask & CRC16 checksum")
    ]
    for row_idx, r_data in enumerate(rows_data, start=1):
        bg = "FFFFFF" if row_idx % 2 == 1 else "F8FAFC"
        for col_idx, text in enumerate(r_data):
            cell = t_ble.cell(row_idx, col_idx)
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=50, bottom=50, left=80, right=80)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if col_idx > 0 else WD_ALIGN_PARAGRAPH.CENTER
            r = p.add_run(text)
            r.font.name = "Times New Roman"
            r.font.size = Pt(7.5)

    # -------------------------------------------------------------
    # SECTION III: KINEMATIC SIGNAL PROCESSING & ML
    # -------------------------------------------------------------
    add_heading_1("III. KINEMATIC SIGNAL PROCESSING AND MACHINE LEARNING")
    add_p("To extract clean driving maneuvers from raw sensor noise, an Adaptive Exponential Moving Average (EMA) filter is applied to the incoming data stream on the mobile gateway:")
    
    add_p("y_t = α_t · x_t + (1 - α_t) · y_{t-1}    (1)", bold=True, align=WD_ALIGN_PARAGRAPH.CENTER)
    
    add_p("During steady cruising, α = 0.22. The system dynamically shifts to α = 0.65 when instantaneous jerk exceeds 1.50 G/s to capture true maneuver peaks without phase lag.")
    add_p("The core predictive intelligence is executed directly on the mobile device. A Random Forest classifier consisting of 100 decision trees categorizes driving behavior using six extracted temporal features: total acceleration magnitude, jerk, Z-axis variance, angular yaw velocity, speed delta, and peak duration.")
    add_p("To eliminate cloud dependency and network latency, the model's decision thresholds and split matrices were compiled directly into native Dart for sub-5 millisecond local execution on the mobile client. A vertical-dominant algorithm detects road anomalies by isolating Z-axis standard deviations exceeding 1.90 G over a 1.5-second sliding window. Critical anomalies, such as angular yaw rates > 18.0 degrees/s at speeds > 35.0 km/h, trigger the mobile app to immediately issue local Text-To-Speech (TTS) voice warnings and enforce localized speed limits.")

    add_fig("fig_harsh_braking.png", "Fig. 3(a). Kinematic waveform during harsh braking.", width_inches=3.2)
    add_fig("fig_pothole_impact.png", "Fig. 3(b). Kinematic waveform during severe pothole shock.", width_inches=3.2)

    # -------------------------------------------------------------
    # SECTION IV: EDGE GEO-FENCING
    # -------------------------------------------------------------
    add_heading_1("IV. EDGE-BASED GEO-FENCING AND SPATIAL COMPLIANCE")
    add_p("To ensure drivers adhere to localized regulations without relying on high-latency cloud queries, the mobile application features a localized spatial geo-fencing engine. Fleet managers define operational boundaries, such as school zones, hospital silence zones, and hazardous hairpin routes, using the React dashboard.")
    add_p("These polygonal coordinates are synchronized to the mobile app's in-memory cache. During a trip, the Flutter client evaluates the vehicle's real-time GPS coordinates against these cached boundaries using the Ray-Casting point-in-polygon algorithm. If a spatial violation occurs, such as exceeding 25 km/h in a designated school zone, the app immediately executes local Text-To-Speech (TTS) audio warnings and restricts the mobile display's speed ceiling, ensuring instantaneous driver compliance.")

    add_fig("fig_mobile_hud.png", "Fig. 4. Flutter Mobile Driver HUD App with Live Risk Gauge & Ghat Mode.", width_inches=3.2)

    # -------------------------------------------------------------
    # SECTION V: FLEET ECONOMICS & SCORING
    # -------------------------------------------------------------
    add_heading_1("V. FLEET ECONOMICS AND ASSET DEGRADATION TRACKING")
    add_p("The platform translates driving behavior into actionable economic metrics through an automated safety ledger. Drivers begin each shift with a baseline safety score of 100. The Node.js backend applies a mathematical penalty model, deducting specific point values for infractions (e.g., 3.0 points for harsh braking, 5.0 points for school zone breaches). This safety score directly influences the driver's trip payout, which can be settled seamlessly via dynamic National Payments Corporation of India (NPCI) UPI deep-linking directly within the app.")
    
    add_p("S_{final} = max(0, 100 - [3.0·N_{brk} + 2.0·N_{acc} + 4.0·N_{trn} + 5.0·N_{geo}])    (2)", bold=True, align=WD_ALIGN_PARAGRAPH.CENTER)

    add_p("Additionally, the backend forecasts vehicle wear-and-tear by calculating a Vehicle Mechanical Stress Index (VMSI):")
    add_p("VMSI = Σ (a_{z,i} - 1.0)² · Δt + 0.15 · Σ |ω_{z,j}| · v_j    (3)", bold=True, align=WD_ALIGN_PARAGRAPH.CENTER)
    add_p("By aggregating the magnitudes of Z-axis shocks from pothole impacts and lateral tire wear from high-yaw cornering, the system automatically flags fleet assets with a maintenance warning on the React dashboard before catastrophic mechanical failures occur.")

    add_fig("fig_fleet_dashboard.png", "Fig. 5. React Tactical Fleet Command Dashboard.", width_inches=3.3)

    # -------------------------------------------------------------
    # SECTION VI: STORE-AND-FORWARD ENGINE
    # -------------------------------------------------------------
    add_heading_1("VI. STORE-AND-FORWARD GHAT MODE SYNCHRONIZATION")
    add_p("In deep mountain valleys, 4G/5G drops eliminate continuous cloud streaming. Algorithm 1 illustrates the autonomous SQLite FIFO buffering and burst-sync mechanism:")
    
    alg_text = """Algorithm 1: Ghat Mode Store-and-Forward
1: Input: Kinematic Packet P_t, State S
2: if S == ONLINE then
3:    POST P_t to Cloud Ingest API;
4:    if Timeout (>1500 ms) or Error then
5:       S <- GHAT_MODE; Queue.enqueue(P_t);
6:    end if
7: else if S == GHAT_MODE then
8:    Queue.enqueue(P_t);
9:    if Cellular Restored == TRUE then
10:      while Queue is not empty do
11:         Batch B <- Queue.dequeue(50);
12:         POST Compressed Batch B;
13:      end while
14:      S <- ONLINE;
15:   end if
16: end if"""
    add_callout_box(doc, alg_text)

    # -------------------------------------------------------------
    # SECTION VII: EXPERIMENTAL RESULTS
    # -------------------------------------------------------------
    add_heading_1("VII. EXPERIMENTAL RESULTS")
    add_p("System testing encompassed 28 trips covering 360 kilometers of diverse terrain (highways, urban stop-and-go traffic, and mountain ghat routes). The mobile-hosted Random Forest classifier was evaluated against a balanced test dataset of N = 2400 windowed time-series samples (1.5-second temporal windows at 20 Hz). The experimental confusion matrix yielded 1135 True Positives, 74 False Positives, 65 False Negatives, and 1126 True Negatives. From these results, the statistical metrics are derived as follows:")
    add_p("• Overall Classification Accuracy: 94.21%\n• Precision (Positive Predictive Value): 93.88%\n• Recall (Sensitivity): 94.58%\n• Specificity (True Negative Rate): 93.83%\n• F1-Score: 94.23%")
    add_p("By leveraging the smartphone as an edge-computing hub, the mobile application successfully managed continuous ML inferences without UI thread blocking or thermal throttling. BLE transmission maintained a mean latency of 14.2 ms, and the mobile application successfully buffered telemetry during simulated cellular blackouts, verifying the resilience of the store-and-forward Ghat Mode.")

    add_fig("confusion_matrix.png", "Fig. 6. Driving Behavior Confusion Matrix.", width_inches=3.1)
    add_fig("score_distribution.png", "Fig. 7. Driver Safety Score Distribution.", width_inches=3.1)

    # -------------------------------------------------------------
    # SECTION VIII: COMPARATIVE ANALYSIS
    # -------------------------------------------------------------
    add_heading_1("VIII. COMPARATIVE BENCHMARK ANALYSIS")
    add_p("Table II contrasts our edge platform against commercial OBD-II units and smartphone-only cloud applications:")
    
    p_t2 = doc.add_paragraph()
    p_t2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t2 = p_t2.add_run("TABLE II: System Paradigm Comparison")
    r_t2.font.name = "Times New Roman"
    r_t2.font.size = Pt(8.5)
    r_t2.font.bold = True
    
    t_comp = doc.add_table(rows=5, cols=4)
    t_comp.alignment = WD_TABLE_ALIGNMENT.CENTER
    t_comp.autofit = False
    
    c_headers = ["Parameter", "OBD-II", "Phone Cloud", "Proposed"]
    for i, h in enumerate(c_headers):
        cell = t_comp.cell(0, i)
        set_cell_background(cell, "0F172A")
        set_cell_margins(cell, top=60, bottom=60, left=60, right=60)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.font.name = "Times New Roman"
        r.font.size = Pt(7.5)
        r.font.bold = True
        r.font.color.rgb = RGBColor(255, 255, 255)
        
    c_rows = [
        ("Unit Cost", "₹25k-65k", "₹0", "₹800 INR"),
        ("Dead Zone", "Lost data", "Inoperable", "Ghat Mode"),
        ("False Alarms", "Low", "High", "Ultra-Low"),
        ("Latency", ">1.5 s", ">800 ms", "<15 ms")
    ]
    for row_idx, r_data in enumerate(c_rows, start=1):
        bg = "FFFFFF" if row_idx % 2 == 1 else "F8FAFC"
        for col_idx, text in enumerate(r_data):
            cell = t_comp.cell(row_idx, col_idx)
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=50, bottom=50, left=60, right=60)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if col_idx > 0 else WD_ALIGN_PARAGRAPH.LEFT
            r = p.add_run(text)
            r.font.name = "Times New Roman"
            r.font.size = Pt(7.5)

    # -------------------------------------------------------------
    # SECTION IX: CONCLUSION & FUTURE SCOPE
    # -------------------------------------------------------------
    add_heading_1("IX. CONCLUSION")
    add_p("The Smart Mobile-Based Driving Behaviour & Risk Monitoring System validates a resilient, mobile-first edge architecture for vehicular telematics. The embedded Random Forest classifier executed natively on the smartphone achieved a 94.21% accuracy rate, while the store-and-forward SQLite buffer eliminated telemetry loss across prolonged cellular blackouts. The peripheral edge sensing node was realized at a unit cost of approximately ₹800 INR, achieving a 95% cost reduction over commercial units by offloading the heavy processing and cloud synchronization directly to the driver's mobile device. Future enhancements will explore active 850nm Infrared (IR) illuminators on the smartphone dashboard mount for night-time driver eye-gaze tracking using the mobile device's front camera, and the integration of factory-calibrated industrial IMUs to minimize thermal zero-bias drift in high-temperature cabin environments.")

    # -------------------------------------------------------------
    # SECTION X: ACKNOWLEDGMENT
    # -------------------------------------------------------------
    add_heading_1("X. ACKNOWLEDGMENT")
    add_p("The authors express their sincere gratitude to Prof. Roopa G K, Head of the Department of CSE (Data Science) at Vivekananda College of Engineering and Technology, Puttur, for their guidance, valuable insights, and continuous encouragement throughout the development of this research.")

    # -------------------------------------------------------------
    # SECTION XI: REFERENCES
    # -------------------------------------------------------------
    add_heading_1("REFERENCES")
    refs = [
        "[1] M. Zarei Yazd, 'A robust machine learning framework for detecting driving events using smartphones,' Int. J. Transp. Syst. Res., 2024.",
        "[2] E. Papatheocharous et al., 'Monitoring distracted driving behaviours with smartphones,' Sensors (MDPI), vol. 23, 2023.",
        "[3] B. Adhikari, 'Using visual and vehicular sensors for driver behavior analysis: A survey,' arXiv preprint, 2023.",
        "[4] S. Ben Brahim et al., 'A machine learning smartphone-based sensing for driver behavior classification,' arXiv preprint, 2022.",
        "[5] P. Wawage et al., 'Smartphone sensor dataset for driver behavior analysis,' Data in Brief, ScienceDirect, 2022.",
        "[6] E. Mantouka et al., 'Smartphone sensing for understanding driving behavior,' Transp. Res., ScienceDirect, 2021.",
        "[7] D. N. Lu et al., 'Vehicle mode and driving activity detection based on smartphone sensors,' Sensors, MDPI, 2021.",
        "[8] E. Huang et al., 'Combining accelerometer and gyroscope data in smartphone-based activity recognition,' arXiv preprint, 2021.",
        "[9] MoRTH, 'Road Accidents in India 2022,' Govt. of India Tech. Rep., 2023.",
        "[10] J. Ferreira et al., 'Data curation and statistical filtering for edge vehicular sensors,' IEEE Sensors J., 2022."
    ]
    for r in refs:
        p_ref = doc.add_paragraph()
        p_ref.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p_ref.paragraph_format.space_before = Pt(0)
        p_ref.paragraph_format.space_after = Pt(2)
        p_ref.paragraph_format.left_indent = Inches(0.2)
        p_ref.paragraph_format.first_line_indent = Inches(-0.2)
        r_ref = p_ref.add_run(r)
        r_ref.font.name = "Times New Roman"
        r_ref.font.size = Pt(8)
        r_ref.font.color.rgb = RGBColor(30, 41, 59)

    doc.save(output_path)
    print(f"Successfully generated JNANASANGAMA 2026 Word Document: {output_path}")

if __name__ == "__main__":
    out_file = "report.docx"
    if len(sys.argv) > 1:
        out_file = sys.argv[1]
    generate_report_docx(out_file)
