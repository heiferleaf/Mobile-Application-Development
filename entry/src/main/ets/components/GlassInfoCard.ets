import { SimpleDiaryRecord } from '../common/SimpleDiaryRecord';

@Component
export default struct GlassInfoCard {
  @Prop record: SimpleDiaryRecord;
  @Prop bgcolor: string = 'rgba(255, 255, 255, 0.6)'; // 默认极透

  // --- Builders (严格遵循 ArkTS 语法，逻辑封装在 Builder 中) ---

  @Builder
  renderLocation() {
    if (this.record.location && this.record.location.length > 0) {
      Row() {
        Text(this.formatTime(this.record.time))
          .fontColor('#8A8077') // 暖灰
          .fontSize(12)
        Text(' · ' + this.record.location)
          .fontColor('#A9CABF') // 淡青色，呼应水彩
          .fontSize(12)
      }
      .margin({ top: 10 })
    } else {
      Row() {
        Text(this.formatTime(this.record.time))
          .fontColor('#8A8077')
          .fontSize(12)
      }
      .margin({ top: 10 })
    }
  }

  @Builder
  renderImageArea() {
    if (this.record.type === 'image') {
      if (this.record.imageUrl && this.record.imageUrl.length > 0) {
        Image(this.record.imageUrl)
          .width('100%')
          .height(100)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
          .margin({ top: 12 })
      } else {
        // 占位图逻辑
        Image($r('app.media.card_placeholder')) // 请确保有此图片，或暂时用纯色
          .width('100%')
          .height(80)
          .objectFit(ImageFit.Contain)
          .opacity(0.5)
          .margin({ top: 12 })
      }
    } else {
      // 文本/语音类型不显示大图，用空白占位保持布局
      Blank()
    }
  }

  // --- 主 Build ---

  build() {
    // 防御性编程：如果数据为空，渲染透明占位
    if (!this.record) {
      Column().width('100%').height('100%')
    } else {
      Column() {
        // 1. 顶部：图标 + 时间地点
        Row() {
          Text(this.getTypeEmoji(this.record.type))
            .fontSize(24)
            .margin({ right: 8 })

          this.renderLocation()
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 2. 内容摘要
        Text(this.record.content)
          .fontSize(16)
          .fontColor('#4A3F35') // 深褐色，比纯黑更柔和
          .fontWeight(FontWeight.Medium)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 12 })
          .lineHeight(24)

        // 3. 图片区 (Builder)
        this.renderImageArea()
      }
      .width('100%')
      .height('100%')
      .padding(20)
      .backgroundColor(this.bgcolor) //主要背景色
      .backdropBlur(20) // 关键：背景模糊，实现毛玻璃质感
      .borderRadius(24)
      .border({ width: 0.5, color: 'rgba(255,255,255,0.4)' }) // 极细的玻璃边缘光
      .shadow({ radius: 15, color: 'rgba(166, 145, 129, 0.1)', offsetY: 5 }) // 暖色柔和阴影
    }
  }

  // --- Helpers ---
  private getTypeEmoji(type: string): string {
    switch (type) {
      case 'text': return '📝';
      case 'image': return '🖼️';
      case 'voice': return '🎙️';
      default: return '📌';
    }
  }

  private formatTime(time: string): string {
    if (!time) return '';
    let parts = time.split(' ');
    return parts.length > 1 ? parts[1] : time;
  }
}