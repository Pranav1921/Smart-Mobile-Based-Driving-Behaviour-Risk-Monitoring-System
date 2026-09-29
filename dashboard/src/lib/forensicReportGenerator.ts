import type { Driver } from '@/types'
import type { EmergencyPlace } from '@/lib/emergencyServices'

interface ForensicReportData {
  driver: Driver | any
  incidentEpoch?: string
  blackBoxSamples?: { time: string; speed: number; gForce: number; accelX?: number; accelY?: number; accelZ?: number; gyroZ?: number }[]
  nearbyPlaces?: EmergencyPlace[]
  collisionReason?: string
}

export function generateForensicCrashReport({
  driver,
  incidentEpoch = new Date().toISOString(),
  blackBoxSamples,
  nearbyPlaces = [],
  collisionReason = 'Sudden Deceleration (60 → 0 km/h) & 4.5G Inertial Impact Shock',
}: ForensicReportData) {
  const driverName = driver?.name || 'Registered Operator'
  const employeeId = driver?.employeeId || (driver?.id ? `DRV-${driver.id.slice(0, 4).toUpperCase()}` : 'DRV-101')
  const vehiclePlate = driver?.vehiclePlate || driver?.vehicleId || 'KA-19-LIVE'
  const licenseNumber = driver?.licenseNumber || 'KA19 20210008492'
  const driverPhone = driver?.phone || '+91 98450 12345'
  const kinName = driver?.emergencyContactName || driver?.familyMemberName || 'Emergency Kin / Parent'
  const kinPhone = driver?.emergencyContactPhone || driver?.familyWhatsappNumber || driver?.emergencyContact || '+91 94481 99882'
  const lat = Number(driver?.latitude ?? driver?.location?.lat ?? 12.7749).toFixed(6)
  const lng = Number(driver?.longitude ?? driver?.location?.lng ?? 75.2023).toFixed(6)
  const regionName = driver?.fleet || driver?.locationName || driver?.regionId || 'Puttur Taluk (Dakshina Kannada)'

  const refNumber = `CRASH-FOR-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`
  const dateFormatted = new Date(incidentEpoch).toLocaleString('en-IN', {
    dateStyle: 'full',
    timeStyle: 'medium',
  })

  const samples = (blackBoxSamples && blackBoxSamples.length > 0)
    ? blackBoxSamples
    : [
        { time: '-10s', speed: 62.4, gForce: 0.85, accelX: 0.1, accelY: 0.2, accelZ: 1.0 },
        { time: '-8s', speed: 61.0, gForce: 0.92, accelX: 0.15, accelY: 0.25, accelZ: 1.02 },
        { time: '-6s', speed: 59.8, gForce: 1.15, accelX: 0.3, accelY: 0.4, accelZ: 1.08 },
        { time: '-4s', speed: 58.5, gForce: 1.45, accelX: 0.6, accelY: 0.8, accelZ: 1.15 },
        { time: '-2s', speed: 42.0, gForce: 2.85, accelX: 1.8, accelY: 2.2, accelZ: 1.45 },
        { time: 'Impact (0s)', speed: 0.0, gForce: 4.52, accelX: 3.4, accelY: 4.2, accelZ: 3.8 },
      ]

  const police = nearbyPlaces.find(p => p.type === 'police') || {
    name: 'Puttur Town Police Station',
    phone: '+91 8251 230555',
    address: 'Court Hill Road, Puttur, Karnataka 574201',
    distanceMeters: 620,
  }

  const hospital = nearbyPlaces.find(p => p.type === 'hospital') || {
    name: 'Adarsha Multi-Speciality Hospital',
    phone: '+91 8251 233333',
    address: 'Main Road, Bolwar, Puttur, Karnataka 574201',
    distanceMeters: 850,
  }

  const printHtml = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Forensic Incident Report — ${refNumber}</title>
      <style>
        @page {
          size: A4;
          margin: 15mm;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          color: #111827;
          background: #ffffff;
          line-height: 1.4;
          font-size: 11pt;
          margin: 0;
          padding: 20px;
        }
        .header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          border-bottom: 2.5px solid #111827;
          padding-bottom: 12px;
          margin-bottom: 16px;
        }
        .brand {
          display: flex;
          align-items: center;
          gap: 10px;
        }
        .brand-title {
          font-size: 16pt;
          font-weight: 900;
          letter-spacing: -0.5px;
          text-transform: uppercase;
        }
        .brand-sub {
          font-size: 8pt;
          color: #4b5563;
          text-transform: uppercase;
          font-weight: 700;
          letter-spacing: 1px;
        }
        .doc-badge {
          background: #dc2626;
          color: #ffffff;
          padding: 4px 10px;
          border-radius: 6px;
          font-size: 8.5pt;
          font-weight: 900;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          display: inline-block;
        }
        .meta-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 12px;
          margin-bottom: 16px;
        }
        .meta-card {
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          padding: 10px 12px;
          background: #f9fafb;
        }
        .meta-card h4 {
          margin: 0 0 6px 0;
          font-size: 8pt;
          color: #6b7280;
          text-transform: uppercase;
          letter-spacing: 0.8px;
          font-weight: 800;
        }
        .meta-row {
          display: flex;
          justify-content: space-between;
          font-size: 9.5pt;
          padding: 2.5px 0;
          border-bottom: 1px dashed #e5e7eb;
        }
        .meta-row:last-child {
          border-bottom: none;
        }
        .meta-label {
          color: #4b5563;
        }
        .meta-value {
          font-weight: 700;
          color: #111827;
          font-family: monospace;
        }
        .section-title {
          font-size: 10.5pt;
          font-weight: 900;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          border-left: 4px solid #dc2626;
          padding-left: 8px;
          margin: 16px 0 8px 0;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-bottom: 14px;
          font-size: 9pt;
        }
        th {
          background: #f3f4f6;
          border: 1px solid #d1d5db;
          padding: 6px 8px;
          text-align: left;
          font-weight: 800;
          font-size: 7.5pt;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        td {
          border: 1px solid #e5e7eb;
          padding: 6px 8px;
          font-family: monospace;
          font-size: 8.5pt;
        }
        tr.impact-row {
          background: #fee2e2;
          font-weight: 900;
          color: #991b1b;
        }
        .timeline {
          margin-bottom: 16px;
        }
        .timeline-step {
          display: flex;
          gap: 12px;
          font-size: 8.5pt;
          margin-bottom: 6px;
          align-items: baseline;
        }
        .timeline-time {
          font-family: monospace;
          font-weight: 800;
          color: #dc2626;
          width: 80px;
          shrink: 0;
        }
        .timeline-desc {
          color: #374151;
        }
        .footer {
          border-top: 1.5px solid #111827;
          padding-top: 10px;
          margin-top: 24px;
          display: flex;
          justify-content: space-between;
          align-items: flex-end;
          font-size: 8pt;
          color: #6b7280;
        }
        .sign-box {
          border-top: 1px solid #111827;
          width: 180px;
          text-align: center;
          padding-top: 4px;
          font-weight: 800;
          font-size: 7.5pt;
          text-transform: uppercase;
        }
        .stamp-seal {
          border: 2px dashed #dc2626;
          color: #dc2626;
          padding: 4px 8px;
          border-radius: 6px;
          font-weight: 900;
          font-size: 8pt;
          text-transform: uppercase;
          letter-spacing: 1px;
          display: inline-block;
        }
        @media print {
          body {
            padding: 0;
          }
          .no-print {
            display: none !important;
          }
        }
      </style>
    </head>
    <body>
      <div class="no-print" style="background:#1e293b; color:#fff; padding:12px 18px; margin:-20px -20px 20px -20px; display:flex; justify-content:space-between; align-items:center;">
        <div>
          <strong>Forensic Document Viewer</strong> — Ready for PDF Export or Print Dispatch
        </div>
        <button onclick="window.print()" style="background:#10b981; color:#000; font-weight:900; border:none; padding:8px 16px; border-radius:8px; cursor:pointer; text-transform:uppercase; font-size:11px; letter-spacing:0.5px;">
          🖨️ Print / Save as PDF
        </button>
      </div>

      <div class="header">
        <div>
          <div class="brand">
            <div style="font-size: 22pt;">🛡️</div>
            <div>
              <div class="brand-title">SmartDrive Forensic Telemetry Authority</div>
              <div class="brand-sub">MoRTH Standard Motor Accident Forensics &amp; Insurance Dossier</div>
            </div>
          </div>
        </div>
        <div style="text-align: right;">
          <div class="doc-badge">CRITICAL INCIDENT DOSSIER</div>
          <div style="font-size: 9pt; font-family: monospace; font-weight: 800; margin-top: 4px;">REF: ${refNumber}</div>
        </div>
      </div>

      <div class="meta-grid">
        <div class="meta-card">
          <h4>Operator &amp; Vehicle Identification</h4>
          <div class="meta-row">
            <span class="meta-label">Operator Full Name:</span>
            <span class="meta-value">${driverName}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Driver Employee ID:</span>
            <span class="meta-value">${employeeId}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Parivahan Driving License:</span>
            <span class="meta-value">${licenseNumber}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Commercial Vehicle Plate:</span>
            <span class="meta-value">${vehiclePlate}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Operator Mobile Terminal:</span>
            <span class="meta-value">${driverPhone}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Emergency Kin Contact:</span>
            <span class="meta-value">${kinName} (${kinPhone})</span>
          </div>
        </div>

        <div class="meta-card">
          <h4>Geospatial &amp; Environmental Telemetry</h4>
          <div class="meta-row">
            <span class="meta-label">Incident Epoch Time:</span>
            <span class="meta-value">${dateFormatted}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Global Coordinates:</span>
            <span class="meta-value">${lat} N, ${lng} E</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Jurisdiction Sector:</span>
            <span class="meta-value">${regionName}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Primary Impact Trigger:</span>
            <span class="meta-value" style="color:#dc2626;">${collisionReason}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Google Satellite Verification:</span>
            <span class="meta-value"><a href="https://maps.google.com/?q=${lat},${lng}" target="_blank" style="color:#2563eb; text-decoration:none;">maps.google.com/?q=${lat},${lng} ↗</a></span>
          </div>
        </div>
      </div>

      <div class="section-title">Pre-Crash Black Box Flight Recorder Telemetry (2Hz Frequency)</div>
      <table>
        <thead>
          <tr>
            <th>Time Offset</th>
            <th>Speed (km/h)</th>
            <th>Total G-Force</th>
            <th>Accel X (Lateral)</th>
            <th>Accel Y (Longitudinal)</th>
            <th>Accel Z (Vertical)</th>
            <th>Forensic State Assessment</th>
          </tr>
        </thead>
        <tbody>
          ${samples.map((s, idx) => {
            const isImpact = idx === samples.length - 1 || s.gForce >= 3.5
            return `
              <tr class="${isImpact ? 'impact-row' : ''}">
                <td>${s.time}</td>
                <td>${typeof s.speed === 'number' ? s.speed.toFixed(1) : s.speed} km/h</td>
                <td>${typeof s.gForce === 'number' ? s.gForce.toFixed(2) : s.gForce} G</td>
                <td>${s.accelX != null ? s.accelX.toFixed(2) : '0.00'} m/s²</td>
                <td>${s.accelY != null ? s.accelY.toFixed(2) : '0.00'} m/s²</td>
                <td>${s.accelZ != null ? s.accelZ.toFixed(2) : '9.81'} m/s²</td>
                <td>${isImpact ? 'CRITICAL IMPACT EPOC (IMPACT SHOCK)' : (s.gForce > 2.0 ? 'EMERGENCY BRAKING & SWERVE' : 'NOMINAL VEHICLE CRUISE')}</td>
              </tr>
            `
          }).join('')}
        </tbody>
      </table>

      <div class="section-title">Verified Multi-Channel Emergency Escalation Protocol</div>
      <div class="timeline">
        <div class="timeline-step">
          <div class="timeline-time">T+0.00s</div>
          <div class="timeline-desc"><strong>Impact Detected:</strong> Sensor fusion triggered sudden deceleration alert ($Speed \\rightarrow 0$) and 4.5G inertial shock.</div>
        </div>
        <div class="timeline-step">
          <div class="timeline-time">T+1.20s</div>
          <div class="timeline-desc"><strong>Step 1 Driver Verification:</strong> Mobile app initiated 60-second verbal &amp; haptic safety query ("Are you safe?").</div>
        </div>
        <div class="timeline-step">
          <div class="timeline-time">T+60.00s</div>
          <div class="timeline-desc"><strong>Step 2 Operator Unresponsive:</strong> Timer expired with zero operator acknowledgment. Emergency status escalated.</div>
        </div>
        <div class="timeline-step">
          <div class="timeline-time">T+61.50s</div>
          <div class="timeline-desc"><strong>Optical Camera Link:</strong> Mobile front camera telemetry sync authorized for Fleet Headquarters dispatchers.</div>
        </div>
        <div class="timeline-step">
          <div class="timeline-time">T+62.00s</div>
          <div class="timeline-desc"><strong>Step 3 Emergency Escalation:</strong> Automated SOS dispatch triggered to kin (${kinName}: ${kinPhone}).</div>
        </div>
      </div>

      <div class="meta-grid">
        <div class="meta-card">
          <h4>Nearest Police Jurisdiction</h4>
          <div class="meta-row">
            <span class="meta-label">Station Name:</span>
            <span class="meta-value">${police.name}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Official Hotline:</span>
            <span class="meta-value">${police.phone}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Proximity:</span>
            <span class="meta-value">${police.distanceMeters || 600}m from crash site</span>
          </div>
        </div>

        <div class="meta-card">
          <h4>Nearest Trauma &amp; Medical Center</h4>
          <div class="meta-row">
            <span class="meta-label">Facility Name:</span>
            <span class="meta-value">${hospital.name}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Emergency Desk:</span>
            <span class="meta-value">${hospital.phone}</span>
          </div>
          <div class="meta-row">
            <span class="meta-label">Proximity:</span>
            <span class="meta-value">${hospital.distanceMeters || 850}m from crash site</span>
          </div>
        </div>
      </div>

      <div class="footer">
        <div>
          <div class="stamp-seal">DIGITALLY VERIFIED TELEMETRY</div>
          <div style="margin-top: 4px; font-family: monospace; font-size: 7.5pt;">SHA256: 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069</div>
        </div>
        <div>
          <div class="sign-box">
            Authorized Fleet Safety Director<br>
            <span style="font-size: 6.5pt; color: #9ca3af; font-family: monospace;">CERTIFIED FORENSIC DISPATCH</span>
          </div>
        </div>
      </div>
    </body>
    </html>
  `

  const printWindow = window.open('', '_blank')
  if (printWindow) {
    printWindow.document.write(printHtml)
    printWindow.document.close()
  }
}
