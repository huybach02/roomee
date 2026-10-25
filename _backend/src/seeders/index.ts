import { DataSource } from "typeorm";
import { DataUnitsSeeder } from "./dataUnitsSeeder.js";
import { UserSeeder } from "./userSeeder.js";
import { WorkspaceSeeder } from "./workspaceSeeder.js";

export interface ISeeder {
  readonly name: string;
  run(dataSource: DataSource): Promise<void>;
}

export const seeders: ISeeder[] = [
  new DataUnitsSeeder(),
  new UserSeeder(),
  new WorkspaceSeeder(),
];

export { DataUnitsSeeder, UserSeeder, WorkspaceSeeder };
