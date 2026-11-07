import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import { Workspace } from "../entities/workspace.js";
import { AppDataSource } from "../config/data-source.js";

@injectable()
export class WorkspaceRepository extends Repository<Workspace> {
  constructor() {
    super(Workspace, AppDataSource.manager);
  }

  public async findByIdWithRelations(id: string): Promise<Workspace | null> {
    return this.createQueryBuilder("workspaces")
      .leftJoinAndSelect("workspaces.province", "province")
      .leftJoinAndSelect("workspaces.ward", "ward")
      .leftJoinAndSelect("workspaces.user", "user")
      .where("workspaces.id = :id", { id })
      .getOne();
  }
}
