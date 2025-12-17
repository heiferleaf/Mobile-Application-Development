import { MonthStat, DayStat } from '../common/CalendarTypes'

export interface CalendarHeatmapHandlers {
  onSelect?: (date: string) => void
}

function defaultMonth(): MonthStat {
  return {
    meta: {
      year: 1970,
      month: 1,
      firstDate: '1970-01-01',
      lastDate: '1970-01-31',
      daysInMonth: 31,
      startWeekday: 0
    },
    days: []
  }
}

function defaultHandlers(): CalendarHeatmapHandlers {
  const h: CalendarHeatmapHandlers = { onSelect: undefined }
  return h
}

@Component
export default struct CalendarHeatmap {
  @State month: MonthStat = defaultMonth()
  @State handlers: CalendarHeatmapHandlers = defaultHandlers()

  private rows(): number {
    const lead = this.month.meta.startWeekday
    const total = lead + this.month.meta.daysInMonth
    return Math.ceil(total / 7)
  }

  private rowIndices(): number[] {
    const n = this.rows()
    const a: number[] = []
    for (let i = 0; i < n; i++) {
      a.push(i)
    }
    return a
  }

  private colIndices(): number[] {
    return [0, 1, 2, 3, 4, 5, 6]
  }

  private hasCell(r: number, c: number): boolean {
    const lead = this.month.meta.startWeekday
    const idx = r * 7 + c
    return idx >= lead && idx < lead + this.month.meta.daysInMonth
  }

  private dayIndex(r: number, c: number): number {
    const lead = this.month.meta.startWeekday
    return r * 7 + c - lead
  }

  private colorFor(hasDiary: boolean): string {
    return hasDiary ? '#A69181' : '#ECE7E3'
  }

  private textColorFor(hasDiary: boolean): string {
    return hasDiary ? '#FFFFFF' : '#5D5652'
  }

  private weekdayLabel(i: number): string {
    const arr: string[] = ['日', '一', '二', '三', '四', '五', '六']
    return arr[i]
  }

  @Builder
  private Cell(r: number, c: number) {
    if (!this.hasCell(r, c)) {
      Blank()
        .width('14.285%')
        .aspectRatio(1)
        .margin({ bottom: 6 })
    } else {
      // 重要：不写 const/let，全部用内联表达式
      Button() {
        Text(`${this.dayIndex(r, c) + 1}`)
          .fontSize(14)
          .fontColor(
            this.textColorFor(
              this.month.days[this.dayIndex(r, c)].hasDiary
            )
          )
      }
      .width('14.285%')
      .aspectRatio(1)
      .margin({ bottom: 6 })
      .backgroundColor(
        this.colorFor(
          this.month.days[this.dayIndex(r, c)].hasDiary
        )
      )
      .borderRadius(8)
      .onClick(() => {
        if (this.month.days[this.dayIndex(r, c)].hasDiary && this.handlers.onSelect) {
          this.handlers.onSelect(this.month.days[this.dayIndex(r, c)].date)
        }
      })
    }
  }

  build() {
    Column() {
      Row() {
        Text(`${this.month.meta.year} 年 ${this.month.meta.month} 月`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F2B28')
        Blank()
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        ForEach(this.colIndices(), (i: number) => {
          Text(this.weekdayLabel(i))
            .fontSize(12)
            .fontColor('#8B8079')
            .width('14.285%')
            .textAlign(TextAlign.Center)
        }, (i: number) => `w${i}`)
      }
      .width('100%')
      .margin({ bottom: 6 })

      Column() {
        ForEach(this.rowIndices(), (r: number) => {
          Row() {
            ForEach(this.colIndices(), (c: number) => {
              this.Cell(r, c)
            }, (c: number) => `c${r}-${c}`)
          }
          .width('100%')
        }, (r: number) => `r${r}`)
      }
      .width('100%')

      Row() {
        Row() {
          Blank()
            .width(16)
            .height(16)
            .backgroundColor('#ECE7E3')
            .borderRadius(4)
          Text('无日记')
            .fontSize(12)
            .fontColor('#8B8079')
            .margin({ left: 6 })
        }
        .margin({ right: 12 })

        Row() {
          Blank()
            .width(16)
            .height(16)
            .backgroundColor('#A69181')
            .borderRadius(4)
          Text('有日记')
            .fontSize(12)
            .fontColor('#8B8079')
            .margin({ left: 6 })
        }
      }
      .margin({ top: 6 })
    }
    .padding(12)
    .borderRadius(16)
    .backgroundColor('rgba(255, 255, 255, 0.65)')
    .backdropBlur(15)
    .shadow({ radius: 10, color: 'rgba(166, 145, 129, 0.15)', offsetY: 4 })
  }
}