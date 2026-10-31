import { injectable } from "tsyringe";
import { Workspace } from "../../entities/workspace.js";
import { WorkspaceRepository } from "../../repositories/workspaceRepository.js";
import { UserRepository } from "../../repositories/userRepository.js";
import { ProvinceRepository } from "../../repositories/provinceRepository.js";
import { WardRepository } from "../../repositories/wardRepository.js";
import { UserRole } from "../../utils/constanst.js";
import { AppError } from "../../utils/appError.js";
import { t } from "../../utils/i18n.js";
import { QueryHelper, FilterSchema } from "../../utils/queryHelper.js";
import {
  CreateWorkspaceDto,
  UpdateWorkspaceDto,
  WorkspaceQueryDto,
} from "./workspaceSchema.js";

const WORKSPACE_SEARCH_FIELDS = [
  "workspace.name",
  "workspace.address",
  "workspace.contactName",
  "workspace.contactPhone",
  "province.fullName",
  "ward.fullName",
];

const WORKSPACE_FILTER_SCHEMA: FilterSchema<WorkspaceQueryDto> = {
  type: { operator: "eq", field: "workspace.type" },
  status: { operator: "eq", field: "workspace.status" },
  provinceId: { operator: "eq", field: "workspace.provinceId" },
  wardId: { operator: "eq", field: "workspace.wardId" },
};

const WORKSPACE_SORT_MAP: Record<string, string> = {
  createdAt: "workspace.createdAt",
  name: "workspace.name",
  area: "workspace.area",
  numberOfRooms: "workspace.numberOfRooms",
};

@injectable()
export class WorkspaceService {
  constructor(
    private workspaceRepository: WorkspaceRepository,
    private userRepository: UserRepository,
    private provinceRepository: ProvinceRepository,
    private wardRepository: WardRepository,
  ) {}

  public async getWorkspaces(
    userId: string,
    userRole: string,
    query: WorkspaceQueryDto,
  ): Promise<{
    data: Workspace[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }> {
    const qb = this.workspaceRepository
      .createQueryBuilder("workspace")
      .leftJoinAndSelect("workspace.province", "province")
      .leftJoinAndSelect("workspace.ward", "ward");

    if (userRole !== UserRole.ADMIN) {
      qb.andWhere("workspace.userId = :userId", { userId });
    }

    QueryHelper.applySearch(qb, query.search, WORKSPACE_SEARCH_FIELDS);
    QueryHelper.applyFilters(qb, query, WORKSPACE_FILTER_SCHEMA);

    QueryHelper.applySorting(
      qb,
      QueryHelper.parseSort(
        query.sort,
        query.sortBy
          ? [{ field: query.sortBy, order: query.sortOrder }]
          : undefined,
      ),
      WORKSPACE_SORT_MAP,
      {},
      { field: "workspace.createdAt", order: "DESC" },
    );

    return QueryHelper.paginate(qb, query.page, query.limit, query.all);
  }

  public async getWorkspaceById(
    id: string,
    userId: string,
    userRole: string,
  ): Promise<Workspace> {
    const workspace = await this.workspaceRepository.findByIdWithRelations(id);

    if (!workspace) {
      throw AppError.notFound(t("workspace.notFound"));
    }

    if (userRole !== UserRole.ADMIN && workspace.userId !== userId) {
      throw AppError.forbidden(t("workspace.forbidden"));
    }

    return workspace;
  }

  public async createWorkspace(
    userId: string,
    dto: CreateWorkspaceDto,
  ): Promise<Workspace> {
    const user = await this.userRepository.findOneBy({ id: userId });
    if (!user || !user.isActive) {
      throw AppError.forbidden(t("auth.accountInactive"));
    }
    if (user.role !== UserRole.LANDLORD && user.role !== UserRole.ADMIN) {
      throw AppError.forbidden(t("workspace.onlyLandlordCanCreate"));
    }

    const province = await this.provinceRepository.findOneBy({
      id: dto.provinceId,
    });
    if (!province) {
      throw AppError.badRequest(t("workspace.provinceNotFound"));
    }

    const ward = await this.wardRepository.findOneBy({ id: dto.wardId });
    if (!ward) {
      throw AppError.badRequest(t("workspace.wardNotFound"));
    }
    if (ward.provinceId !== dto.provinceId) {
      throw AppError.badRequest(t("workspace.wardNotInProvince"));
    }

    const workspace = this.workspaceRepository.create({
      userId,
      name: dto.name,
      type: dto.type,
      area: dto.area,
      numberOfRooms: dto.numberOfRooms ?? 0,
      provinceId: dto.provinceId,
      wardId: dto.wardId,
      address: dto.address,
      description: dto.description ?? null,
      contactName: dto.contactName,
      contactPhone: dto.contactPhone,
      contactZalo: dto.contactZalo ?? null,
      status: dto.status ?? 1,
    });

    const savedWorkspace = await this.workspaceRepository.save(workspace);
    const fullWorkspace = await this.workspaceRepository.findByIdWithRelations(
      savedWorkspace.id,
    );
    return fullWorkspace ?? savedWorkspace;
  }

  public async updateWorkspace(
    id: string,
    userId: string,
    userRole: string,
    dto: UpdateWorkspaceDto,
  ): Promise<Workspace> {
    const workspace = await this.workspaceRepository.findOneBy({ id });

    if (!workspace) {
      throw AppError.notFound(t("workspace.notFound"));
    }

    if (userRole !== UserRole.ADMIN && workspace.userId !== userId) {
      throw AppError.forbidden(t("workspace.forbidden"));
    }

    const targetProvinceId = dto.provinceId ?? workspace.provinceId;
    const targetWardId = dto.wardId ?? workspace.wardId;

    if (dto.provinceId) {
      const province = await this.provinceRepository.findOneBy({
        id: dto.provinceId,
      });
      if (!province) {
        throw AppError.badRequest(t("workspace.provinceNotFound"));
      }
    }

    if (dto.wardId || dto.provinceId) {
      const ward = await this.wardRepository.findOneBy({
        id: targetWardId,
      });
      if (!ward) {
        throw AppError.badRequest(t("workspace.wardNotFound"));
      }
      if (ward.provinceId !== targetProvinceId) {
        throw AppError.badRequest(t("workspace.wardNotInProvince"));
      }
    }

    this.workspaceRepository.merge(workspace, dto);

    await this.workspaceRepository.save(workspace);

    return this.getWorkspaceById(id, userId, userRole);
  }

  public async deleteWorkspace(id: string, userId: string): Promise<boolean> {
    const workspace = await this.workspaceRepository.findOneBy({ id });

    if (!workspace) {
      throw AppError.notFound(t("workspace.notFound"));
    }

    if (workspace.userId !== userId) {
      throw AppError.forbidden(t("workspace.forbidden"));
    }

    await this.workspaceRepository.softRemove(workspace);
    return true;
  }
}
