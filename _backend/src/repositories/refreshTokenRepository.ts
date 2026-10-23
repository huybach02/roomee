import { injectable } from "tsyringe";
import { Repository } from "typeorm";
import { RefreshToken } from "../entities/refreshToken.js";
import { AppDataSource } from "../config/data-source.js";

@injectable()
export class RefreshTokenRepository extends Repository<RefreshToken> {
  constructor() {
    super(RefreshToken, AppDataSource.manager);
  }

  public async findByTokenHash(
    tokenHash: string,
  ): Promise<RefreshToken | null> {
    return this.findOne({
      where: { tokenHash },
      relations: {
        user: true,
      },
    });
  }

  /**
   * Tìm phiên theo tokenHash hiện tại HOẶC previousTokenHash để kiểm tra hợp lệ / phát hiện dùng lại token
   */
  public async findByCurrentOrPreviousTokenHash(
    tokenHash: string,
  ): Promise<RefreshToken | null> {
    return this.findOne({
      where: [{ tokenHash }, { previousTokenHash: tokenHash }],
      relations: {
        user: true,
      },
    });
  }

  public async revokeBySessionId(sessionId: string): Promise<void> {
    await this.update({ id: sessionId }, { isRevoked: true });
  }

  public async revokeAllUserSessions(
    userId: number,
    exceptSessionId?: string,
  ): Promise<void> {
    const qb = this.createQueryBuilder()
      .update(RefreshToken)
      .set({ isRevoked: true })
      .where('"userId" = :userId', { userId })
      .andWhere('"isRevoked" = false');

    if (exceptSessionId) {
      qb.andWhere("id != :exceptSessionId", { exceptSessionId });
    }

    await qb.execute();
  }
}
