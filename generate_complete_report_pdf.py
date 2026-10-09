import os
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Flowable, Image
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas

# Global page number tracker for two-pass compilation
PAGE_TRACKER = {}

class Bookmark(Flowable):
    """Zero-size flowable that records its render page number during document build."""
    def __init__(self, key):
        super().__init__()
        self.key = key
        self.width = 0
        self.height = 0

    def draw(self):
        # canvas._pageNumber is 1-indexed document page
        PAGE_TRACKER[self.key] = self.canv._pageNumber


class VTUCanvas(canvas.Canvas):
    """
    Two-pass canvas applying VTU/VCET standard running headers and footers.
    Preliminary pages (1 to 10) have no header; Roman numerals on LOF/LOT/LOA.
    Chapter 1 to end (11 onwards) have running top header and bottom footer with Arabic page numbers.
    """
    def __init__(self, *args, **kwargs):
        super(VTUCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_header_footer(num_pages)
            super(VTUCanvas, self).showPage()
        super(VTUCanvas, self).save()

    def draw_header_footer(self, page_count):
        p = self._pageNumber
        # Preliminary pages: Cover (1), Cert (2), Decl (3), Abs (4), Ack (5), TOC (6-7), LOF (8), LOT (9), LOA (10)
        # Main chapters start at page 11 (Numbered as Page | 1)
        if p >= 11:
            self.saveState()
            self.setFont("Helvetica", 9)
            self.setStrokeColor(colors.HexColor("#334155"))
            self.setLineWidth(0.75)
            
            # Running Top Header
            self.line(45, 802, 550, 802)
            self.setFillColor(colors.HexColor("#0F172A"))
            self.drawString(45, 806, "Smart Mobile-Based Driving Behaviour & Risk Monitoring System")
            self.drawRightString(550, 806, "2025-27")
            
            # Running Bottom Footer
            self.line(45, 48, 550, 48)
            self.drawString(45, 36, "Dept. of CSE (Data Science), VCET, Puttur")
            arabic_page = p - 10
            self.drawRightString(550, 36, f"Page | {arabic_page}")
            self.restoreState()
        elif p in [8, 9, 10]:
            self.saveState()
            self.setFont("Helvetica", 9)
            self.setFillColor(colors.HexColor("#0F172A"))
            romans = {8: "I", 9: "II", 10: "III"}
            self.drawRightString(550, 36, romans.get(p, ""))
            self.restoreState()


def get_arabic(key, default="?"):
    """Convert recorded document page number to Arabic page number (doc_page - 10)."""
    p = PAGE_TRACKER.get(key)
    if p is not None:
        if p > 10:
            return str(p - 10)
        else:
            return str(p)
    return str(default)


def get_roman(key, default="?"):
    """Get roman numeral for preliminary pages."""
    p = PAGE_TRACKER.get(key)
    romans = {8: "I", 9: "II", 10: "III"}
    if p in romans:
        return romans[p]
    return default


def generate_story():
    """Generates the complete ReportLab flowable story."""
    styles = getSampleStyleSheet()
    
    # Typography Styles
    t_vtu = ParagraphStyle('VTUTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, textColor=colors.HexColor("#991B1B"))
    t_bel = ParagraphStyle('VTUSub', fontName='Helvetica-Bold', fontSize=10, leading=13, alignment=1, textColor=colors.HexColor("#1E293B"))
    p_on = ParagraphStyle('ProjectOn', fontName='Helvetica-Bold', fontSize=11, leading=14, alignment=1, textColor=colors.HexColor("#1E293B"))
    p_title = ParagraphStyle('ProjectTitle', fontName='Helvetica-Bold', fontSize=13.5, leading=17.5, alignment=1, textColor=colors.HexColor("#991B1B"))
    p_subm = ParagraphStyle('ProjectSubm', fontName='Helvetica', fontSize=9.5, leading=13.5, alignment=1, textColor=colors.HexColor("#1E293B"))
    
    chap_heading = ParagraphStyle('ChapHeading', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=0, spaceBefore=4, spaceAfter=4, textColor=colors.HexColor("#0F172A"))
    chap_name = ParagraphStyle('ChapName', fontName='Helvetica-Bold', fontSize=13.5, leading=17, alignment=1, spaceBefore=4, spaceAfter=12, textColor=colors.HexColor("#0F172A"))
    
    sec_heading = ParagraphStyle('SecHeading', fontName='Helvetica-Bold', fontSize=11, leading=14, spaceBefore=9, spaceAfter=4, textColor=colors.HexColor("#0F172A"), keepWithNext=True)
    subsec_heading = ParagraphStyle('SubSecHeading', fontName='Helvetica-Bold', fontSize=9.5, leading=12.5, spaceBefore=6, spaceAfter=3, textColor=colors.HexColor("#1E293B"), keepWithNext=True)
    
    body = ParagraphStyle('BodyText', fontName='Helvetica', fontSize=9, leading=13.2, spaceAfter=5, alignment=4, textColor=colors.HexColor("#1E293B"))
    bullet = ParagraphStyle('BulletText', fontName='Helvetica', fontSize=9, leading=12.8, leftIndent=14, spaceAfter=3.5, textColor=colors.HexColor("#1E293B"))
    
    th_style = ParagraphStyle('TH', fontName='Helvetica-Bold', fontSize=7.5, leading=9.5, alignment=1, textColor=colors.HexColor("#0F172A"))
    td_style = ParagraphStyle('TD', fontName='Helvetica', fontSize=7.5, leading=9.5, textColor=colors.HexColor("#1E293B"))
    fig_cap = ParagraphStyle('FigCap', fontName='Helvetica-Bold', fontSize=8.5, leading=11, alignment=1, spaceBefore=4, spaceAfter=6, textColor=colors.HexColor("#0F172A"))

    story = []

    # ==========================================
    # PRELIMINARY PAGES (1 to 10)
    # ==========================================
    # Page 1: Title Page (Using Placeholders for Names)
    story.append(Paragraph("VISVESVARAYA TECHNOLOGICAL UNIVERSITY", t_vtu))
    story.append(Paragraph("JNANA SANGAMA, BELAGAVI – 590 018, KARNATAKA, INDIA", t_bel))
    story.append(Spacer(1, 10))
    if os.path.exists('report/figures/vtu_logo.png'):
        story.append(Image('report/figures/vtu_logo.png', width=1.05*inch, height=1.05*inch))
    story.append(Spacer(1, 10))
    story.append(Paragraph("A PROJECT REPORT<br/>ON", p_on))
    story.append(Spacer(1, 4))
    story.append(Paragraph("“SMART MOBILE-BASED DRIVING BEHAVIOUR &amp; RISK MONITORING SYSTEM”", p_title))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Submitted in partial fulfillment of the requirements for the award of<br/><b>BACHELOR OF ENGINEERING</b><br/>in<br/><b>CSE (DATA SCIENCE)</b>", p_subm))
    story.append(Spacer(1, 10))
    story.append(Paragraph("<b>Submitted By</b>", p_on))
    story.append(Spacer(1, 4))
    team_data = [
        [Paragraph("<b>Name</b>", th_style), Paragraph("<b>USN</b>", th_style)],
        [Paragraph("[Candidate Name 1]", td_style), Paragraph("[USN 1]", td_style)],
        [Paragraph("[Candidate Name 2]", td_style), Paragraph("[USN 2]", td_style)],
        [Paragraph("[Candidate Name 3]", td_style), Paragraph("[USN 3]", td_style)],
        [Paragraph("[Candidate Name 4]", td_style), Paragraph("[USN 4]", td_style)],
    ]
    t_team = Table(team_data, colWidths=[200, 160])
    t_team.setStyle(TableStyle([('ALIGN', (0,0), (-1,-1), 'CENTER'), ('BOTTOMPADDING', (0,0), (-1,-1), 2), ('TOPPADDING', (0,0), (-1,-1), 2)]))
    story.append(t_team)
    story.append(Spacer(1, 8))
    story.append(Paragraph("<b>Under the Guidance of</b><br/><b>[Guide Name]</b><br/>[Designation], Dept. of CSE (Data Science)", p_subm))
    story.append(Spacer(1, 8))
    if os.path.exists('report/figures/vcet_logo.png'):
        story.append(Image('report/figures/vcet_logo.png', width=0.9*inch, height=0.9*inch))
    story.append(Spacer(1, 5))
    story.append(Paragraph("<b>DEPARTMENT OF CSE (DATA SCIENCE)</b>", ParagraphStyle('Dept', fontName='Helvetica-Bold', fontSize=10, leading=12, alignment=1, textColor=colors.HexColor("#1D4ED8"))))
    story.append(Paragraph("<b>VIVEKANANDA COLLEGE OF ENGINEERING &amp; TECHNOLOGY</b><br/><font size=7.5>[A Unit of Vivekananda Vidyavardhaka Sangha, Puttur (R)]<br/>Affiliated to Visvesvaraya Technological University and Approved by AICTE New Delhi &amp; Govt. of Karnataka<br/>Nehru Nagara, Puttur – 574 203, DK, Karnataka, India<br/><b>Academic Year 2025 - 2027</b></font>", ParagraphStyle('Addr', fontName='Helvetica', fontSize=7.5, leading=10, alignment=1, textColor=colors.HexColor("#0F172A"))))
    story.append(PageBreak())

    # Page 2: Certificate
    story.append(Paragraph("<b>VIVEKANANDA COLLEGE OF ENGINEERING &amp; TECHNOLOGY</b>", ParagraphStyle('C1', fontName='Helvetica-Bold', fontSize=11.5, leading=14, alignment=1, textColor=colors.HexColor("#991B1B"))))
    story.append(Paragraph("<font size=7.5>[A Unit of Vivekananda Vidyavardhaka Sangha, Puttur (R)]<br/>Affiliated to Visvesvaraya Technological University and Approved by AICTE New Delhi &amp; Govt. of Karnataka<br/>Nehru Nagara, Puttur – 574 203, DK, Karnataka, India</font>", ParagraphStyle('C2', fontName='Helvetica', fontSize=7.5, leading=10, alignment=1, textColor=colors.HexColor("#1E293B"))))
    story.append(Spacer(1, 5))
    story.append(Paragraph("<b>DEPARTMENT OF CSE (DATA SCIENCE)</b>", ParagraphStyle('C3', fontName='Helvetica-Bold', fontSize=10.5, leading=13, alignment=1, textColor=colors.HexColor("#1D4ED8"))))
    story.append(Spacer(1, 5))
    if os.path.exists('report/figures/vcet_logo.png'):
        story.append(Image('report/figures/vcet_logo.png', width=0.8*inch, height=0.8*inch))
    story.append(Spacer(1, 6))
    story.append(Paragraph("CERTIFICATE", ParagraphStyle('CertTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, textColor=colors.HexColor("#0F172A"))))
    story.append(Spacer(1, 6))
    cert_text = (
        "Certified that the project work entitled <b>“Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System”</b> "
        "is carried out by <b>[Candidate Name 1], [Candidate Name 2], [Candidate Name 3], and [Candidate Name 4]</b> bearing USNs "
        "<b>[USN 1], [USN 2], [USN 3] and [USN 4]</b>, respectively bonafide students of "
        "<b>Vivekananda College of Engineering &amp; Technology</b>, in partial fulfillment for the award of "
        "<b>Bachelor of Engineering in CSE (Data Science)</b> of the <b>Visvesvaraya Technological University, Belagavi</b> "
        "during the year 2025-27. It is certified that all corrections / suggestions indicated for Internal Assessment have been incorporated "
        "in the report deposited in the departmental library.<br/><br/>"
        "The project report has been approved as it satisfies the academic requirements in respect of Project work prescribed for the said Degree."
    )
    story.append(Paragraph(cert_text, body))
    story.append(Spacer(1, 30))
    sigs = [
        [Paragraph("<b>Signature of the Guide</b><br/>[Guide Name]<br/>[Designation]", td_style),
         Paragraph("<b>Signature of the HOD</b><br/>[HOD Name]<br/>Head of Department", td_style),
         Paragraph("<b>Signature of the Principal</b><br/>[Principal Name]<br/>Principal", td_style)]
    ]
    t_sigs = Table(sigs, colWidths=[165, 170, 165])
    t_sigs.setStyle(TableStyle([('ALIGN', (0,0), (-1,-1), 'CENTER'), ('VALIGN', (0,0), (-1,-1), 'TOP')]))
    story.append(t_sigs)
    story.append(Spacer(1, 30))
    story.append(Paragraph("<b>EXTERNAL VIVA</b>", ParagraphStyle('Viva', fontName='Helvetica-Bold', fontSize=9.5, leading=12, alignment=1)))
    story.append(Spacer(1, 5))
    viva_table = [
        [Paragraph("<b>Name of the Examiners</b>", th_style), Paragraph("<b>Signature with date</b>", th_style)],
        [Paragraph("1. ............................................................", td_style), Paragraph("....................................................", td_style)],
        [Paragraph("2. ............................................................", td_style), Paragraph("....................................................", td_style)],
    ]
    t_viva = Table(viva_table, colWidths=[280, 220])
    t_viva.setStyle(TableStyle([('ALIGN', (0,0), (-1,-1), 'LEFT'), ('BOTTOMPADDING', (0,0), (-1,-1), 6), ('TOPPADDING', (0,0), (-1,-1), 6)]))
    story.append(t_viva)
    story.append(PageBreak())

    # Page 3: Declaration
    story.append(Paragraph("DECLARATION", ParagraphStyle('DeclTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=16)))
    decl_text = (
        "We, <b>[Candidate Name 1] ([USN 1]), [Candidate Name 2] ([USN 2]), [Candidate Name 3] ([USN 3]) and [Candidate Name 4] ([USN 4])</b> "
        "students of seventh semester B.E. in <b>CSE (Data Science)</b>, Vivekananda College of Engineering &amp; Technology, "
        "Puttur, hereby declare that the project work entitled <b>“Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System”</b> "
        "has been carried out and duly executed by us at VCET, Puttur, under the guidance of <b>[Guide Name]</b>, [Designation], "
        "Department of CSE (Data Science), Vivekananda College of Engineering &amp; Technology, Puttur, and submitted in partial fulfillment "
        "of the requirements for the award of degree in <b>Bachelor of Engineering in CSE (Data Science)</b> by "
        "<b>Visvesvaraya Technological University, Belagavi</b> during the academic year 2025-27."
    )
    story.append(Paragraph(decl_text, body))
    story.append(Spacer(1, 25))
    decl_table = [
        [Paragraph("<b>Name of the Students</b>", th_style), Paragraph("<b>USN</b>", th_style), Paragraph("<b>Signature with date</b>", th_style)],
        [Paragraph("[Candidate Name 1]", td_style), Paragraph("[USN 1]", td_style), Paragraph("..................................", td_style)],
        [Paragraph("[Candidate Name 2]", td_style), Paragraph("[USN 2]", td_style), Paragraph("..................................", td_style)],
        [Paragraph("[Candidate Name 3]", td_style), Paragraph("[USN 3]", td_style), Paragraph("..................................", td_style)],
        [Paragraph("[Candidate Name 4]", td_style), Paragraph("[USN 4]", td_style), Paragraph("..................................", td_style)],
    ]
    t_dt = Table(decl_table, colWidths=[180, 140, 180])
    t_dt.setStyle(TableStyle([('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")), ('ALIGN', (0,0), (-1,-1), 'LEFT'), ('BOTTOMPADDING', (0,0), (-1,-1), 8), ('TOPPADDING', (0,0), (-1,-1), 8)]))
    story.append(t_dt)
    story.append(Spacer(1, 30))
    story.append(Paragraph("<b>Date:</b> October 2026<br/><b>Place:</b> Puttur", body))
    story.append(PageBreak())

    # Page 4: Abstract
    story.append(Paragraph("ABSTRACT", ParagraphStyle('AbsTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=16)))
    story.append(Paragraph(
        "In recent years, the rapid growth of vehicular transport has made road safety an escalating global concern due to accidents "
        "caused by unsafe driving behaviors such as overspeeding, harsh braking, sudden acceleration, and distracted driving. "
        "Traditional monitoring systems rely on manual supervision or expensive OBD-II hardware installations that lack scalability. "
        "The project titled <b>“Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System”</b> addresses these challenges by combining "
        "smartphone-based sensing, dedicated external edge IMU sensors (ESP32 + MPU-6050), and cloud analytics. The system samples 3D kinematics "
        "at 20 Hz, applies spatial downsampling, and classifies events using machine learning models to generate real-time driver safety scores, "
        "visualized on an interactive web dashboard.", body))
    story.append(Paragraph(
        "By rigidly mounting the ESP32 node to the vehicle chassis, the platform eliminates the 2.0g to 3.5g false acceleration spikes "
        "typically caused by phone rattling in cup holders. The collected telemetry is transmitted over a 20-byte packed binary BLE GATT packet "
        "to a mobile gateway, which enforces a 3-meter spatial delta filter. A FastAPI cloud microservice filters incoming signals through an "
        "Adaptive Exponential Moving Average (EMA) filter, followed by Random Forest classification achieving <b>94.8% accuracy</b>. "
        "A distance-normalized exponential decay engine assigns an objective 0–100 safety score, visualized on a real-time React 18 GIS fleet command center "
        "with automated collision SOS dispatch.", body))
    story.append(PageBreak())

    # Page 5: Acknowledgement
    story.append(Paragraph("ACKNOWLEDGEMENT", ParagraphStyle('AckTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=16)))
    ack_items = [
        "We take this opportunity to express our deep heartfelt gratitude to all those people who have helped us in the successful completion of the project.",
        "First and foremost, we express sincere gratitude towards our guide <b>[Guide Name]</b>, [Designation], for providing excellent guidance, encouragement and inspiration throughout the project work.",
        "We express sincere gratitude to the Head of the Department of CSE (Data Science), <b>[HOD Name]</b> for their guidance and inspiration.",
        "We thank our Principal <b>[Principal Name]</b> for providing all facilities and a proper environment to work in the college campus.",
        "We are extremely grateful to Management of Vivekananda College of Engineering &amp; Technology, Puttur for their constant support.",
        "We are thankful to all teaching and non-teaching staff members of CSE (Data Science) Department for their help and needed support."
    ]
    for p in ack_items:
        story.append(Paragraph(p, body))
        story.append(Spacer(1, 5))
    story.append(PageBreak())

    # ==========================================
    # SEPARATE SECTION 1: TABLE OF CONTENTS (Pages 6 & 7)
    # Balanced evenly so both pages are fully structured
    # ==========================================
    # Page 6: TOC Part 1 (Preliminary + Chapter 1 + Chapter 2)
    story.append(Paragraph("TABLE OF CONTENTS", ParagraphStyle('TOCTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=12)))
    toc_p1 = [
        [Paragraph("<b>Title</b>", th_style), Paragraph("<b>Page No.</b>", th_style)],
        [Paragraph("<b>LIST OF FIGURES</b>", td_style), Paragraph(f"<b>{get_roman('lof', 'I')}</b>", td_style)],
        [Paragraph("<b>LIST OF TABLES</b>", td_style), Paragraph(f"<b>{get_roman('lot', 'II')}</b>", td_style)],
        [Paragraph("<b>LIST OF ABBREVIATIONS</b>", td_style), Paragraph(f"<b>{get_roman('loa', 'III')}</b>", td_style)],
        [Paragraph("<b>CHAPTER 1   INTRODUCTION</b>", td_style), Paragraph(f"<b>{get_arabic('chap1', '1')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;1.1 Introduction to Project", td_style), Paragraph(get_arabic('sec1_1', '1'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;1.2 Introduction to Technology used", td_style), Paragraph(get_arabic('sec1_2', '2'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.1 Mobile Sensing Technology", td_style), Paragraph(get_arabic('sec1_2_1', '2'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.2 External Sensing Technology", td_style), Paragraph(get_arabic('sec1_2_2', '2'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.3 Communication Technology", td_style), Paragraph(get_arabic('sec1_2_3', '3'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.4 Software Technology", td_style), Paragraph(get_arabic('sec1_2_4', '3'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.5 Machine Learning", td_style), Paragraph(get_arabic('sec1_2_5', '3'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.6 Dashboard and User Interface Technologies", td_style), Paragraph(get_arabic('sec1_2_6', '3'), td_style)],
        [Paragraph("<b>CHAPTER 2   LITERATURE SURVEY</b>", td_style), Paragraph(f"<b>{get_arabic('chap2', '4')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;2.1 Introduction", td_style), Paragraph(get_arabic('sec2_1', '4'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;2.2 Literature Survey", td_style), Paragraph(get_arabic('sec2_2', '4'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;2.3 Summary of Literature Survey", td_style), Paragraph(get_arabic('sec2_3', '7'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;2.4 Comparison with Existing Systems", td_style), Paragraph(get_arabic('sec2_4', '8'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;2.5 Proposed System", td_style), Paragraph(get_arabic('sec2_5', '8'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;2.6 Objectives", td_style), Paragraph(get_arabic('sec2_6', '8'), td_style)],
    ]
    t_toc1 = Table(toc_p1, colWidths=[400, 100])
    t_toc1.setStyle(TableStyle([
        ('ALIGN', (0,0), (0,-1), 'LEFT'),
        ('ALIGN', (1,0), (1,-1), 'RIGHT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5.5),
        ('TOPPADDING', (0,0), (-1,-1), 5.5),
        ('LINEBELOW', (0,0), (-1,0), 0.5, colors.HexColor("#0F172A")),
    ]))
    story.append(t_toc1)
    story.append(PageBreak())

    # Page 7: TOC Part 2 (Chapter 3 to End)
    story.append(Paragraph("TABLE OF CONTENTS (Continued)", ParagraphStyle('TOCTitle2', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=12)))
    toc_p2 = [
        [Paragraph("<b>Title</b>", th_style), Paragraph("<b>Page No.</b>", th_style)],
        [Paragraph("<b>CHAPTER 3   REQUIREMENT SPECIFICATION AND ANALYSIS</b>", td_style), Paragraph(f"<b>{get_arabic('chap3', '9')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;3.1 Introduction", td_style), Paragraph(get_arabic('sec3_1', '9'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;3.2 Functional Requirements", td_style), Paragraph(get_arabic('sec3_2', '9'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3.2.1 User Requirements", td_style), Paragraph(get_arabic('sec3_2_1', '9'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3.2.2 System Requirements", td_style), Paragraph(get_arabic('sec3_2_2', '9'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;3.3 Non-Functional Requirements", td_style), Paragraph(get_arabic('sec3_3', '10'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;3.4 User Interface Requirements", td_style), Paragraph(get_arabic('sec3_4', '10'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;3.5 Software Requirements", td_style), Paragraph(get_arabic('sec3_5', '10'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;3.6 Hardware Requirements", td_style), Paragraph(get_arabic('sec3_6', '10'), td_style)],
        [Paragraph("<b>CHAPTER 4   SYSTEM DESIGN</b>", td_style), Paragraph(f"<b>{get_arabic('chap4', '11')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;4.1 Introduction", td_style), Paragraph(get_arabic('sec4_1', '11'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;4.2 Overview of Proposed Solution", td_style), Paragraph(get_arabic('sec4_2', '11'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;4.3 Block Diagram", td_style), Paragraph(get_arabic('sec4_3', '11'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;4.4 Flowchart", td_style), Paragraph(get_arabic('sec4_4', '12'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;4.5 Data Flow Modeling", td_style), Paragraph(get_arabic('sec4_5', '12'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;4.6 Database Design &amp; Schema", td_style), Paragraph(get_arabic('sec4_6', '13'), td_style)],
        [Paragraph("<b>CHAPTER 5   SYSTEM IMPLEMENTATION</b>", td_style), Paragraph(f"<b>{get_arabic('chap5', '14')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;5.1 Introduction", td_style), Paragraph(get_arabic('sec5_1', '14'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;5.2 Algorithm Used", td_style), Paragraph(get_arabic('sec5_2', '14'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;5.3 Hardware &amp; Network Layers", td_style), Paragraph(get_arabic('sec5_3', '15'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;5.4 Workflow of Driving Behavior Analysis", td_style), Paragraph(get_arabic('sec5_4', '15'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;5.5 Datasets &amp; Driving Scenarios", td_style), Paragraph(get_arabic('sec5_5', '16'), td_style)],
        [Paragraph("<b>CHAPTER 6   SYSTEM TESTING</b>", td_style), Paragraph(f"<b>{get_arabic('chap6', '17')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;6.1 Introduction", td_style), Paragraph(get_arabic('sec6_1', '17'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;6.2 Types of Testing", td_style), Paragraph(get_arabic('sec6_2', '17'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;6.3 Test Cases", td_style), Paragraph(get_arabic('sec6_3', '18'), td_style)],
        [Paragraph("<b>CHAPTER 7   EXPERIMENTAL RESULTS AND SNAPSHOTS</b>", td_style), Paragraph(f"<b>{get_arabic('chap7', '19')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;7.1 Testing and Validation Loss Curve", td_style), Paragraph(get_arabic('sec7_1', '19'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;7.2 Training and Validation Accuracy Curve", td_style), Paragraph(get_arabic('sec7_2', '19'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;7.3 Snapshots", td_style), Paragraph(get_arabic('sec7_3', '20'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;7.4 Performance Analysis", td_style), Paragraph(get_arabic('sec7_4', '22'), td_style)],
        [Paragraph("<b>CHAPTER 8   CONCLUSION &amp; SCOPE FOR FUTURE ENHANCEMENT</b>", td_style), Paragraph(f"<b>{get_arabic('chap8', '23')}</b>", td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;8.1 Conclusion", td_style), Paragraph(get_arabic('sec8_1', '23'), td_style)],
        [Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;8.2 Future Enhancements", td_style), Paragraph(get_arabic('sec8_2', '23'), td_style)],
        [Paragraph("<b>REFERENCES</b>", td_style), Paragraph(f"<b>{get_arabic('refs', '24')}</b>", td_style)],
        [Paragraph("<b>PERSONAL PROFILE</b>", td_style), Paragraph(f"<b>{get_arabic('profile', '25')}</b>", td_style)],
        [Paragraph("<b>CONFERENCE ATTENDED</b>", td_style), Paragraph(f"<b>{get_arabic('conf', '26')}</b>", td_style)],
    ]
    t_toc2 = Table(toc_p2, colWidths=[400, 100])
    t_toc2.setStyle(TableStyle([
        ('ALIGN', (0,0), (0,-1), 'LEFT'),
        ('ALIGN', (1,0), (1,-1), 'RIGHT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3.2),
        ('TOPPADDING', (0,0), (-1,-1), 3.2),
        ('LINEBELOW', (0,0), (-1,0), 0.5, colors.HexColor("#0F172A")),
    ]))
    story.append(t_toc2)
    story.append(PageBreak())

    # ==========================================
    # SEPARATE SECTION 2: LIST OF FIGURES (Page 8)
    # ==========================================
    story.append(Bookmark('lof'))
    story.append(Paragraph("LIST OF FIGURES", ParagraphStyle('LOFTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=18)))
    lof_data = [
        [Paragraph("<b>Figure No.</b>", th_style), Paragraph("<b>Title</b>", th_style), Paragraph("<b>Page No.</b>", th_style)],
        [Paragraph("4.1", td_style), Paragraph("Block Diagram of Proposed System", td_style), Paragraph(get_arabic('fig4_1', '11'), td_style)],
        [Paragraph("4.2", td_style), Paragraph("Flowchart of Driving Behavior Analysis Process", td_style), Paragraph(get_arabic('fig4_2', '12'), td_style)],
        [Paragraph("4.3", td_style), Paragraph("Level-1 Data Flow Diagram (DFD)", td_style), Paragraph(get_arabic('fig4_3', '12'), td_style)],
        [Paragraph("5.1", td_style), Paragraph("Kinematic Profile: Normal Cruising", td_style), Paragraph(get_arabic('fig5_1', '16'), td_style)],
        [Paragraph("5.2", td_style), Paragraph("Kinematic Profile: Harsh Panic Braking", td_style), Paragraph(get_arabic('fig5_2', '16'), td_style)],
        [Paragraph("5.3", td_style), Paragraph("Kinematic Profile: Road Surface Defect (Pothole)", td_style), Paragraph(get_arabic('fig5_3', '16'), td_style)],
        [Paragraph("7.1", td_style), Paragraph("Training and Validation Loss Curve", td_style), Paragraph(get_arabic('fig7_1', '19'), td_style)],
        [Paragraph("7.2", td_style), Paragraph("Training and Validation Accuracy Curve", td_style), Paragraph(get_arabic('fig7_2', '19'), td_style)],
        [Paragraph("7.3", td_style), Paragraph("Mobile Driver HUD Interface", td_style), Paragraph(get_arabic('fig7_3', '20'), td_style)],
        [Paragraph("7.4", td_style), Paragraph("Fleet Operations Command Center GIS Map", td_style), Paragraph(get_arabic('fig7_4', '20'), td_style)],
        [Paragraph("7.5", td_style), Paragraph("Driver Telemetry &amp; Risk Scoring Audit Modal", td_style), Paragraph(get_arabic('fig7_5', '21'), td_style)],
        [Paragraph("7.6", td_style), Paragraph("Emergency SOS Crash &amp; Hazard Incident Report Page", td_style), Paragraph(get_arabic('fig7_6', '21'), td_style)],
    ]
    t_lof = Table(lof_data, colWidths=[70, 360, 70])
    t_lof.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('ALIGN', (2,0), (2,-1), 'RIGHT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('LINEBELOW', (0,0), (-1,0), 0.5, colors.HexColor("#0F172A")),
    ]))
    story.append(t_lof)
    story.append(PageBreak())

    # ==========================================
    # SEPARATE SECTION 3: LIST OF TABLES (Page 9)
    # ==========================================
    story.append(Bookmark('lot'))
    story.append(Paragraph("LIST OF TABLES", ParagraphStyle('LOTTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=18)))
    lot_data = [
        [Paragraph("<b>Table No.</b>", th_style), Paragraph("<b>Title</b>", th_style), Paragraph("<b>Page No.</b>", th_style)],
        [Paragraph("2.1", td_style), Paragraph("Literature Survey Summary", td_style), Paragraph(get_arabic('tab2_1', '7'), td_style)],
        [Paragraph("4.1", td_style), Paragraph("PostgreSQL Database Relational Schema", td_style), Paragraph(get_arabic('tab4_1', '13'), td_style)],
        [Paragraph("5.1", td_style), Paragraph("20-Byte BLE Packed Binary Telemetry Packet Layout", td_style), Paragraph(get_arabic('tab5_1', '15'), td_style)],
        [Paragraph("6.1", td_style), Paragraph("Test Cases for Verification and Validation", td_style), Paragraph(get_arabic('tab6_1', '18'), td_style)],
        [Paragraph("7.1", td_style), Paragraph("Performance Comparison of Maneuver Classification Models", td_style), Paragraph(get_arabic('tab7_1', '22'), td_style)],
    ]
    t_lot = Table(lot_data, colWidths=[70, 360, 70])
    t_lot.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('ALIGN', (2,0), (2,-1), 'RIGHT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('LINEBELOW', (0,0), (-1,0), 0.5, colors.HexColor("#0F172A")),
    ]))
    story.append(t_lot)
    story.append(PageBreak())

    # ==========================================
    # SEPARATE SECTION 4: LIST OF ABBREVIATIONS (Page 10)
    # ==========================================
    story.append(Bookmark('loa'))
    story.append(Paragraph("LIST OF ABBREVIATIONS", ParagraphStyle('LOATitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=18)))
    loa_data = [
        [Paragraph("<b>Acronym</b>", th_style), Paragraph("<b>Expansion</b>", th_style)],
        [Paragraph("AI", td_style), Paragraph("Artificial Intelligence", td_style)],
        [Paragraph("AIoT", td_style), Paragraph("Artificial Intelligence of Things", td_style)],
        [Paragraph("BLE", td_style), Paragraph("Bluetooth Low Energy", td_style)],
        [Paragraph("CAN", td_style), Paragraph("Controller Area Network", td_style)],
        [Paragraph("CNN", td_style), Paragraph("Convolutional Neural Network", td_style)],
        [Paragraph("DLPF", td_style), Paragraph("Digital Low-Pass Filter", td_style)],
        [Paragraph("EMA", td_style), Paragraph("Exponential Moving Average", td_style)],
        [Paragraph("FIFO", td_style), Paragraph("First-In, First-Out", td_style)],
        [Paragraph("GATT", td_style), Paragraph("Generic Attribute Profile", td_style)],
        [Paragraph("GIS", td_style), Paragraph("Geographic Information System", td_style)],
        [Paragraph("GPS", td_style), Paragraph("Global Positioning System", td_style)],
        [Paragraph("HUD", td_style), Paragraph("Heads-Up Display", td_style)],
        [Paragraph("IMU", td_style), Paragraph("Inertial Measurement Unit", td_style)],
        [Paragraph("MEMS", td_style), Paragraph("Micro-Electro-Mechanical Systems", td_style)],
        [Paragraph("OBD-II", td_style), Paragraph("On-Board Diagnostics II", td_style)],
        [Paragraph("REST", td_style), Paragraph("Representational State Transfer", td_style)],
        [Paragraph("SVM", td_style), Paragraph("Support Vector Machine", td_style)],
        [Paragraph("TTC", td_style), Paragraph("Time-To-Collision", td_style)],
        [Paragraph("UBI", td_style), Paragraph("Usage-Based Insurance", td_style)],
        [Paragraph("USN", td_style), Paragraph("University Seat Number", td_style)],
    ]
    t_loa = Table(loa_data, colWidths=[120, 380])
    t_loa.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#E2E8F0")),
    ]))
    story.append(t_loa)
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 1: INTRODUCTION (Pages 11 to 13, numbered Page | 1 to 3)
    # ==========================================
    # Page 11 (Arabic 1)
    story.append(Bookmark('chap1'))
    story.append(Paragraph("CHAPTER 1", chap_heading))
    story.append(Paragraph("INTRODUCTION", chap_name))
    
    story.append(Bookmark('sec1_1'))
    story.append(Paragraph("1.1 Introduction to Project", sec_heading))
    intro_paragraphs = [
        "In recent years, the rapid growth of mobile technology and intelligent data processing has significantly transformed the transportation and automotive industry. Road safety has become a major concern due to the increasing number of accidents caused by unsafe driving behaviors such as overspeeding, harsh braking, sudden acceleration, and distracted driving. Traditional monitoring systems rely heavily on manual supervision or expensive hardware installations, which are not scalable or cost-effective for large-scale deployment. As a result, there is a growing need for an efficient, low-cost, and intelligent system that can continuously monitor driver behavior and provide meaningful insights to improve road safety.",
        "The project titled <b>“Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System”</b> aims to address these challenges by leveraging smartphone-based sensing and modern data analytics techniques. The system utilizes built-in sensors available in smartphones, such as accelerometer, gyroscope, and GPS, to collect real-time driving data without the need for additional hardware devices. This approach significantly reduces system cost while maintaining high accessibility and usability.",
        "The proposed system is designed to analyze driving patterns and identify unsafe behaviors using intelligent data processing techniques. Events such as harsh braking, rapid acceleration, sharp turns, and speed violations are detected based on sensor data patterns. The collected data is transmitted to a cloud-based backend, where it is processed and stored for further analysis. A web-based dashboard is developed to visualize the data in the form of driver scores, trip summaries, event logs, and geographical insights, enabling fleet managers and users to monitor performance effectively.",
        "Unlike traditional IoT-based systems that require dedicated hardware components, this project follows a mobile computing and cloud-integrated architecture. It combines the advantages of mobile computing, wireless communication, and machine learning to provide a scalable and efficient solution. The system not only improves driver safety but also contributes to better fleet management, reduced accident rates, and enhanced decision-making capabilities.",
        "Overall, this project demonstrates how modern smartphone technology can be effectively utilized to build an intelligent, real-time, and cost-efficient driver monitoring system, making it highly suitable for real-world applications."
    ]
    for p in intro_paragraphs:
        story.append(Paragraph(p, body))
        story.append(Spacer(1, 4))
    story.append(PageBreak())

    # Page 12 (Arabic 2)
    story.append(Bookmark('sec1_2'))
    story.append(Paragraph("1.2 Introduction to Technology used", sec_heading))
    story.append(Paragraph("The development of the proposed system involves the integration of multiple modern technologies that work together to enable real-time data collection, intelligent analysis, and effective visualization. These technologies are carefully selected to ensure system efficiency, scalability, and ease of use.", body))
    
    story.append(Bookmark('sec1_2_1'))
    story.append(Paragraph("1.2.1 Mobile Sensing Technology", subsec_heading))
    story.append(Paragraph("• <b>Accelerometer:</b> The smartphone accelerometer is used to measure linear acceleration along the X, Y, and Z axes. In this project, it helps in detecting basic driving behaviors such as sudden acceleration, braking, and movement state. However, its accuracy depends on the phone's placement, which may introduce noise.", bullet))
    story.append(Paragraph("• <b>Gyroscope:</b> The mobile gyroscope measures angular velocity and is used to detect turning movements and orientation changes. It assists in identifying driving patterns such as cornering and slight directional shifts, but may not always provide consistent results due to varying device positioning.", bullet))
    story.append(Paragraph("• <b>GPS Sensor:</b> The GPS sensor provides real-time location data such as speed, latitude, longitude, and travel route. It is used for trip tracking, route visualization, and detecting speed violations. This data is also displayed on the dashboard for analysis.", bullet))
    story.append(Paragraph("• <b>Sensor Fusion (Mobile Processing):</b> The smartphone combines multiple sensor inputs to derive useful information such as motion detection, speed estimation, and driving state. This helps in basic-level behavior monitoring without requiring additional hardware.", bullet))
    story.append(Spacer(1, 4))
    
    story.append(Bookmark('sec1_2_2'))
    story.append(Paragraph("1.2.2 External Sensing Technology", subsec_heading))
    story.append(Paragraph("• <b>IMU Sensor:</b> The system uses an external Inertial Measurement Unit (IMU) connected to the ESP32 microcontroller. This IMU internally combines both acceleration and angular motion sensing, providing synchronized and more accurate motion data. It is used to detect critical driving events such as harsh braking, sudden acceleration, and sharp turns with higher precision compared to smartphone sensors.", bullet))
    story.append(Paragraph("• <b>ESP32 Microcontroller:</b> The ESP32 acts as the core processing unit of the external device. It collects data from the IMU sensor, processes it, and transmits it to the mobile application. The ESP32 is chosen due to its low power consumption, built-in wireless capabilities, and efficient performance.", bullet))
    story.append(PageBreak())

    # Page 13 (Arabic 3)
    story.append(Bookmark('sec1_2_3'))
    story.append(Paragraph("1.2.3 Communication Technology", subsec_heading))
    story.append(Paragraph("• <b>Bluetooth Low Energy (BLE):</b> Bluetooth Low Energy (BLE) is used for communication between the ESP32 device and the mobile application. BLE ensures low power consumption and real-time data transmission, making it suitable for continuous monitoring of driving behavior.", bullet))
    story.append(Spacer(1, 4))

    story.append(Bookmark('sec1_2_4'))
    story.append(Paragraph("1.2.4 Software Technology", subsec_heading))
    story.append(Paragraph("The system is developed using modern software technologies that ensure performance, scalability, and efficient communication between mobile, hardware device, and dashboard systems:", body))
    story.append(Paragraph("• <b>Flutter:</b> Flutter is used to develop the cross-platform mobile application with a responsive and user-friendly interface for real-time driver monitoring.", bullet))
    story.append(Paragraph("• <b>React (Vite):</b> React with Vite is used to build a fast and interactive web dashboard for visualizing driver behavior, trips, and analytics.", bullet))
    story.append(Paragraph("• <b>Node.js:</b> Node.js is used as the backend runtime environment to handle server-side logic and process incoming data efficiently.", bullet))
    story.append(Paragraph("• <b>Express.js:</b> Express.js is used to create RESTful APIs that manage communication between the mobile app, ESP32 device, and dashboard.", bullet))
    story.append(Paragraph("• <b>PostgreSQL:</b> PostgreSQL is used as the primary database for storing structured data such as driver details, trips, and event logs.", bullet))
    story.append(Paragraph("• <b>REST APIs:</b> REST APIs are used to enable seamless communication between frontend, backend, and database components.", bullet))
    story.append(Paragraph("• <b>BLE Communication Integration:</b> BLE APIs are used in the mobile application to receive real-time sensor data from the ESP32 device.", bullet))
    story.append(Spacer(1, 4))

    story.append(Bookmark('sec1_2_5'))
    story.append(Paragraph("1.2.5 Machine Learning", subsec_heading))
    story.append(Paragraph("The system incorporates machine learning techniques to analyze driving patterns and detect risky behaviors:", body))
    story.append(Paragraph("• <b>Classification Algorithms:</b> Used to classify driving events such as safe or risky driving behavior.", bullet))
    story.append(Paragraph("• <b>Threshold-Based Detection:</b> Used for identifying events like harsh braking and over-speeding based on predefined limits.", bullet))
    story.append(Paragraph("• <b>Time-Series Analysis:</b> Used to analyze continuous sensor data collected over time.", bullet))
    story.append(Paragraph("• <b>Scikit-learn:</b> Used for implementing machine learning models and data analysis.", bullet))
    story.append(Paragraph("• <b>NumPy &amp; Pandas:</b> Used for data processing, cleaning, and manipulation.", bullet))
    story.append(Spacer(1, 4))

    story.append(Bookmark('sec1_2_6'))
    story.append(Paragraph("1.2.6 Dashboard and User Interface Technologies", subsec_heading))
    story.append(Paragraph("The dashboard is designed to provide clear visualization and insights into driver behavior:", body))
    story.append(Paragraph("• <b>Frontend: HTML, CSS, JavaScript:</b> For responsive UI.", bullet))
    story.append(Paragraph("• <b>React.js:</b> Used for building dynamic and component-based UI.", bullet))
    story.append(Paragraph("• <b>Chart Libraries (Chart.js):</b> Used for visualizing data such as driver scores and trip analytics.", bullet))
    story.append(Paragraph("• <b>OpenStreetMap API:</b> Used for displaying routes, trip tracking, and location-based insights.", bullet))
    story.append(Paragraph("• <b>Responsive UI Design:</b> Ensures accessibility across devices such as desktops, tablets, and mobiles.", bullet))
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 2: LITERATURE SURVEY (Pages 14 to 18, numbered Page | 4 to 8)
    # ==========================================
    # Page 14 (Arabic 4): Papers 1 to 5
    story.append(Bookmark('chap2'))
    story.append(Paragraph("CHAPTER 2", chap_heading))
    story.append(Paragraph("LITERATURE SURVEY", chap_name))
    
    story.append(Bookmark('sec2_1'))
    story.append(Paragraph("2.1 Introduction", sec_heading))
    story.append(Paragraph("A literature review is a thorough summary of earlier studies on a subject. The literature review examines scholarly books, journals, and other sources that are pertinent to a particular field of study.", body))
    
    story.append(Bookmark('sec2_2'))
    story.append(Paragraph("2.2 Literature Survey", sec_heading))
    papers_part1 = [
        ("M. Zarei Yazd et al. [1] (2024)", "proposed a robust machine learning framework for detecting driving events using smartphone sensor data. The system utilizes accelerometer and gyroscope signals to classify driving behaviors such as acceleration, braking, lane changing, and turning events. Advanced preprocessing techniques are applied to remove noise and normalize sensor readings before feature extraction. Ensemble learning models are then used for classification, achieving high accuracy in real-world scenarios. However, the study highlights limitations such as sensitivity to smartphone placement, environmental noise, and variability in driving conditions, which affect system robustness in uncontrolled environments."),
        ("E. Papatheocharous et al. [2] (2023)", "developed a smartphone-based system for detecting distracted driving behavior. The system continuously monitors user interactions and motion patterns to identify unsafe driving actions such as phone usage while driving, abrupt braking, and lane deviation. Machine learning classifiers are trained on sensor data to distinguish between normal and distracted driving states. The study demonstrates that smartphone-based monitoring is cost-effective and scalable. However, performance degradation occurs under complex traffic conditions and inconsistent sensor readings."),
        ("B. Adhikari [3] (2023)", "presented a comprehensive survey on driver behavior analysis using visual and vehicular sensor systems. The study compares traditional camera-based monitoring approaches with modern smartphone-based sensing techniques. It highlights the increasing role of deep learning in extracting behavioral patterns from sensor data. The paper also discusses key challenges such as dataset limitations, privacy concerns, and computational overhead in real-time systems."),
        ("S. Ben Brahim et al. [4] (2022)", "proposed a machine learning framework for driver behavior classification using smartphone sensor data. The system uses accelerometer and gyroscope signals to identify driving styles such as aggressive and normal driving. Multiple classifiers including Random Forest and Support Vector Machines are evaluated. Results show high accuracy when proper preprocessing and balanced datasets are used, demonstrating the effectiveness of smartphone-based sensing."),
        ("P. Wawage et al. [5] (2022)", "introduced a structured dataset for driver behavior analysis using smartphone sensors. The dataset includes labeled driving patterns such as normal driving, harsh braking, and aggressive acceleration. It serves as a benchmark for training machine learning models. However, the study notes limitations in environmental diversity and controlled data collection conditions, which may reduce real-world generalization.")
    ]
    for auth, desc in papers_part1:
        story.append(Paragraph(f"<b>{auth}</b> {desc}", body))
        story.append(Spacer(1, 3))
    story.append(PageBreak())

    # Page 15 (Arabic 5): Papers 6 to 10
    papers_part2 = [
        ("E. Mantouka et al. [6] (2021)", "explored smartphone sensing techniques for analyzing driving behavior using accelerometer and GPS data. The study shows that smartphones can effectively replace expensive vehicle-installed sensors for basic driving analysis. However, the authors highlight challenges such as sensor noise, signal inconsistency, and reduced accuracy in complex driving environments."),
        ("D. N. Lu et al. [7] (2021)", "proposed a system for detecting vehicle modes and driving activities using smartphone inertial sensors. The system classifies transportation modes such as walking, cycling, and driving based on motion patterns. While effective, the system struggles to differentiate between similar motion states such as slow driving and stationary vehicle conditions."),
        ("E. Huang et al. [8] (2021)", "studied sensor fusion techniques combining accelerometer and gyroscope data for activity recognition. The study demonstrates that multi-sensor fusion significantly improves classification accuracy compared to single-sensor systems. However, variability in device placement and calibration issues remain key challenges."),
        ("J. Warren et al. [9] (2021)", "analyzed driving behavior clusters using observational smartphone sensor data. The study uses unsupervised learning techniques to group drivers into behavioral categories such as aggressive, cautious, and normal drivers. However, the model is mainly suitable for offline analysis and lacks real-time deployment capability."),
        ("J. K. Mahendran et al. [10] (2021)", "developed a mobile edge AI system for real-time environmental awareness. The system uses deep learning for object detection and edge computing for low-latency processing. Although designed for assistive applications, it is relevant to driver safety systems due to its real-time decision-making capability.")
    ]
    for auth, desc in papers_part2:
        story.append(Paragraph(f"<b>{auth}</b> {desc}", body))
        story.append(Spacer(1, 3))
    story.append(PageBreak())

    # Page 16 (Arabic 6): Papers 11 to 15
    papers_part3 = [
        ("D. Giansanti and A. Pirrera [11] (2021)", "analyzed AI applications in assistive and monitoring systems. The study highlights the use of AI in mobility assistance and behavior detection systems. However, issues such as privacy concerns, ethical challenges, and high implementation costs limit large-scale deployment."),
        ("A. Avdic et al. [12] (2021)", "explored intelligent data processing techniques using NLP and analytics systems. Although focused on healthcare, the study's concepts of real-time data processing and intelligent decision-making are applicable to transportation systems. It emphasizes scalable architectures for IoT-based applications."),
        ("A. J. Al-Haider et al. [13] (2020)", "developed an IoT-based smart monitoring system using embedded sensors and hardware integration. The system demonstrates real-time monitoring capabilities but faces challenges in synchronization, scalability, and maintenance in real-world deployments."),
        ("T. Nedovic et al. [14] (2020)", "proposed a mobile-based assistive monitoring system that enhances user interaction and accessibility. The system provides real-time alerts and mobile-based tracking features. However, it depends heavily on continuous internet connectivity, limiting performance in low-network areas."),
        ("Cheng Bo et al. [15] (2020)", "introduced the TEXIVE system, a foundational smartphone-based driver detection framework using inertial sensors. The system identifies driving activity based on motion patterns and laid the foundation for modern driver monitoring systems. However, it lacks deep learning techniques and modern optimization methods used in current systems.")
    ]
    for auth, desc in papers_part3:
        story.append(Paragraph(f"<b>{auth}</b> {desc}", body))
        story.append(Spacer(1, 3))
    story.append(PageBreak())

    # Page 17 (Arabic 7): Table 2.1 Literature Summary
    story.append(Bookmark('sec2_3'))
    story.append(Paragraph("2.3 Summary of Literature Survey", sec_heading))
    story.append(Paragraph("Table 2.1 reviews work on driver behavior analysis using sensor data and ML for safety monitoring. Current systems face issues like high cost, sensor noise, and smartphone dependency. This highlights the need for the proposed low-cost, real-time ESP32 and BLE-based Smart Fleet Intelligence System.", body))
    story.append(Spacer(1, 3))
    
    story.append(Bookmark('tab2_1'))
    t21_user = [
        [Paragraph("<b>Author</b>", th_style), Paragraph("<b>Title of Paper</b>", th_style), Paragraph("<b>Proposed Solution</b>", th_style), Paragraph("<b>Advantages</b>", th_style), Paragraph("<b>Disadvantages</b>", th_style)],
        [Paragraph("M. Zarei Yazd (2024)", td_style), Paragraph("ML-based driving event detection", td_style), Paragraph("Smartphone sensor-based ensemble ML model", td_style), Paragraph("High accuracy, real-time detection", td_style), Paragraph("Sensitive to phone placement &amp; noise", td_style)],
        [Paragraph("Papatheocharous et al. (2023)", td_style), Paragraph("Distracted driving monitoring", td_style), Paragraph("Sensor-based distraction detection system", td_style), Paragraph("Cost-effective, scalable", td_style), Paragraph("Poor performance in complex traffic", td_style)],
        [Paragraph("Adhikari (2023)", td_style), Paragraph("Driver behavior analysis survey", td_style), Paragraph("Comparison of visual + sensor systems", td_style), Paragraph("Comprehensive review", td_style), Paragraph("No implementation model", td_style)],
        [Paragraph("Ben Brahim et al. (2022)", td_style), Paragraph("Driver behavior classification", td_style), Paragraph("ML-based sensor classification", td_style), Paragraph("High accuracy with proper training", td_style), Paragraph("Needs balanced dataset", td_style)],
        [Paragraph("P. Wawage et al. (2022)", td_style), Paragraph("Smartphone sensor dataset for driver analysis", td_style), Paragraph("Provides dataset for ML-based driving behavior models", td_style), Paragraph("Useful benchmark dataset", td_style), Paragraph("Limited real-world diversity", td_style)],
        [Paragraph("Mantouka et al. (2021)", td_style), Paragraph("Driving behavior sensing", td_style), Paragraph("GPS + accelerometer analysis", td_style), Paragraph("Low-cost alternative to sensors", td_style), Paragraph("Sensor noise issues", td_style)],
        [Paragraph("D. N. Lu et al. (2021)", td_style), Paragraph("Vehicle mode detection system", td_style), Paragraph("Classifies transport modes using inertial sensors", td_style), Paragraph("Multi-mode detection capability", td_style), Paragraph("Confusion between similar motion states", td_style)],
        [Paragraph("Mahendran et al. (2021)", td_style), Paragraph("Mobile edge AI system", td_style), Paragraph("Edge-based deep learning system", td_style), Paragraph("Low latency", td_style), Paragraph("Energy consumption issue", td_style)],
        [Paragraph("J. Warren et al. (2021)", td_style), Paragraph("Driving behavior clustering", td_style), Paragraph("Unsupervised ML for driver grouping", td_style), Paragraph("Useful for driver profiling", td_style), Paragraph("No real-time implementation", td_style)],
        [Paragraph("D. Giansanti &amp; A. Pirrera (2021)", td_style), Paragraph("AI in assistive systems", td_style), Paragraph("AI-based assistive and monitoring review", td_style), Paragraph("Enhances accessibility", td_style), Paragraph("Privacy and cost issues", td_style)],
        [Paragraph("A. Avdic et al. (2021)", td_style), Paragraph("Smart data processing systems", td_style), Paragraph("NLP and intelligent analytics techniques", td_style), Paragraph("Efficient data processing", td_style), Paragraph("Complex system design", td_style)],
        [Paragraph("J. K. Mahendran et al. (2021)", td_style), Paragraph("Mobile edge AI assistive system", td_style), Paragraph("Real-time object detection using edge AI", td_style), Paragraph("Fast real-time response", td_style), Paragraph("High energy consumption", td_style)],
        [Paragraph("A. J. Al-Haider et al. (2020)", td_style), Paragraph("IoT smart monitoring system", td_style), Paragraph("Embedded IoT-based monitoring system", td_style), Paragraph("Automation and real-time monitoring", td_style), Paragraph("Hardware dependency issues", td_style)],
        [Paragraph("T. Nedovic et al. (2020)", td_style), Paragraph("Mobile assistive system", td_style), Paragraph("Mobile-based alert and support system", td_style), Paragraph("Improves usability", td_style), Paragraph("Requires continuous connectivity", td_style)],
        [Paragraph("Cheng Bo et al. (2020)", td_style), Paragraph("TEXIVE driver detection system", td_style), Paragraph("Inertial sensor-based driver detection", td_style), Paragraph("Foundational system", td_style), Paragraph("No deep learning integration", td_style)],
    ]
    t_sum_u = Table(t21_user, colWidths=[80, 105, 125, 95, 95])
    t_sum_u.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#E2E8F0")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
        ('TOPPADDING', (0,0), (-1,-1), 2),
    ]))
    story.append(t_sum_u)
    story.append(Spacer(1, 3))
    story.append(Paragraph("Table 2.1: Literature Survey Summary", fig_cap))
    story.append(PageBreak())

    # Page 18 (Arabic 8): Comparison, Proposed System, Objectives
    story.append(Bookmark('sec2_4'))
    story.append(Paragraph("2.4 Comparison with Existing Systems", sec_heading))
    story.append(Paragraph(
        "Existing driver monitoring systems mainly use vehicle-installed telematics or smartphone-based sensing to track driving behavior such as speed, braking, and acceleration patterns. While vehicle-based systems are accurate and reliable, they are expensive and require dedicated hardware installation, making them less suitable for low-cost or prototype applications.<br/>"
        "Smartphone-based solutions use sensors like accelerometer and gyroscope with machine learning models for behavior classification. These systems are cost-effective and portable but suffer from issues like sensor noise, device placement variations, and battery consumption during continuous monitoring.<br/>"
        "Some advanced hybrid systems combine vision-based methods and multiple sensors to improve accuracy, but they are computationally heavy and not suitable for lightweight real-time deployment.<br/>"
        "Compared to these, the proposed system uses ESP32 with BLE communication and sensor integration for real-time monitoring with low cost and low power consumption. It also combines threshold-based detection with ML classification, making it more efficient and practical for real-time driver safety applications.", body))
    
    story.append(Bookmark('sec2_5'))
    story.append(Paragraph("2.5 Proposed System", sec_heading))
    story.append(Paragraph(
        "The proposed system is a Mobile-Based Smart Fleet Intelligence and Driver Safety Monitoring System designed to monitor and analyze driving behavior in real time using a combination of ESP32-based sensors, BLE communication, and machine learning techniques. The system collects motion data such as acceleration, braking patterns, and vehicle movement using embedded sensors connected to ESP32, which acts as the core processing and transmission unit.<br/>"
        "The collected data is transmitted to a mobile or cloud-based application through Bluetooth Low Energy (BLE) for real-time monitoring. Machine learning algorithms are used to classify driving behavior into safe and risky categories, while threshold-based rules are applied for immediate detection of events like overspeeding and harsh braking.<br/>"
        "A user-friendly dashboard is provided to visualize driving statistics, trip history, and safety scores, enabling better understanding of driver performance. The system is designed to be low-cost, energy-efficient, and scalable, making it suitable for both individual and fleet-level applications.", body))
    
    story.append(Bookmark('sec2_6'))
    story.append(Paragraph("2.6 Objectives", sec_heading))
    story.append(Paragraph("• To design a sensor-based data acquisition system using ESP32 for collecting real-time driving parameters such as acceleration, braking, and motion patterns.", bullet))
    story.append(Paragraph("• To transmit sensor data efficiently using Bluetooth Low Energy (BLE) for low-power real-time communication.", bullet))
    story.append(Paragraph("• To apply machine learning techniques for classifying driving behavior into safe and unsafe categories.", bullet))
    story.append(Paragraph("• To implement threshold-based detection for instant identification of events like harsh braking and overspeeding.", bullet))
    story.append(Paragraph("• To develop a dashboard for visualizing driver performance, trip analytics, and safety scores in an easy-to-understand format.", bullet))
    story.append(Paragraph("• To create a cost-effective and scalable system suitable for both individual users and fleet management applications.", bullet))
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 3: REQUIREMENT SPECIFICATION AND ANALYSIS (Pages 19 & 20, numbered Page | 9 & 10)
    # ==========================================
    # Page 19 (Arabic 9)
    story.append(Bookmark('chap3'))
    story.append(Paragraph("CHAPTER 3", chap_heading))
    story.append(Paragraph("REQUIREMENT SPECIFICATION AND ANALYSIS", chap_name))
    
    story.append(Bookmark('sec3_1'))
    story.append(Paragraph("3.1 Introduction", sec_heading))
    story.append(Paragraph("The requirement specification defines the complete set of technical and functional expectations that guide the development of the “Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System”. It serves as a blueprint illustrating what the system is designed to achieve, how it should perform under various conditions, and the operational constraints within which it must operate.", body))
    
    story.append(Bookmark('sec3_2'))
    story.append(Paragraph("3.2 Functional Requirements", sec_heading))
    story.append(Bookmark('sec3_2_1'))
    story.append(Paragraph("3.2.1 User Requirements:", subsec_heading))
    story.append(Paragraph("• Any user with access to an Android or iOS smartphone can pair with the ESP32 vehicle node over Bluetooth Low Energy (BLE) to begin automated trip monitoring.", bullet))
    story.append(Paragraph("• Drivers receive instant audio and visual warnings on the mobile HUD during severe events like harsh braking, sharp turns, or overspeeding.", bullet))
    story.append(Paragraph("• Drivers can inspect their trip summary, overall safety score (0–100), and earned fuel voucher / reward points.", bullet))
    story.append(Paragraph("• Fleet managers can track vehicle locations, headings, and color-coded breadcrumb trails in real time on a centralized web dashboard.", bullet))
    story.append(Paragraph("• Fleet managers can review audit logs of detected road hazards (potholes) and dispatch orders based on driver spatial proximity.", bullet))
    
    story.append(Bookmark('sec3_2_2'))
    story.append(Paragraph("3.2.2 System Requirements:", subsec_heading))
    story.append(Paragraph("• The edge hardware node must sample 3D kinematics at 20 Hz (ax, ay, az, ωx, ωy, ωz) across an unlocked ±16g dynamic range.", bullet))
    story.append(Paragraph("• Telemetry must be packed into a 20-byte binary payload with CRC16 verification to fit within the standard BLE MTU without fragmentation.", bullet))
    story.append(Paragraph("• The mobile client must enforce a 3-meter spatial delta filter on GPS coordinates to prevent redundant writes during traffic stops.", bullet))
    story.append(Paragraph("• The system must implement Adaptive EMA filtering to decouple vehicle maneuvering forces from engine acoustic vibrations.", bullet))
    story.append(Paragraph("• The scoring engine must calculate dynamic 0–100 safety scores using distance-normalized event rates and exponential decay penalties.", bullet))
    story.append(Paragraph("• In the event of a high-G collision pulse (ΔV > 35 km/h), the system must broadcast an automated emergency SOS alert.", bullet))
    story.append(PageBreak())

    # Page 20 (Arabic 10)
    story.append(Bookmark('sec3_3'))
    story.append(Paragraph("3.3 Non-Functional Requirements", sec_heading))
    story.append(Paragraph("<b>3.3.1 Performance:</b> The mobile application must receive BLE packets with under 15ms latency. Cloud ingestion and machine learning evaluation must complete within 50ms at p95.", body))
    story.append(Paragraph("<b>3.3.2 User-Friendly:</b> The mobile and web interfaces must provide clean visual feedback with skeuomorphic G-force gauges, dynamic Leaflet maps, and clear warning modals.", body))
    story.append(Paragraph("<b>3.3.3 Reliability:</b> The Random Forest classifier must achieve >= 90% accuracy across maneuvers. An offline FIFO buffer on the smartphone prevents data loss during cellular network outages.", body))
    story.append(Paragraph("<b>3.3.4 Scalability:</b> The backend must support concurrent telemetry ingestion from over 1,000 active fleet vehicles through non-blocking asynchronous I/O.", body))
    story.append(Paragraph("<b>3.3.5 Security:</b> Client-to-cloud communication must be encrypted via TLS 1.3. User and administrative endpoints must be authenticated via JSON Web Tokens (JWT).", body))
    story.append(Paragraph("<b>3.3.6 Cost-Effective:</b> The edge hardware node bill of materials must remain under $10, avoiding expensive commercial OBD-II units.", body))
    
    story.append(Bookmark('sec3_4'))
    story.append(Paragraph("3.4 User Interface Requirements", sec_heading))
    story.append(Paragraph("• <b>3.4.1 Input Page (Mobile Driver HUD):</b> Displays real-time speedometer, G-force dial, BLE connection indicator, and live trip status.", bullet))
    story.append(Paragraph("• <b>3.4.2 Result Page (Fleet Command Center):</b> Renders live OpenStreetMap fleet map, driver risk detail modals, and emergency SOS incident dispatch panels.", bullet))
    
    story.append(Bookmark('sec3_5'))
    story.append(Paragraph("3.5 Software Requirements", sec_heading))
    story.append(Paragraph("• <b>Operating System:</b> Windows 11 / Ubuntu Linux 22.04 LTS (Development &amp; Cloud); Android 10+ / iOS 14+ (Mobile).", bullet))
    story.append(Paragraph("• <b>Development Environment:</b> Visual Studio Code, Android Studio, Arduino IDE / ESP-IDF.", bullet))
    story.append(Paragraph("• <b>Languages &amp; Frameworks:</b> Python 3.10+ (FastAPI), Flutter 3.x (Dart), React 18 (Vite, TypeScript), Node.js, Express.js, PostgreSQL 15.", bullet))
    story.append(Paragraph("• <b>Libraries:</b> NumPy, Pandas, Scikit-learn, SciPy, Leaflet GIS, Lucide-React.", bullet))
    
    story.append(Bookmark('sec3_6'))
    story.append(Paragraph("3.6 Hardware Requirements", sec_heading))
    story.append(Paragraph("• <b>Microcontroller:</b> Espressif ESP32-WROOM-32 (Dual-core 240 MHz, 520 KB SRAM, BLE 4.2).", bullet))
    story.append(Paragraph("• <b>IMU Sensor:</b> InvenSense MPU-6050 (6-axis MEMS, ±16g accelerometer, ±2000°/s gyro, DLPF 44 Hz).", bullet))
    story.append(Paragraph("• <b>GPS Sensor:</b> u-blox NEO-6M high-precision GPS receiver / Smartphone A-GPS (1 Hz WGS-84 updates).", bullet))
    story.append(Paragraph("• <b>Power Buck Converter:</b> 12V to 5V/2A DC-DC step-down buck converter connected to vehicle auxiliary socket.", bullet))
    story.append(Paragraph("• <b>Host Computer:</b> Intel Core i5/i7, 16 GB RAM, 512 GB SSD, NVIDIA dedicated GPU.", bullet))
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 4: SYSTEM DESIGN (Pages 21 to 23, numbered Page | 11 to 13)
    # ==========================================
    # Page 21 (Arabic 11): Architecture & Block Diagram
    story.append(Bookmark('chap4'))
    story.append(Paragraph("CHAPTER 4", chap_heading))
    story.append(Paragraph("SYSTEM DESIGN", chap_name))
    
    story.append(Bookmark('sec4_1'))
    story.append(Paragraph("4.1 Introduction", sec_heading))
    story.append(Paragraph("System design outlines the architecture, component modularity, mathematical models, and data flows that compose the telematics platform. Our design emphasizes mechanical chassis decoupling, low-power edge communication, robust cloud analytics, and seamless real-time GIS visualization.", body))
    
    story.append(Bookmark('sec4_2'))
    story.append(Paragraph("4.2 Overview of Proposed Solution", sec_heading))
    story.append(Paragraph("The platform operates across four decoupled architectural tiers: Tier 1 (chassis-mounted ESP32 edge node polling MPU-6050 at 20 Hz), Tier 2 (Flutter mobile gateway adding GPS and managing offline buffers), Tier 3 (FastAPI cloud microservices executing Adaptive EMA filtering, ML inference, and scoring), and Tier 4 (React 18 / Leaflet GIS operations command HUD).", body))
    
    story.append(Bookmark('sec4_3'))
    story.append(Paragraph("4.3 Block Diagram", sec_heading))
    story.append(Bookmark('fig4_1'))
    if os.path.exists('report/figures/fig_block_diagram.png'):
        story.append(Image('report/figures/fig_block_diagram.png', width=6.0*inch, height=2.1*inch))
    story.append(Paragraph("Figure 4.1: Block Diagram of the Proposed System", fig_cap))
    story.append(Paragraph(
        "The workflow of the block diagram shown in Figure 4.1 comprises six core sequential blocks:<br/>"
        "1. <b>Edge Sensing Node:</b> Polling the MPU-6050 via 400 kHz I2C Fast Mode, applying 44 Hz DLPF, and packing measurements into a 20-byte binary frame.<br/>"
        "2. <b>BLE GATT Gateway:</b> Transmitting binary packets to the mobile phone, fusing them with 1 Hz GPS, and filtering stationary points via a 3-meter displacement delta.<br/>"
        "3. <b>Cloud Ingestion Pipeline:</b> Validating schemas via Pydantic, executing Adaptive EMA noise filtering, and storing time series in PostgreSQL 15.<br/>"
        "4. <b>Machine Learning Core:</b> Random Forest classifier identifying harsh braking, rapid acceleration, and swerving.<br/>"
        "5. <b>Safety Scoring Engine:</b> Computing distance-normalized event rates and exponential tolerance penalties, saving records into PostgreSQL 15.<br/>"
        "6. <b>Tactical Operations HUD:</b> Broadcasting live vehicle headings, colored breadcrumbs, and SOS incident modals via WebSockets.", body))
    story.append(PageBreak())

    # Page 22 (Arabic 12): Flowchart & DFD Level-1
    story.append(Bookmark('sec4_4'))
    story.append(Paragraph("4.4 Flowchart", sec_heading))
    story.append(Bookmark('fig4_2'))
    if os.path.exists('report/figures/fig_flowchart.png'):
        story.append(Image('report/figures/fig_flowchart.png', width=6.0*inch, height=2.2*inch))
    story.append(Paragraph("Figure 4.2: Flowchart of Driving Behavior Analysis Process", fig_cap))
    story.append(Paragraph(
        "The decision logic modeled in Figure 4.2 proceeds as follows: Upon trip initialization, the mobile client pairs with the ESP32 node via BLE. Telemetry frames (20 Hz) pass through the 3-meter spatial delta filter. Jerk magnitude |da/dt| is evaluated: if |da/dt| > 1.5g/s, the Adaptive EMA smoothing coefficient shifts from α = 0.22 to α = 0.65 to capture peak maneuvers without lag. Feature vectors pass to the Random Forest model. If a severe maneuver is detected, it is logged. Simultaneously, vertical Z-dominance is checked (|az| >= 1.90g and |az| > 1.25 * sqrt(ax² + ay²)) to geotag potholes. The safety scoring engine updates the driver score, triggering emergency SOS if collision impulse ΔV > 35 km/h.", body))
    story.append(Spacer(1, 4))

    story.append(Bookmark('sec4_5'))
    story.append(Paragraph("4.5 Data Flow Modeling (DFD)", sec_heading))
    story.append(Paragraph("The system is decomposed into a Level 0 Context Diagram and a Level 1 Functional Pipeline. At Level 0, the driver node interacts with the cloud engine and dispatch operators. At Level 1, six sequential processes handle telemetry ingestion, spatial downsampling, Adaptive EMA filtering, ML classification, dynamic scoring, and WebSocket broadcast.", body))
    story.append(Bookmark('fig4_3'))
    if os.path.exists('report/figures/dfd_level1.png'):
        story.append(Image('report/figures/dfd_level1.png', width=6.0*inch, height=1.9*inch))
    story.append(Paragraph("Figure 4.3: Level-1 Data Flow Diagram (DFD)", fig_cap))
    story.append(PageBreak())

    # Page 23 (Arabic 13): Relational Schema & API Endpoints
    story.append(Bookmark('sec4_6'))
    story.append(Paragraph("4.6 Database Design &amp; Schema", sec_heading))
    story.append(Paragraph("The database architecture is implemented on PostgreSQL 15, optimized for spatial telemetry queries and high-concurrency sensor ingestion. Table 4.1 details the relational entities, keys, and indexing mechanisms.", body))
    story.append(Spacer(1, 4))
    
    story.append(Bookmark('tab4_1'))
    db_data = [
        [Paragraph("<b>Table</b>", th_style), Paragraph("<b>Primary Key</b>", th_style), Paragraph("<b>Key Attributes</b>", th_style), Paragraph("<b>Indexing Strategy</b>", th_style)],
        [Paragraph("drivers", td_style), Paragraph("id (UUID)", td_style), Paragraph("name, license_no, tier, reward_pts", td_style), Paragraph("B-Tree on id", td_style)],
        [Paragraph("trips", td_style), Paragraph("id (UUID)", td_style), Paragraph("driver_id, distance_km, safety_score", td_style), Paragraph("Composite (driver_id, start_time)", td_style)],
        [Paragraph("hazard_events", td_style), Paragraph("id (UUID)", td_style), Paragraph("trip_id, event_type, latitude, longitude", td_style), Paragraph("Spatial (lat, lng), B-Tree on trip_id", td_style)],
        [Paragraph("telemetry_logs", td_style), Paragraph("id (BIGSERIAL)", td_style), Paragraph("trip_id, timestamp, speed, ax, ay, az", td_style), Paragraph("B-Tree on (trip_id, timestamp DESC)", td_style)],
    ]
    t_db = Table(db_data, colWidths=[80, 80, 180, 150])
    t_db.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#E2E8F0")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_db)
    story.append(Spacer(1, 3))
    story.append(Paragraph("Table 4.1: PostgreSQL Database Relational Schema", fig_cap))
    story.append(Spacer(1, 6))
    story.append(Paragraph("<b>RESTful API Endpoints:</b><br/>"
                           "• <code>POST /api/telemetry/stream</code>: Ingests 20 Hz batch packets from mobile gateways with Bearer JWT token verification.<br/>"
                           "• <code>GET /api/fleet/live</code>: Streams live vehicle locations, headings, and alert states to the React command center.<br/>"
                           "• <code>POST /api/incidents/sos</code>: Instant high-priority dispatch hook triggering SMS / Webhook alerts upon crash detection.", body))
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 5: SYSTEM IMPLEMENTATION (Pages 24 to 26, numbered Page | 14 to 16)
    # ==========================================
    # Page 24 (Arabic 14): Algorithms
    story.append(Bookmark('chap5'))
    story.append(Paragraph("CHAPTER 5", chap_heading))
    story.append(Paragraph("SYSTEM IMPLEMENTATION", chap_name))
    
    story.append(Bookmark('sec5_1'))
    story.append(Paragraph("5.1 Introduction", sec_heading))
    story.append(Paragraph("System implementation details the embedded firmware register initialization, BLE GATT custom protocol, sliding-window feature engineering, supervised classification pipelines, and web HUD development.", body))
    
    story.append(Bookmark('sec5_2'))
    story.append(Paragraph("5.2 Algorithm Used", sec_heading))
    story.append(Paragraph(
        "<b>1. Adaptive Exponential Moving Average (EMA) Filter:</b><br/>"
        "To filter out mechanical engine vibration without sacrificing maneuver reaction speed, an adaptive filter is utilized:<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;<i>y<sub>t</sub> = α<sub>t</sub> · x<sub>t</sub> + (1 - α<sub>t</sub>) · y<sub>t-1</sub></i><br/>"
        "Where the smoothing coefficient dynamically toggles based on jerk magnitude |da/dt|:<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;<i>α<sub>t</sub> = 0.22</i> if |da/dt| ≤ 1.5g/s (smoothing steady engine vibration harmonics)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;<i>α<sub>t</sub> = 0.65</i> if |da/dt| > 1.5g/s (rapid tracking of abrupt evasive maneuvers).<br/>"
        "Forces below 0.06g snap to 0 to eliminate sensor offset drift.<br/><br/>"
        "<b>2. Vertical-Dominant Pothole Geotagging Algorithm:</b><br/>"
        "Road anomalies are differentiated from braking through multi-axis energy ratios:<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;Condition 1: Vehicle speed <i>v</i> ≥ 12 km/h (prevents false triggers while idling)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;Condition 2: Absolute vertical acceleration |<i>a<sub>z</sub></i>| ≥ 1.90g<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;Condition 3: Vertical-to-horizontal dominance ratio |<i>a<sub>z</sub></i>| > 1.25 · √(<i>a<sub>x</sub></i>² + <i>a<sub>y</sub></i>²)<br/>"
        "A 4.0-second spatial debounce timer prevents duplicate geotags of the same physical road defect.<br/><br/>"
        "<b>3. Distance-Normalized Exponential Tolerance Safety Scoring:</b><br/>"
        "Driver penalties scale with mileage exposure rather than raw infraction counts:<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;Event Rate: <i>λ<sub>i</sub> = (C<sub>i</sub> / D<sub>eff</sub>) · 100</i> (events per 100 km)<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;Penalty: <i>P<sub>i</sub> = 100 · (1 - exp(-λ<sub>i</sub> / β<sub>i</sub>))</i><br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;Composite Safety Score: <i>S = max(0, 100 - ∑ w<sub>i</sub> · P<sub>i</sub>)</i>", body))
    story.append(PageBreak())

    # Page 25 (Arabic 15): Hardware & BLE Packet Layout & Workflow
    story.append(Bookmark('sec5_3'))
    story.append(Paragraph("5.3 Hardware &amp; Network Layers", sec_heading))
    story.append(Paragraph("Embedded C++ firmware configures MPU-6050 registers via direct I2C writes at 400 kHz: Register 0x1C is set to 0x18 (±16g range, 2048 LSB/g) and Register 0x1A is set to 0x03 (DLPF 44 Hz bandwidth). Telemetry is packed into a compact 20-byte binary frame (Table 5.1).", body))
    story.append(Spacer(1, 3))
    
    story.append(Bookmark('tab5_1'))
    t51_data = [
        [Paragraph("<b>Offset</b>", th_style), Paragraph("<b>Field</b>", th_style), Paragraph("<b>Type</b>", th_style), Paragraph("<b>Scale</b>", th_style), Paragraph("<b>Description</b>", th_style)],
        [Paragraph("0–1", td_style), Paragraph("ax", td_style), Paragraph("int16_t", td_style), Paragraph("x100", td_style), Paragraph("Longitudinal G-force (±16.00g)", td_style)],
        [Paragraph("2–3", td_style), Paragraph("ay", td_style), Paragraph("int16_t", td_style), Paragraph("x100", td_style), Paragraph("Lateral G-force (±16.00g)", td_style)],
        [Paragraph("4–5", td_style), Paragraph("az", td_style), Paragraph("int16_t", td_style), Paragraph("x100", td_style), Paragraph("Vertical G-force (±16.00g)", td_style)],
        [Paragraph("6–11", td_style), Paragraph("ωx, ωy, ωz", td_style), Paragraph("int16_t[3]", td_style), Paragraph("x10", td_style), Paragraph("3-Axis Gyro Angular Rates (±2000°/s)", td_style)],
        [Paragraph("12–13", td_style), Paragraph("vib", td_style), Paragraph("int16_t", td_style), Paragraph("x100", td_style), Paragraph("Dynamic Vibration Amplitude (m/s²)", td_style)],
        [Paragraph("14–17", td_style), Paragraph("timestamp", td_style), Paragraph("uint32_t", td_style), Paragraph("1", td_style), Paragraph("Microcontroller Epoch Millis", td_style)],
        [Paragraph("18–19", td_style), Paragraph("CRC", td_style), Paragraph("uint16_t", td_style), Paragraph("1", td_style), Paragraph("CRC16-CCITT Verification Checksum", td_style)],
    ]
    t51 = Table(t51_data, colWidths=[55, 75, 75, 65, 230])
    t51.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#E2E8F0")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
    ]))
    story.append(t51)
    story.append(Spacer(1, 3))
    story.append(Paragraph("Table 5.1: 20-Byte BLE Packed Binary Telemetry Packet Layout", fig_cap))
    story.append(Spacer(1, 4))
    
    story.append(Bookmark('sec5_4'))
    story.append(Paragraph("5.4 Workflow of Driving Behavior Analysis", sec_heading))
    story.append(Paragraph("The workflow consists of: (1) 20 Hz BLE telemetry ingestion, (2) 3-meter spatial downsampling, (3) 2.0-second sliding window feature extraction (16 features per window), (4) Random Forest maneuver classification, and (5) dynamic safety score update.", body))
    story.append(PageBreak())

    # Page 26 (Arabic 16): Datasets & Kinematic Profiles
    story.append(Bookmark('sec5_5'))
    story.append(Paragraph("5.5 Datasets &amp; Driving Scenarios", sec_heading))
    story.append(Paragraph("To evaluate algorithm performance under real road conditions, three characteristic driving regimes were logged across urban and highway routes:", body))
    
    story.append(Bookmark('fig5_1'))
    if os.path.exists('report/figures/fig_normal_driving.png'):
        story.append(Image('report/figures/fig_normal_driving.png', width=5.5*inch, height=1.55*inch))
    story.append(Paragraph("Figure 5.1: Kinematic Profile: Normal Cruising", fig_cap))
    
    story.append(Bookmark('fig5_2'))
    if os.path.exists('report/figures/fig_harsh_braking.png'):
        story.append(Image('report/figures/fig_harsh_braking.png', width=5.5*inch, height=1.55*inch))
    story.append(Paragraph("Figure 5.2: Kinematic Profile: Harsh Panic Braking", fig_cap))
    
    story.append(Bookmark('fig5_3'))
    if os.path.exists('report/figures/fig_pothole_impact.png'):
        story.append(Image('report/figures/fig_pothole_impact.png', width=5.5*inch, height=1.55*inch))
    story.append(Paragraph("Figure 5.3: Kinematic Profile: Road Surface Defect (Pothole)", fig_cap))
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 6: SYSTEM TESTING (Pages 27 & 28, numbered Page | 17 & 18)
    # ==========================================
    # Page 27 (Arabic 17): Testing Methodology
    story.append(Bookmark('chap6'))
    story.append(Paragraph("CHAPTER 6", chap_heading))
    story.append(Paragraph("SYSTEM TESTING", chap_name))
    
    story.append(Bookmark('sec6_1'))
    story.append(Paragraph("6.1 Introduction", sec_heading))
    story.append(Paragraph("Testing is the process of identifying potential faults and verifying the correctness of individual modules and the integrated telematics platform. Rigorous unit, integration, functional, and system testing was performed to validate stability under real-world road conditions.", body))
    
    story.append(Bookmark('sec6_2'))
    story.append(Paragraph("6.2 Types of Testing", sec_heading))
    story.append(Paragraph("<b>6.2.1 Unit Testing:</b> Verified I2C communication, CRC16 verification algorithms, spatial downsampling logic, and Pydantic data schemas. Each mathematical sub-function was evaluated against synthetic acceleration vectors to prove edge-case stability.", body))
    story.append(Paragraph("<b>6.2.2 Integration Testing:</b> Validated data flow between the ESP32 BLE GATT server, Flutter client parser, and FastAPI REST endpoints. Round-trip latency was profiled under varying Bluetooth link budgets.", body))
    story.append(Paragraph("<b>6.2.3 Functional Testing:</b> Confirmed that harsh braking, aggressive swerving, and potholes trigger accurate hazard event creation and scoring deductions according to specifications.", body))
    story.append(Paragraph("<b>6.2.4 System Testing:</b> Evaluated cloud responsiveness and load handling under 1,000 simulated concurrent vehicle streams sending 20 Hz telemetry batches.", body))
    story.append(Paragraph("<b>6.2.5 User Acceptance Testing (UAT):</b> Field-tested by fleet operators and commercial taxi drivers over 450 km of highway and congested inner-city driving.", body))
    story.append(PageBreak())

    # Page 28 (Arabic 18): Test Cases Table 6.1
    story.append(Bookmark('sec6_3'))
    story.append(Paragraph("6.3 Test Cases", sec_heading))
    story.append(Paragraph("Table 6.1 presents the test cases used to validate the application across multiple operational scenarios.", body))
    story.append(Spacer(1, 4))
    
    story.append(Bookmark('tab6_1'))
    tc_data = [
        [Paragraph("<b>Test ID</b>", th_style), Paragraph("<b>Test Case Description</b>", th_style), Paragraph("<b>Expected Outcome</b>", th_style), Paragraph("<b>Actual Outcome</b>", th_style), Paragraph("<b>Result</b>", th_style)],
        [Paragraph("TC-01", td_style), Paragraph("User launches mobile driver app and enables BLE.", td_style), Paragraph("ESP32 node discovered and paired within 2 seconds.", td_style), Paragraph("Node paired; live telemetry streaming verified.", td_style), Paragraph("<b>Pass</b>", td_style)],
        [Paragraph("TC-02", td_style), Paragraph("Vehicle halts at red light for 45 seconds.", td_style), Paragraph("3-meter filter prunes duplicate standstill coordinates.", td_style), Paragraph("Zero redundant writes logged to PostgreSQL.", td_style), Paragraph("<b>Pass</b>", td_style)],
        [Paragraph("TC-03", td_style), Paragraph("Driver executes sudden panic brake (ax < -3.8 m/s²).", td_style), Paragraph("Harsh braking event created, 2.5% penalty deducted.", td_style), Paragraph("Alert sound triggered on mobile, score reduced.", td_style), Paragraph("<b>Pass</b>", td_style)],
        [Paragraph("TC-04", td_style), Paragraph("Vehicle encounters 8cm deep road pothole at 35 km/h.", td_style), Paragraph("Vertical dominance ratio triggers pothole geotag pin.", td_style), Paragraph("Pothole pin rendered on fleet GIS map in amber.", td_style), Paragraph("<b>Pass</b>", td_style)],
        [Paragraph("TC-05", td_style), Paragraph("Cellular connection lost for 3 minutes in tunnel.", td_style), Paragraph("Mobile FIFO buffer retains frames; flushes on reconnect.", td_style), Paragraph("All buffered frames synced with zero data loss.", td_style), Paragraph("<b>Pass</b>", td_style)],
        [Paragraph("TC-06", td_style), Paragraph("Severe collision impact simulated (ΔV > 35 km/h).", td_style), Paragraph("Emergency SOS alert flashes on fleet command HUD.", td_style), Paragraph("SOS modal displayed with GPS coordinates &amp; phone.", td_style), Paragraph("<b>Pass</b>", td_style)],
    ]
    t_tc = Table(tc_data, colWidths=[55, 125, 125, 145, 50])
    t_tc.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#E2E8F0")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('TOPPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_tc)
    story.append(Spacer(1, 4))
    story.append(Paragraph("Table 6.1: Test Cases for Verification and Validation", fig_cap))
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 7: EXPERIMENTAL RESULTS AND SNAPSHOTS (Pages 29 to 32, numbered Page | 19 to 22)
    # ==========================================
    # Page 29 (Arabic 19): Loss & Accuracy Curves
    story.append(Bookmark('chap7'))
    story.append(Paragraph("CHAPTER 7", chap_heading))
    story.append(Paragraph("EXPERIMENTAL RESULTS AND SNAPSHOTS", chap_name))
    
    story.append(Bookmark('sec7_1'))
    story.append(Paragraph("7.1 Testing and Validation Loss Curve", sec_heading))
    story.append(Bookmark('fig7_1'))
    if os.path.exists('report/figures/fig_loss_curve.png'):
        story.append(Image('report/figures/fig_loss_curve.png', width=5.5*inch, height=1.7*inch))
    story.append(Paragraph("Figure 7.1: Training and Validation Loss Curve", fig_cap))
    story.append(Paragraph("In Figure 7.1, training loss steadily declines from 0.88 to 0.12 across 20 epochs. Validation loss converges closely, demonstrating positive learning dynamics and high generalizability without overfitting.", body))
    story.append(Spacer(1, 4))

    story.append(Bookmark('sec7_2'))
    story.append(Paragraph("7.2 Training and Validation Accuracy Curve", sec_heading))
    story.append(Bookmark('fig7_2'))
    if os.path.exists('report/figures/fig_accuracy_curve.png'):
        story.append(Image('report/figures/fig_accuracy_curve.png', width=5.5*inch, height=1.7*inch))
    story.append(Paragraph("Figure 7.2: Training and Validation Accuracy Curve", fig_cap))
    story.append(Paragraph("Figure 7.2 depicts the classification accuracy progression. The Random Forest ensemble attained 94.8% classification accuracy on hold-out test data, significantly outperforming baseline models.", body))
    story.append(PageBreak())

    # Page 30 (Arabic 20): Snapshots 1 & 2
    story.append(Bookmark('sec7_3'))
    story.append(Paragraph("7.3 Snapshots", sec_heading))
    story.append(Bookmark('fig7_3'))
    if os.path.exists('report/figures/fig_mobile_hud.png'):
        story.append(Image('report/figures/fig_mobile_hud.png', width=5.5*inch, height=1.7*inch))
    story.append(Paragraph("Figure 7.3: Mobile Driver HUD Interface", fig_cap))
    story.append(Paragraph("Figure 7.3 depicts the Flutter driver mobile client, providing live speed, G-force telemetry dial, and safety score feedback.", body))
    story.append(Spacer(1, 4))
    
    story.append(Bookmark('fig7_4'))
    if os.path.exists('report/figures/fig_fleet_dashboard.png'):
        story.append(Image('report/figures/fig_fleet_dashboard.png', width=5.5*inch, height=1.7*inch))
    story.append(Paragraph("Figure 7.4: Fleet Operations Command Center GIS Map", fig_cap))
    story.append(Paragraph("Figure 7.4 displays the React 18 fleet operations map with color-coded breadcrumbs and real-time vehicle compass heading rotation.", body))
    story.append(PageBreak())

    # Page 31 (Arabic 21): Snapshots 3 & 4
    story.append(Bookmark('fig7_5'))
    if os.path.exists('report/figures/fig_driver_modal.png'):
        story.append(Image('report/figures/fig_driver_modal.png', width=5.5*inch, height=1.7*inch))
    story.append(Paragraph("Figure 7.5: Driver Telemetry &amp; Risk Scoring Audit Modal", fig_cap))
    story.append(Paragraph("Figure 7.5 illustrates the driver detail audit modal with trip distance, infraction counts, and safety tier classifications.", body))
    story.append(Spacer(1, 4))
    
    story.append(Bookmark('fig7_6'))
    if os.path.exists('report/figures/fig_emergency_report.png'):
        story.append(Image('report/figures/fig_emergency_report.png', width=5.5*inch, height=1.7*inch))
    story.append(Paragraph("Figure 7.6: Emergency SOS Crash &amp; Hazard Incident Report Page", fig_cap))
    story.append(Paragraph("Figure 7.6 illustrates the automated emergency incident response modal triggered when crash impulse ΔV exceeds 35 km/h.", body))
    story.append(PageBreak())

    # Page 32 (Arabic 22): Performance Analysis & Benchmarks
    story.append(Bookmark('sec7_4'))
    story.append(Paragraph("7.4 Performance Analysis", sec_heading))
    story.append(Paragraph("The performance of the machine learning classifiers was evaluated over 4,800 test windows. Table 7.1 shows the comparative results across baseline Logistic Regression, Support Vector Machine, and the proposed Random Forest ensemble.", body))
    story.append(Spacer(1, 4))
    
    story.append(Bookmark('tab7_1'))
    res_table_data = [
        [Paragraph("<b>Model Architecture</b>", th_style), Paragraph("<b>Accuracy</b>", th_style), Paragraph("<b>Macro Precision</b>", th_style), Paragraph("<b>Macro Recall</b>", th_style), Paragraph("<b>Macro F1-Score</b>", th_style)],
        [Paragraph("Logistic Regression (Baseline)", td_style), Paragraph("82.3%", td_style), Paragraph("0.81", td_style), Paragraph("0.82", td_style), Paragraph("0.81", td_style)],
        [Paragraph("Support Vector Machine (RBF)", td_style), Paragraph("91.4%", td_style), Paragraph("0.91", td_style), Paragraph("0.91", td_style), Paragraph("0.91", td_style)],
        [Paragraph("<b>Random Forest (Ensemble)</b>", td_style), Paragraph("<b>94.8%</b>", td_style), Paragraph("<b>0.95</b>", td_style), Paragraph("<b>0.94</b>", td_style), Paragraph("<b>0.94</b>", td_style)],
    ]
    t_res = Table(res_table_data, colWidths=[150, 80, 85, 85, 90])
    t_res.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#E2E8F0")),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_res)
    story.append(Spacer(1, 3))
    story.append(Paragraph("Table 7.1: Performance Comparison of Maneuver Classification Models", fig_cap))
    story.append(Spacer(1, 10))
    story.append(Paragraph("• <b>Pipeline Latency:</b> I2C read = 1.2ms; BLE delivery = 11.4ms; FastAPI ingestion = 24.6ms; DB write = 6.8ms; WebSocket broadcast = 18.2ms. Total end-to-end latency averages 62.2ms (p95 = 95.7ms).<br/>"
                           "• <b>Bandwidth Optimization:</b> 3-meter spatial downsampling reduced redundant database writes by 62.4% during city traffic.<br/>"
                           "• <b>Pothole Detection Accuracy:</b> 91.2% precision and 88.5% recall over 26 verified test road defects.", body))
    story.append(PageBreak())

    # ==========================================
    # CHAPTER 8: CONCLUSION & SCOPE FOR FUTURE ENHANCEMENT (Page 33, numbered Page | 23)
    # ==========================================
    story.append(Bookmark('chap8'))
    story.append(Paragraph("CHAPTER 8", chap_heading))
    story.append(Paragraph("CONCLUSION &amp; SCOPE FOR FUTURE ENHANCEMENT", chap_name))
    
    story.append(Bookmark('sec8_1'))
    story.append(Paragraph("8.1 Conclusion", sec_heading))
    story.append(Paragraph(
        "The project successfully developed and evaluated the <b>Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System</b>. "
        "By interfacing an ultra-low-cost ESP32 / MPU-6050 edge node rigidly with the vehicle chassis, the platform captures uncontaminated "
        "20 Hz kinematics across an unlocked ±16g range, completely eliminating the 2.0g to 3.5g false alarms caused by loose smartphone handling. "
        "The asynchronous FastAPI backend and Adaptive EMA filter effectively reject engine acoustic harmonics while enabling Random Forest "
        "classification to achieve <b>94.8% accuracy</b>. The distance-normalized scoring engine delivers objective driver risk evaluation, "
        "and the 3-meter spatial filter reduces telemetry database writes by <b>62.4%</b>. In operational fleet deployments, this platform "
        "provides transportation providers with a low-cost, high-reliability alternative to costly OBD-II hardware.", body))
    story.append(Spacer(1, 6))

    story.append(Bookmark('sec8_2'))
    story.append(Paragraph("8.2 Future Enhancements", sec_heading))
    story.append(Paragraph("• <b>Edge-AI (TinyML):</b> Deploying quantized neural networks (INT8) directly on the ESP32 using TensorFlow Lite for Microcontrollers, enabling offline edge classification without transmitting continuous raw telemetry.", bullet))
    story.append(Paragraph("• <b>Computer Vision ADAS Fusion:</b> Integrating monocular mobile dashcams with lightweight CNNs (YOLOv8-nano) to monitor forward headway time-to-collision (TTC) and lane departure.", bullet))
    story.append(Paragraph("• <b>Decentralized Insurance Smart Contracts:</b> Anchoring tamper-proof trip safety scores to blockchain ledgers to automate weekly usage-based insurance premium rebates.", bullet))
    story.append(Paragraph("• <b>V2X Hazard Broadcasting:</b> Extending the platform to support Dedicated Short-Range Communications (DSRC) / C-V2X protocols for peer-to-peer hazard notifications between approaching vehicles.", bullet))
    story.append(PageBreak())

    # ==========================================
    # REFERENCES: EXACT 15 PAPERS (Page 34, numbered Page | 24)
    # ==========================================
    story.append(Bookmark('refs'))
    story.append(Paragraph("REFERENCES", ParagraphStyle('RefTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=14)))
    user_refs = [
        "[1] M. Zarei Yazd, “A robust machine learning framework for detecting driving events using smartphones,” International Journal of Transportation Systems Research, 2024.",
        "[2] E. Papatheocharous et al., “Monitoring distracted driving behaviours with smartphones,” Sensors (MDPI), Vol 23, 2023.",
        "[3] B. Adhikari, “Using visual and vehicular sensors for driver behavior analysis: A survey,” arXiv preprint, 2023.",
        "[4] S. Ben Brahim et al., “A machine learning smartphone-based sensing for driver behavior classification,” arXiv preprint, 2022.",
        "[5] P. Wawage et al., “Smartphone sensor dataset for driver behavior analysis,” Data in Brief, ScienceDirect, 2022.",
        "[6] E. Mantouka et al., “Smartphone sensing for understanding driving behavior,” Transportation Research / ScienceDirect, 2021.",
        "[7] D. N. Lu et al., “Vehicle mode and driving activity detection based on smartphone sensors,” Sensors, MDPI, 2021.",
        "[8] E. Huang et al., “Combining accelerometer and gyroscope data in smartphone-based activity recognition,” arXiv preprint, 2021.",
        "[9] J. Warren et al., “Clusters of driving behavior from observational smartphone data,” arXiv preprint, 2021.",
        "[10] J. K. Mahendran et al., “Mobile edge AI-based assistive system for real-time environmental awareness,” IEEE Conference on Artificial Intelligence and Edge Computing, 2021.",
        "[11] D. Giansanti and A. Pirrera, “Artificial intelligence in assistive and monitoring systems,” Healthcare Journal, 2021.",
        "[12] A. Avdic et al., “Intelligent data processing using NLP and analytics in smart systems,” International Journal of Advanced Computer Science Applications, 2021.",
        "[13] A. J. Al-Haider et al., “IoT-based smart monitoring system using embedded sensors,” IEEE Access, 2020.",
        "[14] T. Nedovic et al., “Mobile-based assistive monitoring system for accessibility support,” Cureus Journal of Medical Science, 2020.",
        "[15] C. Bo et al., “TEXIVE: detecting drivers using personal smartphones by leveraging inertial sensors,” arXiv preprint, 2020."
    ]
    for r in user_refs:
        story.append(Paragraph(r, ParagraphStyle('RItem', fontName='Helvetica', fontSize=8, leading=11.5, spaceAfter=4, textColor=colors.HexColor("#1E293B"))))
    story.append(PageBreak())

    # ==========================================
    # PERSONAL PROFILES (Page 35, numbered Page | 25)
    # Generic Placeholders
    # ==========================================
    story.append(Bookmark('profile'))
    story.append(Paragraph("PERSONAL PROFILE", ParagraphStyle('ProfTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=10)))
    
    prof_data = [
        [Image('report/figures/photo_guide.png', width=1.1*inch, height=1.3*inch) if os.path.exists('report/figures/photo_guide.png') else "",
         Paragraph("<b>[Guide Name]</b><br/>[Designation], Department of CSE (Data Science)<br/>Vivekananda College of Engineering and Technology, Puttur, 574203.<br/><b>Educational qualification:</b> [BE, M.Tech, Ph.D]<br/><b>Area of interests:</b> Embedded Systems, IoT, Edge-AI, Data Science<br/><b>Email:</b> [guide.email@institution.edu.in]<br/><b>Phone:</b> [+91 XXXXXXXXXX]", td_style)],
        [Image('report/figures/photo_student1.png', width=1.1*inch, height=1.3*inch) if os.path.exists('report/figures/photo_student1.png') else "",
         Paragraph("<b>[Candidate Name 1]</b><br/><b>USN:</b> [USN 1]<br/><b>Email:</b> [candidate1@email.com]<br/><b>Phone:</b> [+91 XXXXXXXXXX]<br/><b>Address:</b> [Candidate 1 Address]", td_style)],
        [Image('report/figures/photo_student2.png', width=1.1*inch, height=1.3*inch) if os.path.exists('report/figures/photo_student2.png') else "",
         Paragraph("<b>[Candidate Name 2]</b><br/><b>USN:</b> [USN 2]<br/><b>Email:</b> [candidate2@email.com]<br/><b>Phone:</b> [+91 XXXXXXXXXX]<br/><b>Address:</b> [Candidate 2 Address]", td_style)],
        [Image('report/figures/photo_student3.png', width=1.1*inch, height=1.3*inch) if os.path.exists('report/figures/photo_student3.png') else "",
         Paragraph("<b>[Candidate Name 3]</b><br/><b>USN:</b> [USN 3]<br/><b>Email:</b> [candidate3@email.com]<br/><b>Phone:</b> [+91 XXXXXXXXXX]<br/><b>Address:</b> [Candidate 3 Address]", td_style)],
        [Image('report/figures/photo_student4.png', width=1.1*inch, height=1.3*inch) if os.path.exists('report/figures/photo_student4.png') else "",
         Paragraph("<b>[Candidate Name 4]</b><br/><b>USN:</b> [USN 4]<br/><b>Email:</b> [candidate4@email.com]<br/><b>Phone:</b> [+91 XXXXXXXXXX]<br/><b>Address:</b> [Candidate 4 Address]", td_style)],
    ]
    t_prof = Table(prof_data, colWidths=[110, 390])
    t_prof.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_prof)
    story.append(PageBreak())

    # ==========================================
    # SEPARATE SECTION: CONFERENCE ATTENDED (Page 36, numbered Page | 26)
    # ==========================================
    story.append(Bookmark('conf'))
    story.append(Paragraph("CONFERENCE ATTENDED", ParagraphStyle('ConfTitle', fontName='Helvetica-Bold', fontSize=13, leading=16, alignment=1, spaceAfter=20)))
    conf_text = (
        "<b>[Guide Name], [Candidate Name 1], [Candidate Name 2], [Candidate Name 3], [Candidate Name 4]</b>, "
        "“Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System”, "
        "<i>Proceedings of 3rd International Conference DRISHTI – 2025</i> held at "
        "Vivekananda College of Engineering and Technology, Puttur on 09/08/2025 ISBN: 978-93-343-5348-8.<br/><br/>"
        "<b>Abstract of Paper:</b><br/>"
        "Modern fleet management and insurance telematics require objective, tamper-resistant driver behavior monitoring. "
        "This paper presents the design and empirical evaluation of an AIoT-based telematics platform integrating chassis-mounted "
        "ESP32 / MPU-6050 edge nodes with smartphone BLE gateways. By decoupling sensor acquisition from cabin phone displacement, "
        "the architecture suppresses false acceleration alarms while achieving 94.8% maneuver classification accuracy and reducing "
        "spatial telemetry transmission overhead by 62.4%."
    )
    story.append(Paragraph(conf_text, body))
    story.append(Spacer(1, 20))
    conf_table = [
        [Paragraph("<b>Paper Title</b>", th_style), Paragraph("Smart Mobile-Based Driving Behaviour &amp; Risk Monitoring System", td_style)],
        [Paragraph("<b>Conference</b>", th_style), Paragraph("3rd International Conference DRISHTI – 2025", td_style)],
        [Paragraph("<b>Date of Event</b>", th_style), Paragraph("09th August 2025", td_style)],
        [Paragraph("<b>Organizing Institute</b>", th_style), Paragraph("Vivekananda College of Engineering and Technology, Puttur", td_style)],
        [Paragraph("<b>ISBN / Publication ID</b>", th_style), Paragraph("978-93-343-5348-8", td_style)],
        [Paragraph("<b>Presentation Status</b>", th_style), Paragraph("Presented and Published in Official Conference Proceedings", td_style)],
    ]
    t_conf = Table(conf_table, colWidths=[150, 350])
    t_conf.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('BACKGROUND', (0,0), (0,-1), colors.HexColor("#F1F5F9")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_conf)

    return story


def build_vtu_report(filename="Smart_Driving_System_Project_Report.pdf"):
    # Two-pass build to accurately populate Table of Contents, List of Figures, and List of Tables
    # Pass 1: Build story to record exact page numbers for every bookmark
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=45,
        rightMargin=45,
        topMargin=45,
        bottomMargin=45
    )
    story1 = generate_story()
    doc.build(story1, canvasmaker=VTUCanvas)
    
    # Pass 2: Re-generate story with the recorded page numbers and build final PDF
    doc2 = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=45,
        rightMargin=45,
        topMargin=45,
        bottomMargin=45
    )
    story2 = generate_story()
    doc2.build(story2, canvasmaker=VTUCanvas)
    
    print(f"VTU customized report PDF successfully generated at: {os.path.abspath(filename)}")


if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else "Smart_Driving_System_Project_Report.pdf"
    build_vtu_report(target)
