import { prisma } from '../database/client';
import { CrashReport, Prisma, Media } from '@prisma/client';

export class CrashRepository {
  async findById(id: string): Promise<CrashReport | null> {
    return prisma.crashReport.findUnique({
      where: { id },
      include: {
        driver: { include: { user: true } },
        vehicle: true,
        trip: true,
        media: true,
      },
    });
  }

  async create(
    data: Prisma.CrashReportUncheckedCreateInput
  ): Promise<CrashReport> {
    return prisma.crashReport.create({ data });
  }

  async update(
    id: string,
    data: Prisma.CrashReportUpdateInput
  ): Promise<CrashReport> {
    return prisma.crashReport.update({
      where: { id },
      data,
    });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.CrashReportWhereInput;
    orderBy?: Prisma.CrashReportOrderByWithRelationInput;
  }): Promise<CrashReport[]> {
    return prisma.crashReport.findMany({
      ...params,
      include: {
        driver: { include: { user: true } },
        vehicle: true,
        media: true,
      },
    });
  }

  async count(where?: Prisma.CrashReportWhereInput): Promise<number> {
    return prisma.crashReport.count({ where });
  }

  async addMedia(data: Prisma.MediaUncheckedCreateInput): Promise<Media> {
    return prisma.media.create({ data });
  }
}
export const crashRepository = new CrashRepository();
