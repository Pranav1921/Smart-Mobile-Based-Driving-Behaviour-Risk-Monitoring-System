# PowerShell PDF Generator for Project Documentation
# Uses pure PDF 1.4 binary/text specification (Zero external dependencies)

$pdfPath = "c:\projects\Major_project\Smart_Driving_System_Project_Report.pdf"

class PdfBuilder {
    [System.Collections.ArrayList]$objects = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$pageObjIds = [System.Collections.ArrayList]::new()
    [int]$fontRegId = 0
    [int]$fontBoldId = 0
    [int]$fontMonoId = 0
    [int]$pagesRootId = 0
    
    # Page layout state
    [System.Collections.ArrayList]$currentPageStream = [System.Collections.ArrayList]::new()
    [double]$currentY = 740
    [int]$pageNumber = 0
    [double]$pageWidth = 612
    [double]$pageHeight = 792
    [double]$leftMargin = 45
    [double]$rightMargin = 567
    [double]$contentWidth = 522
    [double]$bottomMargin = 45

    PdfBuilder() {
        # Object 1: Catalog (will be written at end)
        # Object 2: Pages root
        # Object 3, 4, 5: Fonts
    }

    [void]InitFonts() {
        $this.fontRegId = $this.AddObject("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
        $this.fontBoldId = $this.AddObject("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>")
        $this.fontMonoId = $this.AddObject("<< /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding >>")
    }

    [int]AddObject([string]$content) {
        $id = $this.objects.Count + 1
        $this.objects.Add($content) | Out-Null
        return $id
    }

    [void]StartPage() {
        $this.pageNumber++
        $this.currentPageStream.Clear()
        $this.currentY = 745

        # Draw page header (for pages > 1)
        if ($this.pageNumber -gt 1) {
            $stream = $this.currentPageStream
            $stream.Add("0.5 0.5 0.5 RG 0.5 w") | Out-Null
            $stream.Add("$($this.leftMargin) 762 m $($this.rightMargin) 762 l S") | Out-Null
            $stream.Add("BT /F1 8 Tf 0.4 0.4 0.4 rg $($this.leftMargin) 766 Td (SMART DRIVING BEHAVIOUR & RISK MONITORING SYSTEM | PROJECT REPORT) Tj ET") | Out-Null
            $stream.Add("BT /F1 8 Tf 0.4 0.4 0.4 rg $($this.rightMargin - 60) 766 Td (Page $($this.pageNumber)) Tj ET") | Out-Null
        }

        # Draw page footer
        $stream = $this.currentPageStream
        $stream.Add("0.5 0.5 0.5 RG 0.5 w") | Out-Null
        $stream.Add("$($this.leftMargin) 35 m $($this.rightMargin) 35 l S") | Out-Null
        $stream.Add("BT /F1 8 Tf 0.4 0.4 0.4 rg $($this.leftMargin) 25 Td (Major Project | Complete Technical Architecture & Resume Guide) Tj ET") | Out-Null
        $stream.Add("BT /F1 8 Tf 0.4 0.4 0.4 rg $($this.rightMargin - 40) 25 Td (Page $($this.pageNumber)) Tj ET") | Out-Null
    }

    [void]CheckPageBreak([double]$neededSpace) {
        if (($this.currentY - $neededSpace) -lt $this.bottomMargin) {
            $this.EndPage()
            $this.StartPage()
        }
    }

    [void]EndPage() {
        $streamText = ($this.currentPageStream -join "`n")
        $streamBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($streamText)
        $streamLen = $streamBytes.Length

        $contentObjId = $this.AddObject("<< /Length $streamLen >>`nstream`n$streamText`nendstream")

        $pageDict = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $($this.pageWidth) $($this.pageHeight)] /Contents $contentObjId 0 R /Resources << /Font << /F1 $($this.fontRegId) 0 R /F2 $($this.fontBoldId) 0 R /F3 $($this.fontMonoId) 0 R >> >> >>"
        $pageId = $this.AddObject($pageDict)
        $this.pageObjIds.Add($pageId) | Out-Null
    }

    [string]EscapeString([string]$text) {
        if (-not $text) { return "" }
        $text = $text.Replace("\", "\\").Replace("(", "\(").Replace(")", "\)")
        # Replace common unicode dashes and quotes with standard ASCII
        $text = $text.Replace([string][char]8211, "-").Replace([string][char]8212, "--").Replace([string][char]8216, "'").Replace([string][char]8217, "'").Replace([string][char]8220, "`"").Replace([string][char]8221, "`"").Replace([string][char]8226, "*")
        return $text
    }

    [void]AddTitle([string]$title, [string]$subtitle) {
        $this.CheckPageBreak(80)
        # Background accent header banner
        $this.currentPageStream.Add("0.08 0.18 0.36 rg $($this.leftMargin) $($this.currentY - 48) $($this.contentWidth) 58 re f") | Out-Null
        $this.currentPageStream.Add("1.0 1.0 1.0 rg") | Out-Null
        $this.currentPageStream.Add("BT /F2 15 Tf $($this.leftMargin + 12) $($this.currentY - 18) Td ($($this.EscapeString($title))) Tj ET") | Out-Null
        $this.currentPageStream.Add("BT /F1 9 Tf 0.85 0.92 1.0 rg $($this.leftMargin + 12) $($this.currentY - 36) Td ($($this.EscapeString($subtitle))) Tj ET") | Out-Null
        $this.currentY -= 65
    }

    [void]AddHeading1([string]$heading) {
        $this.CheckPageBreak(40)
        $this.currentY -= 10
        # Underlined Section Heading
        $this.currentPageStream.Add("0.1 0.3 0.6 rg $($this.leftMargin) $($this.currentY - 2) $($this.contentWidth) 1.5 re f") | Out-Null
        $this.currentPageStream.Add("BT /F2 12.5 Tf 0.08 0.22 0.45 rg $($this.leftMargin) $($this.currentY + 3) Td ($($this.EscapeString($heading))) Tj ET") | Out-Null
        $this.currentY -= 18
    }

    [void]AddHeading2([string]$heading) {
        $this.CheckPageBreak(28)
        $this.currentY -= 6
        $this.currentPageStream.Add("BT /F2 10.5 Tf 0.12 0.35 0.55 rg $($this.leftMargin) $($this.currentY) Td ($($this.EscapeString($heading))) Tj ET") | Out-Null
        $this.currentY -= 14
    }

    [void]AddCalloutBox([string]$title, [string[]]$lines, [double]$r = 0.94, [double]$g = 0.97, [double]$b = 1.0, [double]$borderR = 0.2, [double]$borderG = 0.5, [double]$borderB = 0.8) {
        $boxHeight = ($lines.Length * 12.5) + 24
        $this.CheckPageBreak($boxHeight + 10)

        # Draw fill & border
        $this.currentPageStream.Add("$r $g $b rg $($this.leftMargin) $($this.currentY - $boxHeight + 12) $($this.contentWidth) $boxHeight re f") | Out-Null
        $this.currentPageStream.Add("$borderR $borderG $borderB RG 1 w $($this.leftMargin) $($this.currentY - $boxHeight + 12) $($this.contentWidth) $boxHeight re S") | Out-Null
        $this.currentPageStream.Add("$borderR $borderG $borderB rg $($this.leftMargin) $($this.currentY - $boxHeight + 12) 4 $boxHeight re f") | Out-Null

        # Title
        $this.currentPageStream.Add("BT /F2 9.5 Tf $borderR $borderG $borderB rg $($this.leftMargin + 12) $($this.currentY - 3) Td ($($this.EscapeString($title))) Tj ET") | Out-Null
        $lineY = $this.currentY - 17

        foreach ($l in $lines) {
            $this.currentPageStream.Add("BT /F1 8.5 Tf 0.15 0.18 0.22 rg $($this.leftMargin + 12) $lineY Td ($($this.EscapeString($l))) Tj ET") | Out-Null
            $lineY -= 12.5
        }
        $this.currentY -= ($boxHeight + 6)
    }

    [void]AddParagraph([string]$text) {
        $words = $text.Split(" ")
        $curLine = ""
        $maxChars = 92

        foreach ($w in $words) {
            if (($curLine.Length + $w.Length + 1) -le $maxChars) {
                if ($curLine.Length -gt 0) { $curLine += " " }
                $curLine += $w
            } else {
                $this.CheckPageBreak(13)
                $this.currentPageStream.Add("BT /F1 9 Tf 0.15 0.18 0.22 rg $($this.leftMargin) $($this.currentY) Td ($($this.EscapeString($curLine))) Tj ET") | Out-Null
                $this.currentY -= 12.5
                $curLine = $w
            }
        }
        if ($curLine.Length -gt 0) {
            $this.CheckPageBreak(13)
            $this.currentPageStream.Add("BT /F1 9 Tf 0.15 0.18 0.22 rg $($this.leftMargin) $($this.currentY) Td ($($this.EscapeString($curLine))) Tj ET") | Out-Null
            $this.currentY -= 12.5
        }
        $this.currentY -= 3
    }

    [void]AddBullet([string]$label, [string]$detail) {
        $this.CheckPageBreak(16)
        # Bullet dot
        $this.currentPageStream.Add("0.1 0.4 0.7 rg $($this.leftMargin + 4) $($this.currentY + 2.5) 3.5 3.5 re f") | Out-Null
        
        $fullText = "$label $detail"
        $words = $fullText.Split(" ")
        $curLine = ""
        $maxChars = 86
        $isFirst = $true

        foreach ($w in $words) {
            if (($curLine.Length + $w.Length + 1) -le $maxChars) {
                if ($curLine.Length -gt 0) { $curLine += " " }
                $curLine += $w
            } else {
                $this.CheckPageBreak(13)
                $xPos = if ($isFirst) { $this.leftMargin + 14 } else { $this.leftMargin + 14 }
                $font = if ($isFirst) { "/F2 9 Tf 0.1 0.15 0.25 rg" } else { "/F1 9 Tf 0.2 0.22 0.28 rg" }
                $this.currentPageStream.Add("BT $font $xPos $($this.currentY) Td ($($this.EscapeString($curLine))) Tj ET") | Out-Null
                $this.currentY -= 12.5
                $curLine = $w
                $isFirst = $false
            }
        }
        if ($curLine.Length -gt 0) {
            $this.CheckPageBreak(13)
            $xPos = $this.leftMargin + 14
            $font = if ($isFirst) { "/F2 9 Tf 0.1 0.15 0.25 rg" } else { "/F1 9 Tf 0.2 0.22 0.28 rg" }
            $this.currentPageStream.Add("BT $font $xPos $($this.currentY) Td ($($this.EscapeString($curLine))) Tj ET") | Out-Null
            $this.currentY -= 13.5
        }
    }

    [void]AddTableRow([string]$c1, [string]$c2, [string]$c3, [string]$c4) {
        $this.AddTableRow($c1, $c2, $c3, $c4, $false)
    }

    [void]AddTableRow([string]$c1, [string]$c2, [string]$c3, [string]$c4, [bool]$isHeader) {
        $this.CheckPageBreak(16)
        $h = 15.0
        $w1 = 90
        $w2 = 110
        $w3 = 190
        $w4 = 132

        $y = $this.currentY
        if ($isHeader) {
            $this.currentPageStream.Add("0.15 0.25 0.45 rg $($this.leftMargin) $y $($this.contentWidth) $h re f") | Out-Null
            $font = "/F2 8 Tf 1 1 1 rg"
        } else {
            $this.currentPageStream.Add("0.97 0.98 0.99 rg $($this.leftMargin) $y $($this.contentWidth) $h re f") | Out-Null
            $this.currentPageStream.Add("0.85 0.88 0.92 RG 0.5 w $($this.leftMargin) $y $($this.contentWidth) $h re S") | Out-Null
            $font = "/F1 8 Tf 0.15 0.18 0.22 rg"
        }

        $this.currentPageStream.Add("BT $font $($this.leftMargin + 4) $($y + 3.5) Td ($($this.EscapeString($c1))) Tj ET") | Out-Null
        $this.currentPageStream.Add("BT $font $($this.leftMargin + $w1 + 4) $($y + 3.5) Td ($($this.EscapeString($c2))) Tj ET") | Out-Null
        $this.currentPageStream.Add("BT $font $($this.leftMargin + $w1 + $w2 + 4) $($y + 3.5) Td ($($this.EscapeString($c3))) Tj ET") | Out-Null
        $this.currentPageStream.Add("BT $font $($this.leftMargin + $w1 + $w2 + $w3 + 4) $($y + 3.5) Td ($($this.EscapeString($c4))) Tj ET") | Out-Null

        $this.currentY -= $h
    }

    [void]SaveToFile([string]$outputPath) {
        if ($this.currentPageStream.Count -gt 0) {
            $this.EndPage()
        }

        # Build Pages object
        $kidsStr = ($this.pageObjIds | ForEach-Object { "$_ 0 R" }) -join " "
        $pagesDict = "<< /Type /Pages /Kids [ $kidsStr ] /Count $($this.pageObjIds.Count) >>"
        # We need Pages to be object 2
        # Let's rebuild binary stream
        $fileBytes = [System.Collections.ArrayList]::new()
        
        # Header
        $headerStr = "%PDF-1.4`n%`xE2`xE3`xCF`xD3`n"
        $fileBytes.AddRange([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($headerStr))

        # Objects list
        $allObjs = [System.Collections.ArrayList]::new()
        # Obj 1: Catalog
        $allObjs.Add("<< /Type /Catalog /Pages 2 0 R >>") | Out-Null
        # Obj 2: Pages
        $allObjs.Add($pagesDict) | Out-Null
        # The remaining objects from $this.objects
        foreach ($obj in $this.objects) {
            $allObjs.Add($obj) | Out-Null
        }

        $offsets = [System.Collections.ArrayList]::new()

        for ($i = 0; $i -lt $allObjs.Count; $i++) {
            $offsets.Add($fileBytes.Count) | Out-Null
            $objNum = $i + 1
            $objContent = $allObjs[$i]
            $objStr = "$objNum 0 obj`n$objContent`nendobj`n"
            $fileBytes.AddRange([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($objStr))
        }

        # XREF table
        $xrefStart = $fileBytes.Count
        $xrefCount = $allObjs.Count + 1
        $xrefStr = "xref`n0 $xrefCount`n0000000000 65535 f `n"
        for ($i = 0; $i -lt $allObjs.Count; $i++) {
            $off = $offsets[$i]
            $xrefStr += ("{0:D10} 00000 n `n" -f $off)
        }
        $xrefStr += "trailer`n<< /Size $xrefCount /Root 1 0 R >>`nstartxref`n$xrefStart`n%%EOF`n"
        $fileBytes.AddRange([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($xrefStr))

        [System.IO.File]::WriteAllBytes($outputPath, [byte[]]$fileBytes.ToArray([type][byte]))
    }
}

# --- DOCUMENT CREATION ---
$pdf = [PdfBuilder]::new()
$pdf.InitFonts()

# ================= PAGE 1 =================
$pdf.StartPage()
$pdf.AddTitle("Smart Driving Behaviour & Risk Monitoring System", "Comprehensive Technical Report & Complete Resume Defense Guide | Major Project")

$pdf.AddHeading1("1. Master Resume Representation & Exact LaTeX Snippet")
$pdf.AddParagraph("Below is the exact verbatim project entry formatted for your technical resume. Every bullet point represents a core subsystem engineered and tested in this platform:")

$pdf.AddCalloutBox("EXACT RESUME ENTRY (LaTeX Code)", @(
    "\noindent \href{https://github.com/Pranav1921/Smart-Mobile-Based-Driving-Behaviour-Risk-Monitoring-System}",
    "{\textbf{Smart Mobile-Based Driving Behaviour & Risk Monitoring System}} \hfill \textit{Jan 2026 -- Present} \\",
    "\noindent \textit{Major Project}",
    "\begin{itemize}",
    "  * Engineered a backend infrastructure using Python and PostgreSQL to ingest, process, and store high-frequency vehicle telemetry data in real time.",
    "  * Interfaced an ESP32 IMU sensor with a Flutter mobile application over BLE to capture vehicle motion dynamics and detect road hazards like potholes.",
    "  * Implemented driving risk assessment algorithms to analyze time-series sensor data, detect harsh driving maneuvers, and compute driver safety scores.",
    "  * Developed a React web dashboard for live fleet map tracking and containerized the backend services using Docker for consistent deployment.",
    "\end{itemize}"
), 0.95, 0.97, 1.0, 0.15, 0.35, 0.65)

$pdf.AddHeading1("2. Executive Summary & Core Engineering Vision")
$pdf.AddParagraph("Human vehicular behavioral factors (panic braking, harsh turning, continuous overspeeding, and aggressive swerving) account for over 90% of road traffic accidents globally. Traditional commercial telematics solutions require expensive proprietary OBD-II dongles or direct CAN-bus hardwiring costing between $300 and $800 per vehicle.")
$pdf.AddParagraph("This project delivers a complete, sub-$6 hardware-software AIoT telematics ecosystem that combines edge-computed IMU physics, cross-platform mobile sync, asynchronous cloud risk analytics, and real-time fleet command-and-control.")

$pdf.AddHeading2("Master Architectural Layers")
$pdf.AddTableRow("Layer", "Core Technology", "Primary Responsibility", "Key Benefit / Output", $true)
$pdf.AddTableRow("Hardware Edge", "ESP32 C++ / MPU-6050", "Rigid chassis kinematics sampling at 20Hz", "+/-16g dynamic shockwave range; zero handheld false alarms")
$pdf.AddTableRow("Mobile Client", "Flutter (Dart) / BLE", "Dual-sensor fusion, audio TTS HUD, offline buffer", "Real-time driver guidance, turn-by-turn dispatch, OSM navigation")
$pdf.AddTableRow("AI & API Backend", "Python (FastAPI) & PostgreSQL", "Time-series validation, risk engines, crash forensics", "Sub-50ms latency, transactional persistence, Delta-V scoring")
$pdf.AddTableRow("Fleet HUD", "React 18 / Vite / Leaflet", "Live fleet GIS tracking, breadcrumbs, SOS dispatch", "High-visibility operations room control, geofenced alerts")
$pdf.AddTableRow("DevOps Infra", "Docker & Docker Compose", "Containerized service orchestration & volumes", "Reproducible multi-container staging across any cloud/local host")

# ================= PAGE 2 =================
$pdf.StartPage()
$pdf.AddHeading1("3. In-Depth Defense: Bullet Point 1 (Backend Infrastructure & Telemetry)")
$pdf.AddParagraph("Resume Text: 'Engineered a backend infrastructure using Python and PostgreSQL to ingest, process, and store high-frequency vehicle telemetry data in real time.'")

$pdf.AddHeading2("Detailed Explanation of Every Word and Component:")
$pdf.AddBullet("Backend Infrastructure:", "Architected as a high-throughput microservice using FastAPI, an asynchronous ASGI framework built on top of Starlette and Uvicorn. It exposes REST and streaming endpoints capable of handling concurrent vehicular telemetry packets with non-blocking I/O.")
$pdf.AddBullet("Python & FastAPI Engine:", "Leveraged Python 3.10+ for its scientific and numerical capabilities (NumPy, SciPy). FastAPI ensures automatic request schema validation via Pydantic models, OpenAPI documentation, and sub-millisecond serialization overhead.")
$pdf.AddBullet("PostgreSQL Database:", "Designed a relational schema with tables for drivers, vehicles, trips, hazard events, and granular GPS/IMU breadcrumbs. Utilized indexed spatial coordinates and timestamps to support rapid analytical range queries and historical trip playback without table lock contention.")
$pdf.AddBullet("High-Frequency Vehicle Telemetry:", "In telematics, telemetry refers to continuous measurements transmitted from moving vehicles. The system streams 20 samples per second (20 Hz) containing 14 distinct parameters: latitude, longitude, transit speed (km/h), compass heading (deg), 3-axis linear acceleration (X, Y, Z in Gs), 3-axis angular rates (X, Y, Z in rad/s), road vibration rate (m/s2), and Unix epoch timestamps.")
$pdf.AddBullet("Ingestion, Processing & Storage:", "Incoming packets undergo adaptive threshold validation, kinematic physics calculation, and batch insertion. High-frequency coordinates are downsampled using spatial-distance delta filters (>3 meters displacement) to eliminate database bloat during red-light stops.")

$pdf.AddHeading2("Telemetry Packet Schema & Mathematical Pipeline")
$pdf.AddParagraph("Each incoming frame is parsed into a vector P = [lat, lng, v, theta, ax, ay, az, gx, gy, gz, t]. Longitudinal and lateral accelerations are normalized using local gravitational constants (g = 9.80665 m/s2). If network drops occur in valleys or ghat roads, the client buffers samples locally in SQLite/SharedPreferences and flushes them in a transactional sync upon reconnection.")

$pdf.AddHeading1("4. In-Depth Defense: Bullet Point 2 (Hardware Interfacing & Potholes)")
$pdf.AddParagraph("Resume Text: 'Interfaced an ESP32 IMU sensor with a Flutter mobile application over BLE to capture vehicle motion dynamics and detect road hazards like potholes.'")

$pdf.AddHeading2("Detailed Explanation of Every Word and Component:")
$pdf.AddBullet("ESP32 IMU Sensor:", "Utilizes an ESP-WROOM-32 32-bit dual-core Xtensa microcontroller coupled with an MPU-6050 6-axis MEMS motion-tracking sensor via I2C at 400 kHz. Unlike consumer phone sensors limited to +/-2g or +/-4g, the ESP32 registers (0x1C) are configured to Full Scale Range +/-16g (2048 LSB/g) to capture true collision shockwaves without saturation.")
$pdf.AddBullet("Interfaced Mobile Hardware over BLE:", "Implemented Bluetooth Low Energy (BLE 4.2/5.0) Generic Attribute Profile (GATT) architecture. Designed custom 128-bit Service and Characteristic UUIDs with optimized 20-byte packed binary payloads to stream telemetry continuously with under 15ms transmission latency and minimal battery consumption.")
$pdf.AddBullet("Flutter Mobile Application:", "Engineered using Google's cross-platform Flutter SDK (Dart). Features a decoupled reactive state architecture (Provider), throttled UI rebuilds (120ms/150ms intervals) ensuring 60 FPS fluidity on mobile hardware, integrated OpenStreetMap navigation, and text-to-speech audio coaching.")
$pdf.AddBullet("Vehicle Motion Dynamics:", "Vehicle dynamics describe how a vehicle moves in 3D space. Rigidly mounting the ESP32 node to the vehicle chassis decouples it from the phone. This eliminates false-alarm spikes (e.g. driver answering calls, phone sliding on seats) that plague phone-only telematics apps.")
$pdf.AddBullet("Road Hazards & Pothole Detection:", "Developed a vertical-dominant anomaly algorithm. A pothole or speed-bump produces an abrupt spike in vertical Z-axis acceleration accompanied by minimal horizontal turning force. When vertical force |az| >= 1.90g and dominates planar horizontal force (|az| > horizontalG * 1.25) at road speeds >= 12 km/h, the event is geotagged as a road hazard.")

# ================= PAGE 3 =================
$pdf.StartPage()
$pdf.AddHeading1("5. In-Depth Defense: Bullet Point 3 (Risk Assessment & Scoring Engine)")
$pdf.AddParagraph("Resume Text: 'Implemented driving risk assessment algorithms to analyze time-series sensor data, detect harsh driving maneuvers, and compute driver safety scores.'")

$pdf.AddHeading2("Detailed Explanation of Every Word and Component:")
$pdf.AddBullet("Driving Risk Assessment Algorithms:", "Mathematical algorithms analyzing continuous streaming time-series data using Adaptive Exponential Moving Average (EMA) filtering (alpha = 0.22 for cruising, alpha = 0.65 for high-jerk events) and deadband thresholds to distinguish between road vibrations and dangerous maneuvers.")
$pdf.AddBullet("Harsh Driving Maneuvers Detected:", "")
$pdf.AddBullet("  * Harsh Braking:", "Rapid velocity drops with longitudinal deceleration ax < -3.8 m/s2 (or sustained G-force > 0.38g). Indicates tailgating or inattentive driving.")
$pdf.AddBullet("  * Aggressive Acceleration:", "Abrupt throttle application exceeding ax > +3.2 m/s2. Causes excessive fuel burn, brake wear, and loss of traction.")
$pdf.AddBullet("  * Sharp Cornering / Swerving:", "High centrifugal lateral force (|ay| > 9.2 m/s2) combined with high yaw rate (|gz| > 3.6 rad/s) at transit speeds >= 28 km/h.")
$pdf.AddBullet("  * Overspeeding & Zone Violations:", "Vehicle speed cross-referenced with municipal speed limits and OpenStreetMap geofenced school/hospital silence zones (<= 25 km/h).")
$pdf.AddBullet("Compute Driver Safety Scores (0-100 Scale):", "Every driver begins each trip with a baseline 100% score. Penalties are deducted dynamically based on infraction severity (critical events: -2.5%, warnings: -1.5%). Scores are classified into Gold Tier (95-100%), Silver Tier (85-94%), Bronze Tier (75-84%), Cautionary Pass (60-74%), and At-Risk Driving (<60%).")
$pdf.AddBullet("Kinetic Crash Forensics (Delta-V):", "In catastrophic collisions, the engine computes velocity change Delta-V = integral of a(t)dt over the impact pulse duration (30-100ms) to estimate vehicle structural crush deformation index and emergency response severity.")
$pdf.AddBullet("Gamified Points & Rewards:", "Drivers earn points proportionally: Gold Tier awards 100 base pts + 20 clean ride bonus (0 infractions) + 2 pts/km (up to 30 pts). Drivers redeem points for fuel vouchers or direct UPI cash conversion at 10 pts = 1 INR.")

$pdf.AddHeading1("6. In-Depth Defense: Bullet Point 4 (React Fleet Dashboard & Docker)")
$pdf.AddParagraph("Resume Text: 'Developed a React web dashboard for live fleet map tracking and containerized the backend services using Docker for consistent deployment.'")

$pdf.AddHeading2("Detailed Explanation of Every Word and Component:")
$pdf.AddBullet("React Web Dashboard:", "Built with React 18 and Vite for fast client-side rendering. Features modular UI components, live state hooks, tactical dark/light operations command center theme, and skeuomorphic dials for vehicle telemetry.")
$pdf.AddBullet("Live Fleet Map Tracking:", "Integrates interactive Leaflet/OpenStreetMap GIS layers. Renders live vehicle symbols with dynamic heading arrows, active delivery mission polylines, colored breadcrumb routes, and visual radar pins for detected road hazards.")
$pdf.AddBullet("Emergency SOS & Dispatch Management:", "Fleet managers can view instant crash/stillness alerts with exact GPS coordinates, dispatch new delivery orders to nearest available drivers, and review historical trip audit logs.")
$pdf.AddBullet("Containerized Backend Services with Docker:", "Packaged the backend services, PostgreSQL 15, and Redis 7 into container images via Dockerfiles and orchestrated them with Docker Compose. This ensures identical execution environments, isolated networking, persistent database volumes, and effortless single-command deployment across development and cloud servers.")

# ================= PAGE 4 =================
$pdf.StartPage()
$pdf.AddHeading1("7. Technical Interview Q&A Guide (Preparing for Questions on this Project)")
$pdf.AddParagraph("When interviewers review your resume, they will test your depth of understanding on every single claim. Here are the top questions and exact answers to master:")

$pdf.AddCalloutBox("Q1: Why did you use an ESP32 hardware node when modern smartphones already have accelerometers?", @(
    "ANSWER: Smartphones are mechanically decoupled from the vehicle chassis. When a driver picks up their phone, adjusts navigation, or the phone",
    "slides on a passenger seat, it experiences 2.0g - 3.5g surges, causing false harsh-braking and crash triggers in phone-only apps.",
    "Furthermore, phone sensors are clamped by the mobile OS to +/-2g or +/-4g, causing them to clip/saturate during real crashes.",
    "Our ESP32 node is rigidly fixed to the chassis, has zero handheld noise, and is configured to full +/-16g collision range."
), 0.96, 0.98, 1.0, 0.2, 0.5, 0.8)

$pdf.AddCalloutBox("Q2: How does your pothole detection algorithm work mathematically?", @(
    "ANSWER: Potholes generate an abrupt vertical acceleration shockwave on the vehicle suspension while lateral and longitudinal forces remain low.",
    "Our algorithm checks three conditions simultaneously: (1) Vehicle transit speed >= 12 km/h (to ignore door slams), (2) Absolute vertical Z-axis",
    "force |az| >= 1.90g, and (3) Vertical dominance ratio |az| > horizontalG * 1.25. When all 3 pass, it geotags a pothole with a 4-second debounce."
), 0.98, 0.96, 1.0, 0.5, 0.3, 0.8)

$pdf.AddCalloutBox("Q3: How do you handle sensor noise and temporary road vibrations?", @(
    "ANSWER: We implement an Adaptive Exponential Moving Average (EMA) filter coupled with a calibrated deadband. At standstill (<2 km/h),",
    "the system auto-tares zero-bias offsets. During cruising, alpha = 0.22 provides smooth, jitter-free G-force readings, while dynamic",
    "spikes switch alpha = 0.65 to capture genuine harsh events without lag. Accelerations below 0.06g are clamped to zero."
), 0.96, 1.0, 0.97, 0.2, 0.6, 0.3)

$pdf.AddCalloutBox("Q4: How does the driver safety scoring and gamification system work?", @(
    "ANSWER: Trips begin with 100.0% safety score. Minor infractions (overspeeding) deduct 1.5%, while critical events (harsh braking) deduct 2.5%.",
    "At delivery completion, calculateTripPoints() awards base points proportional to safety tier (Gold Tier >= 95% gets 100 pts),",
    "+20 clean ride bonus if zero infractions occurred, and +2 pts per km completed. Drivers redeem points for fuel vouchers or instant UPI cash."
), 0.98, 0.98, 0.95, 0.6, 0.5, 0.2)

$pdf.AddCalloutBox("Q5: What was the benefit of using Docker in your project architecture?", @(
    "ANSWER: Docker allowed us to containerize our Python backend, PostgreSQL database, and Redis cache into isolated microservices with",
    "a single docker-compose.yml file. It eliminated 'works on my machine' dependency issues, ensured identical database schemas and",
    "Python environments, and simplified deployment with isolated networking and persistent volume mounts."
), 0.96, 0.97, 1.0, 0.2, 0.4, 0.7)

$pdf.AddHeading2("Summary Checklist for Your Interview:")
$pdf.AddBullet("Core Tech:", "ESP32 C++, MPU-6050, BLE GATT, Flutter (Dart), Python (FastAPI), React 18, PostgreSQL, Docker.")
$pdf.AddBullet("Key Numbers to Quote:", "20 Hz telemetry stream, +/-16g sensor scale, <50ms latency, 100-point safety scale, 10 pts = 1 INR conversion.")
$pdf.AddBullet("Engineering Highlights:", "Dual-sensor fusion, chassis decoupling, vertical-dominant pothole detection, Delta-V crash forensics.")

# Save final PDF
$pdf.SaveToFile($pdfPath)
Write-Output "PDF successfully generated at: $pdfPath"
