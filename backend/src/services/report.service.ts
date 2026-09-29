import PDFDocument from 'pdfkit';
import ExcelJS from 'exceljs';
import { prisma } from '../database/client';
import { logger } from '../config/logger';

export class ReportService {
  async getFleetData(organizationId: string, startDate: Date, endDate: Date) {
    const trips = await prisma.trip.findMany({
      where: {
        organizationId,
        startTime: { gte: startDate, lte: endDate },
      },
      include: {
        driver: { include: { user: true } },
        vehicle: true,
      },
    });

    const events = await prisma.event.findMany({
      where: {
        organizationId,
        timestamp: { gte: startDate, lte: endDate },
      },
    });

    const crashes = await prisma.crashReport.findMany({
      where: {
        organizationId,
        timestamp: { gte: startDate, lte: endDate },
      },
    });

    const driversCount = await prisma.driver.count({
      where: { user: { organizationId } },
    });

    const vehiclesCount = await prisma.vehicle.count({
      where: { organizationId },
    });

    return { trips, events, crashes, driversCount, vehiclesCount };
  }

  async generateFleetReport(
    organizationId: string,
    format: 'PDF' | 'EXCEL' | 'CSV',
    startDate: Date,
    endDate: Date
  ): Promise<Buffer> {
    const data = await this.getFleetData(organizationId, startDate, endDate);

    switch (format) {
      case 'PDF':
        return this.generatePDF(data, startDate, endDate);
      case 'EXCEL':
        return this.generateExcel(data, startDate, endDate);
      case 'CSV':
        return this.generateCSV(data);
      default:
        throw new Error('Unsupported report format type');
    }
  }

  private async generatePDF(
    data: any,
    startDate: Date,
    endDate: Date
  ): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({ margin: 50 });
        const buffers: Buffer[] = [];

        doc.on('data', (chunk) => buffers.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(buffers)));

        doc
          .fillColor('#1A1C1E')
          .fontSize(24)
          .text('Smart Driving AI - Operational Summary', { align: 'center' });
        doc.moveDown(0.2);
        doc
          .fillColor('#5B5E62')
          .fontSize(10)
          .text(
            `Period: ${startDate.toDateString()} - ${endDate.toDateString()}`,
            { align: 'center' }
          );
        doc.moveDown(2);

        doc
          .fillColor('#1A1C1E')
          .fontSize(16)
          .text('General Fleet Statistics', { underline: true });
        doc.moveDown(0.5);

        doc.fontSize(11);
        doc.text(`Active Drivers Associated: ${data.driversCount}`);
        doc.text(`Monitored Vehicles: ${data.vehiclesCount}`);
        doc.text(`Total Finished Trips: ${data.trips.length}`);

        let totalDistance = 0;
        data.trips.forEach((t: any) => (totalDistance += t.distance));
        doc.text(`Total Distance Covered: ${totalDistance.toFixed(2)} km`);
        doc.text(`Logged Driving Anomalies: ${data.events.length}`);
        doc.text(`Recorded Collision Events: ${data.crashes.length}`);
        doc.moveDown(2);

        doc.fontSize(16).text('Driving Violations Breakdown', { underline: true });
        doc.moveDown(0.5);
        const harshBraking = data.events.filter(
          (e: any) => e.eventType === 'HARSH_BRAKING'
        ).length;
        const overspeed = data.events.filter(
          (e: any) => e.eventType === 'OVERSPEED'
        ).length;
        const phoneUsage = data.events.filter(
          (e: any) => e.eventType === 'PHONE_USAGE'
        ).length;

        doc.fontSize(11);
        doc.text(`Harsh Braking / Deceleration Spikes: ${harshBraking}`);
        doc.text(`Speed Limit Warnings: ${overspeed}`);
        doc.text(`Distracted Phone Behaviors: ${phoneUsage}`);
        doc.moveDown(2);

        doc.fontSize(16).text('Trip Logs (Recent Entries)', { underline: true });
        doc.moveDown(0.5);
        data.trips.slice(0, 12).forEach((trip: any, index: number) => {
          doc
            .fontSize(9)
            .text(
              `${index + 1}. Driver: ${trip.driver.user.firstName} ${
                trip.driver.user.lastName
              } | Plate: ${trip.vehicle.licensePlate} | Distance: ${
                trip.distance
              } km | Max Speed: ${trip.maxSpeed} km/h`
            );
        });

        if (data.trips.length > 12) {
          doc.text(`... and ${data.trips.length - 12} other trips.`);
        }

        doc.end();
      } catch (err) {
        logger.error('Failed to generate PDF document buffer', err);
        reject(err);
      }
    });
  }

  private async generateExcel(
    data: any,
    startDate: Date,
    endDate: Date
  ): Promise<Buffer> {
    const workbook = new ExcelJS.Workbook();

    const summarySheet = workbook.addWorksheet('Operational Summary');
    summarySheet.columns = [
      { header: 'Metric', key: 'metric', width: 25 },
      { header: 'Value', key: 'value', width: 20 },
    ];
    summarySheet.addRow({
      metric: 'Report Generated',
      value: new Date().toDateString(),
    });
    summarySheet.addRow({
      metric: 'Range Start',
      value: startDate.toDateString(),
    });
    summarySheet.addRow({ metric: 'Range End', value: endDate.toDateString() });
    summarySheet.addRow({ metric: 'Active Drivers', value: data.driversCount });
    summarySheet.addRow({ metric: 'Registered Vehicles', value: data.vehiclesCount });
    summarySheet.addRow({ metric: 'Trips Logged', value: data.trips.length });

    let totalDistance = 0;
    data.trips.forEach((t: any) => (totalDistance += t.distance));
    summarySheet.addRow({
      metric: 'Cumulative Distance (km)',
      value: totalDistance,
    });
    summarySheet.addRow({ metric: 'Anomalous Events', value: data.events.length });
    summarySheet.addRow({ metric: 'Crashes Logged', value: data.crashes.length });

    const tripsSheet = workbook.addWorksheet('Trips Log');
    tripsSheet.columns = [
      { header: 'Trip ID', key: 'id', width: 36 },
      { header: 'Driver', key: 'driver', width: 20 },
      { header: 'License Plate', key: 'plate', width: 15 },
      { header: 'Distance (km)', key: 'distance', width: 15 },
      { header: 'Duration (s)', key: 'duration', width: 15 },
      { header: 'Avg Speed (km/h)', key: 'avgSpeed', width: 15 },
      { header: 'Max Speed (km/h)', key: 'maxSpeed', width: 15 },
    ];
    data.trips.forEach((t: any) => {
      tripsSheet.addRow({
        id: t.id,
        driver: `${t.driver.user.firstName} ${t.driver.user.lastName}`,
        plate: t.vehicle.licensePlate,
        distance: t.distance,
        duration: t.duration,
        avgSpeed: t.avgSpeed,
        maxSpeed: t.maxSpeed,
      });
    });

    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer as any);
  }

  private async generateCSV(data: any): Promise<Buffer> {
    let csv =
      'Trip ID,Driver,Plate,Distance (km),Duration (s),Avg Speed (km/h),Max Speed (km/h)\n';
    data.trips.forEach((t: any) => {
      const name = `"${t.driver.user.firstName} ${t.driver.user.lastName}"`;
      csv += `${t.id},${name},${t.vehicle.licensePlate},${t.distance},${t.duration},${t.avgSpeed},${t.maxSpeed}\n`;
    });
    return Buffer.from(csv, 'utf-8');
  }
}
export const reportService = new ReportService();
