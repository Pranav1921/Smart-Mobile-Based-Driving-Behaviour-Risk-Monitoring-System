import { eventRepository } from '../repositories/event.repository';
import { organizationRepository } from '../repositories/organization.repository';
import { prisma } from '../database/client';
import { socketManager } from '../sockets/socket.manager';
import { EventType, Severity, NotificationType, Event } from '@prisma/client';
import { logger } from '../config/logger';

export class EventService {
  async logEvent(data: {
    tripId?: string;
    driverId: string;
    organizationId: string;
    eventType: EventType;
    latitude: number;
    longitude: number;
    sensorValues?: any;
    timestamp?: string;
  }): Promise<Event> {
    logger.info(
      `Logging telemetry event: ${data.eventType} for driver ${data.driverId}`
    );

    const settings = await organizationRepository.getSettings(
      data.organizationId
    );
    let severity: Severity = Severity.LOW;

    // Severity estimation guidelines
    if (data.eventType === EventType.OVERSPEED && settings) {
      const overspeedVal = data.sensorValues?.speed || 0;
      const diff = overspeedVal - settings.overspeedThreshold;
      if (diff > 20) {
        severity = Severity.CRITICAL;
      } else if (diff > 10) {
        severity = Severity.HIGH;
      } else {
        severity = Severity.MEDIUM;
      }
    } else if (data.eventType === EventType.HARSH_BRAKING) {
      severity = Severity.HIGH;
    } else if (data.eventType === EventType.CRASH) {
      severity = Severity.CRITICAL;
    }

    const event = await eventRepository.create({
      tripId: data.tripId || null,
      driverId: data.driverId,
      organizationId: data.organizationId,
      eventType: data.eventType,
      severity,
      latitude: data.latitude,
      longitude: data.longitude,
      sensorValues: data.sensorValues || null,
      timestamp: data.timestamp ? new Date(data.timestamp) : new Date(),
    });

    // Real-time notification over socket channel
    socketManager.broadcastToOrg(data.organizationId, 'driver_event', event);

    // Save persistent dashboard notifications for critical alerts
    if (severity === Severity.HIGH || severity === Severity.CRITICAL) {
      const message = `Critical alert: ${
        data.eventType
      } detected. Coordinates: (${data.latitude}, ${
        data.longitude
      }). Priority level: ${severity}`;

      // Notify organization managers
      const admins = await prisma.user.findMany({
        where: {
          organizationId: data.organizationId,
          role: { in: ['FLEET_ADMIN', 'FLEET_MANAGER'] },
        },
      });

      // Notify the driver
      const driverProfile = await prisma.driver.findUnique({
        where: { id: data.driverId },
        include: { user: true },
      });

      const notifyRecipients = [...admins];
      if (driverProfile?.user) {
        notifyRecipients.push(driverProfile.user);
      }

      await Promise.all(
        notifyRecipients.map((rec) =>
          prisma.notification.create({
            data: {
              userId: rec.id,
              organizationId: data.organizationId,
              title: `Incident: ${data.eventType}`,
              message,
              type: this.mapEventTypeToNotification(data.eventType),
            },
          })
        )
      );

      admins.forEach((admin) => {
        socketManager.sendToUser(admin.id, 'notification', {
          title: `Incident Warning: ${data.eventType}`,
          message,
          severity,
        });
      });
    }

    return event;
  }

  private mapEventTypeToNotification(evt: EventType): NotificationType {
    switch (evt) {
      case EventType.CRASH:
        return NotificationType.EMERGENCY;
      case EventType.OVERSPEED:
        return NotificationType.OVERSPEED;
      case EventType.GPS_LOST:
        return NotificationType.GPS_LOST;
      case EventType.LOW_BATTERY:
        return NotificationType.BATTERY_LOW;
      default:
        return NotificationType.SYSTEM;
    }
  }

  async getEventsList(
    organizationId?: string,
    query: {
      skip?: number;
      take?: number;
      driverId?: string;
      eventType?: EventType;
      severity?: Severity;
    } = {}
  ): Promise<{ events: Event[]; count: number }> {
    const where: any = organizationId ? { organizationId } : {};
    if (query.driverId) {
      where.driverId = query.driverId;
    }
    if (query.eventType) {
      where.eventType = query.eventType;
    }
    if (query.severity) {
      where.severity = query.severity;
    }

    const skip = Number(query.skip) || 0;
    const take = Number(query.take) || 10;

    const events = await eventRepository.findMany({
      skip,
      take,
      where,
      orderBy: { timestamp: 'desc' },
    });
    const count = await eventRepository.count(where);

    return { events, count };
  }
}
export const eventService = new EventService();
