import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DiaryPayload } from '../common/SimpleDiaryRecord' // 按你的实际路径保持不变
import { AiDiaryEntity } from "../utils/DiaryCodec"

export class AiDiaryRepository {
  // 不在构造时触发 getStore，避免 DB 尚未 init 就抛错
  constructor() {}

  // 懒获取，调用时再取
  private get store(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  toEntity(date: string, diary: DiaryPayload, model?: string, latencyMs?: number): AiDiaryEntity {
    const now: string = new Date().toISOString()
    return {
      id: date,
      date,
      title: diary.title ?? '',
      content: diary.content ?? '',
      sectionsJson: JSON.stringify(diary.sections ?? []),
      tagsJson: JSON.stringify(diary.tags ?? []),
      imagesJson: JSON.stringify(diary.images ?? []),
      promptEcho: diary.promptEcho ?? '',
      model,
      latencyMs,
      createdAt: now,
      updatedAt: now
    }
  }

  // 用 ValuesBucket/Predicates 实现 upsert，类型更稳
  async upsert(entity: AiDiaryEntity): Promise<void> {
    // 先判断是否存在
    const pred = new relationalStore.RdbPredicates('ai_diary')
    pred.equalTo('date', entity.date)
    const rs = await this.store.query(pred, ['id'])
    const exists: boolean = rs.rowCount > 0
    rs.close()

    const values: relationalStore.ValuesBucket = {
      id: entity.id,
      date: entity.date,
      title: entity.title,
      content: entity.content,
      sectionsJson: entity.sectionsJson,
      tagsJson: entity.tagsJson,
      imagesJson: entity.imagesJson,
      promptEcho: entity.promptEcho,
      model: entity.model ?? null,
      latencyMs: entity.latencyMs ?? null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt
    }

    if (exists) {
      const upd = new relationalStore.RdbPredicates('ai_diary')
      upd.equalTo('date', entity.date)
      await this.store.update(values, upd)
    } else {
      await this.store.insert('ai_diary', values)
    }
  }

  async getByDate(date: string): Promise<AiDiaryEntity | null> {
    const columns: string[] = [
      'id','date','title','content','sectionsJson','tagsJson','imagesJson','promptEcho','model','latencyMs','createdAt','updatedAt'
    ]
    const pred = new relationalStore.RdbPredicates('ai_diary')
    pred.equalTo('date', date)
    const rs = await this.store.query(pred, columns)
    if (rs.rowCount === 0) { rs.close(); return null }
    rs.goToFirstRow()
    const idx = (k: string) => columns.indexOf(k)
    const entity: AiDiaryEntity = {
      id: rs.getString(idx('id')),
      date: rs.getString(idx('date')),
      title: rs.getString(idx('title')),
      content: rs.getString(idx('content')),
      sectionsJson: rs.getString(idx('sectionsJson')),
      tagsJson: rs.getString(idx('tagsJson')),
      imagesJson: rs.getString(idx('imagesJson')),
      promptEcho: rs.getString(idx('promptEcho')),
      model: rs.isColumnNull(idx('model')) ? undefined : rs.getString(idx('model')),
      latencyMs: Number(rs.getLong(idx('latencyMs'))),
      createdAt: rs.getString(idx('createdAt')),
      updatedAt: rs.getString(idx('updatedAt'))
    }
    rs.close()
    return entity
  }
}