import type { ObjectLiteral, SelectQueryBuilder } from "typeorm";

export interface RelationJoin<Entity extends ObjectLiteral> {
  relationJoin(
    queryBuilder: SelectQueryBuilder<Entity>,
  ): SelectQueryBuilder<Entity>;
}
