import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DiarySummary } from '../common/DiarySummary'
import { DiaryCodec, AiDiaryEntityModel } from '../utils/DiaryCodec'

export interface GetByDateResult {
  item?: DiarySummary
  error?: string
}

export interface GetEntityByDateResult {
  entity?: AiDiaryEntityModel
  error?: string
}

export class DiaryHistoryRepository {
  constructor() {}

  private get store(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  // 私有：统一的“按日期查询并返回类实例”，避免重复代码
  private async queryEntityByDate(date: string): Promise<AiDiaryEntityModel | undefined> {
    const cols: string[] = [
      'id','date','title','content','sectionsJson','tagsJson','imagesJson','promptEcho','model','latencyMs','createdAt','updatedAt'
    ]
    const pred: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('ai_diary')
    pred.equalTo('date', date)

    const rs: relationalStore.ResultSet = await this.store.query(pred, cols)
    try {
      if (rs.rowCount === 0) {
        return undefined
      }
      rs.goToFirstRow()
      const model: AiDiaryEntityModel = new AiDiaryEntityModel({
        id: rs.getString(0),
        date: rs.getString(1),
        title: rs.getString(2),
        content: rs.getString(3),
        sectionsJson: rs.getString(4),
        tagsJson: rs.getString(5),
        imagesJson: rs.getString(6),
        promptEcho: rs.getString(7),
        model: rs.isColumnNull(8) ? undefined : rs.getString(8),
        latencyMs: Number(rs.getLong(9)),
        createdAt: rs.getString(10),
        updatedAt: rs.getString(11)
      })
      return model
    } finally {
      rs.close()
    }
  }

  // 历史页概要用：返回 DiarySummary
  async getByDate(date: string): Promise<GetByDateResult> {
    try {
      const entity: AiDiaryEntityModel | undefined = await this.queryEntityByDate(date)
      if (!entity) {
        return { item: undefined }
      }
      const item: DiarySummary = DiaryCodec.toSummary(entity)
      return { item }
    } catch (err) {
      const msg: string = typeof err === 'string' ? err : JSON.stringify(err)
      return { error: msg }
    }
  }

  // 详情页用：返回完整实体（类实例）
  async getEntityByDate(date: string): Promise<GetEntityByDateResult> {
    try {
      const entity: AiDiaryEntityModel | undefined = await this.queryEntityByDate(date)
      return { entity }
    } catch (err) {
      const msg: string = typeof err === 'string' ? err : JSON.stringify(err)
      return { error: msg }
    }
  }
}