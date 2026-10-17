import { DataSource } from "typeorm";
import { DataUnitsSeeder } from "./dataUnitsSeeder.js";

export interface ISeeder {
  readonly name: string;
  run(dataSource: DataSource): Promise<void>;
}

export const seeders: ISeeder[] = [
  new DataUnitsSeeder(),
];
