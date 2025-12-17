export interface DayStat {
  date: string // YYYY-MM-DD
  hasDiary: boolean
}

export interface MonthMeta {
  year: number
  month: number // 1-12
  firstDate: string // YYYY-MM-01
  lastDate: string  // YYYY-MM-DD
  daysInMonth: number
  startWeekday: number // 0-6, 周日=0
}

export interface MonthStat {
  meta: MonthMeta
  days: DayStat[]
}

export interface LoadMonthResult {
  month?: MonthStat
  error?: string
}