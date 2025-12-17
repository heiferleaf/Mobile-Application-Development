import { getTodayStr, DateParts } from "../common/dataUtils";

@Component
export default struct HomeHeader {
  title: string = "Inspired Day";
  subtitle: string = "让AI帮你陪伴成长，记录当下美好";
  todayParts: DateParts = getTodayStr();

  build() {
    Row() {
      // 左侧日期区 - 视觉重心
      Column() {
        Text(this.todayParts.day)
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#5D5652') // 深暖灰
          .fontFamily('HarmonyOS Sans')

        Row() {
          Text(this.todayParts.year + " . " + this.todayParts.month)
            .fontSize(14)
            .fontColor('#8A8077') // 浅暖灰
            .fontWeight(FontWeight.Medium)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ right: 20 })

      // 中间分割线 (极细)
      Divider()
        .vertical(true)
        .height(40)
        .color('rgba(93, 86, 82, 0.2)')
        .margin({ right: 20 })

      // 右侧标题区
      Column() {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C4A68') // 墨蓝
          .margin({ bottom: 6 })

        Text(this.subtitle)
          .fontSize(12)
          .fontColor('#6F7885') // 灰蓝
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 60, bottom: 20 }) // Top padding 避开刘海/状态栏
    .alignItems(VerticalAlign.Center)
  }
}