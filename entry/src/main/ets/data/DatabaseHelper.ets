import relationalStore from '@ohos.data.relationalStore'
import common from '@ohos.app.ability.common'

export interface DBConfig {
  name: string
  version: number // 仅自维护；API 20 的 getRdbStore 不使用 version 参数
}

export class DatabaseHelper {
  private static appContext?: common.UIAbilityContext
  private static store?: relationalStore.RdbStore
  private static inited = false
  private static dbName = 'dayloom.db'

  static setContext(ctx: common.UIAbilityContext): void {
    DatabaseHelper.appContext = ctx
  }

  static setDbName(name: string): void {
    DatabaseHelper.dbName = name
  }

  static async init(): Promise<void> {
    if (DatabaseHelper.inited) return
    if (!DatabaseHelper.appContext) {
      throw new Error('DatabaseHelper: appContext is not set. Call DatabaseHelper.setContext(ctx) first.')
    }

    const cfg: relationalStore.StoreConfig = {
      name: DatabaseHelper.dbName,
      securityLevel: relationalStore.SecurityLevel.S2
    }

    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(DatabaseHelper.appContext, cfg)

    // 1) 记录表（已有）
    const createRecordsSql = `
      CREATE TABLE IF NOT EXISTS records (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        time TEXT NOT NULL,
        content TEXT NOT NULL,
        imageUrl TEXT,
        location TEXT
      );
    `
    await store.executeSql(createRecordsSql)
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_time ON records(time);')

    // 2) 生成结果表（新增）：ai_diary（每天一篇；入库时序列化 sections/tags/images）
    const createAiDiarySql = `
      CREATE TABLE IF NOT EXISTS ai_diary (
        id TEXT PRIMARY KEY,        -- 可用 date 作为主键，或 uuid
        date TEXT UNIQUE,           -- 'YYYY-MM-DD'，唯一约束（每天一篇）
        title TEXT,
        content TEXT,
        sectionsJson TEXT,          -- JSON.stringify(DiarySection[])
        tagsJson TEXT,              -- JSON.stringify(string[])
        imagesJson TEXT,            -- JSON.stringify(DiaryImagePlacement[])
        promptEcho TEXT,            -- 提示词快照
        model TEXT,
        latencyMs INTEGER,
        createdAt TEXT,             -- ISO
        updatedAt TEXT              -- ISO
      );
    `
    await store.executeSql(createAiDiarySql)
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_ai_date ON ai_diary(date);')

    DatabaseHelper.store = store
    DatabaseHelper.inited = true
  }

  static getStore(): relationalStore.RdbStore {
    if (!DatabaseHelper.store) {
      throw new Error('DatabaseHelper: store is not initialized. Call DatabaseHelper.init() first.')
    }
    return DatabaseHelper.store
  }
}