import GlassInfoCard from './GlassInfoCard';
import { SimpleDiaryRecord } from '../common/SimpleDiaryRecord';

// 显式声明：占位卡样式变换接口（避免匿名对象类型）
interface StyleTransform {
  scaleX: number;
  scaleY: number;
  tx: number;
  ty: number;
  angle: number;
  z: number;
  opacity: number;
}

@Component
export default struct StackSlideCardList {
  @Prop records: SimpleDiaryRecord[];

  @State curIndex: number = 0;
  private panThreshold: number = 40;

  aboutToAppear() {
    if (!this.records || this.records.length === 0) {
      // 空态默认中间卡为主卡
      this.curIndex = 1;
    } else {
      this.curIndex = Math.min(this.curIndex, this.records.length - 1);
    }
  }

  // 工具方法：构造样式变换对象（返回显式接口类型）
  private buildStyle(scaleX: number, scaleY: number, tx: number, ty: number, angle: number, z: number, opacity: number): StyleTransform {
    const s: StyleTransform = { scaleX, scaleY, tx, ty, angle, z, opacity };
    return s;
  }

  // 占位卡片（在内部应用样式，参数使用显式接口类型）
  @Builder
  PlaceholderCard(hint: string, accentBg: string, style: StyleTransform) {
    Column() {
      Row() {
        Text('📌').fontSize(24).margin({ right: 8 })
        Column() {
          Text('这里还没有记录')
            .fontSize(16)
            .fontColor('#4A3F35')
            .fontWeight(FontWeight.Medium)
          Text(hint)
            .fontSize(12)
            .fontColor('#6F7885')
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Rect()
        .width('100%')
        .height(80)
        .fill('rgba(0,0,0,0.06)')
        .borderRadius(12)
    }
    .width(280)
    .height(360)
    .padding(20)
    .backgroundColor(accentBg)
    .backdropBlur(20)
    .borderRadius(24)
    .border({ width: 0.5, color: 'rgba(255,255,255,0.4)' })
    .shadow({ radius: 15, color: 'rgba(166,145,129,0.10)', offsetY: 5 })
    .scale({ x: style.scaleX, y: style.scaleY })
    .translate({ x: style.tx, y: style.ty })
    .rotate({ angle: style.angle, z: style.z })
    .opacity(style.opacity)
    .zIndex(style.opacity >= 1 ? 100 : 99) // 中心卡更高层级
    .animation({ duration: 300, curve: Curve.FastOutSlowIn })
  }

  @Builder
  CardBuilder(item: SimpleDiaryRecord, index: number) {
    if (!item) {
      Blank()
    } else {
      if (Math.abs(index - this.curIndex) <= 2) {
        GlassInfoCard({
          record: item,
          bgcolor: (index === this.curIndex) ? 'rgba(255, 255, 255, 0.55)' : 'rgba(255, 255, 255, 0.75)'
        })
          .width(280)
          .height(360)
          .scale({
            x: (index === this.curIndex) ? 1 : 0.9,
            y: (index === this.curIndex) ? 1 : 0.9
          })
          .translate({
            x: (index - this.curIndex) * 35,
            y: Math.abs(index - this.curIndex) * 10
          })
          .rotate({
            angle: (index === this.curIndex) ? 0 : ((index > this.curIndex) ? 6 : -6),
            z: 1
          })
          .opacity(Math.abs(index - this.curIndex) > 1 ? 0.6 : 1)
          .zIndex(100 - Math.abs(index - this.curIndex))
          .animation({ duration: 300, curve: Curve.FastOutSlowIn })
      }
    }
  }

  build() {
    if (this.records && this.records.length > 0) {
      Stack({ alignContent: Alignment.Center }) {
        ForEach(this.records, (item: SimpleDiaryRecord, index: number) => {
          this.CardBuilder(item, index);
        }, (item: SimpleDiaryRecord) => item.id)
      }
      .width('100%')
      .height(420)
      .gesture(
        PanGesture()
          .onActionEnd((e: GestureEvent) => {
            if (e.offsetX < -this.panThreshold && this.curIndex < this.records.length - 1) {
              this.curIndex++;
            } else if (e.offsetX > this.panThreshold && this.curIndex > 0) {
              this.curIndex--;
            }
          })
      )
    } else {
      // 无数据：展示 3 张占位卡，中间为主卡
      Stack({ alignContent: Alignment.Center }) {
        this.PlaceholderCard(
          '点击下方“记一笔”新增你的第一条记录。',
          'rgba(255,255,255,0.50)',
          this.buildStyle(0.9, 0.9, -35, 10, -6, 1, 0.9)
        )

        this.PlaceholderCard(
          '这里是你的日常记录卡片区，新增内容会出现在这里。',
          'rgba(255,255,255,0.65)',
          this.buildStyle(1, 1, 0, 0, 0, 1, 1)
        )

        this.PlaceholderCard(
          '支持文字、图片和语音类型的记录。',
          'rgba(255,255,255,0.50)',
          this.buildStyle(0.9, 0.9, 35, 10, 6, 1, 0.9)
        )
      }
      .width('100%')
      .height(420)
      .gesture(
        PanGesture()
          .onActionEnd((e: GestureEvent) => {
            if (e.offsetX < -this.panThreshold && this.curIndex < 2) {
              this.curIndex++;
            } else if (e.offsetX > this.panThreshold && this.curIndex > 0) {
              this.curIndex--;
            }
          })
      )
    }
  }
}