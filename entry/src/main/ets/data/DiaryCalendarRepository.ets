import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DayStat, MonthMeta, MonthStat, LoadMonthResult } from '../common/CalendarTypes'
import { DiarySummary } from '../common/DiarySummary'
import { DiaryCodec, AiDiaryEntityModel } from '../utils/DiaryCodec'

export interface GetByDateResult {
  item?: DiarySummary
  error?: string
}

export class DiaryCalendarRepository {
  constructor() {}

  private get store(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  async getByDate(date: string): Promise<GetByDateResult> {
    try {
      const cols: string[] = [
        'id','date','title','content','sectionsJson','tagsJson','imagesJson','promptEcho','model','latencyMs','createdAt','updatedAt'
      ]
      const pred = new relationalStore.RdbPredicates('ai_diary')
      pred.equalTo('date', date)

      const rs = await this.store.query(pred, cols)
      try {
        if (rs.rowCount > 0) {
          rs.goToFirstRow()
          const e: AiDiaryEntityModel = new AiDiaryEntityModel({
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
          });
          const item: DiarySummary = DiaryCodec.toSummary(e)
          const ok: GetByDateResult = { item }
          return ok
        }
        const empty: GetByDateResult = { item: undefined }
        return empty
      } finally {
        rs.close()
      }
    } catch (e) {
      const msg: string = typeof e === 'object' ? JSON.stringify(e) : String(e)
      const err: GetByDateResult = { error: msg }
      return err
    }
  }

  private buildMonthMeta(year: number, month: number): MonthMeta {
    const firstDay = new Date(year, month - 1, 1)
    const nextMonthFirst = new Date(year, month, 1)
    const lastDayDate = new Date(nextMonthFirst.getTime() - 24 * 3600 * 1000)
    const pad = (n: number) => (n < 10 ? `0${n}` : `${n}`)
    const firstDate = `${firstDay.getFullYear()}-${pad(firstDay.getMonth() + 1)}-01`
    const lastDate = `${lastDayDate.getFullYear()}-${pad(lastDayDate.getMonth() + 1)}-${pad(lastDayDate.getDate())}`
    return {
      year,
      month,
      firstDate,
      lastDate,
      daysInMonth: lastDayDate.getDate(),
      startWeekday: firstDay.getDay()
    }
  }

  async loadMonth(year: number, month: number): Promise<LoadMonthResult> {
    try {
      const meta: MonthMeta = this.buildMonthMeta(year, month)
      const cols: string[] = ['date']
      const pred = new relationalStore.RdbPredicates('ai_diary')
      pred.greaterThanOrEqualTo('date', meta.firstDate)
      pred.lessThanOrEqualTo('date', meta.lastDate)
      // 如果你的 RDB 支持 distinct，可开启；不支持也没关系，本表一日一条
      const rs = await this.store.query(pred, cols)

      const set = new Set<string>()
      try {
        if (rs.rowCount > 0) {
          rs.goToFirstRow()
          do {
            set.add(rs.getString(0))
          } while (rs.goToNextRow())
        }
      } finally {
        rs.close()
      }

      const pad = (n: number) => (n < 10 ? `0${n}` : `${n}`)
      const days: DayStat[] = []
      for (let d = 1; d <= meta.daysInMonth; d++) {
        const date = `${meta.year}-${pad(meta.month)}-${pad(d)}`
        days.push({ date, hasDiary: set.has(date) })
      }

      const monthStat: MonthStat = { meta, days }
      return { month: monthStat }
    } catch (e) {
      const msg: string = typeof e === 'object' ? JSON.stringify(e) : String(e)
      const result: LoadMonthResult = { error: msg }
      return result
    }
  }
}