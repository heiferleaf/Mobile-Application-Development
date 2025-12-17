import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { SimpleDiaryRecord } from '../common/SimpleDiaryRecord'

export class RecordRepository {
  constructor() {}

  private get store(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  async insert(rec: SimpleDiaryRecord): Promise<number> {
    const values: relationalStore.ValuesBucket = {
      id: rec.id,
      type: rec.type,
      time: rec.time,
      content: rec.content,
      imageUrl: rec.imageUrl ?? null,
      location: rec.location ?? null
    }
    return await this.store.insert('records', values)
  }

  async queryToday(datePrefix: string): Promise<SimpleDiaryRecord[]> {
    const columns: string[] = ['id','type','time','content','imageUrl','location']
    const pred = new relationalStore.RdbPredicates('records')
    pred.like('time', `${datePrefix}%`)
    const rs: relationalStore.ResultSet = await this.store.query(pred, columns)

    const out: SimpleDiaryRecord[] = []
    try {
      if (rs.rowCount > 0) {
        rs.goToFirstRow()
        do {
          const typeStr = rs.getString(1)
          const type: 'text'|'image'|'voice' = typeStr === 'image' ? 'image' : (typeStr === 'voice' ? 'voice' : 'text')
          out.push({
            id: rs.getString(0),
            type,
            time: rs.getString(2),
            content: rs.getString(3),
            imageUrl: rs.isColumnNull(4) ? undefined : rs.getString(4),
            location: rs.isColumnNull(5) ? undefined : rs.getString(5),
          })
        } while (rs.goToNextRow())
      }
    } finally {
      rs.close()
    }
    return out
  }
}