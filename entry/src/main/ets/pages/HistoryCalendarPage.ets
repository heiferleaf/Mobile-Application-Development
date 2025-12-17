import BottomNavBar from '../components/BottomNavBar'
import router from '@ohos.router'
import { DiaryCalendarRepository } from '../data/DiaryCalendarRepository'
import { DiaryHistoryRepository } from '../data/DiaryHistoryRepository'
import { MonthStat, MonthMeta } from '../common/CalendarTypes'
import CalendarHeatmap, { CalendarHeatmapHandlers } from '../components/CalendarHeatmap'
import { DiarySummary } from '../common/DiarySummary'

function emptyMonth(): MonthStat {
  const meta: MonthMeta = { year: 1970, month: 1, firstDate: '1970-01-01', lastDate: '1970-01-31', daysInMonth: 31, startWeekday: 0 }
  return { meta, days: [] }
}
function defaultHandlers(): CalendarHeatmapHandlers { return { onSelect: undefined } }

@Entry
@Component
export default struct HistoryCalendarPage {
  private calRepo: DiaryCalendarRepository = new DiaryCalendarRepository()
  private histRepo: DiaryHistoryRepository = new DiaryHistoryRepository()

  @State month: MonthStat = emptyMonth()
  @State loading: boolean = false
  @State errorMsg: string = ''

  @State showGenerationModalLocal: boolean = false
  @State bottomIndexInit: number = 2

  // 选中日期与概要
  @State selectedDate: string = ''
  @State summary?: DiarySummary = undefined

  // 传给日历组件的回调
  @State heatmapHandlers: CalendarHeatmapHandlers = defaultHandlers()

  aboutToAppear() {
    // 绑定选择事件
    this.heatmapHandlers = { onSelect: (date: string) => this.onSelectDate(date) }

    const d = new Date()
    this.loadMonth(d.getFullYear(), d.getMonth() + 1).then(() => {})
  }

  private async loadMonth(year: number, monthNum: number): Promise<void> {
    if (this.loading) return
    this.loading = true
    this.errorMsg = ''
    try {
      const res = await this.calRepo.loadMonth(year, monthNum)
      if (res.error) { this.errorMsg = res.error; return }
      if (res.month) { this.month = res.month }
    } catch (e) {
      this.errorMsg = String(e)
    } finally {
      this.loading = false
    }
  }

  private prevMonth(): void {
    const y0 = this.month.meta.year, m0 = this.month.meta.month
    const y = m0 === 1 ? y0 - 1 : y0
    const m = m0 === 1 ? 12 : m0 - 1
    this.loadMonth(y, m).then(() => {})
  }

  private nextMonth(): void {
    const y0 = this.month.meta.year, m0 = this.month.meta.month
    const y = m0 === 12 ? y0 + 1 : y0
    const m = m0 === 12 ? 1 : m0 + 1
    this.loadMonth(y, m).then(() => {})
  }

  private async onSelectDate(date: string): Promise<void> {
    this.selectedDate = date
    // 加载概要
    const r = await this.histRepo.getByDate(date)
    if (r.error) {
      this.errorMsg = r.error
      this.summary = undefined
      return
    }
    this.summary = r.item
  }

  private goHome(): void {
    router.pushUrl({ url: 'pages/MainPage' })
  }

  private goDetail(): void {
    if (this.selectedDate && this.summary) {
      router.pushUrl({ url: 'pages/DiaryDetail', params: { date: this.selectedDate } })
    }
  }

  @Builder
  SummaryCard() {
    if (this.summary) {
      Column() {
        // 标题与日期
        Row() {
          Text(this.summary.title).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#2F2B28').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
          Text(this.summary.date).fontSize(12).fontColor('#8B8079')
        }
        .width('100%')

        // 摘要
        Text(this.summary.snippet).fontSize(14).fontColor('#5D5652').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 8 })

        // 标签与模型
        Row() {
          ForEach(this.summary.tags, (t: string) => {
            Text(t).fontSize(11).fontColor('#5D5652')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('rgba(166,145,129,0.15)')
              .borderRadius(10)
              .margin({ right: 6, top: 8 })
          }, (t: string) => t)

          if (this.summary.model) {
            Text(this.summary.model as string).fontSize(11).fontColor('#8B8079')
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .borderRadius(10)
              .margin({ left: 4, top: 8 })
          }
        }
        .width('100%')

        // 查看详情按钮
        Button() {
          Text('查看详情').fontSize(16).fontColor(Color.White)
        }
        .margin({ top: 12 })
        .linearGradient({ angle: 135, colors: [[0xA69181, 0.0], [0xD7C3B4, 1.0]] })
        .borderRadius(12)
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .onClick(() => this.goDetail())
      }
      .padding(12)
      .borderRadius(16)
      .backgroundColor('rgba(255, 255, 255, 0.7)')
      .backdropBlur(15)
      .shadow({ radius: 10, color: 'rgba(166, 145, 129, 0.15)', offsetY: 4 })
    }
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Button('主页')
          .backgroundColor('transparent')
          .fontColor('#5D5652')
        Blank().layoutWeight(1)
        Button('上个月').backgroundColor('transparent').fontColor('#5D5652').onClick(() => this.prevMonth())
        Button('下个月').backgroundColor('transparent').fontColor('#5D5652').onClick(() => this.nextMonth())
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })

      // 日历主体
      if (this.errorMsg) {
        Text(this.errorMsg).fontColor('#C00').margin({ top: 12 })
      } else if (this.loading) {
        Text('加载中...').fontColor('#8B8079').margin({ top: 12 })
      } else {
        CalendarHeatmap({ month: this.month, handlers: this.heatmapHandlers })
          .margin({ top: 8 })
      }

      // 选中日期小标题
      if (this.selectedDate) {
        Row() {
          Text(`选中：${this.selectedDate}`).fontSize(12).fontColor('#8B8079')
        }
        .margin({ top: 8 })
      }

      // 概要卡片（选中且有数据时显示）
      this.SummaryCard()

      Blank().layoutWeight(1)

      // 底部导航
      Row() {
        BottomNavBar({ showGenerationModal: $showGenerationModalLocal })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 20 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%').height('100%')
  }
}