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
    return this.createQueryBuilder("workspace")
      .leftJoinAndSelect("workspace.province", "province")
      .leftJoinAndSelect("workspace.ward", "ward")
      .leftJoinAndSelect("workspace.user", "user")
      .where("workspace.id = :id", { id })
      .getOne();
  }
}
