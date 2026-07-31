import { prisma } from '../database/client';
import { Organization, Prisma, Settings } from '@prisma/client';

export class OrganizationRepository {
  async findById(id: string): Promise<Organization | null> {
    return prisma.organization.findUnique({
      where: { id },
      include: { settings: true },
    });
  }

  async create(name: string): Promise<Organization> {
    return prisma.organization.create({
      data: {
        name,
        settings: {
          create: {}, // Creates settings with default values
        },
      },
      include: { settings: true },
    });
  }

  async update(
    id: string,
    data: Prisma.OrganizationUpdateInput
  ): Promise<Organization> {
    return prisma.organization.update({ where: { id }, data });
  }

  async delete(id: string): Promise<Organization> {
    return prisma.organization.delete({ where: { id } });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.OrganizationWhereInput;
    orderBy?: Prisma.OrganizationOrderByWithRelationInput;
  }): Promise<Organization[]> {
    return prisma.organization.findMany({
      ...params,
      include: { settings: true },
    });
  }

  async getSettings(organizationId: string): Promise<Settings | null> {
    return prisma.settings.findUnique({
      where: { organizationId },
    });
  }

  async updateSettings(
    organizationId: string,
    data: Prisma.SettingsUpdateInput
  ): Promise<Settings> {
    return prisma.settings.update({
      where: { organizationId },
      data,
    });
  }
}
export const organizationRepository = new OrganizationRepository();
